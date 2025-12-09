// package.dto.ts
import { IsString,IsArray, IsNotEmpty, IsNumber, IsDateString, IsMongoId, ArrayMinSize } from 'class-validator';

export class CreatePackageDto {
    // 🆕 اسم/عنوان الباقة
  @IsNotEmpty()
  @IsString()
  packageName: string; // ✅ الحقل الجديد

  @IsNotEmpty()
  @IsArray()
  @ArrayMinSize(1)
  @IsMongoId({ each: true }) // التأكد من أن كل عنصر هو MongoID صالح
  serviceIds: string[]; 

  // السعر الجديد للباقة، يجب أن يكون رقماً
  @IsNotEmpty()
  @IsNumber()
  newPrice: number; 

  // تاريخ بداية العرض، نستخدم IsDateString للتحقق من تنسيق التاريخ/الوقت
  @IsNotEmpty()
  @IsDateString()
  startDate: string; 

  // تاريخ نهاية العرض
  @IsNotEmpty()
  @IsDateString()
  endDate: string; 
}

// يمكنك إضافة DTOs أخرى هنا لاحقاً إذا احتجت إلى تحديث الباقة