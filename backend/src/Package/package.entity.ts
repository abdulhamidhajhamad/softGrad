// package.entity.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

@Schema({ _id: false })
export class PackageServiceItem {
  @Prop({ type: Types.ObjectId, ref: 'Service', required: true })
  serviceId: Types.ObjectId;

  @Prop({ type: String, required: true })
  serviceName: string;

  @Prop({ type: Number, required: true })
  originalPrice: number; // السعر الأصلي

  @Prop({ type: Number, required: true })
  newPrice: number; // السعر الجديد في الباقة

  // ⭐ إذا موجود = باقة بكمية ثابتة، إذا null = سعر وحدة مخفض
  @Prop({ type: Number })
  maxHours?: number;

  @Prop({ type: Number })
  maxCapacity?: number;

  @Prop({ type: String })
  description?: string;
}

@Schema({ timestamps: true })
export class Package extends Document {
  @Prop({ type: String, required: true })
  providerId: string;

  @Prop({ type: String, required: true })
  companyName: string;

  @Prop({ type: String, required: true })
  packageName: string;

  @Prop({ type: [PackageServiceItem], required: true })
  services: PackageServiceItem[];

  @Prop({ type: Number, required: true })
  originalTotalPrice: number; // مجموع الأسعار الأصلية

  @Prop({ type: Number, required: true })
  newPrice: number; // سعر الباقة النهائي

  @Prop({ type: Date, required: true })
  startDate: Date;

  @Prop({ type: Date, required: true })
  endDate: Date;

  @Prop({ type: String })
  packageImageUrl?: string;

  @Prop({ type: Boolean, default: true })
  isActive: boolean;

  @Prop({ type: String })
  description?: string;
}

export const PackageSchema = SchemaFactory.createForClass(Package);