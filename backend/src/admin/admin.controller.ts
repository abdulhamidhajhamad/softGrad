import { 
  Controller, Get, Post, Put, Delete, Body, Param, 
  Query, HttpCode, HttpStatus, UseGuards, Request, 
  BadRequestException 
} from '@nestjs/common';
import { AdminService } from './admin.service';
import { AdminGuard } from './admin.guard';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { 
  CreateComplaintDto, UpdateComplaintStatusDto, 
  AddComplaintNoteDto, AssignComplaintDto, 
  ComplaintFilterDto, ComplaintResponseDto 
} from './complaint/complaint.dto';

@Controller('admin')
@UseGuards(JwtAuthGuard, AdminGuard)
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

  // ============ إدارة الشكاوي ============

  @Get('complaints')
  @HttpCode(HttpStatus.OK)
  async getAllComplaints(@Query() filters: ComplaintFilterDto) {
    try {
      return await this.adminService.getAllComplaints(filters);
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }

  @Get('complaints/stats')
  @HttpCode(HttpStatus.OK)
  async getComplaintStats() {
    try {
      return await this.adminService.getComplaintStats();
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }

  @Get('complaints/:id')
  @HttpCode(HttpStatus.OK)
  async getComplaintById(@Param('id') complaintId: string) {
    try {
      return await this.adminService.getComplaintById(complaintId);
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }

  @Post('complaints')
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

  @Put('complaints/:id/status')
  @HttpCode(HttpStatus.OK)
  async updateComplaintStatus(
    @Param('id') complaintId: string,
    @Body() updateDto: UpdateComplaintStatusDto,
    @Request() req: any
  ) {
    try {
      const adminId = req.user.userId;
      const adminName = req.user.userName || 'Admin';

      return await this.adminService.updateComplaintStatus(
        complaintId,
        adminId,
        adminName,
        updateDto
      );
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }

  @Post('complaints/:id/notes')
  @HttpCode(HttpStatus.OK)
  async addComplaintNote(
    @Param('id') complaintId: string,
    @Body() noteDto: AddComplaintNoteDto,
    @Request() req: any
  ) {
    try {
      const adminId = req.user.userId;
      const adminName = req.user.userName || 'Admin';

      return await this.adminService.addComplaintNote(
        complaintId,
        adminId,
        adminName,
        noteDto
      );
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }

  @Put('complaints/:id/assign')
  @HttpCode(HttpStatus.OK)
  async assignComplaint(
    @Param('id') complaintId: string,
    @Body() assignDto: AssignComplaintDto,
    @Request() req: any
  ) {
    try {
      const assignerAdminId = req.user.userId;
      const assignerName = req.user.userName || 'Admin';

      return await this.adminService.assignComplaint(
        complaintId,
        assignerAdminId,
        assignerName,
        assignDto.adminId
      );
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }

  @Put('complaints/:id/archive')
  @HttpCode(HttpStatus.OK)
  async archiveComplaint(@Param('id') complaintId: string) {
    try {
      return await this.adminService.archiveComplaint(complaintId);
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }

  @Get('users/:userId/complaints')
  @HttpCode(HttpStatus.OK)
  async getUserComplaints(@Param('userId') userId: string) {
    try {
      return await this.adminService.getUserComplaints(userId);
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }

  @Delete('complaints/:id')
  @HttpCode(HttpStatus.OK)
  async deleteComplaint(@Param('id') complaintId: string) {
    try {
      // يمكنك إضافة منطق الحذف هنا
      throw new BadRequestException('Delete not implemented yet');
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }

  
}
