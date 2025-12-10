// src/booking/booking.controller.ts
import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  HttpCode,
  HttpStatus,
  UseGuards,
  Request,
  ForbiddenException,
  Patch, 
} from '@nestjs/common';
import { BookingService } from './booking.service';
import { Booking } from './booking.entity';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AdminGuard } from '../admin/admin.guard';
import { CreateBookingDto, PaymentConfirmationDto } from './booking.dto';


@Controller('bookings')
export class BookingController {
  constructor(private readonly bookingService: BookingService) {}

  // 1. Get all bookings for the authenticated user
  @Get()
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  async getMyBookings(@Request() req): Promise<Booking[]> {
    const userId = req.user.userId || req.user.id;
    return this.bookingService.findByUser(userId);
  }

  // 2. Create booking from shopping cart (Sets status to PENDING)
  @Post('')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.CREATED)
  async createPendingBooking(@Request() req): Promise<any> {
    const userId = req.user.userId || req.user.id;
    // Call the PENDING creation service
    return this.bookingService.createPendingBookingFromCart(userId); 
  }

  // 3. Endpoint to finalize the booking after successful Stripe payment
  @Post('confirm-payment') 
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  async confirmPayment(@Body() paymentDto: PaymentConfirmationDto, @Request() req): Promise<Booking> {
    const userId = req.user.userId || req.user.id;
    const userName = req.user.username || 'Customer'; // Now available from JWT
    
    console.log('🔍 DEBUG - JWT User Object:', JSON.stringify(req.user, null, 2));
    console.log('👤 DEBUG - Username from JWT:', userName);
    
    return this.bookingService.confirmBookingPayment(
      paymentDto.bookingId,
      userId,
      userName // Pass username from JWT
    );
  }

  // 4. Get all bookings for all users (admin endpoint)
  @Get('allbooking')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @HttpCode(HttpStatus.OK)
  async findAll(): Promise<Booking[]> {
    return this.bookingService.findAll();
  }

  // 5. Admin Endpoint: Get Total Sales
  @Get('admin/sales/total')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @HttpCode(HttpStatus.OK)
  async getTotalSales(): Promise<{ totalSales: number }> {
    return this.bookingService.getTotalSales();
  }

  // 6. Admin Endpoint: Get Total Bookings and Services Details
  @Get('admin/bookings/details')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @HttpCode(HttpStatus.OK)
  async getBookingsDetails(): Promise<{ totalBookings: number, bookedServices: { serviceId: string, bookingDate: Date }[] }> {
    return this.bookingService.getTotalBookingsAndServices();
  }

  // 7. Cancel booking (using PATCH)
  @Patch(':id/cancel') 
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  async cancelBooking(@Param('id') bookingId: string, @Request() req): Promise<Booking> {
    const userId = req.user.userId || req.user.id;
    const userFullName = req.user.username || 'Customer'; // Now available from JWT
    
    console.log('🔍 DEBUG - JWT User Object (Cancel):', JSON.stringify(req.user, null, 2));
    console.log('👤 DEBUG - Username from JWT (Cancel):', userFullName);

    return this.bookingService.cancelBooking(bookingId, userId, userFullName);
  }

  // 8. Vendor Endpoint: Get Vendor Sales
  @Get('vendor/sales')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  async getVendorSales(@Request() req): Promise<{ totalSales: number; totalBookings: number }> {
    const vendorId = req.user.userId || req.user.id;
    const userRole = req.user.role; 

    if (userRole !== 'vendor') {
      throw new ForbiddenException('Only vendors can access their sales data.');
    }

    return this.bookingService.getVendorSalesAndBookings(vendorId);
  }

}