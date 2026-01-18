// package.controller.ts
import { 
  Controller, Get, Post, Put, Patch, Delete, Body, Param, 
  UseGuards, Request, HttpCode, HttpStatus, UseInterceptors, UploadedFile 
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { PackageService } from './package.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CreatePackageDto, UpdatePackageDto, UpdatePackageStatusDto } from './package.dto';

@Controller('packages')
export class PackageController {
  constructor(private readonly packageService: PackageService) {}

  // ✅ Homepage endpoint - Get 5 random packages (Public - no auth required)
  @Get('home/random')
  async getRandomPackagesForHome() {
    return this.packageService.getRandomPackagesForHome(5);
  }

  @Post()
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(FileInterceptor('coverImage')) // ✅ دعم رفع صورة الغلاف
  @HttpCode(HttpStatus.CREATED)
  async createPackage(
    @Request() req, 
    @Body('data') data: string, // ✅ JSON string
    @UploadedFile() coverImage?: Express.Multer.File
  ) {
    const createDto: CreatePackageDto = JSON.parse(data);
    return this.packageService.createPackage(req.user.userId, createDto, coverImage);
  }

  @Get()
  @UseGuards(JwtAuthGuard)
  async getPackages(@Request() req) {
    const userRole = req.user.role;
    
    if (userRole === 'vendor') {
      return this.packageService.getProviderPackages(req.user.userId);
    } else {
      return this.packageService.getActivePackages();
    }
  }

  @Get(':id')
  async getPackageById(@Param('id') id: string) {
    return this.packageService.getPackageById(id);
  }

  @Put(':id')
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(FileInterceptor('coverImage')) // ✅ دعم رفع صورة جديدة
  async updatePackage(
    @Param('id') id: string,
    @Request() req,
    @Body('data') data: string, // ✅ JSON string
    @UploadedFile() coverImage?: Express.Multer.File
  ) {
    const updateDto: UpdatePackageDto = JSON.parse(data);
    return this.packageService.updatePackage(id, req.user.userId, updateDto, coverImage);
  }

  @Patch(':id')
  async updatePackageStatus(
    @Param('id') id: string,
    @Request() req,
    @Body() statusDto: UpdatePackageStatusDto
  ) {
    return this.packageService.updatePackageStatus(id, req.user.userId, statusDto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async deletePackage(@Param('id') id: string, @Request() req) {
    await this.packageService.deletePackage(id, req.user.userId);
  }
}