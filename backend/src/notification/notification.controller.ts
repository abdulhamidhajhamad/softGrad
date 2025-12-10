// src/notification/notification.controller.ts
import { 
  Controller, 
  Get, 
  Patch, 
  Param, 
  Delete, 
  HttpCode, 
  UseGuards,
  Request 
} from '@nestjs/common';
import { NotificationService } from './notification.service';
import { Types } from 'mongoose';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RecipientType } from './notification.schema';

@Controller('notifications')
@UseGuards(JwtAuthGuard) 
export class NotificationController {
  constructor(private readonly notificationService: NotificationService) {}

  // GET /notifications
  @Get()
  async getNotifications(@Request() req) {
    const userId = req.user.userId || req.user.id;
    const userRole = req.user.role;
    
    // Convert role to RecipientType
    const recipientType = userRole === 'vendor' ? RecipientType.VENDOR : RecipientType.USER;
    
    console.log('🔔 Fetching notifications for:', { userId, userRole, recipientType });
    
    return this.notificationService.getNotifications(
      new Types.ObjectId(userId), 
      recipientType
    );
  }

  // GET /notifications/unread/count
  @Get('unread/count')
  async getUnreadCount(@Request() req) {
    const userId = req.user.userId || req.user.id;
    const userRole = req.user.role;
    
    // Convert role to RecipientType
    const recipientType = userRole === 'vendor' ? RecipientType.VENDOR : RecipientType.USER;
    
    console.log('🔔 Fetching unread count for:', { userId, userRole, recipientType });
    
    const count = await this.notificationService.getUnreadCount(
      new Types.ObjectId(userId), 
      recipientType
    );
    
    console.log('📊 Unread count:', count);
    
    return { count };
  }

  // PATCH /notifications/mark-all-read
  @Patch('mark-all-read')
  @HttpCode(204)
  async markAllAsRead(@Request() req) {
    const userId = req.user.userId || req.user.id;
    const userRole = req.user.role;
    
    // Convert role to RecipientType
    const recipientType = userRole === 'vendor' ? RecipientType.VENDOR : RecipientType.USER;
    
    console.log('✅ Marking all as read for:', { userId, userRole, recipientType });
    
    await this.notificationService.markAllAsRead(
      new Types.ObjectId(userId), 
      recipientType
    );
  }

  // DELETE /notifications/:id
  @Delete(':notificationId')
  @HttpCode(204)
  async deleteNotification(
    @Param('notificationId') notificationId: string,
    @Request() req
  ) {
    const userId = req.user.userId || req.user.id;
    
    console.log('🗑️ Deleting notification:', { notificationId, userId });
    
    await this.notificationService.deleteNotification(
      new Types.ObjectId(notificationId), 
      new Types.ObjectId(userId)
    );
  }

  // 🔍 DEBUG ENDPOINT - Remove this after testing
  @Get('debug/all')
  async debugAllNotifications(@Request() req) {
    const userId = req.user.userId || req.user.id;
    
    return this.notificationService.debugGetAllNotifications(new Types.ObjectId(userId));
  }
}