import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import type { Model } from 'mongoose';
import { InjectQueue } from '@nestjs/bull';
import type { Queue } from 'bull';                              // ← fix هنا
import * as PromoEntity from './promotion-code.schema';
import type { PromotionCode } from './promotion-code.schema';
import * as UserEntity from '../auth/user.entity';
import type { User } from '../auth/user.entity';
import { CreatePromotionCodeDto, BroadcastMessageDto } from './promotion.dto';
import { NotificationType } from '../notification/notification.schema';
import type { EmailJob, NotificationJob } from '../notification/notification.processor';
import { Types } from 'mongoose';
@Injectable()
export class PromotionService {
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
    if (expiryDate <= new Date()) {
      throw new BadRequestException('Expiry date must be in the future.');
    }

    const existingCode = await this.promoCodeModel.findOne({ code: dto.code.toUpperCase() });
    if (existingCode) {
      throw new BadRequestException('Promotion code already exists.');
    }

    // 1. Save the new code
    const promoCode = await this.promoCodeModel.create({
      code: dto.code.toUpperCase(),
      discountValue: dto.discountValue,
      expiryDate: expiryDate,
      createdBy: adminId,
    });

    // 2. Prepare broadcast content
    const subject = `🎉 New Discount Code: ${promoCode.code}!`;
    const body = `Use code ${promoCode.code} for ${promoCode.discountValue * 100}% off your next event booking! Hurry, it expires on ${expiryDate.toDateString()}.`;
    const emailHtml = this.generatePromoEmailHtml(promoCode.code, promoCode.discountValue, expiryDate);

    // 3. Queue the broadcast tasks
    await this.broadcastToUsers(subject, body, emailHtml, NotificationType.PROMO_CODE);

    return promoCode;
  }

  /**
   * Admin: Sends a general broadcast message to all 'user' roles.
   */
  async broadcastGeneralMessage(dto: BroadcastMessageDto): Promise<{ message: string }> {
    const subject = dto.title;
    const body = dto.body;
    const emailHtml = this.generateGeneralEmailHtml(dto.title, dto.body);

    // Queue the broadcast tasks
    //await this.broadcastToUsers(subject, body, emailHtml, NotificationType.MESSAGE);
    
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
  ): Promise<void> {
    // Fetch all verified users with 'user' role
    const targetUsers = await this.userModel.find({ 
        role: 'user', 
        isVerified: true 
    }, 'email fcmToken').exec();

    // Add jobs to queues for each user
    for (const user of targetUsers) {
      // Add Email Job
      await this.emailQueue.add('send-email', {
        to: user.email,
        subject: title,
        htmlContent: emailHtml,
      });

      // Add Notification Job (only if token exists)
      if (user.fcmToken) {
        await this.notificationQueue.add('send-notification', {
        token: user.fcmToken,
        title: title,
        body: body,
        userId: (user._id as Types.ObjectId).toString(),
        type: type,
        });
      }
    }
    console.log(`Added ${targetUsers.length} potential email and notification jobs to queues.`);
  }

  // --- HTML Generation Helpers ---
  private generatePromoEmailHtml(code: string, discount: number, expiry: Date): string {
    const discountPercent = discount * 100;
    return `
      <div style="font-family: Arial, sans-serif;">
        <h2>🎉 Exciting News! New Promotion Code!</h2>
        <p>We've added a new discount just for you!</p>
        <div style="background-color: #f0f8ff; padding: 20px; text-align: center; border-radius: 10px;">
          <h3>Your Code:</h3>
          <h1 style="color: #007bff; font-size: 36px; letter-spacing: 3px; margin: 10px 0;">${code}</h1>
          <p style="font-size: 18px;">Get <strong>${discountPercent}% OFF</strong>!</p>
        </div>
        <p>This offer is valid until: ${expiry.toDateString()}. Don't miss out!</p>
        <p>Happy Event Planning!</p>
      </div>
    `;
  }

  private generateGeneralEmailHtml(title: string, body: string): string {
    return `
      <div style="font-family: Arial, sans-serif;">
        <h2>📢 ${title}</h2>
        <p>${body}</p>
        <p>Check out the new deals on our app now!</p>
      </div>
    `;
  }
}