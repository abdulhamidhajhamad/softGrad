// chat.schema.ts

import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

// تعريف الـ TypeScript Interface لحالة القراءة
export interface LastReadStatus {
  userId: Types.ObjectId;
  lastReadAt: Date | null; // السماح بقيمة null لتمثيل حالة "غير مقروء"
}

// Chat model contains list of participants (user + vendor OR admin)
@Schema({ timestamps: true })
export class Chat extends Document {
  @Prop({ type: [{ type: Types.ObjectId, ref: 'User' }], required: true })
  participants: Types.ObjectId[];

  // Optional: last message preview for UI
  @Prop({ default: '' })
  lastMessage: string;

  // ✨ NEW: تتبع آخر وقت قراءة لكل مشارك
  // يتم تعيين lastReadAt = null عندما يكون هناك رسالة جديدة للمستلِم
  @Prop({ 
    type: [{ 
      userId: { type: Types.ObjectId, ref: 'User', required: true },
      lastReadAt: { type: Date, default: null } // السماح لـ Mongoose بتخزين null
    }], 
    required: true 
  })
  lastRead: LastReadStatus[]; // استخدام الـ Interface الجديد
}

export const ChatSchema = SchemaFactory.createForClass(Chat);