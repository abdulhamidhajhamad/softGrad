import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  HttpCode,
  HttpStatus,
  UseGuards,
  Request,
  ForbiddenException, 
} from '@nestjs/common';
import { BookingService } from './booking.service';
import { CreateBookingDto } from './booking.dto';
import { Booking } from './booking.entity';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AdminGuard } from '../admin/admin.guard'; // 👈 يجب استيراد AdminGuard
class PaymentConfirmationDto {
    bookingId: string;
}
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

  // 2. Create booking from shopping cart 
@Post('')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.CREATED)
  async createPendingBooking(@Request() req): Promise<any> {
    const userId = req.user.userId || req.user.id;
    // Call the new PENDING creation service
    return this.bookingService.createPendingBookingFromCart(userId); 
  }

  // NEW: 3. Endpoint to finalize the booking after successful Stripe payment
  @Post('confirm-payment')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  async confirmPayment(
    @Request() req,
    @Body() dto: PaymentConfirmationDto
  ): Promise<any> {
    // In a real app, you might also pass the Stripe PaymentIntent ID for extra verification
    return this.bookingService.confirmPaymentAndUpdateBooking(dto.bookingId);
  }
/*
  // 3. Create booking with custom data
  @Post()
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.CREATED)
  async create(@Request() req, @Body() dto: CreateBookingDto): Promise<Booking> {
    const userId = req.user.userId || req.user.id;
    return this.bookingService.create(userId, dto);
  }
*/
  // 4. Cancel booking (remove booking dates from services)
  @Delete(':bookingId')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  async cancelBooking(
    @Request() req,
    @Param('bookingId') bookingId: string,
  ): Promise<{ message: string }> {
    const userId = req.user.userId || req.user.id;
    return this.bookingService.cancelBooking(userId, bookingId);
  }

  // 5. Get all bookings for all users (admin endpoint)
  @Get('allbooking')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  async findAll(): Promise<Booking[]> {
    return this.bookingService.findAll();
  }

  // 6. Admin Endpoint: Get Total Sales
  @Get('admin/sales/total')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @HttpCode(HttpStatus.OK)
  async getTotalSales(): Promise<{ totalSales: number }> {
    return this.bookingService.getTotalSales();
  }

  // 7. Admin Endpoint: Get Total Bookings and Services Details
  @Get('admin/bookings/details')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @HttpCode(HttpStatus.OK)
  async getBookingsDetails(): Promise<{ totalBookings: number, bookedServices: { serviceId: string, bookingDate: Date }[] }> {
    return this.bookingService.getTotalBookingsAndServices();
  }

/**
   * Retrieves all successful bookings associated with the vendor's services and calculates total sales.
   * Endpoint: GET /bookings/vendor/sales
   * Protected: Vendor role only.
   */
  @Get('vendor/sales')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  async getVendorSales(@Request() req): Promise<{ totalSales: number; bookings: Booking[] }> {
    const vendorId = req.user.userId || req.user.id;
    const userRole = req.user.role; // Assumed to be available from the JWT payload

    // Role check to ensure only vendors can access this data
    if (userRole !== 'vendor') {
      throw new ForbiddenException('Only vendors can access their sales data.');
    }

    return this.bookingService.getVendorSalesAndBookings(vendorId);
  }


}