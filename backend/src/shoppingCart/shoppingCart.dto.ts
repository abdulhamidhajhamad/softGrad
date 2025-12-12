import { IsArray, IsDate, IsMongoId, IsOptional, IsNumber, IsBoolean, Min, Max, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

export class CartServiceDto {
  @IsMongoId()
  serviceId: string;

  @IsDate()
  @Type(() => Date)
  bookingDate: Date;

  // 🆕 للحجوزات بالساعة
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

  // 🆕 للحجوزات حسب السعة
  @IsOptional()
  @IsNumber()
  @Min(1)
  numberOfPeople?: number;

  // 🆕 للحجوزات المختلطة - هل هو حجز كامل للمكان؟
  @IsOptional()
  @IsBoolean()
  isFullVenueBooking?: boolean;
}

export class AddToCartDto {
  @IsMongoId()
  serviceId: string;

  @IsDate()
  @Type(() => Date)
  bookingDate: Date;

  // 🆕 للحجوزات بالساعة
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

  // 🆕 للحجوزات حسب السعة
  @IsOptional()
  @IsNumber()
  @Min(1)
  numberOfPeople?: number;

  // 🆕 للحجوزات المختلطة
  @IsOptional()
  @IsBoolean()
  isFullVenueBooking?: boolean;
}

export class RemoveFromCartDto {
  @IsMongoId()
  serviceId: string;

  @IsDate()
  @Type(() => Date)
  bookingDate: Date;

  @IsOptional()
  @IsNumber()
  startHour?: number;

  @IsOptional()
  @IsNumber()
  endHour?: number;
}

export class ShoppingCartResponseDto {
  _id: string;
  userId: string;
  services: CartServiceDto[];
  totalPrice: number;
  createdAt: Date;
  updatedAt: Date;
}