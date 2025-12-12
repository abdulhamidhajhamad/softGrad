// payment.controller.ts (Updated)
import { Controller, Post, Body, HttpCode, HttpStatus, UseGuards, Request } from '@nestjs/common';
import { PaymentService } from './payment.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { IsString } from 'class-validator';

class CreatePaymentIntentRequestDto {
  amount: number;
  currency: string;
}

class CheckoutDto {
  @IsString()
  currency: string;
}

class ConfirmPaymentDto {
  @IsString()
  paymentIntentId: string;
}

@Controller('payment')
export class PaymentController {
  constructor(private readonly paymentService: PaymentService) {}

  /**
   * Create payment intent from cart
   */
  @Post('checkout')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  async checkout(
    @Request() req,
    @Body() dto: CheckoutDto,
  ): Promise<{ clientSecret: string; amount: number }> {
    return this.paymentService.createPaymentIntentFromCart(req.user.userId, dto);
  }

  /**
   * Confirm payment and create bookings
   */
  @Post('confirm')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  async confirmPayment(
    @Request() req,
    @Body() dto: ConfirmPaymentDto,
  ): Promise<any> {
    return this.paymentService.confirmPaymentAndCreateBookings(
      req.user.userId,
      dto.paymentIntentId
    );
  }

  /**
   * Original endpoint (kept for backward compatibility)
   */
  @Post('create-payment-intent')
  @HttpCode(HttpStatus.OK)
  async createPaymentIntent(
    @Body() dto: CreatePaymentIntentRequestDto,
  ): Promise<{ clientSecret: string }> {
    return this.paymentService.createPaymentIntent(dto);
  }
}