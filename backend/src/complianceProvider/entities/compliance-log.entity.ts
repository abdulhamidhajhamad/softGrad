// compliance-log.entity.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';
import { 
  VerificationStatus, 
  DocumentType, 
  ProviderType,
  RejectionReason 
} from '../constants/compliance.constants';

/**
 * سجل التحقق - يحفظ جميع عمليات التحقق والتغييرات
 */
@Schema({ timestamps: true, collection: 'compliance_logs' })
export class ComplianceLog extends Document {
  @Prop({ type: Types.ObjectId, ref: 'ServiceProvider', required: true, index: true })
  providerId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  userId: Types.ObjectId;

  @Prop({ 
    type: String, 
    enum: Object.values(DocumentType),
    required: true 
  })
  documentType: DocumentType;

  @Prop({ 
    type: String, 
    enum: Object.values(ProviderType),
    required: true 
  })
  providerType: ProviderType;

  @Prop({ 
    type: String, 
    enum: Object.values(VerificationStatus),
    required: true 
  })
  previousStatus: VerificationStatus;

  @Prop({ 
    type: String, 
    enum: Object.values(VerificationStatus),
    required: true 
  })
  newStatus: VerificationStatus;

  @Prop({ type: String })
  documentUrl?: string;

  @Prop({ type: String })
  extractedText?: string;

  @Prop({ type: Object })
  extractedData?: {
    idNumber?: string;
    extractedName?: string;
    issueDate?: Date;
    expiryDate?: Date;
    businessName?: string;
    commercialRegNumber?: string;
    confidence?: number;
  };

  @Prop({ type: Object })
  matchResult?: {
    idMatched: boolean;
    nameMatched: boolean;
    nameSimilarityScore: number;
    firstNameMatched: boolean;
    isValid: boolean;
    daysUntilExpiry?: number;
  };

  @Prop({ 
    type: String, 
    enum: Object.values(RejectionReason),
  })
  rejectionReason?: RejectionReason;

  @Prop({ type: String })
  adminNotes?: string;

  @Prop({ type: Types.ObjectId, ref: 'User' })
  reviewedBy?: Types.ObjectId;

  @Prop({ type: Date })
  reviewedAt?: Date;

  @Prop({ type: String })
  action: string; // 'upload', 'auto_verify', 'admin_review', 'admin_approve', 'admin_reject', 'expire', 'renew', 'deactivate'

  @Prop({ type: Object })
  metadata?: Record<string, any>;
}

export const ComplianceLogSchema = SchemaFactory.createForClass(ComplianceLog);

// Indexes للبحث السريع
ComplianceLogSchema.index({ providerId: 1, createdAt: -1 });
ComplianceLogSchema.index({ newStatus: 1, createdAt: -1 });
ComplianceLogSchema.index({ action: 1, createdAt: -1 });

/**
 * بيانات التحقق المضافة لكيان المزود
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
