// src/promotion/promotion-code.schema.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

@Schema({ collection: 'promotion_codes', timestamps: true })
export class PromotionCode extends Document {
  @Prop({ required: true, unique: true })
  code: string; // e.g., 'SPRING20'

  @Prop({ required: true, type: Number })
  discountValue: number; // e.g., 0.20 for 20%

  @Prop({ required: true })
  expiryDate: Date;

  @Prop({ required: true, default: true })
  isActive: boolean;

  // Reference to the admin who created it (optional, but good practice)
  @Prop({ type: Types.ObjectId, ref: 'User' })
  createdBy: Types.ObjectId;
}

export const PromotionCodeSchema = SchemaFactory.createForClass(PromotionCode);