// src/auth/user.entity.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

@Schema({ collection: 'users', timestamps: true })
export class User extends Document {
  @Prop({ required: true })
  userName: string;

  @Prop({ required: true, unique: true })
  email: string;

  @Prop({ required: true })
  password: string;

  @Prop({ default: null })
  phone?: string;

  @Prop({ default: null })
  city?: string;

  @Prop({ 
    required: true, 
    enum: ['user', 'vendor', 'admin'],
    default: 'user'
  })
  role: 'user' | 'vendor' | 'admin';

  @Prop({ default: null })
  imageUrl?: string;

  @Prop({ default: false })
  isVerified: boolean;


  @Prop({ type: [{ type: Types.ObjectId, ref: 'Service' }], default: [] })
  favoriteServices: Types.ObjectId[];

  @Prop({ type: [{ type: Types.ObjectId, ref: 'Package' }], default: [] })
  favoritePackages: Types.ObjectId[];

  @Prop({ type: [{ type: Types.ObjectId, ref: 'Service' }], default: [] })
  favoriteOffers: Types.ObjectId[]; // Offers are services with discounts
  
  // FCM Token for push notifications
  // DO NOT use default: null - sparse index only ignores undefined, not null
  @Prop({ type: String, sparse: true })
  fcmToken?: string; 
}

export const UserSchema = SchemaFactory.createForClass(User);

UserSchema.index({ email: 1 }, { unique: true });
UserSchema.index({ fcmToken: 1 }, { unique: true, sparse: true });