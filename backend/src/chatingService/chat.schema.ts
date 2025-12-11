// chat.schema.ts

import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';
export interface LastReadStatus {
  userId: Types.ObjectId;
  lastReadAt: Date | null; 
}
// تعريف الـ TypeScript Interface لحالة القراءة
export interface LastReadStatus {
  userId: Types.ObjectId;
  lastReadAt: Date | null; 
}

// Chat model contains list of participants (user + vendor OR admin)
@Schema({ timestamps: true })
export class Chat extends Document {
  @Prop({ type: [{ type: Types.ObjectId, ref: 'User' }], required: true })
  participants: Types.ObjectId[];

  // Optional: last message preview for UI
  @Prop({ default: '' })
  lastMessage: string;

  // ✨ NEW: تتبع آخر وقت قراءة لكل مشارك (يسمح بـ null لـ "غير مقروء")
  @Prop({ 
    type: [{ 
      userId: { type: Types.ObjectId, ref: 'User', required: true },
      lastReadAt: { type: Date, default: null, index: true } // السماح لـ Mongoose بتخزين null
    }], 
    default: [], // قيمة افتراضية لتفادي أخطاء الموديل القديم
  })
  lastRead: LastReadStatus[]; 
}

export const ChatSchema = SchemaFactory.createForClass(Chat);