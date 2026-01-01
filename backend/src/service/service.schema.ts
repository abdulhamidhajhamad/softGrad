import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose'; 

// ... (BookingType, PayType, PricingOptions, ReviewSchema كما هي) ...
export enum BookingType {
    Hourly = 'hourly',       
    Daily = 'daily',         
    Capacity = 'capacity',   
    Display = 'display',     
    Mixed = 'mixed'          
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

export enum PayType { 
    PerHour = 'per hour',
    PerPerson = 'per person',
    PerDay = 'per day',
    Display = 'display'
}

@Schema({ _id: false }) 
export class Review {
   // ... (كما هو)
    @Prop({ type: String, required: true })
    userId: string; 

    @Prop({ type: String })
    userName: string;

    @Prop({ type: Number, required: true, min: 1, max: 5 })
    rating: number;

    @Prop({ 
        type: String, 
        required: true, 
        enum: [PayType.PerHour, PayType.PerPerson, PayType.PerDay, PayType.Display]
    })
    payType: PayType;

    @Prop({ type: String, required: false })
    comment: string;

    @Prop({ type: [String], default: [] })
    images: string[];

    @Prop({ type: Date, default: Date.now })
    createdAt: Date;
}

export const ReviewSchema = SchemaFactory.createForClass(Review);

@Schema({ timestamps: true })
export class Service extends Document {
    // ... (الحقول الأساسية كما هي)
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
        required: true
    })
    location: {
        latitude: number;
        longitude: number;
        address?: string;
        city?: string;
        country?: string;
    };

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

    @Prop({ type: [ReviewSchema], default: [] }) 
    reviews: Review[]; 

    @Prop({ required: false })
    companyName: string;

    // ✅ الحقول الاختيارية
    @Prop({ type: Number, min: 0 })
    maxCapacity?: number; 

    // 🆕 الديفولت 1 (للقاعات الفردية)، ويمكن تغييره لـ 5 مثلاً لشركة التصوير
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