// cart.dto.ts
import { IsString, IsNumber, IsOptional, IsBoolean, IsDateString, ValidateNested, Min, Max, IsArray, IsEnum } from 'class-validator';
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