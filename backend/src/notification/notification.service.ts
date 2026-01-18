// src/notification/notification.service.ts
import { Injectable, OnModuleInit, Logger, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';
import { InjectModel } from '@nestjs/mongoose';
import { join } from 'path';
import { InjectQueue } from '@nestjs/bull';

import type { Model, Types } from 'mongoose';
import type { Queue } from 'bull';

import { Notification, NotificationType, RecipientType } from './notification.schema'; 
import { NotificationJob } from './notification.processor'; 
import { NotificationsGateway } from './notification.gateway'; 

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
    @InjectModel(Notification.name)
    private notificationModel: Model<Notification>,
    @InjectQueue('notification-queue') private notificationQueue: Queue<NotificationJob>,
    private notificationsGateway: NotificationsGateway,
  ) {}

  onModuleInit() {
    try {
      const serviceAccountPath = this.configService.get<string>('FIREBASE_SERVICE_ACCOUNT_PATH');
      if (!serviceAccountPath) {
        this.logger.error('FIREBASE_SERVICE_ACCOUNT_PATH is not set.');
        return;
      }
      const serviceAccount = require(join(process.cwd(), serviceAccountPath));

      try {
        admin.app(); 
        this.logger.log('ℹ️ Firebase Admin SDK already initialized, reusing existing app.');
      } catch (e) {
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
        });
        this.logger.log('✅ Firebase Admin SDK initialized successfully.');
      }
    } catch (error) {
      this.logger.error(`❌ Failed to initialize Firebase Admin SDK: ${error.message}`);
    }
  }

  async createNotification(dto: CreateNotificationDto, pushToken: string): Promise<Notification> {
    try {
      this.logger.log(`📝 Creating notification for recipient: ${dto.recipientId}`);
      this.logger.log(`📝 Notification data: ${JSON.stringify(dto)}`);
      
      // 1. Log the notification in the database (In-app notification)
      const newNotification = await this.notificationModel.create(dto);
      this.logger.log(`✅ Notification saved to DB with ID: ${newNotification._id}`);

      // 2. Queue the push notification (FCM)
      if (pushToken && pushToken.trim() !== '') {
          this.logger.log(`📲 Queuing FCM push for token: ${pushToken.substring(0, 20)}...`);
          try {
            await this.notificationQueue.add('send-notification', {
                token: pushToken,
                title: dto.title,
                body: dto.body,
                userId: dto.recipientId.toString(),
                type: dto.type,
            });
            this.logger.log(`✅ FCM push queued successfully`);
          } catch (queueError) {
            this.logger.error(`❌ Error queuing FCM push: ${queueError.message}`);
          }
      } else {
          this.logger.warn(`⚠️ No FCM token provided for recipient: ${dto.recipientId} - Skipping push notification, but still saving to DB and sending real-time update`);
      }

      // 3. Real-time update (In-App via WebSockets)
      this.logger.log(`📡 Emitting real-time notification to recipient: ${dto.recipientId}`);
      
      // Convert to plain object to avoid serialization issues
      const notificationObject = newNotification.toJSON();
      
      try {
        const emitSuccess = this.notificationsGateway.emitToRecipient(
            dto.recipientId, 
            'newNotification', 
            notificationObject
        );
        
        if (emitSuccess) {
            this.logger.log(`✅ Real-time notification emitted successfully`);
        } else {
            this.logger.warn(`⚠️ Real-time notification NOT delivered (recipient offline)`);
        }
      } catch (emitError) {
        this.logger.error(`❌ Error emitting notification: ${emitError.message}`);
      }
      
      // 4. Also, trigger an unread count update for the red dot
      try {
        const count = await this.getUnreadCount(dto.recipientId, dto.recipientType);
        this.logger.log(`📊 Current unread count for recipient: ${count}`);
        
        const countEmitSuccess = this.notificationsGateway.emitToRecipient(
            dto.recipientId, 
            'unreadCountUpdated', 
            count
        );
        
        if (countEmitSuccess) {
            this.logger.log(`✅ Unread count update emitted successfully`);
        } else {
            this.logger.warn(`⚠️ Unread count update NOT delivered (recipient offline)`);
        }
      } catch (countError) {
        this.logger.error(`❌ Error getting/emitting unread count: ${countError.message}`);
      }

      return newNotification;
    } catch (error) {
      this.logger.error(`❌ Critical error in createNotification: ${error.message}`);
      this.logger.error(`Stack trace: ${error.stack}`);
      throw error;
    }
  }

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
      this.logger.log(`✅ FCM message sent successfully: ${response}`);
    } catch (error) {
      this.logger.error(`❌ Error sending FCM message to token ${token}: ${error.message}`);
      throw error;
    }
  }

  async getNotifications(recipientId: Types.ObjectId, recipientType: string): Promise<Notification[]> {
    this.logger.log(`📥 Fetching notifications for recipient: ${recipientId}, type: ${recipientType}`);
    const notifications = await this.notificationModel
      .find({ recipientId, recipientType })
      .sort({ createdAt: -1 })
      .limit(50) 
      .exec();
    
    this.logger.log(`✅ Found ${notifications.length} notifications`);
    return notifications;
  }

  async getUnreadCount(recipientId: Types.ObjectId, recipientType: RecipientType | string): Promise<number> {
    const count = await this.notificationModel.countDocuments({ 
        recipientId, 
        recipientType, 
        isRead: false
    });
    
    this.logger.log(`📊 Unread count for ${recipientId}: ${count}`);
    return count;
  }

  async markAllAsRead(recipientId: Types.ObjectId, recipientType: string): Promise<void> {
    this.logger.log(`📖 Marking all notifications as read for recipient: ${recipientId}`);
    
    const result = await this.notificationModel.updateMany(
      { recipientId, recipientType, isRead: false },
      { $set: { isRead: true } },
    ).exec();

    this.logger.log(`✅ Marked ${result.modifiedCount} notifications as read`);

    // Real-time update: Broadcast the new count (which is 0)
    if (result.modifiedCount > 0) {
        this.logger.log(`📡 Emitting unread count update (0) to recipient: ${recipientId}`);
        this.notificationsGateway.emitToRecipient(recipientId, 'unreadCountUpdated', 0);
    }
  }

  async deleteNotification(notificationId: Types.ObjectId, recipientId: Types.ObjectId): Promise<void> {
    this.logger.log(`🗑️ Deleting notification: ${notificationId} for recipient: ${recipientId}`);
    
    const notification = await this.notificationModel.findOne({ _id: notificationId, recipientId }).exec();

    if (!notification) {
      throw new NotFoundException('Notification not found or access denied.');
    }

    const wasUnread = !notification.isRead;

    await this.notificationModel.deleteOne({ _id: notificationId }).exec();
    this.logger.log(`✅ Notification deleted successfully`);

    // Real-time update: If the deleted item was unread, update the count
    if (wasUnread) {
        const newCount = await this.getUnreadCount(recipientId, notification.recipientType);
        this.logger.log(`📡 Emitting updated unread count (${newCount}) after deletion`);
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
        isRead: n.isRead
      })),
      userNotificationsAsUser: userNotificationsAsUser,
      userNotificationsAsVendor: userNotificationsAsVendor
    };
  }
}