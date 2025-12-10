// src/notification/notification.controller.ts
import { Controller, Get, Patch, Param, Delete, HttpCode, UseGuards } from '@nestjs/common';
import { NotificationService } from './notification.service';
import { User } from '../auth/user.decorator'; // Assuming you have a custom user decorator
import { Types } from 'mongoose';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

// Note: You must protect these routes with an AuthGuard
@Controller('notifications')
@UseGuards(JwtAuthGuard) 
export class NotificationController {
  constructor(private readonly notificationService: NotificationService) {}

  // GET /notifications
  @Get()
  async getNotifications(
    @User('id') recipientId: Types.ObjectId,
    @User('type') recipientType: string, // Assuming 'type' is User/Vendor
  ) {
    // Fetches the list of notifications for the logged-in user/vendor
    return this.notificationService.getNotifications(recipientId, recipientType);
  }
  // GET /notifications/unread/count
  @Get('unread/count')
  async getUnreadCount(
    @User('id') recipientId: Types.ObjectId,
    @User('type') recipientType: string,
  ) {
    // Fetches the count for the red dot indicator
    return this.notificationService.getUnreadCount(recipientId, recipientType);
  }

  // PATCH /notifications/mark-all-read
  // Implements the feature: "Once they click the page, all become read"
  @Patch('mark-all-read')
  @HttpCode(204)
  async markAllAsRead(
    @User('id') recipientId: Types.ObjectId,
    @User('type') recipientType: string,
  ) {
    await this.notificationService.markAllAsRead(recipientId, recipientType);
  }

  // DELETE /notifications/:id
  @Delete(':notificationId')
  @HttpCode(204)
  async deleteNotification(
    @Param('notificationId') notificationId: Types.ObjectId,
    @User('id') recipientId: Types.ObjectId,
  ) {
    // Deletes the notification, ensuring the recipient owns it
    await this.notificationService.deleteNotification(notificationId, recipientId);
  }
}