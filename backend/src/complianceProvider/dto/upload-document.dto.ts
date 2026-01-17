// upload-document.dto.ts
import { IsEnum, IsOptional, IsString, Length, Matches } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { DocumentType, ProviderType } from '../constants/compliance.constants';

/**
 * DTO لرفع وثيقة التحقق
 */
export class UploadDocumentDto {
  @ApiProperty({
    description: 'نوع الوثيقة المرفوعة',
    enum: DocumentType,
    example: DocumentType.NATIONAL_ID,
  })
  @IsEnum(DocumentType)
  documentType: DocumentType;

  @ApiProperty({
    description: 'نوع المزود (فرد أو مؤسسة)',
    enum: ProviderType,
    example: ProviderType.INDIVIDUAL,
  })
  @IsEnum(ProviderType)
  providerType: ProviderType;

  @ApiPropertyOptional({
    description: 'رقم الهوية الفلسطينية (9 أرقام) - مطلوب للأفراد',
    example: '123456789',
  })
  @IsOptional()
  @IsString()
  @Length(9, 9, { message: 'رقم الهوية يجب أن يتكون من 9 أرقام' })
  @Matches(/^\d{9}$/, { message: 'رقم الهوية يجب أن يحتوي على أرقام فقط' })
  idNumber?: string;

  @ApiPropertyOptional({
    description: 'الاسم بالعربية للتحقق اليدوي (اختياري)',
    example: 'محمد أحمد علي',
  })
  @IsOptional()
  @IsString()
  arabicName?: string;
}

/**
 * DTO للتحقق اليدوي من قبل المشرف
 */
export class AdminVerificationDto {
  @ApiProperty({
    description: 'معرف المزود',
    example: '507f1f77bcf86cd799439011',
  })
  @IsString()
  providerId: string;

  @ApiProperty({
    description: 'هل تتم الموافقة على التحقق؟',
    example: true,
  })
  approved: boolean;

  @ApiPropertyOptional({
    description: 'ملاحظات المشرف',
    example: 'تم التحقق يدوياً - الوثائق سليمة',
  })
  @IsOptional()
  @IsString()
  adminNotes?: string;

  @ApiPropertyOptional({
    description: 'سبب الرفض (في حالة الرفض)',
    example: 'الوثيقة غير واضحة',
  })
  @IsOptional()
  @IsString()
  rejectionReason?: string;
}

/**
 * DTO لتجديد الوثائق
 */
export class RenewDocumentDto {
  @ApiProperty({
    description: 'نوع الوثيقة المراد تجديدها',
    enum: DocumentType,
    example: DocumentType.BUSINESS_LICENSE,
  })
  @IsEnum(DocumentType)
  documentType: DocumentType;
}

/**
 * DTO للبحث عن المزودين حسب حالة التحقق
 */
export class SearchProvidersDto {
  @ApiPropertyOptional({
    description: 'حالة التحقق للبحث',
    example: 'verified',
  })
  @IsOptional()
  @IsString()
  verificationStatus?: string;

  @ApiPropertyOptional({
    description: 'نوع المزود',
    enum: ProviderType,
  })
  @IsOptional()
  @IsEnum(ProviderType)
  providerType?: ProviderType;

  @ApiPropertyOptional({
    description: 'عدد العناصر في الصفحة',
    example: 10,
  })
  @IsOptional()
  limit?: number;

  @ApiPropertyOptional({
    description: 'رقم الصفحة',
    example: 1,
  })
  @IsOptional()
  page?: number;
}
