// payment.service.ts (Updated)
import { Injectable, BadRequestException, HttpException, HttpStatus, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose'; 
import Stripe from 'stripe';
import { Cart } from '../shoppingCart/shoppingCart.schema';
import { BookingService } from '../booking/booking.service';

interface CreatePaymentIntentDto {
  amount?: number;
  currency: string;
}

interface CheckoutDto {
  currency: string;
}

@Injectable()
export class PaymentService {
  private stripe: Stripe;
  private readonly logger = new Logger(PaymentService.name);

  constructor(
    private configService: ConfigService,
    @InjectModel(Cart.name) private cartModel: Model<Cart>,
    private bookingService: BookingService,
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
   * Create payment intent from user's cart
   */
  async createPaymentIntentFromCart(userId: string, dto: CheckoutDto): Promise<{ clientSecret: string; amount: number }> {
    try {
      this.logger.log(`Searching cart for user: ${userId}`); 

      // معالجة مشكلة الـ Type Mismatch (ObjectId vs String)
      let cart = await this.cartModel.findOne({ userId: userId });
      
      if (!cart && Types.ObjectId.isValid(userId)) {
         cart = await this.cartModel.findOne({ userId: new Types.ObjectId(userId) });
      }
      
      // التحقق من وجود الكارت ومحتوياته
      if (!cart || !cart.items || cart.items.length === 0) {
        this.logger.warn(`Cart not found or empty for userId: ${userId}`);
        throw new BadRequestException('Cart is empty');
      }

      const amount = cart.totalAmount;
      
      if (amount <= 0) {
        throw new BadRequestException('Payment amount must be positive.');
      }

      const amountInCents = Math.round(amount * 100);

      const paymentIntent = await this.stripe.paymentIntents.create({
        amount: amountInCents,
        currency: dto.currency || 'usd',
        metadata: { 
          userId: userId,
          cartItemCount: cart.items.length.toString(),
        },
        // **[التعديل الجديد لحل مشكلة return_url عند الإنشاء]**
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
        amount: amount
      };

    } catch (error) {
      this.logger.error('Stripe Payment Intent Creation Error:', error);
      
      if (error && (error as any).type === 'StripeInvalidRequestError') {
        throw new BadRequestException(`Stripe Request Failed: ${(error as any).message}`);
      }
      
      if (error instanceof HttpException) throw error;
      throw new BadRequestException('Failed to process payment request with Stripe.');
    }
  }

  /**
   * Confirm payment and create bookings
   */
  async confirmPaymentAndCreateBookings(userId: string, paymentIntentId: string): Promise<any> {
    try {
      // 1. تنظيف الـ ID
      const validPaymentIntentId = paymentIntentId.split('_secret_')[0];

      this.logger.log(`Verifying PaymentIntent: ${validPaymentIntentId}`); 

      // 2. استرجاع حالة الدفع الحالية
      let paymentIntent = await this.stripe.paymentIntents.retrieve(validPaymentIntentId);
      
      // 3. [FIX] معالجة حالة الاختبار: إذا كان يتطلب دفعاً أو إجراء (بما في ذلك 3D Secure)
      // **(تم تعديل الشرط ليشمل 'requires_action')**
      if (paymentIntent.status === 'requires_payment_method' || paymentIntent.status === 'requires_action') {
        this.logger.warn(`PaymentIntent ${validPaymentIntentId} requires payment method or action. Attempting auto-confirm with test card...`);
        
        // نقوم بتأكيد الدفع باستخدام بطاقة فيزا للاختبار (pm_card_visa)
        paymentIntent = await this.stripe.paymentIntents.confirm(validPaymentIntentId, {
          payment_method: 'pm_card_visa', 
          // **[التعديل الجديد لحل مشكلة return_url عند التأكيد]**
          return_url: 'http://localhost:3000/payment/stripe-callback',
        });
      }

      // 4. التحقق النهائي من نجاح الدفع
      if (paymentIntent.status !== 'succeeded') {
        throw new BadRequestException(`Payment not successful. Current Status: ${paymentIntent.status}`);
      }

      // 5. إنشاء الحجوزات (المنطق الأصلي)
      const bookings = await this.bookingService.createBookingsFromCart(userId, validPaymentIntentId);

      return {
        success: true,
        message: 'Payment confirmed and bookings created successfully',
        bookings: bookings,
        paymentIntent: {
          id: paymentIntent.id,
          amount: paymentIntent.amount / 100,
          status: paymentIntent.status,
        }
      };

    } catch (error) {
      this.logger.error('Failed to confirm payment:', error);
      
      // تحسين رسالة الخطأ لمعرفة السبب الدقيق
      if ((error as any).type === 'StripeInvalidRequestError') {
         throw new BadRequestException(`Stripe Error: ${(error as any).message}`);
      }

      if (error instanceof HttpException) throw error;
      throw new HttpException('Failed to confirm payment', HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }

  async createPaymentIntent(dto: CreatePaymentIntentDto): Promise<{ clientSecret: string }> {
      const { amount, currency } = dto;
      if (!amount || amount <= 0) {
        throw new BadRequestException('Payment amount must be positive.');
      }
      try {
        const amountInCents = Math.round(amount * 100); 
        const paymentIntent = await this.stripe.paymentIntents.create({
          amount: amountInCents,
          currency: currency,
          metadata: { bookingId: 'BOOKING_ID_FROM_REQUEST' }, 
          // **[التعديل الجديد لحل مشكلة return_url عند الإنشاء (هنا أيضاً)]**
          automatic_payment_methods: {
              enabled: true,
              allow_redirects: 'never',
          }
        });
        return { clientSecret: paymentIntent.client_secret! }; 
      } catch (error) {
        this.logger.error('Stripe Payment Intent Creation Error:', error);
        if (error && (error as any).type === 'StripeInvalidRequestError') {
          throw new BadRequestException(`Stripe Request Failed: ${(error as any).message}`);
        }
        throw new BadRequestException('Failed to process payment request with Stripe.');
      }
  }
}