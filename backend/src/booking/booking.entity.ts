// booking.schema.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';
import { BookingType } from '../service/service.schema';

export enum BookingStatus {
  PENDING = 'pending',
  CONFIRMED = 'confirmed',
  CANCELLED = 'cancelled',
  COMPLETED = 'completed'
}

@Schema({ _id: false })
export class BookingDetails {
  @Prop({ type: Date, required: true })
  date: Date;

  @Prop({ type: Number })
  startHour?: number;

  @Prop({ type: Number })
  endHour?: number;

  @Prop({ type: Number })
  numberOfPeople?: number;

  @Prop({ type: Boolean, default: false })
  isFullVenue?: boolean;
}

@Schema({ timestamps: true })
export class Booking extends Document {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  userId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Service', required: true })
  serviceId: Types.ObjectId;

  @Prop({ type: String, required: true })
  serviceName: string;

  @Prop({ type: String, required: true })
  providerId: string;

  @Prop({ type: String, required: true })
  companyName: string;

  @Prop({ type: String, enum: Object.values(BookingType), required: true })
  bookingType: BookingType;

  @Prop({ type: BookingDetails, required: true })
  bookingDetails: BookingDetails;

  @Prop({ type: Number, required: true })
  price: number;

  @Prop({ type: String, enum: Object.values(BookingStatus), default: BookingStatus.CONFIRMED })
  status: BookingStatus;

  @Prop({ type: String, required: true })
  paymentIntentId: string;

  @Prop({ type: String })
  cancellationReason?: string;

  @Prop({ type: Date })
  cancelledAt?: Date;

  @Prop({ type: String })
  cancelledBy?: string; // 'vendor' or 'user'

  @Prop({ type: Boolean, default: false })
  refunded: boolean;

  @Prop({ type: String })
  refundId?: string;
}

export const BookingSchema = SchemaFactory.createForClass(Booking);