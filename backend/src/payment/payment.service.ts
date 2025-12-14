// payment.service.ts - النسخة المصلحة مع forwardRef
import { Injectable, BadRequestException, HttpException, HttpStatus, Logger, Inject, forwardRef } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose'; 
import Stripe from 'stripe';
import { Cart } from '../shoppingCart/shoppingCart.schema';
import { BookingService } from '../booking/booking.service';
import { PromotionService } from '../promotion/promotion.service';

interface CheckoutDto {
  currency: string;
  promoCode?: string;
}

@Injectable()
export class PaymentService {
  private stripe: Stripe;
  private readonly logger = new Logger(PaymentService.name);

  constructor(
    private configService: ConfigService,
    @InjectModel(Cart.name) private cartModel: Model<Cart>,
    @Inject(forwardRef(() => BookingService)) // ✅ أضف forwardRef هنا
    private bookingService: BookingService,
    private promotionService: PromotionService,
  ) {
    const secretKey = this.configService.get<string>('STRIPE_SECRET_KEY');
    if (!secretKey) {
      throw new Error('STRIPE_SECRET_KEY is not set in environment variables.');
    }
    this.stripe = new Stripe(secretKey!, { 
      apiVersion: '2025-11-17.clover' as any,
    });
  }

  /**
   * Create payment intent from cart with optional promo code
   */
  async createPaymentIntentFromCart(
    userId: string, 
    dto: CheckoutDto
  ): Promise<{ 
    clientSecret: string; 
    originalAmount: number;
    discount?: number;
    finalAmount: number;
    promoCodeApplied?: string;
  }> {
    try {
      this.logger.log(`Creating payment intent for user: ${userId}`); 

      // Find cart
      let cart = await this.cartModel.findOne({ userId: userId });
      
      if (!cart && Types.ObjectId.isValid(userId)) {
         cart = await this.cartModel.findOne({ userId: new Types.ObjectId(userId) });
      }
      
      if (!cart || !cart.items || cart.items.length === 0) {
        this.logger.warn(`Cart not found or empty for userId: ${userId}`);
        throw new BadRequestException('Cart is empty');
      }

      const originalAmount = cart.totalAmount;
      let finalAmount = originalAmount;
      let discount = 0;
      let promoCodeApplied = '';

      // Apply promo code if provided
      if (dto.promoCode) {
        const validation = await this.promotionService.validatePromoCode(
          userId,
          dto.promoCode,
          originalAmount
        );

        if (validation.valid && validation.discount && validation.finalAmount) {
          discount = validation.discount;
          finalAmount = validation.finalAmount;
          promoCodeApplied = dto.promoCode.toUpperCase();
          
          this.logger.log(`Promo code ${promoCodeApplied} applied: -$${discount}`);
        } else {
          throw new BadRequestException(validation.message || 'Invalid promo code');
        }
      }

      if (finalAmount <= 0) {
        throw new BadRequestException('Payment amount must be positive after discount');
      }

      const amountInCents = Math.round(finalAmount * 100);

      const paymentIntent = await this.stripe.paymentIntents.create({
        amount: amountInCents,
        currency: dto.currency || 'usd',
        metadata: { 
          userId: userId,
          cartItemCount: cart.items.length.toString(),
          originalAmount: originalAmount.toString(),
          discount: discount.toString(),
          promoCode: promoCodeApplied,
        },
        automatic_payment_methods: {
            enabled: true,
            allow_redirects: 'never',
        }
      });

      if (!paymentIntent.client_secret) {
        throw new HttpException('Failed to create payment intent', HttpStatus.INTERNAL_SERVER_ERROR);
      }

      return { 
        clientSecret: paymentIntent.client_secret,
        originalAmount,
        discount: discount > 0 ? discount : undefined,
        finalAmount,
        promoCodeApplied: promoCodeApplied || undefined,
      };

    } catch (error) {
      this.logger.error('Payment Intent Creation Error:', error);
      
      if (error && (error as any).type === 'StripeInvalidRequestError') {
        throw new BadRequestException(`Stripe Request Failed: ${(error as any).message}`);
      }
      
      if (error instanceof HttpException) throw error;
      throw new BadRequestException('Failed to process payment request');
    }
  }

  /**
   * Confirm payment and create bookings
   */
  async confirmPaymentAndCreateBookings(userId: string, paymentIntentId: string): Promise<any> {
    try {
      const validPaymentIntentId = paymentIntentId.split('_secret_')[0];
      this.logger.log(`Verifying PaymentIntent: ${validPaymentIntentId}`); 

      let paymentIntent = await this.stripe.paymentIntents.retrieve(validPaymentIntentId);
      
      // Handle payment confirmation if needed
      if (paymentIntent.status === 'requires_payment_method' || paymentIntent.status === 'requires_action') {
        this.logger.warn(`PaymentIntent requires action, attempting confirm...`);
        
        paymentIntent = await this.stripe.paymentIntents.confirm(validPaymentIntentId, {
          payment_method: 'pm_card_visa', 
          return_url: 'http://localhost:3000/payment/stripe-callback',
        });
      }

      if (paymentIntent.status !== 'succeeded') {
        throw new BadRequestException(`Payment not successful. Status: ${paymentIntent.status}`);
      }

      // Mark promo code as used if it was applied
      const promoCode = paymentIntent.metadata?.promoCode;
      if (promoCode) {
        await this.promotionService.markPromoCodeAsUsed(promoCode, userId);
        this.logger.log(`Promo code ${promoCode} marked as used by user ${userId}`);
      }

      // Create bookings
      const bookings = await this.bookingService.createBookingsFromCart(userId, validPaymentIntentId);

      return {
        success: true,
        message: 'Payment confirmed and bookings created successfully',
        bookings: bookings,
        paymentIntent: {
          id: paymentIntent.id,
          amount: paymentIntent.amount / 100,
          originalAmount: parseFloat(paymentIntent.metadata?.originalAmount || '0'),
          discount: parseFloat(paymentIntent.metadata?.discount || '0'),
          promoCode: paymentIntent.metadata?.promoCode,
          status: paymentIntent.status,
        }
      };

    } catch (error) {
      this.logger.error('Failed to confirm payment:', error);
      
      if ((error as any).type === 'StripeInvalidRequestError') {
         throw new BadRequestException(`Stripe Error: ${(error as any).message}`);
      }

      if (error instanceof HttpException) throw error;
      throw new HttpException('Failed to confirm payment', HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }

  async createPaymentIntent(dto: any): Promise<{ clientSecret: string }> {
      const { amount, currency } = dto;
      if (!amount || amount <= 0) {
        throw new BadRequestException('Payment amount must be positive');
      }
      try {
        const amountInCents = Math.round(amount * 100); 
        const paymentIntent = await this.stripe.paymentIntents.create({
          amount: amountInCents,
          currency: currency,
          metadata: { bookingId: 'BOOKING_ID_FROM_REQUEST' }, 
          automatic_payment_methods: {
              enabled: true,
              allow_redirects: 'never',
          }
        });
        return { clientSecret: paymentIntent.client_secret! }; 
      } catch (error) {
        this.logger.error('Stripe Payment Intent Error:', error);
        if (error && (error as any).type === 'StripeInvalidRequestError') {
          throw new BadRequestException(`Stripe Failed: ${(error as any).message}`);
        }
        throw new BadRequestException('Failed to process payment');
      }
  }

  async processPartialRefund(paymentIntentId: string, amountToRefund: number): Promise<void> {
    try {
      if (amountToRefund <= 0) {
        this.logger.warn(`Attempted to refund zero or negative amount for PI: ${paymentIntentId}`);
        return;
      }
      
      const amountInCents = Math.round(amountToRefund * 100);

      const refund = await this.stripe.refunds.create({
        payment_intent: paymentIntentId,
        amount: amountInCents, 
        metadata: {
            reason: 'Vendor cancelled specific service',
            amountUSD: amountToRefund.toFixed(2),
        }
      });
      
      this.logger.log(`✅ Partial refund of $${amountToRefund} processed successfully for PI: ${paymentIntentId}`);

    } catch (error) {
      this.logger.error(`❌ Failed to process partial refund for PI: ${paymentIntentId}`, error.message);
      throw new HttpException('Refund operation failed at the payment gateway.', HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }
}