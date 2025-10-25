import { IsString, IsNumber, IsArray, IsOptional, IsObject, IsNotEmpty, Min } from 'class-validator';

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

  @IsOptional()
  additionalInfo?: any;

  // 🔄 أضف هذا الحقل الجديد
  @IsString()
  @IsOptional()
  companyName?: string;
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

  @IsOptional()
  additionalInfo?: any;

  // 🔄 أضف هذا الحقل الجديد
  @IsString()
  @IsOptional()
  companyName?: string;
}

export class ServiceResponseDto {
  _id: string;
  providerId: string;
  serviceName: string;
  images: string[];
  reviews: any[];
  location: any;
  price: number;
  additionalInfo?: any;
  createdAt: Date;
  updatedAt: Date;
  
  // 🔄 أضف هذا الحقل الجديد
  companyName?: string;
}