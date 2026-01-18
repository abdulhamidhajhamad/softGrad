// src/ai-search/ai-search.module.ts

import { Module } from '@nestjs/common';
import { AiSearchService } from './ai-search.service';
import { AiSearchController } from './ai-search.controller';
import { ServiceModule } from '../service/service.module'; 
import { PackageBuilderService } from './package-builder.service'; // 🆕 استيراد الخدمة الجديدة
import { MongooseModule } from '@nestjs/mongoose';
import { Booking, BookingSchema } from 'src/booking/booking.entity';

@Module({
  imports: [ServiceModule,
  MongooseModule.forFeature([
    { name: Booking.name, schema: BookingSchema }, // ✅ أضفنا Booking هنا
  ]),], 
  controllers: [AiSearchController],
  providers: [AiSearchService, PackageBuilderService], // 🆕 إضافة PackageBuilderService
  exports: [AiSearchService, PackageBuilderService], 
})
export class AiSearchModule {}