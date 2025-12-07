import { IsString, IsNumber, IsArray, IsOptional,IsBoolean, IsObject, IsNotEmpty, Min, IsDate, MinLength, Max } from 'class-validator';
import { Transform, Type } from 'class-transformer'; // ← أضف هذا

export class LocationDto {
  @IsNumber()
  @IsNotEmpty()
  latitude: number;

  @IsNumber()
  @IsNotEmpty()
  longitude: number;

  @IsString()
  @IsOptional()
  address?: string;

  @IsString()
  @IsOptional()
  city?: string;

  @IsString()
  @IsOptional()
  country?: string;
}

export class CreateServiceDto {
  @IsString()
  @IsNotEmpty()
  serviceName: string;

  @IsArray()
  @IsOptional()
  images?: string[];

  @IsObject()
  @IsNotEmpty()
  @Type(() => LocationDto) // ← مهم جداً
  location: LocationDto;

  @IsNumber()
  @Min(0)
  @Transform(({ value }) => parseFloat(value)) // ← أضف هذا
  price: number;

  @IsString()
  @IsNotEmpty()
  category: string;

  @IsOptional()
  additionalInfo?: any;

  @IsString()
  @IsOptional()
  companyName?: string;

  @IsArray()
  @IsOptional()
  @IsDate({ each: true })
  bookedDates?: Date[];

  @IsNumber()
  @Min(0)
  @Max(5)
  @IsOptional()
  @Transform(({ value }) => value ? parseFloat(value) : 0) // ← أضف هذا
  rating?: number;
  
@IsBoolean()
  @IsOptional()
  @Transform(({ value }) => { 
    if (value === 'true') return true;
    if (value === 'false') return false;
    return value;
  })
  isActive?: boolean;
}

export class UpdateServiceDto {
  @IsString()
  @IsOptional()
  serviceName?: string;

  @IsArray()
  @IsOptional()
  images?: string[];

  @IsObject()
  @IsOptional()
  location?: LocationDto;

  @IsNumber()
  @Min(0)
  @IsOptional()
  price?: number;

  @IsString()
  @IsOptional()
  category?: string;

  @IsOptional()
  additionalInfo?: any;

  @IsString()
  @IsOptional()
  companyName?: string;

  @IsArray()
  @IsOptional()
  @IsDate({ each: true })
  bookedDates?: Date[];

  // ✅ إضافة الرايتنج للتحديث
  @IsNumber()
  @Min(0)
  @Max(5)
  @IsOptional()
  rating?: number;

  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}

export class ServiceResponseDto {
  _id: string;
  providerId: string;
  serviceName: string;
  images: string[];
  reviews: any[];
  location: any;
  price: number;
  category: string;
  additionalInfo?: any;
  createdAt: Date;
  updatedAt: Date;
  companyName?: string;
  bookedDates: Date[];
  rating: number; // ✅ إضافة الرايتنج للاستجابة
}