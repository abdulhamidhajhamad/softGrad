// package.controller.ts
import { Controller, Post, HttpCode, HttpStatus, Body, Req, UseGuards, Get, Delete, Param } from '@nestjs/common';import { PackageService } from './package.service';
import { CreatePackageDto } from './package.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard'; 

@Controller('packages')
@UseGuards(JwtAuthGuard)
export class PackageController {
  constructor(private readonly packageService: PackageService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  // 💡 تم تغيير نوع الإرجاع ليتضمن رسالة نصية فقط
  async create(@Req() req, @Body() dto: CreatePackageDto): Promise<{ message: string }> { 
    const vendorId = req.user.userId; 
    console.log('Creating package for vendor:', vendorId);
    
    await this.packageService.createPackage(vendorId, dto);
    
    // ✅ إرجاع رسالة النجاح المطلوبة
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