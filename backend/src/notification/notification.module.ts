// notification.module.ts
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { BullModule } from '@nestjs/bull';
import { User, UserSchema } from '../auth/user.entity';
import { MailService } from '../auth/mail.service';
import { NotificationService } from './notification.service';
import { EmailProcessor, NotificationProcessor } from './notification.processor';
import { NotificationLog, NotificationLogSchema } from './notification-log.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: User.name, schema: UserSchema },
      { name: NotificationLog.name, schema: NotificationLogSchema },
    ]),
    BullModule.registerQueue({
      name: 'email-queue',
    }),
    BullModule.registerQueue({
      name: 'notification-queue',
    }),
  ],
  providers: [
    NotificationService,
    EmailProcessor,        // 👈 Add email processor
    NotificationProcessor, // 👈 Add notification processor
    MailService,
  ],
  exports: [NotificationService, BullModule],
})
export class NotificationModule {}