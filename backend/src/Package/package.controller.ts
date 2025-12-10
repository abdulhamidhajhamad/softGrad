// package.controller.ts
import { Controller, Post, HttpCode, HttpStatus, Body, Req, UseGuards, Get, Delete, Param, UseInterceptors, UploadedFile, BadRequestException } from '@nestjs/common';
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
}