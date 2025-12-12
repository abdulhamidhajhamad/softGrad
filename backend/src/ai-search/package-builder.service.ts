// src/ai-search/package-builder.service.ts

import { Injectable, Logger } from '@nestjs/common';
import { ServiceService } from '../service/service.service';
import { AiSearchBlueprint, AggregatedPackage, PackageBlueprint } from './ai-search.interface';
import { Service } from '../service/service.schema';

@Injectable()
export class PackageBuilderService {
    private readonly logger = new Logger(PackageBuilderService.name);

    constructor(private readonly serviceService: ServiceService) {}

    
    /**
     * 🏗️ يقوم بتجميع الخدمات من قاعدة البيانات بناءً على مخططات الذكاء الاصطناعي.
     * @param blueprint مخططات الباكجات المستخلصة من AI
     * @returns مصفوفة من الباكجات المجمّعة (AggregatedPackage)
     */
    /*
    async buildPackages(blueprint: AiSearchBlueprint): Promise<AggregatedPackage[]> {
        const aggregatedPackages: AggregatedPackage[] = [];

        // معالجة كل مخطط باكج على حدة
        for (const pkgBlueprint of blueprint.packages) {
            const aggregated: AggregatedPackage = {
                ...pkgBlueprint, // نسخ الاسم والسعر المستهدف والوصف
                city: blueprint.city,
                finalPrice: 0,
                services: [],
            };
            
            // 💡 فرز الخدمات المطلوبة حسب الأولوية (Priority 1 أولاً)
            const requiredServices = pkgBlueprint.requiredServices.sort((a, b) => a.priority - b.priority);

            let totalServiceCost = 0;
            let success = true;

            // البحث عن أفضل خدمة مطابقة لكل تصنيف
            for (const requiredService of requiredServices) {
                
                // 1. تحديد فلترة السعر التقريبية بناءً على وزن الميزانية
                const maxBudgetForService = pkgBlueprint.targetPrice * requiredService.budgetWeight;
                const priceRange = { 
                    min: 0, 
                    max: maxBudgetForService * 1.2 // سماحية 20% فوق الوزن التقديري
                };
                
                // 2. تجميع فلاتر البحث لخدمة واحدة
                const filters = {
                    city: blueprint.city,
                    category: requiredService.categoryName,
                    priceRange: priceRange,
                    aiTags: requiredService.aiTags,
                };

                try {
                    // 3. البحث في قاعدة البيانات: نبحث عن خدمة واحدة فقط (الأفضل تقييمًا أو الأقرب للميزانية)
                    // ملاحظة: دالة searchServices الحالية في ServiceService ترجع مصفوفة.
                    // سنفترض أننا نأخذ الخدمة الأولى أو يجب تعديل ServiceService للحصول على "الأفضل"
                    const matchingServices = await this.serviceService.searchServices(filters);
                    
                    if (matchingServices.length > 0) {
                        // 4. اختيار الخدمة الأفضل (هنا نختار أول خدمة، يفضل اختيار الأعلى تقييماً)
                        const bestService = matchingServices[0]; 
                        aggregated.services.push(bestService);
                        totalServiceCost += bestService.price;
                    } else {
                        // إذا لم يتم العثور على خدمة أساسية (مثل القاعة)، قد نفشل الباكج
                        this.logger.warn(`No service found for ${requiredService.categoryName} in package ${pkgBlueprint.packageName}`);
                        // 🛑 يمكنك اختيار إذا كنت تريد تمرير الباكج جزئياً أو فشله بالكامل
                        // لنفترض أننا نستمر، لكن الخدمة لن تُضاف
                    }
                } catch (error) {
                    this.logger.error(`Error searching for ${requiredService.categoryName}: ${error.message}`);
                }
            } // نهاية حلقة requiredServices

            aggregated.finalPrice = totalServiceCost;

            // 5. إضافة الباكج المُجمّع إلى القائمة النهائية
            aggregatedPackages.push(aggregated);
        } // نهاية حلقة packages

        return aggregatedPackages;
    }
    */
}