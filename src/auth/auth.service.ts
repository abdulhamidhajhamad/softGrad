import {
  Injectable,
  UnauthorizedException,
  ConflictException,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { User } from './user.entity';
import { SignUpDto, LoginDto, ForgotPasswordDto, ResetPasswordDto } from './auth.dto';
import { MailService } from './mail.service';
import { ForbiddenException} from '@nestjs/common';

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
    private jwtService: JwtService,
    private mailService: MailService,
  ) {}

  async signUp(signUpDto: SignUpDto): Promise<{ token: string; user: any }> {
  const { userName, email, password, phone, city, role } = signUpDto;
  const allowedRoles = ['client', 'vendor', 'admin'];
  if (!allowedRoles.includes(role)) {
    throw new ForbiddenException(`Role must be one of: ${allowedRoles.join(', ')}`);
  }
  const existingUser = await this.userRepository.findOne({ where: { email } });
  if (existingUser) {
    throw new ConflictException('Email already exists');
  }
  const hashedPassword = await bcrypt.hash(password, 10);

  const user = this.userRepository.create({
    userName,
    email,
    password: hashedPassword,
    phone,
    city,
    role,
  });
  await this.userRepository.save(user);

  const token = this.jwtService.sign({ id: user.id, email: user.email });
  const { password: _, ...userWithoutPassword } = user;
  return {
    token,
    user: userWithoutPassword,
  };
  }

  async login(loginDto: LoginDto): Promise<{ token: string; user: any }> {
    const { email, password } = loginDto;
    // Find user by email
    const user = await this.userRepository.findOne({ where: { email } });
    if (!user) {
      throw new UnauthorizedException('Invalid Email/Pass');
    }
    // Check password
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid Email/Pass');
    }
    // Generate JWT token
    const token = this.jwtService.sign({ id: user.id, email: user.email });
    // Remove password from response
    const { password: _, ...userWithoutPassword } = user;
    return {
      token,
      user: userWithoutPassword,
     };
    }
/*
  async forgotPassword(forgotPasswordDto: ForgotPasswordDto): Promise<{ message: string }> {
    const { email } = forgotPasswordDto;

    // Find user by email
    const user = await this.userRepository.findOne({ where: { email } });
    if (!user) {
      // Don't reveal if email exists or not for security
      return { message: 'If the email exists, a reset link has been sent' };
    }

    // Generate reset token
    const resetToken = randomBytes(32).toString('hex');
    const hashedToken = await bcrypt.hash(resetToken, 10);

    // Set token and expiration (1 hour)
    user.resetPasswordToken = hashedToken;
    user.resetPasswordExpires = new Date(Date.now() + 3600000); // 1 hour
    await this.userRepository.save(user);

    // Send reset email
    const resetUrl = `${process.env.FRONTEND_URL || 'http://localhost:3000'}/reset-password?token=${resetToken}`;
    await this.mailService.sendPasswordResetEmail(user.email, resetUrl);

    return { message: 'If the email exists, a reset link has been sent' };
  }
  async resetPassword(resetPasswordDto: ResetPasswordDto): Promise<{ message: string }> {
    const { token, newPassword } = resetPasswordDto;

    // Find user with valid reset token
    const user = await this.userRepository.findOne({
      where: {
        resetPasswordToken: { $ne: null } as any,
        resetPasswordExpires: { $gt: new Date() } as any,
      },
    });

    if (!user || !user.resetPasswordToken) {
      throw new BadRequestException('Invalid or expired reset token');
    }

    // Verify token
    const isTokenValid = await bcrypt.compare(token, user.resetPasswordToken);
    if (!isTokenValid) {
      throw new BadRequestException('Invalid or expired reset token');
    }

    // Hash new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    // Update password and clear reset token
    user.password = hashedPassword;
    //user.resetPasswordToken = null;
    //user.resetPasswordExpires = null;
    await this.userRepository.save(user);

    return { message: 'Password reset successfully' };
  }
  async validateUser(userId: string): Promise<User> {
    const user = await this.userRepository.findOne({ where: { id: userId } });
    if (!user) {
      throw new UnauthorizedException('User not found');
    }
    return user;
  }
  */
}