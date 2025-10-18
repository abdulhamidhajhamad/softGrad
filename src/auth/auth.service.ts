import {
  Injectable,
  UnauthorizedException,
  ConflictException,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
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
    @InjectRepository(User)
    private userRepository: Repository<User>,
    private jwtService: JwtService,
    private mailService: MailService,
  ) {}

  // ✅ Helper: Generate 6-digit random code
  private generateVerificationCode(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }

  async signUp(signUpDto: SignUpDto): Promise<{ message: string; email: string }> {
    const { userName, email, password, phone, city, role, imageUrl } = signUpDto;
    
    // Validate role
    const allowedRoles = ['client', 'vendor', 'admin'];
    if (!allowedRoles.includes(role)) {
      throw new ForbiddenException(`Role must be one of: ${allowedRoles.join(', ')}`);
    }

    // Check if user already exists
    const existingUser = await this.userRepository.findOne({ where: { email } });
    if (existingUser) {
      throw new ConflictException('Email already exists');
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Generate verification code and expiration (15 minutes from now)
    const verificationCode = this.generateVerificationCode();
    const verificationCodeExpires = new Date(Date.now() + 15 * 60 * 1000); // 15 minutes

    // Create user
    const user = this.userRepository.create({
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

    await this.userRepository.save(user);

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
    const user = await this.userRepository.findOne({ where: { email } });
    
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
    user.verificationCode = null;
    user.verificationCodeExpires = null;
    await this.userRepository.save(user);

    // Generate JWT token
    const token = this.jwtService.sign({ userId: user.id, email: user.email });
    
    // Return user without sensitive data
    const { password, verificationCode: _, verificationCodeExpires: __, ...userWithoutPassword } = user;
    
    return {
      token,
      user: userWithoutPassword,
    };
  }

  // ✅ NEW: Resend verification code
  async resendVerificationCode(resendVerificationDto: ResendVerificationDto): Promise<{ message: string }> {
    const { email } = resendVerificationDto;

    // Find user by email
    const user = await this.userRepository.findOne({ where: { email } });
    
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
    await this.userRepository.save(user);

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
    
    const user = await this.userRepository.findOne({ where: { email } });
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
    
    const token = this.jwtService.sign({ userId: user.id, email: user.email });
    
    const { password: _, verificationCode, verificationCodeExpires, ...userWithoutPassword } = user;
    return {
      token,
      user: userWithoutPassword,
    };
  }
}