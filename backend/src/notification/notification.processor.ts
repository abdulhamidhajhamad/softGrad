// src/notification/notification.processor.ts
import { Process, Processor } from '@nestjs/bull';
import type { Job } from 'bull';
import { Injectable, Logger } from '@nestjs/common';
// Assuming the path to MailService is correct
import { MailService } from '../auth/mail.service'; 
import { NotificationService } from './notification.service';
// Import the updated NotificationType enum (assuming it's available)
import { NotificationType } from './notification.schema'; 

// Interface for Email jobs (kept for completeness as it was in the original file)
export interface EmailJob {
  to: string;
  subject: string;
  htmlContent: string;
}

// Interface for Notification jobs (FCM push)
export interface NotificationJob {
  token: string;
  title: string;
  body: string;
  userId: string; // Recipient ID (User or Vendor)
  type: NotificationType;
}

// =============================================================
// 👇 Email Queue Processor (Kept from original)
// =============================================================
@Injectable()
@Processor('email-queue')
export class EmailProcessor {
  private readonly logger = new Logger(EmailProcessor.name);

  constructor(private readonly mailService: MailService) {}

  @Process('send-email')
  async handleSendEmail(job: Job<EmailJob>) {
    this.logger.log(`Processing email job ${job.id} for ${job.data.to}`);
    try {
      await this.mailService.sendHtmlEmail(
        job.data.to,
        job.data.subject,
        job.data.htmlContent,
      );
      this.logger.log(`✅ Email job ${job.id} sent successfully.`);
    } catch (error) {
      this.logger.error(`❌ Failed to send email job ${job.id}:`, error.message);
      throw error; // Re-throw to allow Bull to handle retries/failures
    }
  }
}

// =============================================================
// 👇 Notification Queue Processor (FCM PUSH) - Updated
// =============================================================
@Injectable()
@Processor('notification-queue')
export class NotificationProcessor {
  private readonly logger = new Logger(NotificationProcessor.name);

  constructor(private readonly notificationService: NotificationService) {}

  // Process the job to send the push notification using Firebase
  @Process('send-notification')
  async handleSendNotification(job: Job<NotificationJob>) {
    this.logger.log(`Processing push notification job ${job.id} for user ${job.data.userId}`);
    try {
      // 1. Call the low-level service function to send the FCM message
      await this.notificationService.sendNotification(
        job.data.token,
        job.data.title,
        job.data.body,
      );
      
      this.logger.log(`✅ Push notification job ${job.id} sent successfully via FCM.`);
      
      // Note: In-app notification logging (DB creation) is done 
      // synchronously in the NotificationService.createNotification before queuing.
      
    } catch (error) {
      this.logger.error(`❌ Failed to send push notification job ${job.id}:`, error.message);
      // Throw the error to let the Bull queue handle retries (based on queue configuration)
      throw error; 
    }
  }
}