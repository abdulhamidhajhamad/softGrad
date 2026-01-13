// package.controller.ts
import { Controller, Get, Post, Put, Patch, Delete, Body, Param, UseGuards, Request, HttpCode, HttpStatus } from '@nestjs/common';
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
  @HttpCode(HttpStatus.CREATED)
  async createPackage(@Request() req, @Body() createDto: CreatePackageDto) {
    return this.packageService.createPackage(req.user.userId, createDto);
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
  async updatePackage(
    @Param('id') id: string,
    @Request() req,
    @Body() updateDto: UpdatePackageDto
  ) {
    return this.packageService.updatePackage(id, req.user.userId, updateDto);
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