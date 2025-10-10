import { IsNotEmpty, IsString, IsDateString, IsEnum, IsOptional, IsPositive, IsNumber } from 'class-validator';
import { Type } from 'class-transformer';
import { BookingStatus } from './booking.entity';

export class CreateBookingDto {
  @IsString() // Changed from @IsNumber
  @IsNotEmpty()
  userName: string; // Changed from userId

  @IsString() // Changed from @IsNumber
  @IsNotEmpty()
  serviceName: string; // Changed from serviceId

  @IsDateString()
  @IsNotEmpty()
  bookingDate: string;

  @IsEnum(BookingStatus)
  @IsOptional()
  status?: BookingStatus;

  @IsNumber({ maxDecimalPlaces: 2 })
  @IsPositive()
  @Type(() => Number)
  totalPrice: number;
}

export class UpdateBookingDto {
  @IsString() // Changed from @IsNumber
  @IsOptional()
  userName?: string; // Changed from userId

  @IsString() // Changed from @IsNumber
  @IsOptional()
  serviceName?: string; // Changed from serviceId

  @IsDateString()
  @IsOptional()
  bookingDate?: string;

  @IsEnum(BookingStatus)
  @IsOptional()
  status?: BookingStatus;

  @IsNumber({ maxDecimalPlaces: 2 })
  @IsPositive()
  @IsOptional()
  @Type(() => Number)
  totalPrice?: number;
}