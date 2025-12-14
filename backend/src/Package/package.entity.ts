// package.entity.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

@Schema({ timestamps: { createdAt: true, updatedAt: true }, collection: 'packages' })
export class Package extends Document {
  // معرف البائع (Vendor) الذي أنشأ الباقة، يتم أخذه من التوكن
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  vendorId: Types.ObjectId; 
    @Prop({ required: true, trim: true })
    packageName: string; // ✅ الحقل الجديد
  // مصفوفة من معرفات الخدمات التي تنطبق عليها هذه الباقة
  @Prop({ type: [Types.ObjectId], required: true })
  serviceIds: Types.ObjectId[]; 

  // السعر الجديد (المخفض) الذي سيصبح عليه سعر الخدمات المشمولة في الباقة
  @Prop({ type: Number, required: true })
  newPrice: number; 

  // تاريخ بداية العرض
  @Prop({ type: Date, required: true })
  startDate: Date; 

  // تاريخ نهاية العرض، وهو التاريخ الذي سيتم بعده حذف الباقة تلقائياً
  @Prop({ type: Date, required: true, expires: 0 }) 
  endDate: Date; // 💡 الميزة الأهم: "expires: 0" تجعل MongoDB تحذف المستند تلقائياً عند انتهاء صلاحية هذا التاريخ

  @Prop({ required: false, type: String }) 
  packageImageUrl?: string; // 👈 التعديل هنا

  @Prop({ required: false, trim: true })
  description: string; // 👈 تمت الإضافة

  @Prop({ type: Boolean, default: true })
  isActive: boolean;

}

export const PackageSchema = SchemaFactory.createForClass(Package);