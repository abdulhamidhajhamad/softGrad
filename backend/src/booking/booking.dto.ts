import { 
  IsNotEmpty, 
  IsArray, 
  IsNumber, 
  IsPositive, 
  ValidateNested,
  IsDateString,
  IsString
} from 'class-validator';
import { Type } from 'class-transformer';

export class PaymentConfirmationDto {
    @IsString()
    @IsNotEmpty()
    bookingId: string;
}

export class BookingServiceItemDto {
  @IsString()
  @IsNotEmpty()
  serviceId: string;

  @IsDateString()
  @IsNotEmpty()
  bookingDate: string;
}

export class CreateBookingDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => BookingServiceItemDto)
  services: BookingServiceItemDto[];

  @IsNumber({ maxDecimalPlaces: 2 })
  @IsPositive()
  @Type(() => Number)
  totalAmount: number;
}
