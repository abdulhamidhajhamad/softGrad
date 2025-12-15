// package.controller.ts
import { Controller, Post, HttpCode, HttpStatus, Body, Req, UseGuards, Get, Delete, Param, UseInterceptors, UploadedFile, BadRequestException, Patch, Put, Query, DefaultValuePipe, ParseIntPipe } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express'; // 👈 استيراد جديد
import { PackageService } from './package.service';
import { CreatePackageDto } from './package.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
@Controller('packages')
@UseGuards(JwtAuthGuard)
export class PackageController {
  constructor(private readonly packageService: PackageService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @UseInterceptors(FileInterceptor('file')) // 👈 التعديل هنا
  async create(
    @Req() req, 
    @Body() dto: CreatePackageDto,
    @UploadedFile() file?: Express.Multer.File, // 👈 التعديل هنا (اختياري)
  ): Promise<{ message: string }> { 
    const vendorId = req.user.userId; 
    // ملاحظة: التحقق من نوع الملف يمكن إجراؤه هنا إذا لزم الأمر
    await this.packageService.createPackage(vendorId, dto, file); // 👈 إرسال الملف إلى الـ Service
    
    return { message: 'Package created successfully' }; 
  }

  // 🆕 GET /packages - جلب جميع الباقات للمستخدم الحالي (Vendor)
  @Get()
  @HttpCode(HttpStatus.OK)
  async getAll(@Req() req): Promise<any[]> {
    const vendorId = req.user.userId;
    // ترجع [{ packageName: '...', serviceNames: ['name1', 'name2'] }, ...]
    return this.packageService.getVendorPackages(vendorId);
  }

  // 🆕 DELETE /packages/:id - حذف باقة بواسطة ID
  @Delete(':id')
  @HttpCode(HttpStatus.OK) 
  async remove(@Req() req, @Param('id') packageId: string): Promise<{ message: string }> {
    const vendorId = req.user.userId;
    await this.packageService.deletePackage(packageId, vendorId);
    return { message: 'Package deleted successfully' };
  }

  @Get(':id')
@HttpCode(HttpStatus.OK)
async getOne(@Req() req, @Param('id') packageId: string): Promise<any> {
  const vendorId = req.user.userId;
  return this.packageService.getPackageById(packageId, vendorId);
}

@Put(':id')
@HttpCode(HttpStatus.OK)
async update(
  @Req() req,
  @Param('id') packageId: string,
  @Body() dto: CreatePackageDto,
): Promise<{ message: string }> {
  const vendorId = req.user.userId;
  await this.packageService.updatePackage(packageId, vendorId, dto);
  return { message: 'Package updated successfully' };
}

@Patch(':id')
@HttpCode(HttpStatus.OK)
async updateStatus(
  @Req() req,
  @Param('id') packageId: string,
  @Body('isActive') isActive: boolean,
): Promise<{ message: string }> {
  const vendorId = req.user.userId;
  await this.packageService.updatePackageStatus(packageId, vendorId, isActive);
  return { message: 'Package status updated successfully' };
}

// ✅ NEW ENDPOINT: /packages/public/random-images
  // يجب التأكد من إزالة حماية JwtAuthGuard عن هذا الـ Endpoint (مثلاً باستخدام @Public())
  @Get('public/random-images') 
  @HttpCode(HttpStatus.OK)
  async getPublicRandomImages(
    // limit: عدد الصور العشوائية المطلوبة (افتراضياً 10)
    @Query('limit', new DefaultValuePipe(10), ParseIntPipe) limit: number,
  ): Promise<string[]> {
    // نمرر العدد المطلوب إلى الـ Service
    return this.packageService.getShuffledPackageImages(limit);
  }
  


  

}