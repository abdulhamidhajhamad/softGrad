// package.dto.ts
import { IsString,IsArray, IsNotEmpty, IsNumber, IsDateString, IsMongoId, ArrayMinSize } from 'class-validator';

import { Transform } from 'class-transformer'; // 👈 استيراد جديد وحيوي

export class CreatePackageDto {
  @IsNotEmpty()
  @IsString()
  packageName: string; 

  @IsNotEmpty()
  @IsArray()
  @ArrayMinSize(1)
  // 1. 🆕 التحويل من نص JSON إلى مصفوفة قبل التحقق
  @Transform(({ value }) => JSON.parse(value)) // 👈 التعديل هنا
  @IsMongoId({ each: true }) 
  serviceIds: string[]; 

  @IsNotEmpty()
  // 2. 🆕 التحويل من نص إلى رقم قبل التحقق
  @Transform(({ value }) => parseFloat(value)) // 👈 التعديل هنا
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