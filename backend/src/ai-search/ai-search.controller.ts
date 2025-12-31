// src/ai-search/ai-search.controller.ts

import { Controller, Post, Body, HttpCode, HttpStatus, HttpException } from '@nestjs/common';
import { AiSearchService } from './ai-search.service';
import { AiSearchDto } from './ai-search.dto';
import { AggregatedPackage, AiSearchBlueprint } from './ai-search.interface'; 
import { PackageBuilderService } from './package-builder.service'; 

@Controller('ai-search')
export class AiSearchController {
    constructor(
        private readonly aiSearchService: AiSearchService,
        private readonly packageBuilderService: PackageBuilderService,
    ) {}

    @Post()
    @HttpCode(HttpStatus.OK) 
    async aiPackageSearch(@Body() dto: AiSearchDto): Promise<AggregatedPackage[]> {
        
        // 1. استخلاص مخططات الباكجات من الـ AI (تم إضافة userTags و additionalNotes)
        const blueprint: AiSearchBlueprint = await this.aiSearchService.extractSearchFilters(
            dto.city,
            dto.guestCount,
            dto.budgetMin,
            dto.budgetMax,
            dto.eventType,
            dto.eventDate,
            dto.userTags,       // 🆕 تمرير التاجز
            dto.additionalNotes, // 🆕 تمرير الملاحظات
            dto.startTime,
            dto.endTime
        );
        
        // 2. استخدام المخطط لتجميع الخدمات (هذا الجزء يبقى كما هو لا يتغير)
        const aggregatedPackages = await this.packageBuilderService.buildPackages(blueprint);

        if (!aggregatedPackages || aggregatedPackages.length === 0) {
            throw new HttpException(
                'Could not build any packages matching your criteria.',
                HttpStatus.NOT_FOUND
            );
        }

        return aggregatedPackages;
    }
}