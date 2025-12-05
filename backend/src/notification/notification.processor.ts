// notification.processor.ts
import { Process, Processor } from '@nestjs/bull';
import type { Job } from 'bull';
import { Injectable, Logger } from '@nestjs/common';
import { MailService } from '../auth/mail.service';
import { NotificationService } from './notification.service';
import { NotificationType } from './notification-log.schema';

export interface EmailJob {
  to: string;
  subject: string;
  htmlContent: string;
}

export interface NotificationJob {
  token: string;
  title: string;
  body: string;
  userId: string;
  type: NotificationType;
}

// 👇 Process email-queue
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
      throw error;
    }
  }
}

// 👇 Process notification-queue
@Injectable()
@Processor('notification-queue')
export class NotificationProcessor {
  private readonly logger = new Logger(NotificationProcessor.name);

  constructor(private readonly notificationService: NotificationService) {}

  @Process('send-notification')
  async handleSendNotification(job: Job<NotificationJob>) {
    this.logger.log(`Processing notification job ${job.id} for user ${job.data.userId}`);
    try {
      await this.notificationService.sendNotification(
        job.data.token,
        job.data.title,
        job.data.body,
      );

      await this.notificationService.logNotification({
        userId: job.data.userId,
        title: job.data.title,
        body: job.data.body,
        type: job.data.type,
      });

      this.logger.log(`✅ Notification job ${job.id} sent and logged successfully.`);
    } catch (error) {
      this.logger.error(`❌ Failed to send notification job ${job.id}:`, error.message);
      throw error;
    }
  }
}