// notification.schema.ts
// Just add NEW_MESSAGE to your existing NotificationType enum

import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export enum NotificationType {
  BOOKING_CONFIRMED = 'booking_confirmed',
  BOOKING_CANCELLED = 'booking_cancelled',
  BOOKING_REMINDER = 'booking_reminder',
  PAYMENT_SUCCESS = 'payment_success',
  PAYMENT_FAILED = 'payment_failed',
  PROMO_CODE = 'promo_code',
  NEW_MESSAGE = 'new_message',  // ← Add this single line
  GENERAL = 'general',
}

export enum RecipientType {
  USER = 'user',
  VENDOR = 'vendor',
  ADMIN = 'admin',
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

  @Prop({ type: Boolean, default: false })
  read: boolean;

  @Prop({ type: Date })
  readAt?: Date;

  @Prop({ type: Date, default: Date.now })
  createdAt: Date;
}

export const NotificationSchema = SchemaFactory.createForClass(Notification);

// Indexes
NotificationSchema.index({ recipientId: 1, createdAt: -1 });
NotificationSchema.index({ recipientId: 1, read: 1 });