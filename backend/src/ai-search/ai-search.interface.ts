// src/ai-search/ai-search.interface.ts (تحديث)

import { Service } from '../service/service.schema'; // 💡 سنحتاجها في الرد النهائي

// واجهة الخدمات المطلوبة ضمن الباكج (التي سيحددها AI)
export interface RequiredService {
    categoryName: string; // مثال: "Venue" أو "Photography"
    priority: number; // الأهمية (1 للأعلى، 3 للأدنى)
    budgetWeight: number; // النسبة المئوية التقريبية للميزانية
    aiTags: string[]; // علامات البحث المحددة لهذه الخدمة (مثل: "Grand Hall", "High Quality Food")
}

// واجهة الباكج المخطط له (Blueprint)
export interface PackageBlueprint {
    packageName: string; 
    description: string;
    targetPrice: number; 
    requiredServices: RequiredService[]; // قائمة بالخدمات المطلوبة
}

// الواجهة الرئيسية لنتائج استخلاص الذكاء الاصطناعي
export interface AiSearchBlueprint {
    city: string; 
    originalBudget: number;
    eventCategory: string; 
    packages: PackageBlueprint[]; // مصفوفة بثلاثة مخططات
}

// 🆕 واجهة الرد النهائي (الباكج المُجمّع) الذي سيعود للمستخدم
export interface AggregatedPackage {
    packageName: string;
    description: string;
    targetPrice: number;
    finalPrice: number; // السعر النهائي بعد تجميع الخدمات
    city: string;
    services: Service[]; // مصفوفة الخدمات التي تم العثور عليها وتجميعها
}
export interface AiSearchFilters {
    city?: string; 
    category?: string; 
    priceRange?: {
        min: number;
        max: number;
    };
    aiTags?: string[];
    totalBudget?: number; 
}