// src/booking/booking.entity.ts

import { Schema, Prop, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';
import { User } from '../auth/user.entity'; 
import { Service } from '../service/service.entity'; 

// FIX: Export the User and Service Document types here
export type UserDocument = User & Document;
export type ServiceDocument = Service & Document;

export enum BookingStatus {
  PENDING = 'pending',
  CONFIRMED = 'confirmed',
  CANCELLED = 'cancelled',
  COMPLETED = 'completed',
}

@Schema({ 
  collection: 'bookings', 
  timestamps: true,
  toJSON: { virtuals: true }, 
  toObject: { virtuals: true } 
})
export class Booking extends Document {

  @Prop({ required: true, ref: 'User' })
  userId: number; 

  @Prop({ required: true, ref: 'Service' })
  serviceId: number; 

  @Prop({ type: Date, required: true })
  bookingDate: Date;

  @Prop({
    type: String,
    enum: Object.values(BookingStatus),
    default: BookingStatus.PENDING,
  })
  status: BookingStatus;

  @Prop({ type: Number, required: true })
  totalPrice: number;

  user?: User;
  service?: Service;
}

export const BookingSchema = SchemaFactory.createForClass(Booking);

BookingSchema.virtual('user', {
  ref: 'User',
  localField: 'userId',
  foreignField: 'id', 
  justOne: true,
});

BookingSchema.virtual('service', {
  ref: 'Service',
  localField: 'serviceId',
  foreignField: 'serviceId', 
  justOne: true,
});

export type BookingDocument = Booking & Document;