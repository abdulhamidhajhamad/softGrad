// service.schema.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

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

  @Prop({ type: Object, default: {} })
  additionalInfo: any;

  @Prop({ type: [{ type: Object }], default: [] })
  reviews: any[];

  // 🔄 أضف هذا الحقل الجديد
  @Prop({ required: true })
  companyName: string;
}

export const ServiceSchema = SchemaFactory.createForClass(Service);