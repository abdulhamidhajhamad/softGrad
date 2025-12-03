import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export enum ComplaintStatus {
  PENDING = 'PENDING',
  UNDER_REVIEW = 'UNDER_REVIEW',
  RESOLVED = 'RESOLVED',
  REJECTED = 'REJECTED',
  ESCALATED = 'ESCALATED'
}

export enum ComplaintType {
  SERVICE = 'SERVICE',          // شكوى على خدمة
  VENDOR = 'VENDOR',            // شكوى على مزود
  REVIEW = 'REVIEW',            // شكوى على مراجعة
  BOOKING = 'BOOKING',          // شكوى على حجز
  PAYMENT = 'PAYMENT',          // شكوى على دفع
  TECHNICAL = 'TECHNICAL',      // مشكلة فنية
  OTHER = 'OTHER'               // أخرى
}

export enum ComplaintPriority {
  LOW = 'LOW',
  MEDIUM = 'MEDIUM',
  HIGH = 'HIGH',
  URGENT = 'URGENT'
}

@Schema({ timestamps: true })
export class Complaint extends Document {
  @Prop({ required: true })
  userId: string;               // المستخدم الذي أرسل الشكوى

  @Prop({ required: true })
  userName: string;             // اسم المستخدم

  @Prop({ required: true })
  userEmail: string;            // إيميل المستخدم

  @Prop({ required: true, enum: ComplaintType })
  type: ComplaintType;

  @Prop({ required: true })
  title: string;                // عنوان الشكوى

  @Prop({ required: true })
  description: string;          // تفاصيل الشكوى

  @Prop({ enum: ComplaintPriority, default: ComplaintPriority.MEDIUM })
  priority: ComplaintPriority;

  @Prop({ enum: ComplaintStatus, default: ComplaintStatus.PENDING })
  status: ComplaintStatus;

  @Prop()
  targetId?: string;            // ID للشيء المشكو عليه (خدمة، مراجعة، etc.)

  @Prop()
  targetType?: string;          // نوع الشيء المشكو عليه

  @Prop({ type: [String], default: [] })
  attachments: string[];        // صور أو ملفات مرفقة

  @Prop({ type: [Object], default: [] })
  notes: {                      // ملاحظات الإدمن
    adminId: string;
    adminName: string;
    note: string;
    timestamp: Date;
  }[];

  @Prop({ type: [Object], default: [] })
  activityLog: {                // سجل النشاطات
    action: string;
    adminId?: string;
    details: string;
    timestamp: Date;
  }[];

  @Prop()
  assignedTo?: string;          // الإدمن المسؤول عن المتابعة

  @Prop()
  resolvedBy?: string;          // الإدمن الذي حل الشكوى

  @Prop()
  resolution?: string;          // كيفية حل المشكلة

  @Prop()
  resolvedAt?: Date;

  @Prop({ default: 0 })
  responseTimeHours?: number;   // وقت الاستجابة بالساعات

  @Prop({ default: false })
  isArchived: boolean;          // هل تم أرشفته؟
}

export const ComplaintSchema = SchemaFactory.createForClass(Complaint);

// إنشاء indexes للبحث السريع
ComplaintSchema.index({ status: 1, priority: -1 });
ComplaintSchema.index({ userId: 1 });
ComplaintSchema.index({ type: 1 });
ComplaintSchema.index({ createdAt: -1 });