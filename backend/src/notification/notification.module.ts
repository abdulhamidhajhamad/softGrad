// src/notification/notification.module.ts

import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { BullModule } from '@nestjs/bull';
import { User, UserSchema } from '../auth/user.entity';
import { MailService } from '../auth/mail.service';
import { NotificationService } from './notification.service';
import { EmailProcessor, NotificationProcessor } from './notification.processor';
import { Notification, NotificationSchema } from './notification.schema';
import { NotificationsGateway } from './notification.gateway';
import { NotificationController } from './notification.controller'; 
// 💡 افترض أن هذا هو مسار ملف AuthModule الخاص بك
import { AuthModule } from '../auth/auth.module'; // ✅ إضافة الاستيراد

@Module({
  imports: [
    // 🔑 الخطوة التصحيحية: استيراد AuthModule للسماح بحقن JwtService
    AuthModule, 
    
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
  controllers: [NotificationController], 
  
  providers: [
    NotificationService,
    EmailProcessor,
    NotificationProcessor,
    MailService,
    NotificationsGateway, // هذا يحتاج JwtService
  ],
  exports: [NotificationService, BullModule],
})
export class NotificationModule {}