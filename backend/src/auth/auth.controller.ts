import {
  Controller,
  Post,
  Body,
  HttpCode,
  HttpStatus,
  Get,
  UseGuards,
  Req,
  UseInterceptors,
  UploadedFile,
  Put,
  Query
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { AuthService } from './auth.service';
import { 
  SignUpDto, 
  LoginDto, 
  ForgotPasswordDto, 
  ResetPasswordDto,
  VerifyEmailDto,
  ResendVerificationDto 
} from './auth.dto';
import { JwtAuthGuard } from './jwt-auth.guard';
import { ApiConsumes, ApiBody } from '@nestjs/swagger';

@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post('signup')
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    description: 'User registration data with optional image',
    type: SignUpDto,
  })
  @UseInterceptors(FileInterceptor('image'))
  async signUp(
    @Body() signUpDto: SignUpDto,
    @UploadedFile() file?: Express.Multer.File 
  ) {
    return this.authService.signUp(signUpDto, file);
  }

  @Post('verify-email')
  @HttpCode(HttpStatus.OK)
  async verifyEmail(@Body() verifyEmailDto: VerifyEmailDto) {
    return this.authService.verifyEmail(verifyEmailDto);
  }

  @Post('resend-verification')
  @HttpCode(HttpStatus.OK)
  async resendVerification(@Body() resendVerificationDto: ResendVerificationDto) {
    return this.authService.resendVerificationCode(resendVerificationDto);
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  async login(@Body() loginDto: LoginDto) {
    return this.authService.login(loginDto);
  }

  @Put('profile')
  @UseGuards(JwtAuthGuard)
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FileInterceptor('image'))
  async updateProfile(
    @Req() req,
    @Body() updateData: {
      userName?: string;
      phone?: string;
      city?: string;
    },
    @UploadedFile() file?: Express.Multer.File
  ) {
    return this.authService.updateProfile(req.user.userId, updateData, file);
  }


  @Post('forgot-password')
  async forgotPassword(@Body('email') email: string) {
    return this.authService.forgotPassword(email);
  }

  @Get('verify-reset-token')
  async verifyToken(@Query('token') token: string, @Query('email') email: string) {
    return this.authService.verifyResetToken(token, email);
  }

  @Post('reset-password')
  async resetPassword(@Body() body: any) {
    const { email, token, newPassword } = body;
    return this.authService.resetPassword(email, token, newPassword);
  }

 /*
  @Get('profile')
  @UseGuards(JwtAuthGuard)
  async getProfile(@Req() req) {
    const { password, resetPasswordToken, resetPasswordExpires, ...user } = req.user;
    return user;
  }
  */
}