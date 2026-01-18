// src/notification/notification.module.ts - FINAL FIXED VERSION

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
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [
    AuthModule, // ✅ ضروري لـ JwtService
    
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
    NotificationsGateway,
  ],
  
  exports: [
    NotificationService, 
    NotificationsGateway, // ✅ تصدير Gateway لاستخدامه في ChatModule
    BullModule
  ],
})
export class NotificationModule {}