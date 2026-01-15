// cart.dto.ts
import { IsString, IsNumber, IsOptional, IsBoolean, IsDateString, ValidateNested, Min, Max, IsArray, IsEnum, IsObject, MaxLength } from 'class-validator';
import { Type } from 'class-transformer';

export enum DayOfWeek {
  SUNDAY = 'sunday',
  MONDAY = 'monday',
  TUESDAY = 'tuesday',
  WEDNESDAY = 'wednesday',
  THURSDAY = 'thursday',
  FRIDAY = 'friday',
  SATURDAY = 'saturday'
}

// 🆕 DTO لموقع العميل
export class ClientLocationDto {
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
  @MaxLength(500)
  locationDescription?: string;
}

export class BookingDetailsDto {
  @IsDateString()
  date: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(23)
  startHour?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(23)
  endHour?: number;

  @IsOptional()
  @IsNumber()
  @Min(1)
  numberOfPeople?: number;

  @IsOptional()
  @IsBoolean()
  isFullVenue?: boolean;

  // 🆕 موقع العميل (للخدمات التي تذهب للعميل)
  @IsOptional()
  @ValidateNested()
  @Type(() => ClientLocationDto)
  clientLocation?: ClientLocationDto;

  // 🆕 وصف الحجز (ملاحظات خاصة من العميل)
  @IsOptional()
  @IsString()
  @MaxLength(500)
  bookingDescription?: string;
}

export class AddToCartDto {
  @IsString()
  serviceId: string;

  @ValidateNested()
  @Type(() => BookingDetailsDto)
  bookingDetails: BookingDetailsDto;
}

export class RemoveFromCartDto {
  @IsString()
  serviceId: string;
}

export class UpdateCartItemDto {
  @IsString()
  serviceId: string;

  @ValidateNested()
  @Type(() => BookingDetailsDto)
  bookingDetails: BookingDetailsDto;
}