// provider.entity.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

@Schema({ timestamps: { createdAt: true, updatedAt: false }, collection: 'service_providers' })
export class ServiceProvider extends Document {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  userId: Types.ObjectId; 

  @Prop({ required: true, trim: true })
  companyName: string;

  @Prop({ type: String, default: null })
  description?: string;

  @Prop({
    type: {
      city: { type: String, default: null },
      country: { type: String, default: null },
      coordinates: {
        latitude: { type: Number, default: null },
        longitude: { type: Number, default: null },
      },
    },
    default: {},
  })
  location?: {
    city?: string;
    country?: string;
    coordinates?: { latitude?: number; longitude?: number };
  };

  @Prop({ type: Object, default: {} })
  details?: Record<string, any>;

  @Prop({ type: String, default: null })
  venueType?: string;

  @Prop({ type: Boolean, default: false })
  hasGoogleMapLocation?: boolean;

  @Prop({ type: String, enum: ['regular', 'mid', 'high'], default: 'regular' })
  targetCustomerType?: 'regular' | 'mid' | 'high';
}

export const ServiceProviderSchema = SchemaFactory.createForClass(ServiceProvider);