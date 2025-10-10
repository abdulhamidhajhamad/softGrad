import { Controller, Get, HttpCode, HttpStatus, UseGuards } from '@nestjs/common';
import { AdminService } from './admin.service';
import { AdminGuard } from './admin.guard';
import { JwtAuthGuard } from '../auth/jwt-auth.guard'; // Import your JWT guard

@Controller('admin')
@UseGuards(JwtAuthGuard, AdminGuard) // Apply JWT auth first, then admin check
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('users')
  @HttpCode(HttpStatus.OK)
  async getAllUsers() {
    return await this.adminService.getAllUsers();
  }

  @Get('providers')
  @HttpCode(HttpStatus.OK)
  async getAllProviders() {
    return await this.adminService.getAllProviders();
  }

  @Get('services')
  @HttpCode(HttpStatus.OK)
  async getAllServices() {
    return await this.adminService.getAllServices();
  }

  @Get('bookings')
  @HttpCode(HttpStatus.OK)
  async getAllBookings() {
    return await this.adminService.getAllBookings();
  }

  @Get('dashboard')
  @HttpCode(HttpStatus.OK)
  async getDashboard() {
    return await this.adminService.getDashboardStats();
  }

  @Get('analytics')
  @HttpCode(HttpStatus.OK)
  async getAnalytics() {
    return await this.adminService.getAnalytics();
  }
}