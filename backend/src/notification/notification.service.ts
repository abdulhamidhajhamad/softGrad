// src/notification/notification.service.ts
import { Injectable, OnModuleInit, Logger, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';
import { InjectModel } from '@nestjs/mongoose';
import { join } from 'path';
import { InjectQueue } from '@nestjs/bull';

// --- Import Types ONLY (safely use 'import type') ---
import type { Model, Types } from 'mongoose';
import type { Queue } from 'bull';

// --- Import VALUES/CLASSES (Regular import, needed at runtime by Decorators) ---
// Notification class and Enums are imported normally
import { Notification, NotificationType, RecipientType } from './notification.schema'; 
import { NotificationJob } from './notification.processor'; 
import { NotificationsGateway } from './notification.gateway'; 


// DTO for creating a new notification entry (used by other services)
export interface CreateNotificationDto {
  recipientId: Types.ObjectId;
  recipientType: RecipientType;
  title: string;
  body: string;
  type: NotificationType;
  metadata?: Record<string, any>;
}


@Injectable()
export class NotificationService implements OnModuleInit {
  private readonly logger = new Logger(NotificationService.name);

  constructor(
    private configService: ConfigService,
    // Inject the updated Mongoose Model. Notification is used here as a VALUE (for .name)
    @InjectModel(Notification.name)
    private notificationModel: Model<Notification>,
    // Inject the Bull Queue. Queue is imported as type
    @InjectQueue('notification-queue') private notificationQueue: Queue<NotificationJob>,
    // Inject the Gateway for real-time updates
    private notificationsGateway: NotificationsGateway,
  ) {}

  // =============================================================
  // 🌟 Firebase Admin SDK Initialization
  // =============================================================
  onModuleInit() {
    try {
      const serviceAccountPath = this.configService.get<string>('FIREBASE_SERVICE_ACCOUNT_PATH');
      if (!serviceAccountPath) {
        this.logger.error('FIREBASE_SERVICE_ACCOUNT_PATH is not set.');
        return;
      }
      const serviceAccount = require(join(process.cwd(), serviceAccountPath));

      // Check if the app is already initialized
      try {
        admin.app(); 
        this.logger.log('ℹ️ Firebase Admin SDK already initialized, reusing existing app.');
      } catch (e) {
        // If not, initialize it
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
  // CORE LOGIC: Create, Log, Queue, and Push Notification
  // (Called by services like BookingService, MessageService)
  // =============================================================
  async createNotification(dto: CreateNotificationDto, pushToken: string): Promise<Notification> {
    // 1. Log the notification in the database (In-app notification)
    const newNotification = await this.notificationModel.create(dto);

    // 2. Queue the push notification (FCM)
    if (pushToken) {
        await this.notificationQueue.add('send-notification', {
            token: pushToken,
            title: dto.title,
            body: dto.body,
            userId: dto.recipientId.toString(),
            type: dto.type,
        });
    }

    // 3. Real-time update (In-App via WebSockets)
    // Send the new notification object
    this.notificationsGateway.emitToRecipient(
        dto.recipientId, 
        'newNotification', 
        newNotification
    );
    
    // Also, trigger an unread count update for the red dot
    const count = await this.getUnreadCount(dto.recipientId, dto.recipientType);
    this.notificationsGateway.emitToRecipient(dto.recipientId, 'unreadCountUpdated', count);

    return newNotification;
  }

  // =============================================================
  // LOW-LEVEL: Send Push Notification (Used by NotificationProcessor)
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
      throw error; // Re-throw the error for Bull to handle
    }
  }
  
  // =============================================================
  // CRUD and Read Status Management (Used by NotificationController)
  // =============================================================

  // Fetch a list of notifications for a recipient
  async getNotifications(recipientId: Types.ObjectId, recipientType: string): Promise<Notification[]> {
    return this.notificationModel
      .find({ recipientId, recipientType })
      .sort({ createdAt: -1 })
      .limit(50) 
      .exec();
  }

  // Get the count of unread notifications (for the red dot)
  async getUnreadCount(recipientId: Types.ObjectId, recipientType: RecipientType | string): Promise<number> {
    return this.notificationModel.countDocuments({ 
        recipientId, 
        recipientType, 
        isRead: false 
    });
  }

  // Mark all unread notifications as read (upon opening the list)
  async markAllAsRead(recipientId: Types.ObjectId, recipientType: string): Promise<void> {
    const result = await this.notificationModel.updateMany(
      { recipientId, recipientType, isRead: false },
      { $set: { isRead: true } },
    ).exec();

    // Real-time update: Broadcast the new count (which is 0)
    if (result.modifiedCount > 0) {
        this.notificationsGateway.emitToRecipient(recipientId, 'unreadCountUpdated', 0);
    }
  }

  // Delete a specific notification, ensuring ownership
  async deleteNotification(notificationId: Types.ObjectId, recipientId: Types.ObjectId): Promise<void> {
    const notification = await this.notificationModel.findOne({ _id: notificationId, recipientId }).exec();

    if (!notification) {
      throw new NotFoundException('Notification not found or access denied.');
    }

const wasUnread = !notification.read;

    await this.notificationModel.deleteOne({ _id: notificationId }).exec();

    // Real-time update: If the deleted item was unread, update the count
    if (wasUnread) {
        const newCount = await this.getUnreadCount(recipientId, notification.recipientType);
        this.notificationsGateway.emitToRecipient(recipientId, 'unreadCountUpdated', newCount);
    }
  }

  async debugGetAllNotifications(userId: Types.ObjectId): Promise<any> {
  const allNotifications = await this.notificationModel.find({}).exec();
  
  const userNotificationsAsUser = await this.notificationModel.find({
    recipientId: userId,
    recipientType: RecipientType.USER
  }).exec();
  
  const userNotificationsAsVendor = await this.notificationModel.find({
    recipientId: userId,
    recipientType: RecipientType.VENDOR
  }).exec();
  
  return {
    userId: userId.toString(),
    totalNotificationsInDB: allNotifications.length,
    notificationsForThisUserAsUser: userNotificationsAsUser.length,
    notificationsForThisUserAsVendor: userNotificationsAsVendor.length,
    allNotificationsInDB: allNotifications.map(n => ({
      _id: n._id,
      recipientId: n.recipientId.toString(),
      recipientType: n.recipientType,
      title: n.title,
read: n.read
    })),
    userNotificationsAsUser: userNotificationsAsUser,
    userNotificationsAsVendor: userNotificationsAsVendor
  };
}
}

