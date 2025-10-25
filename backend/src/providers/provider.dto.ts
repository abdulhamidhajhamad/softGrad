import { IsString, IsOptional, IsNumber, IsBoolean, IsArray, IsObject, IsNotEmpty, IsIn } from 'class-validator';
import { Type } from 'class-transformer';

class CoordinatesDto {
  @IsOptional() @IsNumber() latitude?: number;
  @IsOptional() @IsNumber() longitude?: number;
}

class LocationDto {
  @IsOptional() @IsString() city?: string;
  @IsOptional() @IsString() country?: string;
  @IsOptional() @Type(() => CoordinatesDto) coordinates?: CoordinatesDto;
}

export class CreateServiceProviderDto {
  @IsNotEmpty() @IsString() companyName: string;
  @IsOptional() @IsString() description?: string;
  @IsOptional() @Type(() => LocationDto) location?: LocationDto;
  @IsOptional() @IsObject() details?: Record<string, any>;
  @IsOptional() @IsString() venueType?: string;
  @IsOptional() @IsBoolean() hasGoogleMapLocation?: boolean;
  @IsOptional() @IsIn(['regular', 'mid', 'high']) targetCustomerType?: 'regular' | 'mid' | 'high';
}

export class UpdateServiceProviderDto {
  @IsOptional() @IsString() description?: string;
  @IsOptional() @Type(() => LocationDto) location?: LocationDto;
  @IsOptional() @IsObject() details?: Record<string, any>;
  @IsOptional() @IsString() venueType?: string;
  @IsOptional() @IsBoolean() hasGoogleMapLocation?: boolean;
  @IsOptional() @IsIn(['regular', 'mid', 'high']) targetCustomerType?: 'regular' | 'mid' | 'high';
}
