// src/notification/notification-log.schema.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export enum NotificationType {
  PROMO_CODE = 'PROMO_CODE',
  GENERAL_BROADCAST = 'GENERAL_BROADCAST',
}

export enum NotificationStatus {
  PENDING = 'PENDING',
  SENT = 'SENT',
  FAILED = 'FAILED',
}

@Schema({ collection: 'notification_logs', timestamps: true })
export class NotificationLog extends Document {
  @Prop({ required: true })
  title: string;

  @Prop({ required: true })
  body: string;

  @Prop({ required: true, enum: NotificationType })
  type: NotificationType;

  // The user who received the notification (Optional for broadcast)
  @Prop({ type: Types.ObjectId, ref: 'User', default: null })
  targetUser?: Types.ObjectId;

  @Prop({ required: true, enum: NotificationStatus, default: NotificationStatus.PENDING })
  status: NotificationStatus;

  @Prop({ default: null })
  failureReason?: string;
}

export const NotificationLogSchema = SchemaFactory.createForClass(NotificationLog);