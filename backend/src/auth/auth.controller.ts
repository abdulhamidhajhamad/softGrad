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
  Query,
  Param,
  NotFoundException,
  Patch
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
import { User } from './user.entity'; // 👈 تأكد من مسار ملف الـ User entity الصحيح
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService,
    @InjectModel(User.name) private userModel: Model<User>
  ) {}


  @Post('favorites/service/:serviceId')
@UseGuards(JwtAuthGuard)
async toggleServiceFavorite(@Req() req, @Param('serviceId') serviceId: string) {
  const favorites = await this.authService.toggleFavoriteService(req.user.userId, serviceId);
  return { message: 'Favorite services updated', favorites };
}

@Post('favorites/package/:packageId')
@UseGuards(JwtAuthGuard)
async togglePackageFavorite(@Req() req, @Param('packageId') packageId: string) {
  const favorites = await this.authService.toggleFavoritePackage(req.user.userId, packageId);
  return { message: 'Favorite packages updated', favorites };
}

// تعديل بسيط على getUserProfile ليعيد المفضلات أيضاً
@Get('favorites')
@UseGuards(JwtAuthGuard) //
async getFavorites(@Req() req) {
  // req.user.userId يأتي من الـ JwtStrategy بعد التحقق من التوكن
  return this.authService.getUserFavorites(req.user.userId);
}



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

  @Get('profile')
@UseGuards(JwtAuthGuard)
async getProfile(@Req() req) {
  return this.authService.getUserProfile(req.user.userId);
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

 @Patch('profile') // أو @Patch('profile') حسب استخدامك، في الملف المرفق كان @Put
  @UseGuards(JwtAuthGuard) //
  @ApiConsumes('multipart/form-data') //
  @UseInterceptors(FileInterceptor('image')) //
  async updateProfile(
    @Req() req,
    @Body() updateData: {
      userName?: string;
      phone?: string;
      city?: string;
      currentPassword?: string; 
      newPassword?: string;
      confirmNewPassword?: string;
    },
    @UploadedFile() file?: Express.Multer.File //
  ) {
    return this.authService.updateProfile(req.user.userId, updateData, file); //
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

  // ✅ NEW: Endpoint to receive and store FCM token
  @Put('fcm-token')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  async updateFCMToken(@Req() req, @Body('fcmToken') fcmToken: string) {
    await this.authService.updateFCMToken(req.user.userId, fcmToken);
    return { message: 'FCM token updated successfully' };
  }

  @Get(':id')
async getUserById(@Param('id') id: string) {
  const user = await this.userModel.findById(id).select('userName email').lean().exec();
  if (!user) {
    throw new NotFoundException('User not found');
  }
  return user;
}


}