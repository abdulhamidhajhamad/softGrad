import { Controller, Post, Body, HttpCode, HttpStatus } from '@nestjs/common';
import { PaymentService } from './payment.service';

// DTO for the request data
class CreatePaymentIntentRequestDto {
  amount: number;
  currency: string;
}

@Controller('payment')
export class PaymentController {
  constructor(private readonly paymentService: PaymentService) {}

  @Post('create-payment-intent')
  @HttpCode(HttpStatus.OK)
  async createPaymentIntent(
    @Body() dto: CreatePaymentIntentRequestDto,
  ): Promise<{ clientSecret: string }> {
    // In a real app, you'd calculate the final amount here based on the cart ID
    return this.paymentService.createPaymentIntent(dto);
  }
}