// src/ai-search/ai-search.controller.ts

import { Controller, Post, Body, HttpCode, HttpStatus, HttpException } from '@nestjs/common';
import { AiSearchService } from './ai-search.service';
import { AiSearchDto, SingleServiceSearchDto } from './ai-search.dto';
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
            dto.endTime,
            dto.servicePriorities, // 🆕 تمرير أولويات الخدمات مع النسب
            dto.budgetFlexibility, // 🆕 تمرير نسبة المرونة
        );
        
        // 2. استخدام المخطط لتجميع الخدمات (هذا الجزء يبقى كما هو لا يتغير)
        const aggregatedPackages = await this.packageBuilderService.buildPackages(blueprint);

        if (!aggregatedPackages || aggregatedPackages.length === 0) {
            throw new HttpException(
                "We're sorry, there are no services matching your specific criteria at the moment.",
                HttpStatus.NOT_FOUND
            );
        }

        return aggregatedPackages;
    }

    /**
     * 🆕 NEW: Single Service Search Endpoint
     * البحث عن خدمة واحدة فقط بناءً على الفلاتر
     */
    @Post('single-service')
    @HttpCode(HttpStatus.OK)
    async searchSingleService(@Body() dto: SingleServiceSearchDto) {
        const services = await this.packageBuilderService.searchSingleServiceType(
            dto.category,
            dto.city,
            dto.guestCount,
            dto.budgetMin,
            dto.budgetMax,
            dto.eventDate,
            dto.startTime,
            dto.endTime,
            dto.budgetFlexibility,
            dto.eventType,  // ✅ NEW: Pass event type for bestFor matching
        );

        if (!services || services.length === 0) {
            throw new HttpException(
                "We're sorry, there are no services matching your specific criteria at the moment.",
                HttpStatus.NOT_FOUND
            );
        }

        return { 
            success: true,
            category: dto.category,
            city: dto.city,
            services: services,
            count: services.length,
        };
    }
}