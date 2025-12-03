// src/promotion/promotion.dto.ts
import { IsString, IsNotEmpty, IsNumber, IsDateString, Min } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreatePromotionCodeDto {
  @IsString()
  @IsNotEmpty()
  @ApiProperty({ example: 'NEWYEAR20' })
  code: string;

  @IsNumber()
  @Min(0.01)
  @ApiProperty({ example: 0.15, description: 'Discount value as a decimal (e.g., 0.15 for 15%)' })
  discountValue: number;

  @IsDateString()
  @ApiProperty({ example: '2026-12-31T23:59:59.000Z', description: 'ISO 8601 Date String' })
  expiryDate: Date;
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