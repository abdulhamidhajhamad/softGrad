
import { 
  Controller, Get, Post, Body, Param, 
  HttpCode, HttpStatus, UseGuards, Request, 
  BadRequestException 
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AdminService } from '../admin/admin.service';
import { 
  CreateComplaintDto 
} from './complaint/complaint.dto';

@Controller('user-complaints')
export class UserComplaintController {
  constructor(private readonly adminService: AdminService) {}

  // 1. إنشاء شكوى جديدة
  @Post()
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.CREATED)
  async createComplaint(
    @Body() createComplaintDto: CreateComplaintDto,
    @Request() req: any
  ) {
    try {
      const userId = req.user.userId;
      const userName = req.user.userName || req.user.email;
      const userEmail = req.user.email;

      return await this.adminService.createComplaint(
        userId,
        userName,
        userEmail,
        createComplaintDto
      );
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }

  // 2. جلب شكاوى المستخدم نفسه
  @Get('my-complaints')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  async getMyComplaints(@Request() req: any) {
    try {
      const userId = req.user.userId;
      return await this.adminService.getUserComplaints(userId);
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }

  // 3. جلب شكوى محددة (فقط إذا كانت للمستخدم)
  @Get(':id')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  async getComplaintById(
    @Param('id') complaintId: string,
    @Request() req: any
  ) {
    try {
      const userId = req.user.userId;
      const complaint = await this.adminService.getComplaintById(complaintId);
      
      // التحقق من أن الشكوى تخص المستخدم
      if (complaint.userId !== userId) {
        throw new BadRequestException('You are not authorized to view this complaint');
      }

      return complaint;
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }
}
