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
  imageUrl?: string; // ← Add this line
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