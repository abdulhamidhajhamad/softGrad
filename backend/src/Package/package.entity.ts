// package.entity.ts - Updated with category
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

@Schema({ _id: false })
export class PackageServiceItem {
  @Prop({ type: Types.ObjectId, ref: 'Service', required: true })
  serviceId: Types.ObjectId;

  @Prop({ type: String, required: true })
  serviceName: string;

  @Prop({ type: String }) // ✅ إضافة category
  category?: string;

  @Prop({ type: String }) // ✅ نوع الحجز
  bookingType?: string;

  @Prop({ type: Number, required: true })
  originalPrice: number;

  @Prop({ type: Number, required: true })
  newPrice: number;

  @Prop({ type: Number })
  maxHours?: number;

  @Prop({ type: Number })
  maxCapacity?: number;

  @Prop({ type: String })
  description?: string;

  // 🆕 معلومات إضافية من السيرفس الأصلية
  @Prop({ type: Boolean, default: true })
  hasFixedLocation?: boolean;

  @Prop({ type: [String] })
  workingDays?: string[];

  @Prop({ type: [Number] })
  availableHours?: number[];

  @Prop({ type: Number })
  minBookingHours?: number;

  @Prop({ type: Number })
  maxBookingHours?: number;
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
  originalTotalPrice: number;

  @Prop({ type: Number, required: true })
  newPrice: number;

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

  @Prop({ type: String }) // ✅ إضافة city
  city?: string;
}

export const PackageSchema = SchemaFactory.createForClass(Package);