// داخل ملف review.dto.ts
import { IsString, IsNumber, IsNotEmpty, Min, Max, IsOptional } from 'class-validator';

export class CreateReviewDto {
  @IsString()
  @IsNotEmpty()
  serviceId: string;

  @IsNumber()
  @IsNotEmpty()
  @Min(1)
  @Max(5)
  rating: number; // إلزامي

  @IsString()
  @IsOptional() // أصبح اختيارياً
  comment?: string;

  @IsString()
  @IsNotEmpty()
  bookingId: string; 
  
  @IsOptional()
  payType?: string; // أضفته لضمان التوافق مع السكيما إذا لم يكن موجوداً في التوكن
}