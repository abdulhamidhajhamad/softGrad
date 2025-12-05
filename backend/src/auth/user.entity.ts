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

  // ✅ NEW FIELD: For Firebase Cloud Messaging Token
  // unique: true with sparse: true ensures that only unique tokens are stored, 
  // but null values (for users who haven't logged in on the app) are allowed.
  @Prop({ default: null, unique: true, sparse: true })
  fcmToken?: string; 
}

export const UserSchema = SchemaFactory.createForClass(User);

UserSchema.index({ email: 1 });