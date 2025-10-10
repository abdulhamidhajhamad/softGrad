import { IsString, IsNotEmpty, IsEnum, IsOptional, IsNumber, IsPositive, Min, Max } from 'class-validator';
import { Type } from 'class-transformer';

export enum ServiceCategory {
  VENUE = 'venue',
  BUFFET = 'buffet',
  PHOTOGRAPHY = 'photography',
}

export class CreateServiceDto {
  @IsNumber()
  @IsNotEmpty()
  providerId: number;

  @IsString()
  @IsNotEmpty()
  name: string;

  @IsEnum(ServiceCategory)
  @IsOptional()
  category?: ServiceCategory;

  @IsString()
  @IsOptional()
  description?: string;

  @IsNumber({ maxDecimalPlaces: 2 })
  @IsPositive()
  @Type(() => Number)
  price: number;

  @IsNumber({ maxDecimalPlaces: 1 })
  @Min(0)
  @Max(5)
  @IsOptional()
  @Type(() => Number)
  rating?: number;
}

export class UpdateServiceDto {
  @IsNumber()
  @IsOptional()
  providerId?: number;

  @IsString()
  @IsOptional()
  name?: string;

  @IsEnum(ServiceCategory)
  @IsOptional()
  category?: ServiceCategory;

  @IsString()
  @IsOptional()
  description?: string;

  @IsNumber({ maxDecimalPlaces: 2 })
  @IsPositive()
  @IsOptional()
  @Type(() => Number)
  price?: number;

  @IsNumber({ maxDecimalPlaces: 1 })
  @Min(0)
  @Max(5)
  @IsOptional()
  @Type(() => Number)
  rating?: number;
}