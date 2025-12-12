import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose'; 

// 🆕 تعريف أنواع الحجز الجديدة
export enum BookingType {
    Hourly = 'hourly',       // قاعات (ساعات)
    Daily = 'daily',         // سيارات، فنادق (يوم كامل)
    Capacity = 'capacity',   // كيترينج، مطاعم (حسب عدد الأشخاص)
    Display = 'display',     // مجوهرات (عرض ورابط خارجي فقط)
    Mixed = 'mixed'          // مطاعم (يقبل حجز كامل، أو طلبات، أو حجز طاولة)
}

// 🆕 تعريف هيكلية السعر الجديد (يقبل خيارات متعددة)
@Schema({ _id: false })
export class PricingOptions {
    @Prop({ type: Number })
    perHour?: number;        // سعر الساعة (للقاعات)

    @Prop({ type: Number })
    perDay?: number;         // سعر اليوم (للسيارات/الفنادق)

    @Prop({ type: Number })
    perPerson?: number;      // سعر الشخص (للكيترينج/المطاعم)

    @Prop({ type: Number })
    fullVenue?: number;      // سعر حجز المكان بالكامل (للمطاعم)
    
    @Prop({ type: Number })
    basePrice?: number;      // سعر ثابت عام (لأي غرض آخر)
}

// 🆕 هيكلية لحفظ الحجوزات حسب النوع
@Schema({ _id: false })
export class HourlyBooking {
    @Prop({ type: Date, required: true })
    date: Date;
    
    @Prop({ type: Number, required: true })
    startHour: number; // 0-23
    
    @Prop({ type: Number, required: true })
    endHour: number; // 0-23
}

@Schema({ _id: false })
export class CapacityBooking {
    @Prop({ type: Date, required: true })
    date: Date;
    
    @Prop({ type: Number, required: true })
    bookedCount: number; // عدد الأشخاص المحجوزين
}

@Schema({ _id: false })
export class BookingSlots {
    @Prop({ type: [Date], default: [] })
    dailyBookings: Date[]; // للحجوزات اليومية الكاملة
    
    @Prop({ type: [HourlyBooking], default: [] })
    hourlyBookings: HourlyBooking[]; // للحجوزات بالساعة
    
    @Prop({ type: [CapacityBooking], default: [] })
    capacityBookings: CapacityBooking[]; // للحجوزات حسب السعة
}

// PayType القديم (تم الاحتفاظ به للـ Review)
export enum PayType { 
    PerEvent = 'per event',
    PerHour = 'per hour',
    PerPerson = 'per person',
}

@Schema({ _id: false }) 
export class Review {
    @Prop({ type: String, required: true })
    userId: string; 

    @Prop({ type: String })
    userName: string;
    
    @Prop({ type: Number, required: true, min: 1, max: 5 })
    rating: number; 
    
    @Prop({ 
        type: String, 
        required: true, 
        enum: [PayType.PerEvent, PayType.PerHour, PayType.PerPerson] 
    })
    payType: PayType;
    
    @Prop({ type: String })
    comment: string;
    
    @Prop({ type: Date, default: Date.now })
    createdAt: Date;
}

export const ReviewSchema = SchemaFactory.createForClass(Review);

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

    // 🆕 نوع الحجز 
    @Prop({ 
        type: String, 
        required: true, 
        enum: [BookingType.Hourly, BookingType.Daily, BookingType.Capacity, BookingType.Display, BookingType.Mixed],
        default: BookingType.Daily
    })
    bookingType: BookingType;

    @Prop({
        type: {
            latitude: { type: Number, required: true },
            longitude: { type: Number, required: true },
            address: { type: String },
            city: { type: String },
            country: { type: String }
        },
        required: true
    })
    location: {
        latitude: number;
        longitude: number;
        address?: string;
        city?: string;
        country?: string;
    };

    // 🆕 السعر أصبح Object
    @Prop({ type: PricingOptions, default: {} })
    price: PricingOptions;

    // 🆕 رابط خارجي 
    @Prop({ type: String })
    externalLink?: string;

    @Prop({ required: true })
    category: string;
    
    @Prop({ 
        type: String, 
        required: true, 
        enum: [PayType.PerEvent, PayType.PerHour, PayType.PerPerson] 
    })
    payType: PayType;

    @Prop({ type: Object, default: {} })
    additionalInfo: any;

    @Prop({ type: [ReviewSchema], default: [] }) 
    reviews: Review[]; 

    @Prop({ required: false })
    companyName: string;

    // 🆕 استبدال bookedDates بنظام أكثر مرونة
    @Prop({ type: BookingSlots, default: { dailyBookings: [], hourlyBookings: [], capacityBookings: [] } })
    bookingSlots: BookingSlots;

    // 🆕 حقول خاصة بأنواع الحجز المختلفة
    @Prop({ type: Number, min: 0 })
    maxCapacity?: number; // الحد الأقصى للسعة (للـ Capacity و Mixed)

    @Prop({ type: Number, min: 0 })
    minBookingHours?: number; // الحد الأدنى لساعات الحجز (للـ Hourly)

    @Prop({ type: Number, min: 0 })
    maxBookingHours?: number; // الحد الأقصى لساعات الحجز (للـ Hourly)

    @Prop({ type: [Number], default: [] })
    availableHours?: number[]; // الساعات المتاحة للحجز (للـ Hourly) مثال: [8,9,10,11,12,13,14,15,16,17,18,19,20]

    @Prop({ type: Number, default: 0, min: 0 })
    cleanupTimeMinutes?: number; // وقت التنظيف بين الحجوزات بالدقائق (للقاعات والأماكن التي تحتاج تنظيف)

    @Prop({ type: Boolean, default: false })
    allowFullVenueBooking?: boolean; // هل يسمح بحجز المكان كاملاً (للـ Mixed)

    @Prop({ type: Number, default: 0, min: 0, max: 5 })
    rating: number;

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
}

export const ServiceSchema = SchemaFactory.createForClass(Service);