import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose'; 

// تعريف أنواع الحجز
export enum BookingType {
    Hourly = 'hourly',       
    Daily = 'daily',         
    Capacity = 'capacity',   
    Display = 'display',     
    Mixed = 'mixed'          
}

// تعريف هيكلية السعر
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

// هياكل الحجوزات
@Schema({ _id: false })
export class HourlyBooking {
    @Prop({ type: Date, required: true })
    date: Date;
    
    @Prop({ type: Number, required: true })
    startHour: number; 
    
    @Prop({ type: Number, required: true })
    endHour: number; 
}

@Schema({ _id: false })
export class CapacityBooking {
    @Prop({ type: Date, required: true })
    date: Date;
    
    @Prop({ type: Number, required: true })
    bookedCount: number; 
}

@Schema({ _id: false })
export class BookingSlots {
    @Prop({ type: [Date], default: [] })
    dailyBookings: Date[]; 
    
    @Prop({ type: [HourlyBooking], default: [] })
    hourlyBookings: HourlyBooking[]; 
    
    @Prop({ type: [CapacityBooking], default: [] })
    capacityBookings: CapacityBooking[]; 
}

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
    
    // ❌ تمت إزالة workingDays من هنا لأن مكانها غير صحيح في التقييمات

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

    @Prop({ 
        type: String, 
        required: true, 
        enum: [BookingType.Hourly, BookingType.Daily, BookingType.Capacity, BookingType.Display, BookingType.Mixed],
        default: BookingType.Daily
    })
    bookingType: BookingType;

    // ✅ تمت إضافة workingDays هنا (المكان الصحيح)
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
        required: true
    })
    location: {
        latitude: number;
        longitude: number;
        address?: string;
        city?: string;
        country?: string;
    };

    @Prop({ type: PricingOptions, default: {} })
    price: PricingOptions;

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

    @Prop({ type: BookingSlots, default: { dailyBookings: [], hourlyBookings: [], capacityBookings: [] } })
    bookingSlots: BookingSlots;

    @Prop({ type: Number, min: 0 })
    maxCapacity?: number; 

    @Prop({ type: Number, min: 0 })
    minBookingHours?: number; 

    @Prop({ type: Number, min: 0 })
    maxBookingHours?: number; 

    @Prop({ type: [Number], default: [] })
    availableHours?: number[]; 

    @Prop({ type: Number, default: 0, min: 0 })
    cleanupTimeMinutes?: number; 

    @Prop({ type: Boolean, default: false })
    allowFullVenueBooking?: boolean; 

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