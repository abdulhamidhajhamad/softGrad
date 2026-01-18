// provider.entity.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

/**
 * حالات التحقق من المزود
 */
export enum VerificationStatus {
  PENDING = 'pending',
  UNDER_REVIEW = 'under_review',
  VERIFIED = 'verified',
  ADMIN_REVIEW = 'admin_review',
  REJECTED = 'rejected',
  EXPIRED = 'expired',
  DEACTIVATED = 'deactivated',
}

/**
 * أنواع المزودين
 */
export enum ProviderType {
  INDIVIDUAL = 'individual',
  BUSINESS = 'business',
}

/**
 * بيانات التحقق المضمنة في المزود
 */
@Schema({ _id: false })
export class VerificationData {
  @Prop({ 
    type: String, 
    enum: Object.values(VerificationStatus),
    default: VerificationStatus.PENDING 
  })
  verificationStatus: VerificationStatus;

  @Prop({ 
    type: String, 
    enum: Object.values(ProviderType),
  })
  providerType?: ProviderType;

  @Prop({ type: String })
  idNumber?: string; // رقم الهوية (9 أرقام) - مشفر

  @Prop({ type: Date })
  issueDate?: Date; // تاريخ إصدار الوثيقة

  @Prop({ type: Date })
  licenseExpiryDate?: Date; // تاريخ انتهاء الصلاحية

  @Prop({ type: String })
  documentUrl?: string; // رابط الوثيقة في Supabase

  @Prop({ type: String })
  extractedText?: string; // النص المستخرج للمراجعة

  @Prop({ type: String })
  businessName?: string; // اسم المنشأة (للشركات)

  @Prop({ type: String })
  commercialRegNumber?: string; // رقم السجل التجاري

  @Prop({ type: Number, default: 0 })
  remindersSent: number; // عدد التذكيرات المرسلة

  @Prop({ type: Date })
  lastReminderDate?: Date; // تاريخ آخر تذكير

  @Prop({ type: Date })
  verifiedAt?: Date; // تاريخ التوثيق

  @Prop({ type: Types.ObjectId, ref: 'User' })
  verifiedBy?: Types.ObjectId; // المشرف الذي وافق (إن وجد)

  @Prop({ type: String })
  rejectionReason?: string; // سبب الرفض

  @Prop({ type: String })
  adminNotes?: string; // ملاحظات المشرف
}

export const VerificationDataSchema = SchemaFactory.createForClass(VerificationData);

@Schema({ timestamps: { createdAt: true, updatedAt: false }, collection: 'service_providers' })
export class ServiceProvider extends Document {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  userId: Types.ObjectId; 

  @Prop({ required: true, trim: true })
  companyName: string;

  @Prop({ type: String, default: null })
  description?: string;

  @Prop({
    type: {
      city: { type: String, default: null },
      country: { type: String, default: null },
      coordinates: {
        latitude: { type: Number, default: null },
        longitude: { type: Number, default: null },
      },
    },
    default: {},
  })
  location?: {
    city?: string;
    country?: string;
    coordinates?: { latitude?: number; longitude?: number };
  };

  @Prop({ type: Object, default: {} })
  details?: Record<string, any>;

  @Prop({ type: String, default: null })
  venueType?: string;

  @Prop({ type: Boolean, default: false })
  hasGoogleMapLocation?: boolean;

  @Prop({ type: String, enum: ['regular', 'mid', 'high'], default: 'regular' })
  targetCustomerType?: 'regular' | 'mid' | 'high';

  @Prop({ default: null })
  image?: string;

  @Prop({ type: String, default: null })
  logoUrl?: string; // شعار الشركة (اختياري)

  // ==================== حقول التحقق والامتثال ====================
  
  @Prop({ type: VerificationDataSchema, default: () => ({}) })
  verification?: VerificationData;

}

export const ServiceProviderSchema = SchemaFactory.createForClass(ServiceProvider);

// Indexes للبحث السريع
ServiceProviderSchema.index({ 'verification.verificationStatus': 1 });
ServiceProviderSchema.index({ 'verification.licenseExpiryDate': 1 });
ServiceProviderSchema.index({ userId: 1 });