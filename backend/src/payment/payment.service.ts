// payment.service.ts - النسخة المصلحة

import { Injectable, BadRequestException, HttpException, HttpStatus, Logger, Inject, forwardRef } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose'; 
import Stripe from 'stripe';
import { Cart } from '../shoppingCart/shoppingCart.schema';
import { BookingService } from '../booking/booking.service';
import { PromotionService } from '../promotion/promotion.service';
import { MailService } from '../auth/mail.service';
import { User } from '../auth/user.entity';
import { NotificationService } from '../notification/notification.service';
import { NotificationType, RecipientType } from '../notification/notification.schema';

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
    @InjectModel(User.name) private userModel: Model<User>,
    @Inject(forwardRef(() => BookingService))
    private bookingService: BookingService,
    private promotionService: PromotionService,
    private mailService: MailService,
    private notificationService: NotificationService,
  ) {
    const secretKey = this.configService.get<string>('STRIPE_SECRET_KEY');
    if (!secretKey) {
      throw new Error('STRIPE_SECRET_KEY is not set in environment variables.');
    }
    // ✅ الحل: إزالة apiVersion أو تحديثه للنسخة الصحيحة
    this.stripe = new Stripe(secretKey);
  }

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

  async confirmPaymentAndCreateBookings(userId: string, paymentIntentId: string): Promise<any> {
    try {
      const validPaymentIntentId = paymentIntentId.split('_secret_')[0];
      this.logger.log(`Verifying PaymentIntent: ${validPaymentIntentId}`); 

      let paymentIntent = await this.stripe.paymentIntents.retrieve(validPaymentIntentId);
      
      if (paymentIntent.status === 'requires_payment_method' || paymentIntent.status === 'requires_action') {
        this.logger.warn(`PaymentIntent requires action, attempting confirm...`);
        
        paymentIntent = await this.stripe.paymentIntents.confirm(validPaymentIntentId, {
          payment_method: 'pm_card_visa', 
          return_url: 'http://localhost:3000/payment/stripe-callback',
        });
      }

      if (paymentIntent.status !== 'succeeded') {
        await this.notifyAdminPaymentFailed(userId, paymentIntent, `Payment not successful. Status: ${paymentIntent.status}`);
        
        throw new BadRequestException(`Payment not successful. Status: ${paymentIntent.status}`);
      }

      const promoCode = paymentIntent.metadata?.promoCode;
      if (promoCode) {
        await this.promotionService.markPromoCodeAsUsed(promoCode, userId);
        this.logger.log(`Promo code ${promoCode} marked as used by user ${userId}`);
      }

      const bookings = await this.bookingService.createBookingsFromCart(userId, validPaymentIntentId);

      const user = await this.getUserInfo(userId);
      
      await this.notifyAdminPaymentSuccess(user, paymentIntent, bookings.length);

      if (user && user.email) {
        await this.sendPaymentConfirmationEmail(user.email, {
          userName: user.name || user.email,
          originalAmount: parseFloat(paymentIntent.metadata?.originalAmount || '0'),
          discount: parseFloat(paymentIntent.metadata?.discount || '0'),
          finalAmount: paymentIntent.amount / 100,
          promoCode: paymentIntent.metadata?.promoCode,
          bookingsCount: bookings.length,
        });
      }

      await this.clearUserCart(userId);
      this.logger.log(`✅ Cart cleared for user: ${userId}`);

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
      
      try {
        await this.notifyAdminPaymentFailed(userId, null, error.message);
      } catch (notifError) {
        this.logger.error('Failed to send admin notification:', notifError);
      }
      
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

  private async clearUserCart(userId: string): Promise<void> {
    try {
      const objectId = Types.ObjectId.isValid(userId) ? new Types.ObjectId(userId) : userId;
      const result = await this.cartModel.findOneAndDelete({ userId: objectId });
      
      if (result) {
        this.logger.log(`✅ Cart cleared successfully for user: ${userId}`);
      } else {
        this.logger.warn(`⚠️ No cart found to clear for user: ${userId}`);
      }
    } catch (error) {
      this.logger.error(`❌ Failed to clear cart for user ${userId}:`, error);
    }
  }

  private async getUserInfo(userId: string): Promise<any> {
    try {
      const objectId = Types.ObjectId.isValid(userId) ? new Types.ObjectId(userId) : userId;
      const user = await this.userModel.findById(objectId).select('email name').exec();
      
      if (!user) {
        this.logger.warn(`⚠️ User not found: ${userId}`);
        return null;
      }
      
      return user;
    } catch (error) {
      this.logger.error(`❌ Failed to get user info for ${userId}:`, error);
      return null;
    }
  }

  private async sendPaymentConfirmationEmail(email: string, paymentDetails: any): Promise<void> {
    try {
      const hasDiscount = paymentDetails.discount > 0;
      
      const htmlContent = `
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    font-family: Arial, sans-serif;
                    line-height: 1.6;
                    color: #333;
                    background-color: #f4f4f4;
                    margin: 0;
                    padding: 0;
                }
                .container {
                    max-width: 600px;
                    margin: 20px auto;
                    background-color: #ffffff;
                    border-radius: 8px;
                    overflow: hidden;
                    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
                }
                .header {
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                    padding: 30px 20px;
                    text-align: center;
                }
                .header h1 {
                    margin: 0;
                    font-size: 28px;
                }
                .success-icon {
                    font-size: 48px;
                    margin-bottom: 10px;
                }
                .content {
                    padding: 30px 20px;
                }
                .greeting {
                    font-size: 18px;
                    margin-bottom: 20px;
                    color: #333;
                }
                .payment-details {
                    background-color: #f8f9fa;
                    border-radius: 6px;
                    padding: 20px;
                    margin: 20px 0;
                }
                .detail-row {
                    display: flex;
                    justify-content: space-between;
                    padding: 10px 0;
                    border-bottom: 1px solid #e0e0e0;
                }
                .detail-row:last-child {
                    border-bottom: none;
                }
                .detail-label {
                    font-weight: 600;
                    color: #555;
                }
                .detail-value {
                    color: #333;
                }
                .discount-row {
                    color: #28a745;
                    font-weight: 600;
                }
                .total-row {
                    font-size: 20px;
                    font-weight: bold;
                    color: #667eea;
                    margin-top: 10px;
                    padding-top: 10px;
                    border-top: 2px solid #667eea;
                }
                .message {
                    text-align: center;
                    padding: 20px;
                    color: #666;
                }
                .footer {
                    background-color: #f8f9fa;
                    padding: 20px;
                    text-align: center;
                    color: #666;
                    font-size: 14px;
                }
                .promo-badge {
                    display: inline-block;
                    background-color: #28a745;
                    color: white;
                    padding: 4px 12px;
                    border-radius: 20px;
                    font-size: 12px;
                    font-weight: bold;
                    margin-top: 15px;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <div class="success-icon">✅</div>
                    <h1>Payment Confirmed!</h1>
                    <p>Your booking has been successfully completed</p>
                </div>
                
                <div class="content">
                    <div class="greeting">
                        Hello ${paymentDetails.userName},
                    </div>
                    
                    <p>Thank you for your payment! Your booking has been confirmed successfully.</p>
                    
                    <div class="payment-details">
                        <h3 style="margin-top: 0; color: #667eea;">Payment Summary</h3>
                        
                        <div class="detail-row">
                            <span class="detail-label">Original Amount:</span>
                            <span class="detail-value">$${paymentDetails.originalAmount.toFixed(2)}</span>
                        </div>
                        
                        ${hasDiscount ? `
                        <div class="detail-row discount-row">
                            <span class="detail-label">
                                Discount ${paymentDetails.promoCode ? `(${paymentDetails.promoCode})` : ''}:
                            </span>
                            <span class="detail-value">-$${paymentDetails.discount.toFixed(2)}</span>
                        </div>
                        ` : ''}
                        
                        <div class="detail-row total-row">
                            <span class="detail-label">Total Paid:</span>
                            <span class="detail-value">$${paymentDetails.finalAmount.toFixed(2)}</span>
                        </div>
                        
                        <div class="detail-row">
                            <span class="detail-label">Number of Bookings:</span>
                            <span class="detail-value">${paymentDetails.bookingsCount}</span>
                        </div>
                        
                        ${paymentDetails.promoCode ? `
                        <div style="text-align: center;">
                            <span class="promo-badge">Promo Code Applied: ${paymentDetails.promoCode}</span>
                        </div>
                        ` : ''}
                    </div>
                    
                    <div class="message">
                        <p>🎉 Your payment has been processed successfully!</p>
                        <p>You can view your bookings in your dashboard.</p>
                    </div>
                </div>
                
                <div class="footer">
                    <p>If you have any questions, please contact our support team.</p>
                    <p style="margin: 0; color: #999; font-size: 12px;">
                        This is an automated email. Please do not reply to this message.
                    </p>
                </div>
            </div>
        </body>
        </html>
      `;

      await this.mailService.sendHtmlEmail(
        email,
        'Payment Confirmation - Your Booking is Confirmed! ✅',
        htmlContent
      );

      this.logger.log(`✅ Payment confirmation email sent to: ${email}`);
    } catch (error) {
      this.logger.error(`❌ Failed to send confirmation email to ${email}:`, error);
    }
  }

  private async notifyAdminPaymentSuccess(
    user: any, 
    paymentIntent: Stripe.PaymentIntent, 
    bookingsCount: number
  ): Promise<void> {
    try {
      const admins = await this.userModel
        .find({ role: 'admin' })
        .select('_id fcmToken')
        .lean()
        .exec();

      if (!admins || admins.length === 0) {
        this.logger.warn('⚠️ No admins found to notify');
        return;
      }

      const userName = user?.name || user?.email || 'Unknown User';
      const amount = (paymentIntent.amount / 100).toFixed(2);
      const originalAmount = parseFloat(paymentIntent.metadata?.originalAmount || '0');
      const discount = parseFloat(paymentIntent.metadata?.discount || '0');
      const promoCode = paymentIntent.metadata?.promoCode;

      let notificationBody = `💰 New payment of $${amount} from ${userName}`;
      
      if (discount > 0 && promoCode) {
        notificationBody += ` (Original: $${originalAmount.toFixed(2)}, Discount: $${discount.toFixed(2)} with code ${promoCode})`;
      }
      
      notificationBody += `. ${bookingsCount} booking(s) created.`;

      for (const admin of admins) {
        try {
          await this.notificationService.createNotification(
            {
              recipientId: new Types.ObjectId(String(admin._id)),
              recipientType: RecipientType.ADMIN,
              title: '💳 Payment Successful',
              body: notificationBody,
              type: NotificationType.PAYMENT_SUCCESS,
              metadata: {
                userId: user?._id?.toString(),
                userName: userName,
                paymentIntentId: paymentIntent.id,
                amount: amount,
                originalAmount: originalAmount,
                discount: discount,
                promoCode: promoCode || null,
                bookingsCount: bookingsCount,
                timestamp: new Date().toISOString(),
              }
            },
            (admin as any).fcmToken || ''
          );
        } catch (notifError) {
          this.logger.error(`Failed to send notification to admin ${admin._id}:`, notifError);
        }
      }

      this.logger.log(`✅ Payment success notifications sent to ${admins.length} admin(s)`);
    } catch (error) {
      this.logger.error('❌ Failed to notify admins of payment success:', error);
    }
  }

  private async notifyAdminPaymentFailed(
    userId: string, 
    paymentIntent: Stripe.PaymentIntent | null, 
    errorMessage: string
  ): Promise<void> {
    try {
      const admins = await this.userModel
        .find({ role: 'admin' })
        .select('_id fcmToken')
        .lean()
        .exec();

      if (!admins || admins.length === 0) {
        this.logger.warn('⚠️ No admins found to notify');
        return;
      }

      const user = await this.getUserInfo(userId);
      const userName = user?.name || user?.email || 'Unknown User';

      const notificationBody = `❌ Payment failed for ${userName}. Reason: ${errorMessage}`;

      for (const admin of admins) {
        try {
          await this.notificationService.createNotification(
            {
              recipientId: new Types.ObjectId(String(admin._id)),
              recipientType: RecipientType.ADMIN,
              title: '⚠️ Payment Failed',
              body: notificationBody,
              type: NotificationType.PAYMENT_FAILED,
              metadata: {
                userId: userId,
                userName: userName,
                paymentIntentId: paymentIntent?.id || 'N/A',
                status: paymentIntent?.status || 'unknown',
                errorMessage: errorMessage,
                timestamp: new Date().toISOString(),
              }
            },
            (admin as any).fcmToken || ''
          );
        } catch (notifError) {
          this.logger.error(`Failed to send notification to admin ${admin._id}:`, notifError);
        }
      }

      this.logger.log(`✅ Payment failure notifications sent to ${admins.length} admin(s)`);
    } catch (error) {
      this.logger.error('❌ Failed to notify admins of payment failure:', error);
    }
  }
}