// src/notification/notification.schema.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

// Full list of notification types, separated by recipient for clarity
export enum NotificationType {
  // User Notifications
  PROMO_CODE = 'PROMO_CODE',
  USER_MESSAGE = 'USER_MESSAGE',

  // Vendor Notifications (Based on image and requirements)
  NEW_MESSAGE = 'NEW_MESSAGE',
  BOOKING_CONFIRMED = 'BOOKING_CONFIRMED',
  BOOKING_CANCELLED = 'BOOKING_CANCELLED',
  REVIEW_ADDED = 'REVIEW_ADDED',
  PAYOUT_SENT = 'PAYOUT_SENT',
  SERVICE_FAVOURITED = 'SERVICE_FAVOURITED',
}

export enum RecipientType {
  USER = 'User',
  VENDOR = 'Vendor',
}

@Schema({ collection: 'notifications', timestamps: true })
export class Notification extends Document {
  // The ID of the User or Vendor who is the recipient
  @Prop({ type: Types.ObjectId, required: true, index: true })
  recipientId: Types.ObjectId;

  // Type of the recipient (to support polymorphic logic)
  @Prop({ required: true, enum: RecipientType })
  recipientType: RecipientType;

  @Prop({ required: true })
  title: string;

  @Prop({ required: true })
  body: string;

  @Prop({ required: true, enum: NotificationType })
  type: NotificationType;

  // NEW: State for the 'red dot' feature
  @Prop({ default: false })
  isRead: boolean;

  // NEW: Optional field for dynamic data (e.g., bookingId, senderName)
  @Prop({ type: Object, default: {} })
  metadata: Record<string, any>;
}

export const NotificationSchema = SchemaFactory.createForClass(Notification);