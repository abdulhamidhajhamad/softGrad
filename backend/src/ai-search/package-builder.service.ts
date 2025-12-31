// src/ai-search/package-builder.service.ts

import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { ServiceService } from '../service/service.service';
import { AiSearchBlueprint, AggregatedPackage, PackageBlueprint, AiSearchFilters } from './ai-search.interface';
import { Service } from '../service/service.schema';
import { Booking, BookingStatus } from '../booking/booking.entity';

@Injectable()
export class PackageBuilderService {
    private readonly logger = new Logger(PackageBuilderService.name);

    constructor(
        private readonly serviceService: ServiceService,
        @InjectModel(Booking.name) private bookingModel: Model<Booking>, // ✅ حقن موديل Booking
    ) {}

    /**
     * 🏗️ يقوم بتجميع الخدمات من قاعدة البيانات بناءً على مخططات الذكاء الاصطناعي
     */
    async buildPackages(blueprint: AiSearchBlueprint): Promise<AggregatedPackage[]> {
        const aggregatedPackages: AggregatedPackage[] = [];

        // معالجة كل مخطط باكج على حدة
        for (const pkgBlueprint of blueprint.packages) {
            this.logger.log(`Building package: ${pkgBlueprint.packageName} with target price: ${pkgBlueprint.targetPrice}`);

            const aggregated: AggregatedPackage = {
                ...pkgBlueprint,
                city: blueprint.city,
                guestCount: blueprint.guestCount,
                eventDate: blueprint.eventDate,
                startTime: blueprint.startTime,
                endTime: blueprint.endTime,
                finalPrice: 0,
                services: [],
            };
            
            // 💡 فرز الخدمات المطلوبة حسب الأولوية (Priority 1 أولاً)
            const requiredServices = pkgBlueprint.requiredServices.sort((a, b) => a.priority - b.priority);

            let totalServiceCost = 0;

            // البحث عن أفضل خدمة مطابقة لكل تصنيف
            for (const requiredService of requiredServices) {
                
                // 1. تحديد فلترة السعر التقريبية بناءً على وزن الميزانية
                const maxBudgetForService = pkgBlueprint.targetPrice * requiredService.budgetWeight;
                const priceRange = { 
                    min: 0, 
                    max: maxBudgetForService * 1.3 // سماحية 30% فوق الوزن التقديري
                };
                
                // 2. تجميع فلاتر البحث لخدمة واحدة
                const filters: AiSearchFilters = {
                    city: blueprint.city,
                    category: requiredService.categoryName,
                    priceRange: priceRange,
                    aiTags: requiredService.aiTags,
                    guestCount: blueprint.guestCount,
                    eventDate: blueprint.eventDate,
                    startTime: blueprint.startTime,
                    endTime: blueprint.endTime,
                };

                try {
                    // 3. البحث في قاعدة البيانات
                    const matchingServices = await this.serviceService.searchServices(filters);
                    
                    if (matchingServices.length > 0) {
                        // 4. تصفية الخدمات المتاحة فقط (غير المحجوزة) ✅ من جدول Booking
                        const availableServices = await this.filterAvailableServices(
                            matchingServices,
                            blueprint.eventDate,
                            blueprint.startTime,
                            blueprint.endTime,
                            blueprint.guestCount
                        );

                        if (availableServices.length > 0) {
                            // 5. اختيار الخدمة الأفضل
                            const bestService = this.selectBestService(
                                availableServices, 
                                requiredService.aiTags,
                                maxBudgetForService,
                                blueprint.guestCount
                            );
                            
                            if (bestService) {
                                // 6. حساب السعر النهائي للخدمة (مع مراعاة per person)
                                const servicePrice = this.calculateServicePrice(bestService, blueprint.guestCount);
                                
                                aggregated.services.push(bestService);
                                totalServiceCost += servicePrice;

                                this.logger.log(
                                    `Added ${requiredService.categoryName}: ${bestService.serviceName} ` +
                                    `(Price: ${servicePrice}, Rating: ${bestService.rating})`
                                );
                            }
                        } else {
                            this.logger.warn(
                                `No available service for ${requiredService.categoryName} ` +
                                `on ${blueprint.eventDate} in package ${pkgBlueprint.packageName}`
                            );
                        }
                    } else {
                        this.logger.warn(
                            `No service found for ${requiredService.categoryName} ` +
                            `in package ${pkgBlueprint.packageName}`
                        );
                    }
                } catch (error) {
                    this.logger.error(
                        `Error searching for ${requiredService.categoryName}: ${error.message}`
                    );
                }
            }

            aggregated.finalPrice = totalServiceCost;

            // 6. إضافة الباكج المُجمّع إلى القائمة النهائية
            aggregatedPackages.push(aggregated);
            
            this.logger.log(
                `Package ${pkgBlueprint.packageName} complete. ` +
                `Target: ${pkgBlueprint.targetPrice}, Final: ${totalServiceCost}`
            );
        }

        return aggregatedPackages;
    }

    /**
     * 🔍 تصفية الخدمات المتاحة (غير المحجوزة) في التاريخ المطلوب
     * ✅ التعديل: الفحص من جدول Booking بدلاً من service.bookedDates
     */
    private async filterAvailableServices(
        services: Service[],
        eventDate: string,
        startTime?: string,
        endTime?: string,
        guestCount?: number
    ): Promise<Service[]> {
        const requestedDate = new Date(eventDate);
        const availableServices: Service[] = [];

        for (const service of services) {
            // 1️⃣ التحقق من السعة (capacity) - إذا كانت موجودة
            if (service.additionalInfo?.capacity) {
                const capacity = service.additionalInfo.capacity;
                if (guestCount && guestCount > capacity) {
                    this.logger.log(
                        `Service ${service.serviceName} rejected: ` +
                        `capacity ${capacity} < required ${guestCount}`
                    );
                    continue; // تخطي هذه الخدمة
                }
            }

            // 2️⃣ ✅ الفحص من جدول Booking
            const serviceId = (service as any)._id?.toString() || service._id;
            const isAvailable = await this.checkServiceAvailability(
                serviceId,
                requestedDate,
                startTime,
                endTime
            );

            if (isAvailable) {
                availableServices.push(service);
            } else {
                this.logger.log(
                    `Service ${service.serviceName} rejected: ` +
                    `already booked on ${eventDate}` +
                    (startTime && endTime ? ` from ${startTime} to ${endTime}` : '')
                );
            }
        }

        return availableServices;
    }

    /**
     * 🆕 التحقق من توفر الخدمة في التاريخ والوقت المطلوب
     * @param serviceId معرف الخدمة
     * @param requestedDate التاريخ المطلوب
     * @param startTime وقت البداية (اختياري)
     * @param endTime وقت النهاية (اختياري)
     * @returns true إذا كانت الخدمة متاحة، false إذا كانت محجوزة
     */
    private async checkServiceAvailability(
        serviceId: string,
        requestedDate: Date,
        startTime?: string,
        endTime?: string
    ): Promise<boolean> {
        // 📅 تحديد بداية ونهاية اليوم المطلوب (UTC)
        const dayStart = new Date(requestedDate);
        dayStart.setUTCHours(0, 0, 0, 0);
        
        const dayEnd = new Date(requestedDate);
        dayEnd.setUTCHours(23, 59, 59, 999);

        // 🔍 البحث عن حجوزات نشطة (CONFIRMED أو PENDING) في نفس التاريخ
        const existingBookings = await this.bookingModel.find({
            serviceId: new Types.ObjectId(serviceId),
            status: { $in: [BookingStatus.CONFIRMED, BookingStatus.PENDING] },
            'bookingDetails.date': {
                $gte: dayStart,
                $lte: dayEnd
            }
        }).exec();

        // إذا لم توجد حجوزات في هذا التاريخ، الخدمة متاحة ✅
        if (existingBookings.length === 0) {
            return true;
        }

        // 🕐 إذا لم يتم تحديد الأوقات من المستخدم
        // نفترض أن اليوم كله محجوز إذا وُجدت أي حجوزات
        if (!startTime || !endTime) {
            return false; // اليوم محجوز بالكامل
        }

        // 🕐 إذا تم تحديد الأوقات، نفحص تداخل الأوقات
        const requestedStartHour = this.parseTimeToHour(startTime);
        const requestedEndHour = this.parseTimeToHour(endTime);

        // التحقق من عدم تداخل الأوقات مع الحجوزات الموجودة
        for (const booking of existingBookings) {
            const bookedStartHour = booking.bookingDetails.startHour;
            const bookedEndHour = booking.bookingDetails.endHour;

            // إذا لم يتم تحديد أوقات في الحجز الموجود، نعتبر اليوم كله محجوز
            if (bookedStartHour === undefined || bookedEndHour === undefined) {
                return false;
            }

            // فحص التداخل في الأوقات
            // التداخل يحدث إذا: (البداية المطلوبة < النهاية المحجوزة) && (النهاية المطلوبة > البداية المحجوزة)
            const hasOverlap = 
                requestedStartHour < bookedEndHour && 
                requestedEndHour > bookedStartHour;

            if (hasOverlap) {
                return false; // يوجد تداخل في الأوقات ❌
            }
        }

        // لا يوجد تداخل، الخدمة متاحة ✅
        return true;
    }

    /**
     * 🕐 تحويل الوقت من صيغة نصية (مثل "14:00" أو "2:00 PM") إلى رقم (ساعة)
     */
    private parseTimeToHour(time: string): number {
        // إزالة المسافات
        time = time.trim();

        // التعامل مع صيغة 24 ساعة (مثل "14:00")
        if (time.includes(':')) {
            const [hours] = time.split(':');
            return parseInt(hours, 10);
        }

        // التعامل مع صيغة 12 ساعة (مثل "2:00 PM")
        const isPM = time.toLowerCase().includes('pm');
        const isAM = time.toLowerCase().includes('am');
        
        const numericPart = time.replace(/[^\d]/g, '');
        let hours = parseInt(numericPart, 10);

        if (isPM && hours < 12) {
            hours += 12;
        } else if (isAM && hours === 12) {
            hours = 0;
        }

        return hours;
    }

    /**
     * 🎯 اختيار أفضل خدمة من النتائج بناءً على:
     * - التطابق مع الـ AI Tags
     * - التقييم (Rating)
     * - القرب من الميزانية المحددة
     */
    private selectBestService(
        services: Service[], 
        targetTags: string[],
        maxBudget: number,
        guestCount: number
    ): Service | null {
        if (services.length === 0) return null;

        // حساب نقاط لكل خدمة
        const scoredServices = services.map(service => {
            let score = 0;

            // 1. نقاط التقييم (Rating) - الأهم
            score += (service.rating || 0) * 30;

            // 2. نقاط التطابق مع AI Tags
            const serviceTags = service.additionalInfo?.aiAnalysis?.tags || [];
            const tagMatches = targetTags.filter(tag => 
                serviceTags.some((sTag: string) => 
                    sTag.toLowerCase().includes(tag.toLowerCase()) ||
                    tag.toLowerCase().includes(sTag.toLowerCase())
                )
            ).length;
            score += tagMatches * 20;

            // 3. نقاط القرب من الميزانية (الأقرب أفضل)
            const servicePrice = this.calculateServicePrice(service, guestCount);
            const budgetDiff = Math.abs(maxBudget - servicePrice);
            const budgetScore = Math.max(0, 50 - (budgetDiff / maxBudget) * 50);
            score += budgetScore;

            return { service, score };
        });

        // ترتيب حسب النقاط واختيار الأفضل
        scoredServices.sort((a, b) => b.score - a.score);
        
        return scoredServices[0].service;
    }

    /**
     * 💰 حساب السعر النهائي للخدمة مع مراعاة per person
     */
    private calculateServicePrice(service: Service, guestCount: number): number {
        // إذا كان السعر من نوع PricingOptions
        if (typeof service.price === 'object' && service.price !== null) {
            const pricing = service.price as any;
            
            // إذا كان per person
            if (pricing.perPerson) {
                return pricing.perPerson * guestCount;
            }
            
            // إذا كان per event
            if (pricing.perEvent) {
                return pricing.perEvent;
            }
            
            // إذا كان per hour (نفترض 4 ساعات كمتوسط)
            if (pricing.perHour) {
                return pricing.perHour * 4;
            }
            
            // إذا كان per day
            if (pricing.perDay) {
                return pricing.perDay;
            }
        }
        
        // إذا كان السعر رقم بسيط (fallback)
        if (typeof service.price === 'number') {
            // نتحقق من payType لمعرفة كيف نحسب
            if (service.payType === 'per person') {
                return service.price * guestCount;
            }
            return service.price;
        }

        return 0;
    }
}