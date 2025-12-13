// notification.schema.ts

import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export enum NotificationType {
  BOOKING_CONFIRMED = 'booking_confirmed',
  BOOKING_CANCELLED = 'booking_cancelled',
  BOOKING_REMINDER = 'booking_reminder',
  PAYMENT_SUCCESS = 'payment_success',
  PAYMENT_FAILED = 'payment_failed',
  PROMO_CODE = 'promo_code',
  NEW_MESSAGE = 'new_message',
  GENERAL = 'general',
}

// ✅ FIX: تأكد من أن القيم بحروف صغيرة تماماً كما في user.role
export enum RecipientType {
  USER = 'user',      // بحروف صغيرة
  VENDOR = 'vendor',  // بحروف صغيرة
  ADMIN = 'admin',    // بحروف صغيرة
}

@Schema({ timestamps: true })
export class Notification extends Document {
  @Prop({ type: Types.ObjectId, required: true })
  recipientId: Types.ObjectId;

  @Prop({ 
    type: String, 
    enum: Object.values(RecipientType), 
    required: true 
  })
  recipientType: RecipientType;

  @Prop({ required: true })
  title: string;

  @Prop({ required: true })
  body: string;

  @Prop({ 
    type: String, 
    enum: Object.values(NotificationType), 
    required: true 
  })
  type: NotificationType;

  @Prop({ type: Object })
  metadata?: Record<string, any>;

  // 🔴 FIX: العودة إلى isRead
  @Prop({ type: Boolean, default: false })
  isRead: boolean;

  // 🔴 تم حذف readAt لأنها غير مستخدمة الآن

  @Prop({ type: Date, default: Date.now })
  createdAt: Date;
}

export const NotificationSchema = SchemaFactory.createForClass(Notification);

// Indexes
NotificationSchema.index({ recipientId: 1, createdAt: -1 });
// 🔴 FIX: تحديث الـ index لـ isRead
NotificationSchema.index({ recipientId: 1, isRead: 1 });