// notification.module.ts
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { BullModule } from '@nestjs/bull';
import { User, UserSchema } from '../auth/user.entity';
import { MailService } from '../auth/mail.service';
import { NotificationService } from './notification.service';
import { EmailProcessor, NotificationProcessor } from './notification.processor';
import { Notification, NotificationSchema } from './notification.schema';
import { NotificationsGateway } from './notification.gateway';
// ✅ 1. استيراد NotificationController
import { NotificationController } from './notification.controller'; 


@Module({
  imports: [
    MongooseModule.forFeature([
      { name: User.name, schema: UserSchema },
      { name: Notification.name, schema: NotificationSchema },
    ]),
    BullModule.registerQueue({
      name: 'email-queue',
    }),
    BullModule.registerQueue({
      name: 'notification-queue',
    }),
  ],
  // ✅ 2. إضافة Controller إلى قائمة المتحكمات
  controllers: [NotificationController], 
  
  providers: [
    NotificationService,
    EmailProcessor,
    NotificationProcessor,
    MailService,
    NotificationsGateway, 
  ],
  exports: [NotificationService, BullModule],
})
export class NotificationModule {}