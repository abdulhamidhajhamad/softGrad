// booking.controller.ts
import { Controller, Post, Get, Body, Param, UseGuards, Request, HttpCode, HttpStatus, Patch } from '@nestjs/common';
import { BookingService } from './booking.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { IsString, IsOptional } from 'class-validator';

class CancelBookingDto {
  @IsOptional()
  @IsString()
  reason?: string;
}

@Controller('bookings')
@UseGuards(JwtAuthGuard)
export class BookingController {
  constructor(private readonly bookingService: BookingService) {}

@Get()
  async getBookings(@Request() req) {
    const userId = req.user.userId;
    const userRole = req.user.role; // 👈 نفترض أن الـ Role موجود في الـ Token

    // نمرر الـ ID ونوع الـ Role إلى Service ليقوم بتحديد دالة البحث المناسبة
    return this.bookingService.getBookingsByRole(userId, userRole);
  }

  @Get(':id')
  async getBookingById(@Param('id') id: string) {
    return this.bookingService.getBookingById(id);
  }

  @Patch(':id/cancel')
  @HttpCode(HttpStatus.OK)
  async cancelBooking(
    @Param('id') id: string,
    @Request() req,
    @Body() cancelDto: CancelBookingDto
  ) {
    return this.bookingService.cancelBookingByVendor(
      id,
      req.user.userId,
      cancelDto.reason
    );
  }

  @Get('vendor/unseen-count')
  @HttpCode(HttpStatus.OK)
  async getUnseenBookingCount(@Request() req) {
    // نرسل ID الفندر لخدمة الحجز
    const count = await this.bookingService.getUnseenCount(req.user.userId);
    // نرجع الرقم في اوبجيكت بسيط
    return { count };
  }


// 🆕 PATCH /bookings/mark-all-seen - التعديل ليناسب طلبك (تحديث الكل)
  @Patch('mark-all-seen')
  @HttpCode(HttpStatus.NO_CONTENT) // 204 No Content هو الأفضل لعمليات التحديث التي لا ترجع محتوى
  async markAllAsSeen(@Request() req) {
    const vendorId = req.user.userId;
    // 👈 استدعاء الدالة الجديدة التي تحدث جميع حجوزات البائع غير المشاهدة
    await this.bookingService.markAllVendorBookingsAsSeen(vendorId); 
    // لا نرجع شيء (204)
  }

}