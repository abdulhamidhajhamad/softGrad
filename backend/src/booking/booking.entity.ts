// booking.entity.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';
import { BookingType } from '../service/service.schema';

export enum BookingStatus {
  PENDING = 'pending',
  CONFIRMED = 'confirmed',
  CANCELLED = 'cancelled', // 👈 حالة الإلغاء لبوكينج واحد
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
  // 🔗 هذا المعرف يربط هذا الحجز بالـ Payment Intent
  @Prop({ type: String, required: true })
  paymentIntentId: string;
    
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  userId: Types.ObjectId;

  // معلومات الخدمة
  @Prop({ type: Types.ObjectId, ref: 'Service', required: true })
  serviceId: Types.ObjectId;

  @Prop({ type: String, required: true })
  serviceName: string;

  // معلومات البائع
  @Prop({ type: String, required: true })
  providerId: string; // Vendor ID
    
  @Prop({ type: String, required: true })
  companyName: string;

  @Prop({ type: String, enum: Object.values(BookingType), required: true })
  bookingType: BookingType;

  @Prop({ type: BookingDetails, required: true })
  bookingDetails: BookingDetails;

  @Prop({ type: Number, required: true })
  price: number; // 💰 سعر الخدمة الواحدة (مهم للريفند)

  @Prop({ type: String, enum: Object.values(BookingStatus), default: BookingStatus.PENDING }) // 👈 تبدأ PENDING بعد الدفع
  status: BookingStatus;
    
  @Prop({ type: Boolean, default: false }) // 💰 حقل لتسجيل عملية الـ Refund
  refunded: boolean;
    
  @Prop({ type: String, required: false }) // 📝 سبب الإلغاء
  cancellationReason?: string;

  // 🟢 الحقل الجديد: لتحديد ما إذا كان البائع قد شاهد الحجز
  @Prop({ type: Boolean, default: false })
  seen: boolean;
}

export const BookingSchema = SchemaFactory.createForClass(Booking);