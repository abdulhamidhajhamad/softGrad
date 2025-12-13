// package.dto.ts
import { IsString,IsOptional,IsArray, IsNotEmpty, IsNumber, IsDateString, IsMongoId, ArrayMinSize } from 'class-validator';

import { Transform } from 'class-transformer'; // 👈 استيراد جديد وحيوي

export class CreatePackageDto {
  @IsNotEmpty()
  @IsString()
  packageName: string; 

  @IsNotEmpty()
  @IsArray()
  serviceIds: string[];

  // 🟢 التعديلات للوصف: جعله اختياريًا وضمان القيمة الفارغة
  
  @IsOptional() // 👈 1. الآن يمكنك عدم إرساله
  @Transform(({ value }) => value ?? '') // 👈 2. إذا لم يتم إرساله (undefined/null)، يصبح ""
  @IsString()
  description: string; 

  @IsNotEmpty()
  @Transform(({ value }) => parseFloat(value)) 
  @IsNumber()
  newPrice: number; 

  @IsNotEmpty()
  @IsDateString()
  startDate: string; 

  @IsNotEmpty()
  @IsDateString()
  endDate: string; 
}
// يمكنك إضافة DTOs أخرى هنا لاحقاً إذا احتجت إلى تحديث الباقة