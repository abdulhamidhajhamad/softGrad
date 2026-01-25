import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export enum BookingType {
  Hourly = 'hourly',
  Daily = 'daily',
  Capacity = 'capacity',
  Display = 'display',
  Mixed = 'mixed'
}

export enum PayType {
  PerHour = 'per hour',
  PerPerson = 'per person',
  PerDay = 'per day',
  Display = 'display'
}

@Schema({ _id: false })
export class PricingOptions {
  @Prop({ type: Number })
  perHour?: number;

  @Prop({ type: Number })
  perDay?: number;

  @Prop({ type: Number })
  perPerson?: number;

  @Prop({ type: Number })
  fullVenue?: number;

  @Prop({ type: Number })
  basePrice?: number;
}

@Schema({ timestamps: true })
export class Service extends Document {
  @Prop({ required: true })
  providerId: string;

  @Prop({ required: true })
  serviceName: string;

  @Prop({ type: Boolean, default: true })
  isActive: boolean;

  @Prop({ type: [String], default: [] })
  images: string[];

  @Prop({ type: String, default: '' })
  description: string;

  @Prop({
    type: String,
    required: true,
    enum: [BookingType.Hourly, BookingType.Daily, BookingType.Capacity, BookingType.Display, BookingType.Mixed],
    default: BookingType.Daily
  })
  bookingType: BookingType;

  @Prop({
    type: [String],
    default: ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'],
    enum: ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']
  })
  workingDays: string[];

  @Prop({
    type: {
      latitude: { type: Number, required: false },
      longitude: { type: Number, required: false },
      address: { type: String },
      city: { type: String },
      country: { type: String }
    },
    required: false  // ✅ تغيير إلى false لأن بعض الخدمات لا تملك موقع ثابت
  })
  location: {
    latitude: number;
    longitude: number;
    address?: string;
    city?: string;
    country?: string;
  };

  // 🆕 هل الخدمة لها موقع ثابت أم تذهب للعميل (مثل الكيترينج)
  @Prop({ type: Boolean, default: true })
  hasFixedLocation: boolean;

  @Prop({ type: Number, required: false })
  price?: number;

  @Prop({ type: PricingOptions })
  priceOptions?: PricingOptions;

  @Prop({ type: String })
  externalLink?: string;

  @Prop({ required: true })
  category: string;

  @Prop({
    type: String,
    required: true,
    enum: [PayType.PerHour, PayType.PerPerson, PayType.PerDay, PayType.Display]
  })
  payType: PayType;

  @Prop({ type: Object, default: {} })
  additionalInfo: any;

  @Prop({ required: false })
  companyName: string;

  @Prop({ type: Number, min: 0 })
  maxCapacity?: number;

  @Prop({ type: Number, min: 1, default: 1 })
  maxConcurrency?: number;

  @Prop({ type: Number, min: 0 })
  minBookingHours?: number;

  @Prop({ type: Number, min: 0 })
  maxBookingHours?: number;

  @Prop({ type: [Number], default: [] })
  availableHours?: number[];

  @Prop({ type: Number, default: 0, min: 0 })
  cleanupTimeMinutes?: number;
  //  NEW: Venue Type (Indoor/Outdoor) for Venues category
  @Prop({ 
    type: String, 
    enum: ['indoor', 'outdoor'], 
    required: false 
  })
  venueType?: string;

  //  NEW: Calculated time slots for hourly bookings
  @Prop({ 
    type: [{ 
      startTime: { type: String }, 
      endTime: { type: String } 
    }], 
    default: [] 
  })
  timeSlots?: Array<{ startTime: string; endTime: string }>;


  // ✅ NEW: Cached Review Statistics
  @Prop({ type: Number, default: 0, min: 0, max: 5 })
  averageRating: number;

  @Prop({ type: Number, default: 0, min: 0 })
  totalReviews: number;

  // ✅ Alias for backward compatibility (maps to averageRating)
  get rating(): number {
    return this.averageRating;
  }

  // ✅ KEEP: AI Analysis (Gemini results)
  @Prop({
    type: {
      score: { type: Number, default: 0.5 },
      tags: { type: [String], default: [] },
      bestFor: { type: [String], default: [] },
      lastUpdated: { type: Date, default: new Date(0) }
    },
    default: { score: 0.5, tags: [], bestFor: [], lastUpdated: new Date(0) }
  })
  aiAnalysis: {
    score: number;
    tags: string[];
    bestFor: string[];
    lastUpdated: Date;
  };

  // ✅ NEW: Offer/Discount System
  @Prop({
    type: {
      isActive: { type: Boolean, default: false },
      discountedPrice: { type: Number },
      discountPercentage: { type: Number },
      startDate: { type: Date },
      endDate: { type: Date },
      description: { type: String }
    },
    default: null
  })
  offer?: {
    isActive: boolean;
    discountedPrice: number;
    discountPercentage: number;
    startDate: Date;
    endDate: Date;
    description?: string;
  };
}

export const ServiceSchema = SchemaFactory.createForClass(Service);