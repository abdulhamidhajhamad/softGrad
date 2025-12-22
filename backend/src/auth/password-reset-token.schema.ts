import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ collection: 'password_reset_tokens', timestamps: true })
export class PasswordResetToken extends Document {
  @Prop({ required: true })
  email: string;

  @Prop({ required: true })
  tokenHash: string;

  @Prop({ required: true, type: Date, expires: 0 }) 
  expiresAt: Date;
}

export const PasswordResetTokenSchema = SchemaFactory.createForClass(PasswordResetToken);