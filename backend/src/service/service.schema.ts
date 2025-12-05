import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose'; 

@Schema({ _id: false }) 
export class Review {
    @Prop({ type: String, required: true })
    userId: string; 

    @Prop({ type: String })
    userName: string;
    
    @Prop({ type: Number, required: true, min: 1, max: 5 })
    rating: number; 

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

    @Prop({ type: [String], default: [] })
    images: string[];

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

    @Prop({ required: true, min: 0 })
    price: number;

    @Prop({ required: true })
    category: string;

    @Prop({ type: Object, default: {} })
    additionalInfo: any;

    @Prop({ type: [ReviewSchema], default: [] }) 
    reviews: Review[]; 

    @Prop({ required: true })
    companyName: string;

    @Prop({ type: [Date], default: [] })
    bookedDates: Date[];

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