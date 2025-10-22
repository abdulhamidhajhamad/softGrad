import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Schema as MongooseSchema, Types } from 'mongoose';

export enum CustomerType {
  REGULAR = 'regular',
  MID = 'mid',
  HIGH = 'high'
}

@Schema({ collection: 'service_providers', timestamps: true })
export class ServiceProvider extends Document {
  @Prop({ required: true, type: MongooseSchema.Types.ObjectId, ref: 'User' })
  userId: Types.ObjectId;

  @Prop({ required: true })
  companyName: string;

  @Prop({ default: '' })
  description: string;

  @Prop({ default: '' })
  location: string;

  @Prop({ type: [String], default: [] })
  imageUrls: string[];

  @Prop({ 
    type: String, 
    enum: Object.values(CustomerType), 
    default: CustomerType.REGULAR 
  })
  customerType: CustomerType;

  @Prop({ type: MongooseSchema.Types.Mixed, default: {} })
  details: Record<string, any>;
}

export const ServiceProviderSchema = SchemaFactory.createForClass(ServiceProvider);

// Create indexes
ServiceProviderSchema.index({ userId: 1 }, { unique: true });
ServiceProviderSchema.index({ location: 1 });
ServiceProviderSchema.index({ companyName: 'text', description: 'text' });
ServiceProviderSchema.index({ customerType: 1 });