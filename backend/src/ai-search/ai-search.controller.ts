// src/ai-search/ai-search.controller.ts (الإصلاح)

import { Controller, Post, Body, HttpCode, HttpStatus, HttpException } from '@nestjs/common';
import { AiSearchService } from './ai-search.service';
import { AiSearchDto } from './ai-search.dto';
// 🛑 يجب استيراد الواجهة الجديدة AiSearchBlueprint هنا
import { AggregatedPackage, AiSearchBlueprint } from './ai-search.interface'; 
import { PackageBuilderService } from './package-builder.service'; 

@Controller('ai-search')
export class AiSearchController {
    constructor(
        private readonly aiSearchService: AiSearchService,
        private readonly packageBuilderService: PackageBuilderService,
    ) {}

    /**
     * POST /ai-search
     */
    @Post()
    @HttpCode(HttpStatus.OK) 
    async aiPackageSearch(@Body() dto: AiSearchDto): Promise<AggregatedPackage[]> {
        
        // 1. استخلاص مخططات الباكجات من نص المستخدم باستخدام AI
        // 🛑 تم إضافة التصريح الصريح لنوع المتغير AiSearchBlueprint
        const blueprint: AiSearchBlueprint = await this.aiSearchService.extractSearchFilters(dto.prompt);
        
        // 2. استخدام المخطط لتجميع الخدمات من قاعدة البيانات
        // الآن المتغير blueprint من النوع الصحيح، فلن يظهر الخطأ هنا
     const aggregatedPackages = await this.packageBuilderService.buildPackages(blueprint);

    // 3. التحقق من النتائج قبل الإرجاع
        if (!aggregatedPackages || aggregatedPackages.length === 0) {
            throw new HttpException(
                'Could not build any packages matching your criteria.',
                HttpStatus.NOT_FOUND
            );
        }

        return aggregatedPackages;
    }
}