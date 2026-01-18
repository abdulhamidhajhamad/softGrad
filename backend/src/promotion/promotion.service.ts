// src/promotion/promotion.service.ts (Enhanced)
import { Injectable, BadRequestException, NotFoundException, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import type { Model } from 'mongoose';
import { InjectQueue } from '@nestjs/bull';
import type { Queue } from 'bull';
import * as PromoEntity from './promotion-code.schema';
import type { PromotionCode } from './promotion-code.schema';
import { PromoCodeStatus, PromoCodeType } from './promotion-code.schema';
import * as UserEntity from '../auth/user.entity';
import type { User } from '../auth/user.entity';
import { 
  CreatePromotionCodeDto, 
  UpdatePromotionCodeDto,
  BroadcastMessageDto,
  ValidatePromoCodeResponseDto 
} from './promotion.dto';
import { NotificationType } from '../notification/notification.schema';
import type { EmailJob, NotificationJob } from '../notification/notification.processor';
import { Types } from 'mongoose';

@Injectable()
export class PromotionService {
  private readonly logger = new Logger(PromotionService.name);

  constructor(
    @InjectModel(PromoEntity.PromotionCode.name)
    private promoCodeModel: Model<PromotionCode>,
    @InjectModel(UserEntity.User.name)
    private userModel: Model<User>,
    @InjectQueue('email-queue') private emailQueue: Queue<EmailJob>,
    @InjectQueue('notification-queue') private notificationQueue: Queue<NotificationJob>,
  ) {}

  /**
   * Admin: Creates a new promotion code and broadcasts it to all 'user' roles.
   */
  async createAndBroadcastPromoCode(
    dto: CreatePromotionCodeDto,
    adminId: string,
  ): Promise<PromotionCode> {
    const expiryDate = new Date(dto.expiryDate);
    const startDate = dto.startDate ? new Date(dto.startDate) : new Date();

    // Validation
    if (expiryDate <= new Date()) {
      throw new BadRequestException('Expiry date must be in the future.');
    }

    if (dto.startDate && expiryDate <= startDate) {
      throw new BadRequestException('Expiry date must be after start date.');
    }

    const existingCode = await this.promoCodeModel.findOne({ 
      code: dto.code.toUpperCase() 
    });
    
    if (existingCode) {
      throw new BadRequestException('Promotion code already exists.');
    }

    // Validate discount value based on type
    const type = dto.type || PromoCodeType.PERCENTAGE;
    if (type === PromoCodeType.PERCENTAGE && dto.discountValue > 100) {
      throw new BadRequestException('Percentage discount cannot exceed 100%');
    }

    // Create the promo code
    const promoCode = await this.promoCodeModel.create({
      code: dto.code.toUpperCase(),
      description: dto.description,
      type: type,
      discountValue: dto.discountValue,
      minPurchaseAmount: dto.minPurchaseAmount,
      maxDiscountAmount: dto.maxDiscountAmount,
      startDate: startDate,
      expiryDate: expiryDate,
      usageLimit: dto.usageLimit,
      usageLimitPerUser: dto.usageLimitPerUser,
      createdBy: new Types.ObjectId(adminId),
      status: PromoCodeStatus.ACTIVE,
      isActive: true,
      notificationSent: false,
    });

    // Send notifications if requested
    if (dto.sendNotification !== false) { // Default to true
      await this.broadcastPromoCode(promoCode);
      
      // Mark as sent
      promoCode.notificationSent = true;
      await promoCode.save();
    }

    this.logger.log(`Promo code ${promoCode.code} created successfully`);
    return promoCode;
  }

  /**
   * Broadcast promo code to all users
   */
  private async broadcastPromoCode(promoCode: PromotionCode): Promise<void> {
    const discountText = promoCode.type === PromoCodeType.PERCENTAGE 
      ? `${promoCode.discountValue}% OFF` 
      : `$${promoCode.discountValue} OFF`;

    const subject = `🎉 New Discount Code: ${promoCode.code}!`;
    const body = `Use code ${promoCode.code} to get ${discountText}! ${promoCode.description}`;
    const emailHtml = this.generatePromoEmailHtml(promoCode, discountText);

    await this.broadcastToUsers(subject, body, emailHtml, NotificationType.PROMO_CODE, {
promoCodeId: (promoCode._id as Types.ObjectId).toString(),
      code: promoCode.code,
      discountValue: promoCode.discountValue,
      type: promoCode.type,
      expiryDate: promoCode.expiryDate,
    });

    this.logger.log(`Promo code ${promoCode.code} broadcast initiated`);
  }

  /**
   * Admin: Sends a general broadcast message to all 'user' roles.
   */
  async broadcastGeneralMessage(dto: BroadcastMessageDto): Promise<{ message: string }> {
    const subject = dto.title;
    const body = dto.body;
    const emailHtml = this.generateGeneralEmailHtml(dto.title, dto.body);

    await this.broadcastToUsers(subject, body, emailHtml, NotificationType.GENERAL);
    
    return { message: 'Broadcast jobs successfully added to queues.' };
  }

  /**
   * Common function to fetch users and add jobs to queues.
   */
  private async broadcastToUsers(
    title: string,
    body: string,
    emailHtml: string,
    type: NotificationType,
    metadata?: Record<string, any>,
  ): Promise<void> {
    // Fetch all verified users with 'user' role (not vendors/admins)
    const targetUsers = await this.userModel.find({ 
      role: 'user', 
      isVerified: true 
    }, 'email fcmToken _id').exec();

    this.logger.log(`Broadcasting to ${targetUsers.length} users`);

    // Add jobs to queues for each user
    for (const user of targetUsers) {
      // Add Email Job
      try {
        await this.emailQueue.add('send-email', {
          to: user.email,
          subject: title,
          htmlContent: emailHtml,
        });
      } catch (error) {
        this.logger.error(`Failed to queue email for ${user.email}:`, error);
      }

    if (user.fcmToken) {
      try {
        const notificationJob: NotificationJob = {
          token: user.fcmToken,
          title: title,
          body: body,
          userId: (user._id as Types.ObjectId).toString(),
          type: type,
        };

        await this.notificationQueue.add('send-notification', notificationJob);
      } catch (error) {
        this.logger.error(`Failed to queue notification for user ${user._id}:`, error);
      }
    }
  }


    this.logger.log(`Added ${targetUsers.length} email and notification jobs to queues`);
  }

  /**
   * User: Validate promo code for a specific amount
   */
  async validatePromoCode(
    userId: string, 
    code: string, 
    cartAmount: number
  ): Promise<ValidatePromoCodeResponseDto> {
    try {
      const promoCode = await this.promoCodeModel.findOne({ 
        code: code.toUpperCase() 
      });

      if (!promoCode) {
        return {
          valid: false,
          message: 'Invalid promo code'
        };
      }

      // Check if active
      if (promoCode.status !== PromoCodeStatus.ACTIVE || !promoCode.isActive) {
        return {
          valid: false,
          message: 'This promo code is no longer active'
        };
      }

      // Check dates
      const now = new Date();
      if (promoCode.startDate && now < new Date(promoCode.startDate)) {
        return {
          valid: false,
          message: 'This promo code is not yet valid'
        };
      }

      if (now > new Date(promoCode.expiryDate)) {
        return {
          valid: false,
          message: 'This promo code has expired'
        };
      }

      // Check usage limit
      if (promoCode.usageLimit && promoCode.usedCount >= promoCode.usageLimit) {
        return {
          valid: false,
          message: 'This promo code has reached its usage limit'
        };
      }

      // Check per-user usage limit
      if (promoCode.usageLimitPerUser) {
        const userUsageCount = promoCode.usedByUsers.filter(
          id => id === userId
        ).length;
        
        if (userUsageCount >= promoCode.usageLimitPerUser) {
          return {
            valid: false,
            message: 'You have already used this promo code the maximum number of times'
          };
        }
      }

      // Check minimum purchase amount
      if (promoCode.minPurchaseAmount && cartAmount < promoCode.minPurchaseAmount) {
        return {
          valid: false,
          message: `Minimum purchase amount of $${promoCode.minPurchaseAmount} required`
        };
      }

      // Calculate discount
      let discount = 0;
      if (promoCode.type === PromoCodeType.PERCENTAGE) {
        discount = (cartAmount * promoCode.discountValue) / 100;
        
        // Apply max discount cap if exists
        if (promoCode.maxDiscountAmount && discount > promoCode.maxDiscountAmount) {
          discount = promoCode.maxDiscountAmount;
        }
      } else {
        discount = promoCode.discountValue;
        
        // Discount cannot exceed cart amount
        if (discount > cartAmount) {
          discount = cartAmount;
        }
      }

      const finalAmount = Math.max(0, cartAmount - discount);

      return {
        valid: true,
        message: 'Promo code applied successfully',
        discount: Number(discount.toFixed(2)),
        finalAmount: Number(finalAmount.toFixed(2)),
        promoCode: {
          code: promoCode.code,
          description: promoCode.description,
          type: promoCode.type,
          discountValue: promoCode.discountValue,
          expiryDate: promoCode.expiryDate,
        }
      };
    } catch (error) {
      this.logger.error('Failed to validate promo code:', error);
      throw new BadRequestException('Failed to validate promo code');
    }
  }

  /**
   * Mark promo code as used by a user
   */
  async markPromoCodeAsUsed(code: string, userId: string): Promise<void> {
    try {
      await this.promoCodeModel.findOneAndUpdate(
        { code: code.toUpperCase() },
        {
          $inc: { usedCount: 1 },
          $push: { usedByUsers: userId }
        }
      );
      this.logger.log(`Promo code ${code} marked as used by user ${userId}`);
    } catch (error) {
      this.logger.error('Failed to mark promo code as used:', error);
    }
  }

  /**
   * Admin: Get all promo codes
   */
  async getAllPromoCodes(): Promise<PromotionCode[]> {
    return this.promoCodeModel.find().sort({ createdAt: -1 }).exec();
  }

  /**
   * Admin: Get promo code by ID
   */
  async getPromoCodeById(id: string): Promise<PromotionCode> {
    const promoCode = await this.promoCodeModel.findById(id);
    if (!promoCode) {
      throw new NotFoundException('Promo code not found');
    }
    return promoCode;
  }

  /**
   * Admin: Update promo code
   */
  async updatePromoCode(id: string, dto: UpdatePromotionCodeDto): Promise<PromotionCode> {
    const updateData: any = { ...dto };

    // Sync isActive with status
    if (dto.status === PromoCodeStatus.DISABLED) {
      updateData.isActive = false;
    } else if (dto.status === PromoCodeStatus.ACTIVE) {
      updateData.isActive = true;
    }

    const promoCode = await this.promoCodeModel.findByIdAndUpdate(
      id,
      { $set: updateData },
      { new: true, runValidators: true }
    );

    if (!promoCode) {
      throw new NotFoundException('Promo code not found');
    }

    return promoCode;
  }

  /**
   * Admin: Delete promo code
   */
  async deletePromoCode(id: string): Promise<{ message: string }> {
    const result = await this.promoCodeModel.findByIdAndDelete(id);
    
    if (!result) {
      throw new NotFoundException('Promo code not found');
    }

    return { message: 'Promo code deleted successfully' };
  }

  /**
   * Admin: Get promo code statistics
   */
  async getPromoCodeStats(): Promise<any> {
    const [total, active, expired, disabled, totalUsage] = await Promise.all([
      this.promoCodeModel.countDocuments(),
      this.promoCodeModel.countDocuments({ status: PromoCodeStatus.ACTIVE }),
      this.promoCodeModel.countDocuments({ 
        expiryDate: { $lt: new Date() } 
      }),
      this.promoCodeModel.countDocuments({ status: PromoCodeStatus.DISABLED }),
      this.promoCodeModel.aggregate([
        { $group: { _id: null, totalUsed: { $sum: '$usedCount' } } }
      ])
    ]);

    return {
      total,
      active,
      expired,
      disabled,
      totalUsage: totalUsage[0]?.totalUsed || 0
    };
  }

  /**
   * Update expired promo codes (can be called by a cron job)
   */
  async updateExpiredPromoCodes(): Promise<void> {
    try {
      const result = await this.promoCodeModel.updateMany(
        {
          expiryDate: { $lt: new Date() },
          status: PromoCodeStatus.ACTIVE
        },
        {
          $set: { 
            status: PromoCodeStatus.EXPIRED,
            isActive: false 
          }
        }
      );
      this.logger.log(`Updated ${result.modifiedCount} expired promo codes`);
    } catch (error) {
      this.logger.error('Failed to update expired promo codes:', error);
    }
  }

  // --- HTML Generation Helpers ---
  private generatePromoEmailHtml(promoCode: PromotionCode, discountText: string): string {
    const expiryDateFormatted = new Date(promoCode.expiryDate).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });

    return `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
          .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
          .promo-code { background: white; border: 2px dashed #667eea; padding: 20px; margin: 20px 0; text-align: center; border-radius: 8px; }
          .code { font-size: 32px; font-weight: bold; color: #667eea; letter-spacing: 2px; }
          .discount { font-size: 24px; color: #764ba2; margin: 10px 0; }
          .details { background: white; padding: 15px; margin: 20px 0; border-radius: 8px; }
          .btn { display: inline-block; background: #667eea; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; margin: 20px 0; }
          .footer { text-align: center; color: #666; font-size: 12px; margin-top: 20px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🎉 Special Offer Just for You!</h1>
          </div>
          <div class="content">
            <p>We have an exclusive promo code that you won't want to miss!</p>
            
            <div class="promo-code">
              <div class="discount">${discountText}</div>
              <div class="code">${promoCode.code}</div>
              <p style="margin: 10px 0; color: #666;">${promoCode.description}</p>
            </div>

            <div class="details">
              <h3>Promo Code Details:</h3>
              <ul>
                <li><strong>Discount:</strong> ${discountText}</li>
                ${promoCode.minPurchaseAmount ? `<li><strong>Minimum Purchase:</strong> $${promoCode.minPurchaseAmount}</li>` : ''}
                ${promoCode.maxDiscountAmount ? `<li><strong>Maximum Discount:</strong> $${promoCode.maxDiscountAmount}</li>` : ''}
                <li><strong>Valid Until:</strong> ${expiryDateFormatted}</li>
                ${promoCode.usageLimit ? `<li><strong>Limited to:</strong> ${promoCode.usageLimit} total uses</li>` : ''}
              </ul>
            </div>

            <center>
              <a href="YOUR_APP_URL" class="btn">Start Booking Now</a>
            </center>

            <p style="margin-top: 20px; font-size: 14px; color: #666;">
              Don't miss out on this amazing deal! Use the code at checkout before it expires.
            </p>
          </div>
          <div class="footer">
            <p>This is an automated email. Please do not reply.</p>
            <p>&copy; ${new Date().getFullYear()} Your Company. All rights reserved.</p>
          </div>
        </div>
      </body>
      </html>
    `;
  }

  private generateGeneralEmailHtml(title: string, body: string): string {
    return `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; background: #f9f9f9; border-radius: 10px; }
          .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; text-align: center; border-radius: 10px 10px 0 0; }
          .content { background: white; padding: 30px; border-radius: 0 0 10px 10px; }
          .footer { text-align: center; color: #666; font-size: 12px; margin-top: 20px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h2>📢 ${title}</h2>
          </div>
          <div class="content">
            <p>${body}</p>
            <p>Check out the new deals on our app now!</p>
          </div>
          <div class="footer">
            <p>&copy; ${new Date().getFullYear()} Your Company. All rights reserved.</p>
          </div>
        </div>
      </body>
      </html>
    `;
  }
}