// src/review/review.dto.ts
import { IsString, IsNumber, IsNotEmpty, Min, Max, IsOptional, MaxLength, IsArray } from 'class-validator';
import { Type } from 'class-transformer';

export class CreateReviewDto {
  @IsString()
  @IsNotEmpty()
  serviceId: string;

  @IsString()
  @IsNotEmpty()
  bookingId: string;

  @IsNumber()
  @IsNotEmpty()
  @Min(1)
  @Max(5)
  @Type(() => Number)
  rating: number;

  @IsString()
  @IsOptional()
  @MaxLength(500)
  comment?: string;

  @IsArray()
  @IsOptional()
  @IsString({ each: true })
  images?: string[];
}

export class GetReviewsQueryDto {
  @IsString()
  @IsOptional()
  serviceId?: string;

  @IsNumber()
  @IsOptional()
  @Min(1)
  @Type(() => Number)
  page?: number = 1;

  @IsNumber()
  @IsOptional()
  @Min(1)
  @Max(50)
  @Type(() => Number)
  limit?: number = 10;
}

export class GetMyReviewsQueryDto {
  @IsNumber()
  @IsOptional()
  @Min(1)
  @Type(() => Number)
  page?: number = 1;

  @IsNumber()
  @IsOptional()
  @Min(1)
  @Max(50)
  @Type(() => Number)
  limit?: number = 10;
}