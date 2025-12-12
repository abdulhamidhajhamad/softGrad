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

  @Get('user')
  async getUserBookings(@Request() req) {
    return this.bookingService.getUserBookings(req.user.userId);
  }

  @Get('vendor')
  async getVendorBookings(@Request() req) {
    return this.bookingService.getVendorBookings(req.user.userId);
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
}