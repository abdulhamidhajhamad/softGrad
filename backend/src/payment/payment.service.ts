import { Injectable, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Stripe from 'stripe';

// DTO for the request data
interface CreatePaymentIntentDto {
  amount: number; // Amount in USD
  currency: string; // e.g., 'usd'
}

@Injectable()
export class PaymentService {
  private stripe: Stripe;

  constructor(private configService: ConfigService) {
    // Initialize Stripe with the Secret Key from environment variables
    const secretKey = this.configService.get<string>('STRIPE_SECRET_KEY');
    if (!secretKey) {
      throw new Error('STRIPE_SECRET_KEY is not set in environment variables.');
    }
    // FIX 2: Use non-null assertion on secretKey
    this.stripe = new Stripe(secretKey!, { 
      apiVersion: '2025-11-17.clover', 
    });
  }

  /**
   * Creates a Payment Intent on Stripe's server.
   * @param amount - The total amount to be charged (e.g., 50.00)
   * @param currency - The currency (e.g., 'usd')
   * @returns The clientSecret required by Flutter to confirm payment.
   */
  async createPaymentIntent(dto: CreatePaymentIntentDto): Promise<{ clientSecret: string }> {
    const { amount, currency } = dto;
    
    if (amount <= 0) {
      throw new BadRequestException('Payment amount must be positive.');
    }

    try {
      // Stripe requires the amount in the smallest currency unit (e.g., cents)
      const amountInCents = Math.round(amount * 100); 

   const paymentIntent = await this.stripe.paymentIntents.create({
    amount: amountInCents,
    currency: currency,
    metadata: { bookingId: 'BOOKING_ID_FROM_REQUEST' }, 
});
      // FIX 3: Use non-null assertion on client_secret
      // We only return the clientSecret to the frontend (Flutter)
      return { clientSecret: paymentIntent.client_secret! }; 

    } catch (error) {
      console.error('Stripe Payment Intent Creation Error:', error);
      
      // Check if it's a known Stripe error type
      if (error && (error as any).type === 'StripeInvalidRequestError') {
        throw new BadRequestException(`Stripe Request Failed: ${(error as any).message}`);
      }
      
      // General error handling
      throw new BadRequestException('Failed to process payment request with Stripe.');
    }
  }

  // Future service for handling Webhooks (optional for basic project)
  // async handleWebhook(signature: string, rawBody: Buffer) { ... }
}