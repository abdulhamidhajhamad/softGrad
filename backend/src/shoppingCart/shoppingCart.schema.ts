import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

@Schema({ _id: true })
export class CartService {
  @Prop({ type: Types.ObjectId, required: true, ref: 'Service' })
  serviceId: Types.ObjectId;

  @Prop({ type: Date, required: true })
  bookingDate: Date;

  // 🆕 للحجوزات بالساعة
  @Prop({ type: Number, min: 0, max: 23 })
  startHour?: number;

  @Prop({ type: Number, min: 0, max: 23 })
  endHour?: number;

  // 🆕 للحجوزات حسب السعة
  @Prop({ type: Number, min: 1 })
  numberOfPeople?: number;

  // 🆕 للحجوزات المختلطة - هل هو حجز كامل للمكان؟
  @Prop({ type: Boolean, default: false })
  isFullVenueBooking?: boolean;

  // 🆕 حفظ السعر المحسوب عند الإضافة
  @Prop({ type: Number, default: 0 })
  calculatedPrice?: number;
}

@Schema({ timestamps: true })
export class ShoppingCart extends Document {
  @Prop({ type: Types.ObjectId, required: true, ref: 'User', unique: true })
  userId: Types.ObjectId;

  @Prop({ type: [CartService], default: [] })
  services: CartService[];

  @Prop({ type: Number, default: 0 })
  totalPrice: number;
}

export const ShoppingCartSchema = SchemaFactory.createForClass(ShoppingCart);