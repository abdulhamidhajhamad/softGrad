import { 
  IsString, IsNumber, IsOptional, IsArray, IsObject, 
  IsEnum, IsBoolean, ValidateNested, Min, Max 
} from 'class-validator';
import { Type } from 'class-transformer';
import { BookingType, PayType } from './service.schema';

// ... (PricingOptionsDto & LocationDto بقيت كما هي) ...
export class PricingOptionsDto {
  @IsOptional()
  @IsNumber()
  @Min(0)
  perHour?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  perDay?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  perPerson?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  fullVenue?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  basePrice?: number;
}

export class LocationDto {
  @IsOptional()
  @IsNumber()
  latitude?: number;
  
  @IsOptional()
  @IsNumber()
  longitude?: number;
  
  @IsOptional()
  @IsString()
  address?: string;

  @IsOptional()
  @IsString()
  city?: string;

  @IsOptional()
  @IsString()
  country?: string;
}

export class CreateServiceDto {
  // ... (الحقول السابقة كما هي) ...
  @IsString()
  serviceName: string;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  images?: string[];

  @IsEnum(BookingType)
  bookingType: BookingType;

  @ValidateNested()
  @Type(() => LocationDto)
  location: LocationDto;

  @IsOptional()
  @IsNumber()
  @Min(0)
  price?: number;

  @IsOptional()
  @IsString()
  externalLink?: string;

  @IsString()
  category: string;

  @IsEnum(PayType)
  payType: PayType;

  @IsOptional()
  @IsObject()
  additionalInfo?: any;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(5)
  rating?: number;

  // ✅ الحقول الاختيارية
  @IsOptional()
  @IsNumber()
  @Min(0)
  maxCapacity?: number;

  // 🆕 حقل جديد: الحد الأقصى للفعاليات في نفس الوقت
  @IsOptional()
  @IsNumber()
  @Min(1)
  maxConcurrency?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  minBookingHours?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  maxBookingHours?: number;

  @IsOptional()
  @IsArray()
  @IsNumber({}, { each: true })
  availableHours?: number[];

  @IsOptional()
  @IsNumber()
  @Min(0)
  cleanupTimeMinutes?: number;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  workingDays?: string[];

  @IsOptional()
  @IsString()
  description?: string;
}

export class UpdateServiceDto {
  // ... (نفس التعديل هنا) ...
  @IsOptional()
  @IsString()
  serviceName?: string;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  images?: string[];

  @IsOptional()
  @IsEnum(BookingType)
  bookingType?: BookingType;

  @IsOptional()
  @ValidateNested()
  @Type(() => LocationDto)
  location?: LocationDto;

  @IsOptional()
  @IsNumber()
  @Min(0)
  price?: number;

  @IsOptional()
  @IsString()
  externalLink?: string;

  @IsOptional()
  @IsString()
  category?: string;

  @IsOptional()
  @IsEnum(PayType)
  payType?: PayType;

  @IsOptional()
  @IsObject()
  additionalInfo?: any;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(5)
  rating?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  maxCapacity?: number;

  // 🆕 حقل جديد
  @IsOptional()
  @IsNumber()
  @Min(1)
  maxConcurrency?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  minBookingHours?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  maxBookingHours?: number;

  @IsOptional()
  @IsArray()
  @IsNumber({}, { each: true })
  availableHours?: number[];

  @IsOptional()
  @IsNumber()
  @Min(0)
  cleanupTimeMinutes?: number;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  workingDays?: string[];

  @IsOptional()
  @IsString()
  description?: string;
}