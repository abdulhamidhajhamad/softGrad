import { Model } from 'mongoose';
import { JwtService } from '@nestjs/jwt';
import { User } from './user.entity';
import { SignUpDto, LoginDto, VerifyEmailDto, ResendVerificationDto } from './auth.dto';
import { MailService } from './mail.service';
export declare class AuthService {
    private userModel;
    private jwtService;
    private mailService;
    constructor(userModel: Model<User>, jwtService: JwtService, mailService: MailService);
    private generateVerificationCode;
    signUp(signUpDto: SignUpDto): Promise<{
        message: string;
        email: string;
    }>;
    verifyEmail(verifyEmailDto: VerifyEmailDto): Promise<{
        token: string;
        user: any;
    }>;
    resendVerificationCode(resendVerificationDto: ResendVerificationDto): Promise<{
        message: string;
    }>;
    login(loginDto: LoginDto): Promise<{
        token: string;
        user: any;
    }>;
}
