import { IsEmail, IsString, MinLength, IsOptional, IsIn } from 'class-validator';

export class SignUpDto {
  @IsString()
  userName: string;

  @IsEmail()
  email: string;

  @IsString()
  @MinLength(6)
  password: string;

  @IsOptional()
  @IsString()
  phone?: string;

  @IsOptional()
  @IsString()
  city?: string;

  @IsString()
  @IsIn(['client', 'vendor', 'admin'])
  role: 'client' | 'vendor' | 'admin';

  @IsOptional()
  @IsString()
  imageUrl?: string;
}

export class LoginDto {
  @IsEmail()
  email: string;

  @IsString()
  password: string;
}

export class ForgotPasswordDto {
  @IsEmail()
  email: string;
}

export class ResetPasswordDto {
  @IsString()
  token: string;

  @IsString()
  @MinLength(6)
  newPassword: string;
}

// ✅ NEW: DTO for verifying email with code
export class VerifyEmailDto {
  @IsEmail()
  email: string;

  @IsString()
  @MinLength(6)
  @MinLength(6)
  verificationCode: string;
}

// ✅ NEW: DTO for resending verification code
export class ResendVerificationDto {
  @IsEmail()
  email: string;
}