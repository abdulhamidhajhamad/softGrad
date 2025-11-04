import { IsArray, IsDate, IsMongoId, IsOptional, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

export class CartServiceDto {
  @IsMongoId()
  serviceId: string;

  @IsDate()
  @Type(() => Date)
  bookingDate: Date;
}

export class AddToCartDto {
  @IsMongoId()
  serviceId: string;

  @IsDate()
  @Type(() => Date)
  bookingDate: Date;
}

export class RemoveFromCartDto {
  @IsMongoId()
  serviceId: string;

  @IsDate()
  @Type(() => Date)
  bookingDate: Date;
}

export class ShoppingCartResponseDto {
  _id: string;
  userId: string;
  services: CartServiceDto[];
  totalPrice: number;
  createdAt: Date;
  updatedAt: Date;
}