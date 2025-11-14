import { IsString, IsNumber, IsArray, IsOptional, IsObject, IsNotEmpty, Min, IsDate, MinLength, Max } from 'class-validator';

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
  location: LocationDto;

  @IsNumber()
  @Min(0)
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

  // ✅ إضافة الرايتنج الافتراضي
  @IsNumber()
  @Min(0)
  @Max(5)
  @IsOptional()
  rating?: number;
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