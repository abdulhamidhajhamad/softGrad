// verification-response.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { 
  VerificationStatus, 
  DocumentType, 
  ProviderType,
  RejectionReason 
} from '../constants/compliance.constants';

/**
 * Result of data extraction from document
 */
export class ExtractedDataDto {
  @ApiPropertyOptional({
    description: 'Extracted ID number',
    example: '123456789',
  })
  idNumber?: string;

  @ApiPropertyOptional({
    description: 'Extracted name from document',
    example: 'محمد أحمد علي',
  })
  extractedName?: string;

  @ApiPropertyOptional({
    description: 'Extracted issue date',
    example: '2024-01-15',
  })
  issueDate?: Date;

  @ApiPropertyOptional({
    description: 'Calculated expiry date',
    example: '2025-01-15',
  })
  expiryDate?: Date;

  @ApiPropertyOptional({
    description: 'Business name (for companies)',
    example: 'شركة النجاح للخدمات',
  })
  businessName?: string;

  @ApiPropertyOptional({
    description: 'Commercial registration number',
    example: '12345',
  })
  commercialRegNumber?: string;

  @ApiPropertyOptional({
    description: 'Full text extracted from document',
  })
  rawText?: string;

  @ApiPropertyOptional({
    description: 'Extraction confidence level (0-1)',
    example: 0.95,
  })
  confidence?: number;
}

/**
 * Match result
 */
export class MatchResultDto {
  @ApiProperty({
    description: 'Did the ID number match?',
    example: true,
  })
  idMatched: boolean;

  @ApiProperty({
    description: 'Did the name match?',
    example: true,
  })
  nameMatched: boolean;

  @ApiProperty({
    description: 'Name similarity score',
    example: 0.85,
  })
  nameSimilarityScore: number;

  @ApiProperty({
    description: 'Did at least the first name match?',
    example: true,
  })
  firstNameMatched: boolean;

  @ApiProperty({
    description: 'Is the document valid?',
    example: true,
  })
  isValid: boolean;

  @ApiPropertyOptional({
    description: 'Days remaining until expiry',
    example: 180,
  })
  daysUntilExpiry?: number;
}

/**
 * Document verification response
 */
export class VerificationResponseDto {
  @ApiProperty({
    description: 'Was the verification successful?',
    example: true,
  })
  success: boolean;

  @ApiProperty({
    description: 'New verification status',
    enum: VerificationStatus,
    example: VerificationStatus.VERIFIED,
  })
  status: VerificationStatus;

  @ApiProperty({
    description: 'Explanatory message',
    example: 'Document verified successfully',
  })
  message: string;

  @ApiPropertyOptional({
    description: 'Data extracted from document',
    type: ExtractedDataDto,
  })
  extractedData?: ExtractedDataDto;

  @ApiPropertyOptional({
    description: 'Match result',
    type: MatchResultDto,
  })
  matchResult?: MatchResultDto;

  @ApiPropertyOptional({
    description: 'Rejection reason (in case of rejection)',
    enum: RejectionReason,
  })
  rejectionReason?: RejectionReason;

  @ApiPropertyOptional({
    description: 'Uploaded document URL',
    example: 'https://storage.supabase.co/...',
  })
  documentUrl?: string;

  @ApiPropertyOptional({
    description: 'Expiry date',
    example: '2025-01-15T00:00:00.000Z',
  })
  expiryDate?: Date;
}

/**
 * Provider verification status response
 */
export class ProviderVerificationStatusDto {
  @ApiProperty({
    description: 'Provider ID',
    example: '507f1f77bcf86cd799439011',
  })
  providerId: string;

  @ApiProperty({
    description: 'Current verification status',
    enum: VerificationStatus,
    example: VerificationStatus.VERIFIED,
  })
  verificationStatus: VerificationStatus;

  @ApiProperty({
    description: 'Provider type',
    enum: ProviderType,
    example: ProviderType.INDIVIDUAL,
  })
  providerType: ProviderType;

  @ApiPropertyOptional({
    description: 'ID number (partially masked)',
    example: '***456789',
  })
  maskedIdNumber?: string;

  @ApiPropertyOptional({
    description: 'Document issue date',
  })
  issueDate?: Date;

  @ApiPropertyOptional({
    description: 'Expiry date',
  })
  licenseExpiryDate?: Date;

  @ApiPropertyOptional({
    description: 'Days remaining until expiry',
    example: 180,
  })
  daysUntilExpiry?: number;

  @ApiProperty({
    description: 'Can provider add services?',
    example: true,
  })
  canAddServices: boolean;

  @ApiPropertyOptional({
    description: 'Last update date',
  })
  lastUpdated?: Date;

  @ApiPropertyOptional({
    description: 'Notes (in case of rejection or review)',
  })
  notes?: string;
}

/**
 * Verification statistics for dashboard
 */
export class VerificationStatsDto {
  @ApiProperty({ description: 'Total providers' })
  total: number;

  @ApiProperty({ description: 'Verified providers' })
  verified: number;

  @ApiProperty({ description: 'Pending review' })
  pendingReview: number;

  @ApiProperty({ description: 'Requires admin review' })
  adminReview: number;

  @ApiProperty({ description: 'Expired' })
  expired: number;

  @ApiProperty({ description: 'Rejected' })
  rejected: number;

  @ApiProperty({ description: 'Deactivated' })
  deactivated: number;

  @ApiProperty({ description: 'Providers expiring within 30 days' })
  expiringWithin30Days: number;
}
