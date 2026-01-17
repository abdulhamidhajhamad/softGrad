// verification-response.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { 
  VerificationStatus, 
  DocumentType, 
  ProviderType,
  RejectionReason 
} from '../constants/compliance.constants';

/**
 * نتيجة استخراج البيانات من الوثيقة
 */
export class ExtractedDataDto {
  @ApiPropertyOptional({
    description: 'رقم الهوية المستخرج',
    example: '123456789',
  })
  idNumber?: string;

  @ApiPropertyOptional({
    description: 'الاسم المستخرج من الوثيقة',
    example: 'محمد أحمد علي',
  })
  extractedName?: string;

  @ApiPropertyOptional({
    description: 'تاريخ الإصدار المستخرج',
    example: '2024-01-15',
  })
  issueDate?: Date;

  @ApiPropertyOptional({
    description: 'تاريخ الانتهاء المحسوب',
    example: '2025-01-15',
  })
  expiryDate?: Date;

  @ApiPropertyOptional({
    description: 'اسم المنشأة (للشركات)',
    example: 'شركة النجاح للخدمات',
  })
  businessName?: string;

  @ApiPropertyOptional({
    description: 'رقم السجل التجاري',
    example: '12345',
  })
  commercialRegNumber?: string;

  @ApiPropertyOptional({
    description: 'النص الكامل المستخرج من الوثيقة',
  })
  rawText?: string;

  @ApiPropertyOptional({
    description: 'مستوى الثقة في الاستخراج (0-1)',
    example: 0.95,
  })
  confidence?: number;
}

/**
 * نتيجة المطابقة
 */
export class MatchResultDto {
  @ApiProperty({
    description: 'هل تطابق رقم الهوية؟',
    example: true,
  })
  idMatched: boolean;

  @ApiProperty({
    description: 'هل تطابق الاسم؟',
    example: true,
  })
  nameMatched: boolean;

  @ApiProperty({
    description: 'نسبة تشابه الاسم',
    example: 0.85,
  })
  nameSimilarityScore: number;

  @ApiProperty({
    description: 'هل تطابق الاسم الأول على الأقل؟',
    example: true,
  })
  firstNameMatched: boolean;

  @ApiProperty({
    description: 'هل الوثيقة سارية الصلاحية؟',
    example: true,
  })
  isValid: boolean;

  @ApiPropertyOptional({
    description: 'عدد الأيام المتبقية للصلاحية',
    example: 180,
  })
  daysUntilExpiry?: number;
}

/**
 * استجابة التحقق من الوثيقة
 */
export class VerificationResponseDto {
  @ApiProperty({
    description: 'هل نجحت عملية التحقق؟',
    example: true,
  })
  success: boolean;

  @ApiProperty({
    description: 'حالة التحقق الجديدة',
    enum: VerificationStatus,
    example: VerificationStatus.VERIFIED,
  })
  status: VerificationStatus;

  @ApiProperty({
    description: 'رسالة توضيحية',
    example: 'تم التحقق من الوثيقة بنجاح',
  })
  message: string;

  @ApiPropertyOptional({
    description: 'البيانات المستخرجة من الوثيقة',
    type: ExtractedDataDto,
  })
  extractedData?: ExtractedDataDto;

  @ApiPropertyOptional({
    description: 'نتيجة المطابقة',
    type: MatchResultDto,
  })
  matchResult?: MatchResultDto;

  @ApiPropertyOptional({
    description: 'سبب الرفض (في حالة الرفض)',
    enum: RejectionReason,
  })
  rejectionReason?: RejectionReason;

  @ApiPropertyOptional({
    description: 'رابط الوثيقة المرفوعة',
    example: 'https://storage.supabase.co/...',
  })
  documentUrl?: string;

  @ApiPropertyOptional({
    description: 'تاريخ انتهاء الصلاحية',
    example: '2025-01-15T00:00:00.000Z',
  })
  expiryDate?: Date;
}

/**
 * استجابة حالة التحقق للمزود
 */
export class ProviderVerificationStatusDto {
  @ApiProperty({
    description: 'معرف المزود',
    example: '507f1f77bcf86cd799439011',
  })
  providerId: string;

  @ApiProperty({
    description: 'حالة التحقق الحالية',
    enum: VerificationStatus,
    example: VerificationStatus.VERIFIED,
  })
  verificationStatus: VerificationStatus;

  @ApiProperty({
    description: 'نوع المزود',
    enum: ProviderType,
    example: ProviderType.INDIVIDUAL,
  })
  providerType: ProviderType;

  @ApiPropertyOptional({
    description: 'رقم الهوية (مخفي جزئياً)',
    example: '***456789',
  })
  maskedIdNumber?: string;

  @ApiPropertyOptional({
    description: 'تاريخ إصدار الوثيقة',
  })
  issueDate?: Date;

  @ApiPropertyOptional({
    description: 'تاريخ انتهاء الصلاحية',
  })
  licenseExpiryDate?: Date;

  @ApiPropertyOptional({
    description: 'عدد الأيام المتبقية للصلاحية',
    example: 180,
  })
  daysUntilExpiry?: number;

  @ApiProperty({
    description: 'هل يمكن للمزود إضافة خدمات؟',
    example: true,
  })
  canAddServices: boolean;

  @ApiPropertyOptional({
    description: 'تاريخ آخر تحديث',
  })
  lastUpdated?: Date;

  @ApiPropertyOptional({
    description: 'ملاحظات (في حالة الرفض أو المراجعة)',
  })
  notes?: string;
}

/**
 * إحصائيات التحقق للوحة التحكم
 */
export class VerificationStatsDto {
  @ApiProperty({ description: 'إجمالي المزودين' })
  total: number;

  @ApiProperty({ description: 'المزودين الموثقين' })
  verified: number;

  @ApiProperty({ description: 'في انتظار المراجعة' })
  pendingReview: number;

  @ApiProperty({ description: 'يحتاج مراجعة المشرف' })
  adminReview: number;

  @ApiProperty({ description: 'منتهي الصلاحية' })
  expired: number;

  @ApiProperty({ description: 'مرفوض' })
  rejected: number;

  @ApiProperty({ description: 'معطل' })
  deactivated: number;

  @ApiProperty({ description: 'المزودين الذين ستنتهي صلاحيتهم خلال 30 يوم' })
  expiringWithin30Days: number;
}
