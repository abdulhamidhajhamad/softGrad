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
  
  // FCM Token for push notifications (not unique - same token can be reused)
  @Prop({ default: null })
  fcmToken?: string; 
}

export const UserSchema = SchemaFactory.createForClass(User);

UserSchema.index({ email: 1 });