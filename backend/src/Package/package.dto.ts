// package.dto.ts
import { IsString, IsNumber, IsArray, ValidateNested, IsOptional, IsDateString, Min, Max } from 'class-validator';
import { Type } from 'class-transformer';

export class PackageServiceItemDto {
  @IsString()
  serviceId: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  newPrice?: number;

  @IsOptional()
  @IsNumber()
  @Min(1)
  maxHours?: number;

  @IsOptional()
  @IsNumber()
  @Min(1)
  maxCapacity?: number;
}

export class CreatePackageDto {
  @IsString()
  packageName: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PackageServiceItemDto)
  services: PackageServiceItemDto[];

  @IsNumber()
  @Min(0)
  newPrice: number;

  @IsDateString()
  startDate: string;

  @IsDateString()
  endDate: string;

  @IsOptional()
  @IsString()
  packageImageUrl?: string;
}

export class UpdatePackageDto {
  @IsOptional()
  @IsString()
  packageName?: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PackageServiceItemDto)
  services?: PackageServiceItemDto[];

  @IsOptional()
  @IsNumber()
  @Min(0)
  newPrice?: number;

  @IsOptional()
  @IsDateString()
  startDate?: string;

  @IsOptional()
  @IsDateString()
  endDate?: string;

  @IsOptional()
  @IsString()
  packageImageUrl?: string;
}

export class UpdatePackageStatusDto {
  @IsOptional()
  isActive?: boolean;
}

// DTO للحجز من الباقة
export class BookingDetailsDto {
  @IsDateString()
  date: string;

  @IsOptional()
  @IsNumber()
  @Min(1)
  numberOfHours?: number;

  @IsOptional()
  @IsNumber()
  @Min(1)
  numberOfPeople?: number;

  // 🆕 إضافة الحقول لخدمات Hourly
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
}

export class PackageServiceBookingDto {
  @IsString()
  serviceId: string;

  @ValidateNested()
  @Type(() => BookingDetailsDto)
  bookingDetails: BookingDetailsDto;
}

export class AddPackageToCartDto {
  @IsString()
  packageId: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PackageServiceBookingDto)
  serviceBookings: PackageServiceBookingDto[];
}