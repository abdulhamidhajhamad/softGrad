import { IsString, IsNotEmpty, IsOptional, IsNumber, Min, Max, IsArray, IsEnum, IsObject } from 'class-validator';
import { Type } from 'class-transformer';
import { CustomerType } from './provider.entity';

export class CreateProviderDto {
  @IsString()
  @IsNotEmpty()
  companyName: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsString()
  @IsOptional()
  location?: string;

  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  imageUrls?: string[];

  @IsEnum(CustomerType)
  @IsOptional()
  customerType?: CustomerType;

  @IsObject()
  @IsOptional()
  details?: Record<string, any>;
}

export class UpdateProviderDto {
  @IsString()
  @IsOptional()
  companyName?: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsString()
  @IsOptional()
  location?: string;

  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  imageUrls?: string[];

  @IsEnum(CustomerType)
  @IsOptional()
  customerType?: CustomerType;

  @IsObject()
  @IsOptional()
  details?: Record<string, any>;
}

export class SearchProviderDto {
  @IsOptional()
  @IsString()
  location?: string;

  @IsOptional()
  @IsString()
  searchTerm?: string;

  @IsOptional()
  @IsEnum(CustomerType)
  customerType?: CustomerType;

  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  @Min(1)
  page?: number = 1;

  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  @Min(1)
  @Max(100)
  limit?: number = 10;
}

export class ProviderResponseDto {
  providerId: string;
  userId: string;
  companyName: string;
  description: string;
  location: string;
  imageUrls: string[];
  customerType: CustomerType;
  details: Record<string, any>;
}