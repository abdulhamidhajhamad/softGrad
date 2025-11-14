"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthService = void 0;
const common_1 = require("@nestjs/common");
const mongoose_1 = require("@nestjs/mongoose");
const mongoose_2 = require("mongoose");
const jwt_1 = require("@nestjs/jwt");
const bcrypt = __importStar(require("bcrypt"));
const user_entity_1 = require("./user.entity");
const mail_service_1 = require("./mail.service");
let AuthService = class AuthService {
    userModel;
    jwtService;
    mailService;
    constructor(userModel, jwtService, mailService) {
        this.userModel = userModel;
        this.jwtService = jwtService;
        this.mailService = mailService;
    }
    generateVerificationCode() {
        return Math.floor(100000 + Math.random() * 900000).toString();
    }
    async signUp(signUpDto) {
        const { userName, email, password, phone, city, role, imageUrl } = signUpDto;
        const allowedRoles = ['client', 'vendor', 'admin'];
        if (!allowedRoles.includes(role)) {
            throw new common_1.ForbiddenException(`Role must be one of: ${allowedRoles.join(', ')}`);
        }
        const existingUser = await this.userModel.findOne({ email }).exec();
        if (existingUser) {
            throw new common_1.ConflictException('Email already exists');
        }
        const hashedPassword = await bcrypt.hash(password, 10);
        const verificationCode = this.generateVerificationCode();
        const verificationCodeExpires = new Date(Date.now() + 15 * 60 * 1000);
        const user = new this.userModel({
            userName,
            email,
            password: hashedPassword,
            phone,
            city,
            role,
            imageUrl,
            isVerified: false,
            verificationCode,
            verificationCodeExpires,
        });
        await user.save();
        try {
            await this.mailService.sendVerificationEmail(email, verificationCode);
        }
        catch (error) {
            console.error('Failed to send verification email:', error);
        }
        return {
            message: 'User registered successfully. Please check your email for verification code.',
            email: user.email,
        };
    }
    async verifyEmail(verifyEmailDto) {
        const { email, verificationCode } = verifyEmailDto;
        const user = await this.userModel.findOne({ email }).exec();
        if (!user) {
            throw new common_1.NotFoundException('User not found');
        }
        if (user.isVerified) {
            throw new common_1.BadRequestException('Email is already verified');
        }
        if (!user.verificationCode || !user.verificationCodeExpires) {
            throw new common_1.BadRequestException('No verification code found. Please request a new one.');
        }
        if (new Date() > user.verificationCodeExpires) {
            throw new common_1.BadRequestException('Verification code has expired. Please request a new one.');
        }
        if (user.verificationCode !== verificationCode) {
            throw new common_1.BadRequestException('Invalid verification code');
        }
        user.isVerified = true;
        user.verificationCode = undefined;
        user.verificationCodeExpires = undefined;
        await user.save();
        const token = this.jwtService.sign({
            userId: user._id.toString(),
            email: user.email
        });
        const userObject = user.toObject();
        const { password, verificationCode: _, verificationCodeExpires: __, ...userWithoutPassword } = userObject;
        return {
            token,
            user: userWithoutPassword,
        };
    }
    async resendVerificationCode(resendVerificationDto) {
        const { email } = resendVerificationDto;
        const user = await this.userModel.findOne({ email }).exec();
        if (!user) {
            return { message: 'If the email exists and is not verified, a new code has been sent.' };
        }
        if (user.isVerified) {
            throw new common_1.BadRequestException('Email is already verified');
        }
        const verificationCode = this.generateVerificationCode();
        const verificationCodeExpires = new Date(Date.now() + 15 * 60 * 1000);
        user.verificationCode = verificationCode;
        user.verificationCodeExpires = verificationCodeExpires;
        await user.save();
        try {
            await this.mailService.sendVerificationEmail(email, verificationCode);
        }
        catch (error) {
            console.error('Failed to send verification email:', error);
            throw new common_1.BadRequestException('Failed to send verification email. Please try again.');
        }
        return {
            message: 'A new verification code has been sent to your email.',
        };
    }
    async login(loginDto) {
        const { email, password } = loginDto;
        const user = await this.userModel.findOne({ email }).exec();
        if (!user) {
            throw new common_1.UnauthorizedException('Invalid Email/Pass');
        }
        if (!user.isVerified) {
            throw new common_1.UnauthorizedException('Please verify your email before logging in');
        }
        const isPasswordValid = await bcrypt.compare(password, user.password);
        if (!isPasswordValid) {
            throw new common_1.UnauthorizedException('Invalid Email/Pass');
        }
        const token = this.jwtService.sign({
            userId: user._id.toString(),
            email: user.email
        });
        const userObject = user.toObject();
        const { password: _, verificationCode, verificationCodeExpires, ...userWithoutPassword } = userObject;
        return {
            token,
            user: userWithoutPassword,
        };
    }
};
exports.AuthService = AuthService;
exports.AuthService = AuthService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, mongoose_1.InjectModel)(user_entity_1.User.name)),
    __metadata("design:paramtypes", [mongoose_2.Model,
        jwt_1.JwtService,
        mail_service_1.MailService])
], AuthService);
//# sourceMappingURL=auth.service.js.map