import { Controller, HttpCode, HttpStatus, Post, Body, Patch, Delete, Get, Param, Req, UseGuards, UseInterceptors, UploadedFile, BadRequestException } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ProviderService } from './provider.service';
import { CreateServiceProviderDto, UpdateServiceProviderDto } from './provider.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { DeleteResult } from 'mongodb';
import { ServiceProvider } from './provider.entity';
// provider.controller.ts
@Controller('providers')
@UseGuards(JwtAuthGuard)
export class ProviderController {
  constructor(private readonly providerService: ProviderService) {}

@Post()
  @HttpCode(HttpStatus.CREATED)
  async create(@Req() req, @Body() dto: CreateServiceProviderDto): Promise<{ provider: ServiceProvider, token: string }> {
    try {
      const userId = req.user.userId;
      console.log('Creating provider for user:', userId);
     
      return await this.providerService.create(userId, dto);
    } catch (error) {
      throw error;
    }
  }

  @Patch('my-details') 
  async updateMyDetails(
    @Req() req,
    @Body() dto: UpdateServiceProviderDto
  ) {
    const userId = req.user.userId;
    return this.providerService.updateByUserId(userId, dto);
  }



  @Get('my-details') // 👈 الـ Endpoint الجديد: /providers/my-details
  async getMyDetails(@Req() req): Promise<any> {
    const userId = req.user.userId;
    return this.providerService.findProviderDetails(userId);
  }


  @Get()
  async getAll(@Req() req) {
    const userId = req.user.userId;
    return this.providerService.findAllByUser(userId);
  }

  @Patch(':companyName')
  async update(
    @Req() req,
    @Param('companyName') companyName: string,
    @Body() dto: UpdateServiceProviderDto
  ) {
    const userId = req.user.userId;
    return this.providerService.update(userId, companyName, dto);
  }



  @Get('my-company-name')
  async getCompanyName(@Req() req): Promise<{ companyName: string }> {
    const userId = req.user.userId;
    const companyName = await this.providerService.findCompanyNameByUserId(userId);
    return { companyName };
  }
  
  @Delete(':companyName')
  async remove(@Req() req, @Param('companyName') companyName: string): Promise<DeleteResult> {
    const userId = req.user.userId;
    const isAdmin = req.user.role === 'admin';
    return this.providerService.remove(userId, companyName, isAdmin);
  }

  @Get(':companyName')
  async get(@Req() req, @Param('companyName') companyName: string) {
    const userId = req.user.userId;
    return this.providerService.findByName(userId, companyName);
  }

  // 🆕 رفع شعار الشركة (Logo)
  @Post('upload-logo')
  @UseInterceptors(FileInterceptor('logo'))
  async uploadLogo(
    @Req() req,
    @UploadedFile() file: Express.Multer.File
  ): Promise<{ logoUrl: string }> {
    const userId = req.user.userId;
    
    if (!file) {
      throw new BadRequestException('Logo file is required');
    }

    // التحقق من نوع الملف
    const allowedMimeTypes = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
    if (!allowedMimeTypes.includes(file.mimetype)) {
      throw new BadRequestException('Invalid file type. Allowed: JPEG, PNG, WebP, GIF');
    }

    // التحقق من حجم الملف (5MB max)
    const maxSize = 5 * 1024 * 1024;
    if (file.size > maxSize) {
      throw new BadRequestException('File too large. Maximum size is 5MB');
    }

    const logoUrl = await this.providerService.uploadLogo(userId, file);
    return { logoUrl };
  }
}