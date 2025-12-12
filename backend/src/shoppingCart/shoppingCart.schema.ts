// cart.schema.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';
import { BookingType } from '../service/service.schema';

@Schema({ _id: false })
export class CartItemBookingDetails {
  @Prop({ type: Date, required: true })
  date: Date;

  // For Hourly bookings
  @Prop({ type: Number })
  startHour?: number;

  @Prop({ type: Number })
  endHour?: number;

  // For Capacity bookings
  @Prop({ type: Number })
  numberOfPeople?: number;

  // For full venue bookings
  @Prop({ type: Boolean, default: false })
  isFullVenue?: boolean;
}

@Schema({ _id: false })
export class CartItem {
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

  @Prop({ type: CartItemBookingDetails, required: true })
  bookingDetails: CartItemBookingDetails;

  @Prop({ type: Number, required: true })
  price: number;

  @Prop({ type: String })
  imageUrl?: string;
}

@Schema({ timestamps: true })
export class Cart extends Document {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true, unique: true })
  userId: Types.ObjectId;

  @Prop({ type: [CartItem], default: [] })
  items: CartItem[];

  @Prop({ type: Number, default: 0 })
  totalAmount: number;
}

export const CartSchema = SchemaFactory.createForClass(Cart);