import { 
  IsString, IsNumber, IsOptional, IsArray, IsObject, 
  IsEnum, IsBoolean, ValidateNested, Min, Max 
} from 'class-validator';
import { Type } from 'class-transformer';
import { BookingType, PayType } from './service.schema';

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
  // ✅ بعد التعديل (أصبحت اختيارية في الـ DTO)
  @IsOptional()
  @IsNumber()
  latitude?: number; // ⬅️ إضافة علامة ? وجعلها اختيارية
  
  @IsOptional()
  @IsNumber()
  longitude?: number; // ⬅️ إضافة علامة ? وجعلها اختيارية
  
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
  @ValidateNested()
  @Type(() => PricingOptionsDto)
  price?: PricingOptionsDto;

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

  // 🆕 حقول خاصة بأنواع الحجز المختلفة
  @IsOptional()
  @IsNumber()
  @Min(0)
  maxCapacity?: number;

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
  cleanupTimeMinutes?: number; // 🆕 وقت التنظيف بين الحجوزات

  @IsOptional()
  @IsBoolean()
  allowFullVenueBooking?: boolean;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  workingDays?: string[]; // ['sunday', 'monday', 'tuesday', etc.]

  @IsOptional()
  @IsString()
  description?: string; // إضافة الوصف هنا


}

export class UpdateServiceDto {
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
  @ValidateNested()
  @Type(() => PricingOptionsDto)
  price?: PricingOptionsDto;

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
  cleanupTimeMinutes?: number; // 🆕 وقت التنظيف

  @IsOptional()
  @IsBoolean()
  allowFullVenueBooking?: boolean;


  @IsOptional()
  @IsString()
  description?: string; // إضافة الوصف هنا أيضاً
  
}