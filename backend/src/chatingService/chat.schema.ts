
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

// Chat model contains list of participants (user + vendor OR admin)
@Schema({ timestamps: true })
export class Chat extends Document {
  @Prop({ type: [{ type: Types.ObjectId, ref: 'User' }], required: true })
  participants: Types.ObjectId[];

  // Optional: last message preview for UI
  @Prop({ default: '' })
  lastMessage: string;
}

export const ChatSchema = SchemaFactory.createForClass(Chat);
