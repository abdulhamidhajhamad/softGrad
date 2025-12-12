// src/promotion/promotion-code.schema.ts (Enhanced)
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export enum PromoCodeStatus {
  ACTIVE = 'active',
  EXPIRED = 'expired',
  DISABLED = 'disabled'
}

export enum PromoCodeType {
  PERCENTAGE = 'percentage',
  FIXED_AMOUNT = 'fixed_amount'
}

@Schema({ collection: 'promotion_codes', timestamps: true })
export class PromotionCode extends Document {
  @Prop({ required: true, unique: true, uppercase: true })
  code: string; // e.g., 'SPRING20'

  @Prop({ required: true })
  description: string;

  @Prop({ 
    type: String, 
    enum: Object.values(PromoCodeType), 
    default: PromoCodeType.PERCENTAGE 
  })
  type: PromoCodeType;

  @Prop({ required: true, type: Number, min: 0 })
  discountValue: number; // For percentage: 0-100, For fixed: actual amount

  @Prop({ type: Number, min: 0 })
  minPurchaseAmount?: number;

  @Prop({ type: Number, min: 0 })
  maxDiscountAmount?: number; // Max cap for percentage discounts

  @Prop({ type: Date })
  startDate?: Date;

  @Prop({ required: true })
  expiryDate: Date;

  @Prop({ type: Number, min: 0 })
  usageLimit?: number; // Total usage limit across all users

  @Prop({ type: Number, default: 0 })
  usedCount: number;

  @Prop({ type: Number, min: 1 })
  usageLimitPerUser?: number;

  @Prop({ 
    type: String, 
    enum: Object.values(PromoCodeStatus), 
    default: PromoCodeStatus.ACTIVE 
  })
  status: PromoCodeStatus;

  @Prop({ type: [String], default: [] })
  usedByUsers: string[]; // Array of user IDs who used this code

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  createdBy: Types.ObjectId;

  @Prop({ type: Boolean, default: false })
  notificationSent: boolean;

  // Legacy field for backward compatibility
  @Prop({ type: Boolean, default: true })
  isActive: boolean;
}

export const PromotionCodeSchema = SchemaFactory.createForClass(PromotionCode);

// Indexes for better query performance
PromotionCodeSchema.index({ code: 1 });
PromotionCodeSchema.index({ status: 1 });
PromotionCodeSchema.index({ expiryDate: 1 });