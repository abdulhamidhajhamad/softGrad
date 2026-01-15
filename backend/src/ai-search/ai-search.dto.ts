// src/ai-search/ai-search.dto.ts

import { IsString, IsNotEmpty, IsNumber, Min, IsDateString, IsOptional, IsArray, ValidateNested, IsInt, Max } from 'class-validator';
import { Type } from 'class-transformer';

// DTO for service priority with budget percentage
export class ServicePriorityDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsInt()
  @Min(1)
  @Max(10)
  priority: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(100)
  budgetPercent?: number;  // نسبة الميزانية المخصصة (0 = auto)
}

export class AiSearchDto {
  @IsString({ message: 'المدينة يجب أن تكون نص' })
  @IsNotEmpty({ message: 'المدينة مطلوبة' })
  city: string;

  @IsNumber({}, { message: 'عدد الأشخاص يجب أن يكون رقم' })
  @Min(1, { message: 'عدد الأشخاص يجب أن يكون على الأقل 1' })
  guestCount: number;

  @IsNumber({}, { message: 'الحد الأدنى للبدجت يجب أن يكون رقم' })
  @Min(1, { message: 'الحد الأدنى للبدجت يجب أن يكون أكبر من صفر' })
  budgetMin: number;

  @IsNumber({}, { message: 'الحد الأقصى للبدجت يجب أن يكون رقم' })
  @Min(1, { message: 'الحد الأقصى للبدجت يجب أن يكون أكبر من صفر' })
  budgetMax: number;

  @IsString({ message: 'نوع الحفلة يجب أن يكون نص' })
  @IsNotEmpty({ message: 'نوع الحفلة مطلوب' })
  eventType: string;

  @IsDateString({}, { message: 'تاريخ الحفلة يجب أن يكون تاريخ صالح' })
  @IsNotEmpty({ message: 'تاريخ الحفلة مطلوب' })
  eventDate: string;

  @IsOptional()
  @IsString({ message: 'وقت البداية يجب أن يكون نص' })
  startTime?: string;

  @IsOptional()
  @IsString({ message: 'وقت النهاية يجب أن يكون نص' })
  endTime?: string;

  // 🆕 التعديل الجديد: التاجز الإجبارية من اليوزر
  @IsArray({ message: 'التفضيلات يجب أن تكون قائمة' })
  @IsString({ each: true, message: 'كل تفضيل يجب أن يكون نص' })
  @IsNotEmpty({ message: 'يجب اختيار تفضيلات (Tags) للحفلة' })
  userTags: string[]; // مثال: ["Outdoor", "Modern", "DJ", "Buffet"]

  // 🆕 التعديل الجديد: الملاحظات النصية الاختيارية
  @IsOptional()
  @IsString()
  additionalNotes?: string; // مثال: "أريد التركيز على الإضاءة الخافتة"

  // 🆕 NEW: Service priorities with optional budget percentages
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ServicePriorityDto)
  servicePriorities?: ServicePriorityDto[];

  // 🆕 Budget flexibility percentage (±5% tolerance)
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(50)
  budgetFlexibility?: number;  // default 5%
}

// DTO for Single Service Search
export class SingleServiceSearchDto {
  @IsString({ message: 'نوع الخدمة يجب أن يكون نص' })
  @IsNotEmpty({ message: 'نوع الخدمة مطلوب' })
  category: string;

  @IsString({ message: 'المدينة يجب أن تكون نص' })
  @IsNotEmpty({ message: 'المدينة مطلوبة' })
  city: string;

  @IsNumber({}, { message: 'عدد الأشخاص يجب أن يكون رقم' })
  @Min(1, { message: 'عدد الأشخاص يجب أن يكون على الأقل 1' })
  guestCount: number;

  @IsNumber({}, { message: 'الحد الأدنى للبدجت يجب أن يكون رقم' })
  @Min(0, { message: 'الحد الأدنى للبدجت يجب أن يكون صفر أو أكثر' })
  budgetMin: number;

  @IsNumber({}, { message: 'الحد الأقصى للبدجت يجب أن يكون رقم' })
  @Min(1, { message: 'الحد الأقصى للبدجت يجب أن يكون أكبر من صفر' })
  budgetMax: number;

  @IsString({ message: 'نوع الحفلة يجب أن يكون نص' })
  @IsNotEmpty({ message: 'نوع الحفلة مطلوب' })
  eventType: string;

  @IsDateString({}, { message: 'تاريخ الحفلة يجب أن يكون تاريخ صالح' })
  @IsNotEmpty({ message: 'تاريخ الحفلة مطلوب' })
  eventDate: string;

  @IsOptional()
  @IsString()
  startTime?: string;

  @IsOptional()
  @IsString()
  endTime?: string;

  @IsOptional()
  @IsString()
  venueType?: string;

  @IsOptional()
  @IsString()
  notes?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(50)
  budgetFlexibility?: number;  // نسبة المرونة في الميزانية
}