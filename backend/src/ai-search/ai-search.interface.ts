// src/ai-search/ai-search.interface.ts

import { Service } from '../service/service.schema';

// واجهة الخدمات المطلوبة ضمن الباكج (التي سيحددها AI)
export interface RequiredService {
    categoryName: string; // مثال: "Venue" أو "Photography"
    priority: number; // الأهمية (1 للأعلى)
    budgetWeight: number; // النسبة المئوية التقريبية للميزانية (0.5 = 50%)
    aiTags: string[]; // علامات البحث المحددة لهذه الخدمة
}

// واجهة الباكج المخطط له (Blueprint)
export interface PackageBlueprint {
    packageName: string; 
    description: string;
    targetPrice: number; 
    requiredServices: RequiredService[];
}

// الواجهة الرئيسية لنتائج استخلاص الذكاء الاصطناعي
export interface AiSearchBlueprint {
    city: string; 
    guestCount: number; // 🆕 عدد الأشخاص
    originalBudget: number;
    eventCategory: string;
    eventDate: string; // 🆕 تاريخ الحفلة
    startTime?: string; // 🆕 وقت البداية (اختياري)
    endTime?: string; // 🆕 وقت النهاية (اختياري)
    packages: PackageBlueprint[]; // مصفوفة بثلاثة مخططات
}

// 🆕 واجهة الرد النهائي (الباكج المُجمّع) الذي سيعود للمستخدم
export interface AggregatedPackage {
    packageName: string;
    description: string;
    targetPrice: number;
    finalPrice: number; // السعر النهائي بعد تجميع الخدمات
    city: string;
    guestCount: number;
    eventDate: string; // 🆕 تاريخ الحفلة
    startTime?: string; // 🆕 وقت البداية
    endTime?: string; // 🆕 وقت النهاية
    services: Service[]; // مصفوفة الخدمات التي تم العثور عليها وتجميعها
}

// واجهة الفلاتر للبحث عن الخدمات
export interface AiSearchFilters {
    city?: string; 
    category?: string; 
    priceRange?: {
        min: number;
        max: number;
    };
    aiTags?: string[];
    guestCount?: number; // 🆕 لحساب السعر للخدمات per person
    eventDate?: string; // 🆕 للتحقق من التوفر
    startTime?: string; // 🆕 وقت البداية
    endTime?: string; // 🆕 وقت النهاية
    eventType?: string; // 🆕 NEW: For bestFor matching
}