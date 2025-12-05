import { IsString, IsNumber, IsNotEmpty, Min, Max } from 'class-validator';
import { Types } from 'mongoose';

// DTO لاستقبال بيانات التقييم من Flutter
export class CreateReviewDto {
  @IsString()
  @IsNotEmpty()
  serviceId: string; // ID of the service being reviewed

  @IsNumber()
  @IsNotEmpty()
  @Min(1)
  @Max(5)
  rating: number; // The user's star rating

  @IsString()
  @IsNotEmpty()
  comment: string; // The user's text review (in English)

  // ⚠️ نضيف bookingId للتحقق من أن المستخدم قام بالشراء والخدمة اكتملت
  @IsString()
  @IsNotEmpty()
  bookingId: string; 
}