// src/promotion/promotion.dto.ts (Enhanced)
import { 
  IsString, 
  IsNotEmpty, 
  IsNumber, 
  IsDateString, 
  Min, 
  Max,
  IsOptional,
  IsBoolean,
  IsEnum
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { PromoCodeType, PromoCodeStatus } from './promotion-code.schema';

export class CreatePromotionCodeDto {
  @IsString()
  @IsNotEmpty()
  @ApiProperty({ example: 'NEWYEAR25', description: 'Unique promo code (will be uppercase)' })
  code: string;

  @IsString()
  @IsNotEmpty()
  @ApiProperty({ example: 'New Year Special - 25% off all bookings!' })
  description: string;

  @IsEnum(PromoCodeType)
  @IsOptional()
  @ApiPropertyOptional({ 
    enum: PromoCodeType, 
    default: PromoCodeType.PERCENTAGE,
    example: PromoCodeType.PERCENTAGE 
  })
  type?: PromoCodeType;

  @IsNumber()
  @Min(0)
  @ApiProperty({ 
    example: 25, 
    description: 'For percentage: 0-100, For fixed amount: actual dollar amount' 
  })
  discountValue: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  @ApiPropertyOptional({ example: 50, description: 'Minimum purchase amount required' })
  minPurchaseAmount?: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  @ApiPropertyOptional({ example: 100, description: 'Maximum discount cap (for percentage type)' })
  maxDiscountAmount?: number;

  @IsDateString()
  @IsOptional()
  @ApiPropertyOptional({ example: '2025-01-01T00:00:00.000Z' })
  startDate?: string;

  @IsDateString()
  @IsNotEmpty()
  @ApiProperty({ example: '2025-12-31T23:59:59.000Z', description: 'ISO 8601 Date String' })
  expiryDate: string;

  @IsNumber()
  @Min(0)
  @IsOptional()
  @ApiPropertyOptional({ example: 1000, description: 'Total usage limit across all users' })
  usageLimit?: number;

  @IsNumber()
  @Min(1)
  @IsOptional()
  @ApiPropertyOptional({ example: 1, description: 'Max uses per user' })
  usageLimitPerUser?: number;

  @IsBoolean()
  @IsOptional()
  @ApiPropertyOptional({ 
    example: true, 
    description: 'Send email & push notifications to all users' 
  })
  sendNotification?: boolean;
}

export class UpdatePromotionCodeDto {
  @IsString()
  @IsOptional()
  @ApiPropertyOptional()
  description?: string;

  @IsEnum(PromoCodeStatus)
  @IsOptional()
  @ApiPropertyOptional({ enum: PromoCodeStatus })
  status?: PromoCodeStatus;

  @IsNumber()
  @Min(0)
  @IsOptional()
  @ApiPropertyOptional()
  minPurchaseAmount?: number;

  @IsDateString()
  @IsOptional()
  @ApiPropertyOptional()
  expiryDate?: string;

  @IsNumber()
  @Min(0)
  @IsOptional()
  @ApiPropertyOptional()
  usageLimit?: number;

  @IsBoolean()
  @IsOptional()
  @ApiPropertyOptional()
  isActive?: boolean;
}

export class ApplyPromoCodeDto {
  @IsString()
  @IsNotEmpty()
  @ApiProperty({ example: 'NEWYEAR25' })
  promoCode: string;
}

export class ValidatePromoCodeResponseDto {
  valid: boolean;
  message: string;
  discount?: number;
  finalAmount?: number;
  promoCode?: {
    code: string;
    description: string;
    type: PromoCodeType;
    discountValue: number;
    expiryDate: Date;
  };
}

export class BroadcastMessageDto {
  @IsString()
  @IsNotEmpty()
  @ApiProperty({ example: '🔥 خصومات الخريف بدأت الآن!' })
  title: string;

  @IsString()
  @IsNotEmpty()
  @ApiProperty({ example: 'استمتع بخصم 20% على جميع الفعاليات الجديدة...' })
  body: string;
}