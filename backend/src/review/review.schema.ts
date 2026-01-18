// src/review/review.schema.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

@Schema({ timestamps: true, collection: 'reviews' })
export class Review extends Document {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true, index: true })
  userId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Service', required: true, index: true })
  serviceId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Booking', required: true, unique: true })
  bookingId: Types.ObjectId;

  @Prop({ required: true, min: 1, max: 5 })
  rating: number;

  @Prop({ type: String, maxlength: 500, default: '' })
  comment: string;

  @Prop({ type: [String], default: [] })
  images: string[];

  @Prop({ type: String })
  userName: string;

  @Prop({ type: Boolean, default: true })
  isVisible: boolean;
}

export const ReviewSchema = SchemaFactory.createForClass(Review);

// 🔍 Indexes for Performance
ReviewSchema.index({ serviceId: 1, createdAt: -1 });
ReviewSchema.index({ userId: 1, createdAt: -1 });
ReviewSchema.index({ bookingId: 1 }, { unique: true });