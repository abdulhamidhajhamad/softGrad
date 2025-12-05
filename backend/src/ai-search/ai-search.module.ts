// src/ai-search/ai-search.module.ts

import { Module } from '@nestjs/common';
import { AiSearchService } from './ai-search.service';
import { AiSearchController } from './ai-search.controller';
import { ServiceModule } from '../service/service.module'; 
import { PackageBuilderService } from './package-builder.service'; // 🆕 استيراد الخدمة الجديدة

@Module({
  imports: [ServiceModule], 
  controllers: [AiSearchController],
  providers: [AiSearchService, PackageBuilderService], // 🆕 إضافة PackageBuilderService
  exports: [AiSearchService, PackageBuilderService], 
})
export class AiSearchModule {}