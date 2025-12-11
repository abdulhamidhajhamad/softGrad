import { IsEmail, IsString, MinLength, IsOptional, IsEnum,IsNotEmpty } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class SignUpDto {
  @IsString()
  @ApiProperty({ example: 'John Doe' })
  userName: string;

  @IsEmail()
  @ApiProperty({ example: 'john@example.com' })
  email: string;

  @IsString()
  @MinLength(6)
  @ApiProperty({ example: '123456' })
  password: string;

  @IsOptional()
  @IsString()
  @ApiPropertyOptional({ example: '0791234567' })
  phone?: string;

  @IsOptional()
  @IsString()
  @ApiPropertyOptional({ example: 'Amman' })
  city?: string;
  
  // ✅ NEW: Add role field with enum validation
  @IsEnum(['user', 'vendor'], { 
    message: 'Role must be either "user" or "vendor"' 
  })
  @ApiProperty({
    enum: ['user', 'vendor'],
    description: 'User role - either "user" or "vendor"',
    example: 'user'
  })
  role: 'user' | 'vendor';
}


export class LoginDto {
  @IsEmail()
  email: string;

  @IsString()
  password: string;

  @IsOptional()
  @IsString()
  @ApiPropertyOptional({ example: 'fcm-registration-token-from-firebase' })
  fcmToken?: string;
}

export class ForgotPasswordDto {
  @IsEmail()
  email: string;
}

export class ResetPasswordDto {
  @IsEmail()
  email: string;

  @IsString()
  token: string;

  @IsString()
  @MinLength(6)
  newPassword: string;
}

export class VerifyEmailDto {
  @IsEmail()
  email: string;

  @IsString()
  verificationCode: string;
}

export class ResendVerificationDto {
  @IsEmail()
  email: string;
}

export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  @ApiPropertyOptional({ example: 'John Doe Updated' })
  userName?: string;

  @IsOptional()
  @IsString()
  @ApiPropertyOptional({ example: '0797654321' })
  phone?: string;

  @IsOptional()
  @IsString()
  @ApiPropertyOptional({ example: 'Irbid' })
  city?: string;
}
export class UpdateFCMTokenDto {
  @IsString()
  @IsNotEmpty()
  @ApiProperty({ example: 'fcm-registration-token-from-firebase' })
  fcmToken: string;
}
