import { Schema, Prop, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export enum PaymentStatus {
  SUCCESSFUL = 'successful',
  PENDING = 'pending', // <--- ADD THIS
  CANCELLED = 'cancelled',
}

// Subdocument for service items in booking
@Schema({ _id: false })
export class BookingServiceItem {
  @Prop({ required: true })
  serviceId: string;

  @Prop({ type: Date, required: true })
  bookingDate: Date;
}

const BookingServiceItemSchema = SchemaFactory.createForClass(BookingServiceItem);

@Schema({ 
  collection: 'bookings', 
  timestamps: true,
  toJSON: { virtuals: true }, 
  toObject: { virtuals: true } 
})
export class Booking extends Document {
  @Prop({ required: true })
  userId: string;

  @Prop({ type: [BookingServiceItemSchema], default: [] })
  services: BookingServiceItem[];

  @Prop({ type: Number, required: true, min: 0 })
  totalAmount: number;

  @Prop({
    type: String,
    enum: Object.values(PaymentStatus),
    required: true,
  })
  paymentStatus: PaymentStatus;
}

export const BookingSchema = SchemaFactory.createForClass(Booking);

export type BookingDocument = Booking & Document;