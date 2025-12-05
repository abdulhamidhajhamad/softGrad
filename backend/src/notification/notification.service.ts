import { Injectable, OnModuleInit, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { NotificationLog, NotificationType } from './notification-log.schema';
import { join } from 'path';

// واجهة لتسجيل الإشعار في قاعدة البيانات
interface LogNotificationDto {
  userId: string;
  title: string;
  body: string;
  type: NotificationType;
}

@Injectable()
export class NotificationService implements OnModuleInit {
  private readonly logger = new Logger(NotificationService.name);

  constructor(
    private configService: ConfigService,
    @InjectModel(NotificationLog.name)
    private notificationLogModel: Model<NotificationLog>,
  ) {}

  // =============================================================
  // 🌟 تهيئة Firebase Admin SDK
  // =============================================================
onModuleInit() {
  try {
    const serviceAccountPath = this.configService.get<string>('FIREBASE_SERVICE_ACCOUNT_PATH');
    if (!serviceAccountPath) {
      this.logger.error('FIREBASE_SERVICE_ACCOUNT_PATH is not set.');
      return;
    }
    const serviceAccount = require(join(process.cwd(), serviceAccountPath));

    // ✅ استخدام getApp() لمعرفة ما إذا كان التطبيق مُهيأ
    try {
      admin.app(); // يحاول الحصول على التطبيق الافتراضي
      this.logger.log('ℹ️ Firebase Admin SDK already initialized, reusing existing app.');
    } catch (e) {
      // إذا لم يكن موجودًا، نقوم بالتهيئة
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      this.logger.log('✅ Firebase Admin SDK initialized successfully.');
    }
  } catch (error) {
    this.logger.error(`❌ Failed to initialize Firebase Admin SDK: ${error.message}`);
  }
}



  // =============================================================
  // وظيفة إرسال الإشعار (تُستخدم بواسطة NotificationProcessor)
  // =============================================================
  async sendNotification(token: string, title: string, body: string): Promise<void> {
    const message: admin.messaging.Message = {
      notification: {
        title,
        body,
      },
      token: token,
      apns: {
        payload: {
          aps: {
            sound: 'default',
          },
        },
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'default_notification_channel_id',
        },
      },
    };

    try {
      const response = await admin.messaging().send(message);
      this.logger.log(`Successfully sent message: ${response}`);
    } catch (error) {
      this.logger.error(`Error sending message to token ${token}: ${error.message}`);
      throw error; // إعادة إطلاق الخطأ ليتمكن Bull من معالجته
    }
  }
  
  // =============================================================
  // وظيفة تسجيل الإشعار (تُستخدم بواسطة NotificationProcessor)
  // =============================================================
  async logNotification(logDto: LogNotificationDto): Promise<NotificationLog> {
    return this.notificationLogModel.create(logDto);
  }
}