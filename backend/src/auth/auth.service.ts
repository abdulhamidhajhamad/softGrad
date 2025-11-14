import {
  Injectable,
  UnauthorizedException,
  ConflictException,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { User } from './user.entity';
import { 
  SignUpDto, 
  LoginDto, 
  ForgotPasswordDto, 
  ResetPasswordDto,
  VerifyEmailDto,
  ResendVerificationDto 
} from './auth.dto';
import { MailService } from './mail.service';

@Injectable()
export class AuthService {
  constructor(
    @InjectModel(User.name)
    private userModel: Model<User>,
    private jwtService: JwtService,
    private mailService: MailService,
  ) {}

  // ✅ Helper: Generate 6-digit random code
  private generateVerificationCode(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }


  private generateDefaultAvatar(userName: string): string {
  const initials = this.getUserInitials(userName);
  return `https://ui-avatars.com/api/?name=${encodeURIComponent(initials)}&background=0D8ABC&color=fff&size=128`;
}
  private getUserInitials(userName: string): string {
  if (!userName) return 'U';
  
  const names = userName.trim().split(/\s+/);
  
  if (names.length === 1) {
    return userName.substring(0, 2).toUpperCase();
  } else {
    return (names[0].charAt(0) + names[names.length - 1].charAt(0)).toUpperCase();
  }
}
  async signUp(signUpDto: SignUpDto): Promise<{ message: string; email: string }> {
  const { userName, email, password, phone, city, imageUrl } = signUpDto;
  // Set default role to 'user'
  const role = 'user';
  // Check if user already exists
  const existingUser = await this.userModel.findOne({ email }).exec();
  if (existingUser) {
    throw new ConflictException('Email already exists');
  }
  // Hash password
  const hashedPassword = await bcrypt.hash(password, 10);
  // Generate verification code and expiration (15 minutes from now)
  const verificationCode = this.generateVerificationCode();
  const verificationCodeExpires = new Date(Date.now() + 15 * 60 * 1000); // 15 minutes
  const finalImageUrl = imageUrl || this.generateDefaultAvatar(userName);
  // Create user
  const user = new this.userModel({
    userName,
    email,
    password: hashedPassword,
    phone,
    city,
    role,
    imageUrl: finalImageUrl,
    isVerified: false,
    verificationCode,
    verificationCodeExpires,
  });

  await user.save();

  // Send verification email
  try {
    await this.mailService.sendVerificationEmail(email, verificationCode);
  } catch (error) {
    console.error('Failed to send verification email:', error);
    // Don't fail registration if email fails, but log it
  }

  return {
    message: 'User registered successfully. Please check your email for verification code.',
    email: user.email,
  };
}


  // ✅ NEW: Verify email with code
  async verifyEmail(verifyEmailDto: VerifyEmailDto): Promise<{ token: string; user: any }> {
    const { email, verificationCode } = verifyEmailDto;

    // Find user by email
    const user = await this.userModel.findOne({ email }).exec();
    
    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Check if already verified
    if (user.isVerified) {
      throw new BadRequestException('Email is already verified');
    }

    // Check if verification code exists
    if (!user.verificationCode || !user.verificationCodeExpires) {
      throw new BadRequestException('No verification code found. Please request a new one.');
    }

    // Check if code has expired
    if (new Date() > user.verificationCodeExpires) {
      throw new BadRequestException('Verification code has expired. Please request a new one.');
    }

    // Verify code matches
    if (user.verificationCode !== verificationCode) {
      throw new BadRequestException('Invalid verification code');
    }

    // Mark user as verified and clear verification fields
    user.isVerified = true;
    user.verificationCode = undefined;
    user.verificationCodeExpires = undefined;
    await user.save();

    // Generate JWT token
    const token = this.jwtService.sign({ 
      userId: (user._id as Types.ObjectId).toString(), 
      email: user.email 
    });
    
    // Return user without sensitive data
    const userObject = user.toObject();
    const { password, verificationCode: _, verificationCodeExpires: __, ...userWithoutPassword } = userObject;
    
    return {
      token,
      user: userWithoutPassword,
    };
  }

  // ✅ NEW: Resend verification code
  async resendVerificationCode(resendVerificationDto: ResendVerificationDto): Promise<{ message: string }> {
    const { email } = resendVerificationDto;

    // Find user by email
    const user = await this.userModel.findOne({ email }).exec();
    
    if (!user) {
      // Don't reveal if email exists or not for security
      return { message: 'If the email exists and is not verified, a new code has been sent.' };
    }

    // Check if already verified
    if (user.isVerified) {
      throw new BadRequestException('Email is already verified');
    }

    // Generate new verification code and expiration
    const verificationCode = this.generateVerificationCode();
    const verificationCodeExpires = new Date(Date.now() + 15 * 60 * 1000); // 15 minutes

    // Update user with new code
    user.verificationCode = verificationCode;
    user.verificationCodeExpires = verificationCodeExpires;
    await user.save();

    // Send verification email
    try {
      await this.mailService.sendVerificationEmail(email, verificationCode);
    } catch (error) {
      console.error('Failed to send verification email:', error);
      throw new BadRequestException('Failed to send verification email. Please try again.');
    }

    return {
      message: 'A new verification code has been sent to your email.',
    };
  }

  async login(loginDto: LoginDto): Promise<{ token: string; user: any }> {
    const { email, password } = loginDto;
    
    const user = await this.userModel.findOne({ email }).exec();
    if (!user) {
      throw new UnauthorizedException('Invalid Email/Pass');
    }

    // ✅ NEW: Check if email is verified
    if (!user.isVerified) {
      throw new UnauthorizedException('Please verify your email before logging in');
    }
    
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid Email/Pass');
    }
    
    const token = this.jwtService.sign({ 
      userId: (user._id as Types.ObjectId).toString(), 
      email: user.email 
    });
    
    const userObject = user.toObject();
    const { password: _, verificationCode, verificationCodeExpires, ...userWithoutPassword } = userObject;
    return {
      token,
      user: userWithoutPassword,
    };
  }
}