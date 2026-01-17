// upload-document.dto.ts
import { IsEnum, IsOptional, IsString, Length, Matches } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { DocumentType, ProviderType } from '../constants/compliance.constants';

/**
 * DTO for uploading verification document
 */
export class UploadDocumentDto {
  @ApiProperty({
    description: 'Type of uploaded document',
    enum: DocumentType,
    example: DocumentType.NATIONAL_ID,
  })
  @IsEnum(DocumentType)
  documentType: DocumentType;

  @ApiProperty({
    description: 'Provider type (individual or business)',
    enum: ProviderType,
    example: ProviderType.INDIVIDUAL,
  })
  @IsEnum(ProviderType)
  providerType: ProviderType;

  @ApiPropertyOptional({
    description: 'Palestinian ID number (9 digits) - required for individuals',
    example: '123456789',
  })
  @IsOptional()
  @IsString()
  @Length(9, 9, { message: 'ID number must be 9 digits' })
  @Matches(/^\d{9}$/, { message: 'ID number must contain only digits' })
  idNumber?: string;

  @ApiPropertyOptional({
    description: 'Arabic name for manual verification (optional)',
    example: 'محمد أحمد علي',
  })
  @IsOptional()
  @IsString()
  arabicName?: string;
}

/**
 * DTO for manual verification by admin
 */
export class AdminVerificationDto {
  @ApiProperty({
    description: 'Provider ID',
    example: '507f1f77bcf86cd799439011',
  })
  @IsString()
  providerId: string;

  @ApiProperty({
    description: 'Is verification approved?',
    example: true,
  })
  approved: boolean;

  @ApiPropertyOptional({
    description: 'Admin notes',
    example: 'Manually verified - documents are valid',
  })
  @IsOptional()
  @IsString()
  adminNotes?: string;

  @ApiPropertyOptional({
    description: 'Rejection reason (in case of rejection)',
    example: 'Document is unclear',
  })
  @IsOptional()
  @IsString()
  rejectionReason?: string;
}

/**
 * DTO for document renewal
 */
export class RenewDocumentDto {
  @ApiProperty({
    description: 'Type of document to renew',
    enum: DocumentType,
    example: DocumentType.BUSINESS_LICENSE,
  })
  @IsEnum(DocumentType)
  documentType: DocumentType;
}

/**
 * DTO for searching providers by verification status
 */
export class SearchProvidersDto {
  @ApiPropertyOptional({
    description: 'Verification status to search for',
    example: 'verified',
  })
  @IsOptional()
  @IsString()
  verificationStatus?: string;

  @ApiPropertyOptional({
    description: 'Provider type',
    enum: ProviderType,
  })
  @IsOptional()
  @IsEnum(ProviderType)
  providerType?: ProviderType;

  @ApiPropertyOptional({
    description: 'Number of items per page',
    example: 10,
  })
  @IsOptional()
  limit?: number;

  @ApiPropertyOptional({
    description: 'Page number',
    example: 1,
  })
  @IsOptional()
  page?: number;
}
