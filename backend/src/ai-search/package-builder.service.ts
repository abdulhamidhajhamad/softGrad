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
        @InjectModel(Booking.name) private bookingModel: Model<Booking>,
    ) {}

    async buildPackages(blueprint: AiSearchBlueprint): Promise<AggregatedPackage[]> {
        const aggregatedPackages: AggregatedPackage[] = [];

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
            
            const requiredServices = pkgBlueprint.requiredServices.sort((a, b) => a.priority - b.priority);
            let totalServiceCost = 0;

            for (const requiredService of requiredServices) {
                const maxBudgetForService = pkgBlueprint.targetPrice * requiredService.budgetWeight;
                const priceRange = { 
                    min: 0, 
                    max: maxBudgetForService * 1.3
                };
                
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
                    const matchingServices = await this.serviceService.searchServices(filters);
                    
                    if (matchingServices.length > 0) {
                        const availableServices = await this.filterAvailableServices(
                            matchingServices,
                            blueprint.eventDate,
                            blueprint.startTime,
                            blueprint.endTime,
                            blueprint.guestCount
                        );

                        if (availableServices.length > 0) {
                            const bestService = this.selectBestService(
                                availableServices, 
                                requiredService.aiTags,
                                maxBudgetForService,
                                blueprint.guestCount
                            );
                            
                            if (bestService) {
                                const servicePrice = this.calculateServicePrice(bestService, blueprint.guestCount);
                                aggregated.services.push(bestService);
                                totalServiceCost += servicePrice;

                                // ✅ FIX: استخدام averageRating بدلاً من rating
                                const rating = (bestService as any).averageRating || 0;
                                this.logger.log(
                                    `Added ${requiredService.categoryName}: ${bestService.serviceName} ` +
                                    `(Price: ${servicePrice}, Rating: ${rating})`
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
            aggregatedPackages.push(aggregated);
            
            this.logger.log(
                `Package ${pkgBlueprint.packageName} complete. ` +
                `Target: ${pkgBlueprint.targetPrice}, Final: ${totalServiceCost}`
            );
        }

        return aggregatedPackages;
    }

    private async filterAvailableServices(
        services: Service[],
        eventDate: string,
        startTime?: string,
        endTime?: string,
        guestCount?: number
    ): Promise<Service[]> {
        // Parse the date correctly - remove time component if present
        const dateStr = eventDate.split('T')[0]; // Get just the date part "YYYY-MM-DD"
        const [year, month, day] = dateStr.split('-').map(Number);
        const requestedDate = new Date(year, month - 1, day); // month is 0-indexed
        
        const availableServices: Service[] = [];

        this.logger.log(`Filtering ${services.length} services for date: ${requestedDate.toDateString()}, guests: ${guestCount}`);

        // Parse requested hours for working hours check
        const requestedStartHour = startTime ? this.parseTimeToHour(startTime) : null;
        const requestedEndHour = endTime ? this.parseTimeToHour(endTime) : null;

        for (const service of services) {
            // Check working days - if the service doesn't work on this day of week
            const workingDays = (service as any).workingDays || service.additionalInfo?.workingDays;
            if (workingDays && workingDays.length > 0) {
                const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
                const requestedDayName = dayNames[requestedDate.getDay()];
                
                // Check if requested day is in working days (case-insensitive)
                const isWorkingDay = workingDays.some((day: string) => 
                    day.toLowerCase() === requestedDayName.toLowerCase()
                );
                
                if (!isWorkingDay) {
                    this.logger.log(
                        `Service ${service.serviceName} rejected: ` +
                        `doesn't work on ${requestedDayName} (works: ${workingDays.join(', ')})`
                    );
                    continue;
                }
            }

            // Check available hours - if the service doesn't operate at requested time
            const availableHours = (service as any).availableHours || service.additionalInfo?.availableHours;
            if (availableHours && availableHours.length > 0 && requestedStartHour !== null && requestedEndHour !== null) {
                // availableHours is an array of hours like [9, 10, 11, 12, 13, 14, 15, 16, 17]
                // Check if ALL requested hours are within available hours
                let allHoursAvailable = true;
                for (let hour = requestedStartHour; hour < requestedEndHour; hour++) {
                    if (!availableHours.includes(hour)) {
                        allHoursAvailable = false;
                        this.logger.log(
                            `Service ${service.serviceName} rejected: ` +
                            `hour ${hour}:00 not in available hours (${availableHours.join(', ')})`
                        );
                        break;
                    }
                }
                if (!allHoursAvailable) {
                    continue;
                }
            }

            // Check capacity from multiple possible fields
            const capacity = (service as any).maxCapacity || 
                            service.additionalInfo?.capacity ||
                            service.additionalInfo?.maxCapacity;
            
            if (capacity && guestCount && guestCount > capacity) {
                this.logger.log(
                    `Service ${service.serviceName} rejected: ` +
                    `capacity ${capacity} < required ${guestCount}`
                );
                continue;
            }

            // Check minimum capacity if exists (for venues, catering)
            const minCapacity = service.additionalInfo?.minCapacity || 
                               (service as any).minCapacity;
            if (minCapacity && guestCount && guestCount < minCapacity) {
                this.logger.log(
                    `Service ${service.serviceName} rejected: ` +
                    `minCapacity ${minCapacity} > provided ${guestCount}`
                );
                continue;
            }

            const serviceId = (service as any)._id?.toString() || service._id;
            const bookingType = (service as any).bookingType || service.bookingType;
            
            const isAvailable = await this.checkServiceAvailability(
                serviceId,
                requestedDate,
                startTime,
                endTime,
                bookingType
            );

            if (isAvailable) {
                availableServices.push(service);
                this.logger.log(`Service ${service.serviceName} is AVAILABLE`);
            } else {
                this.logger.log(
                    `Service ${service.serviceName} rejected: ` +
                    `already booked on ${eventDate}` +
                    (startTime && endTime ? ` from ${startTime} to ${endTime}` : '')
                );
            }
        }

        this.logger.log(`${availableServices.length} services available out of ${services.length}`);
        return availableServices;
    }

    private async checkServiceAvailability(
        serviceId: string,
        requestedDate: Date,
        startTime?: string,
        endTime?: string,
        bookingType?: string
    ): Promise<boolean> {
        // Use start of day in local time for comparison
        const dayStart = new Date(requestedDate);
        dayStart.setHours(0, 0, 0, 0);
        
        const dayEnd = new Date(requestedDate);
        dayEnd.setHours(23, 59, 59, 999);

        this.logger.log(`Checking availability for service ${serviceId} on ${requestedDate.toISOString()}`);
        this.logger.log(`Date range: ${dayStart.toISOString()} to ${dayEnd.toISOString()}`);
        this.logger.log(`Booking type: ${bookingType || 'not specified'}`);

        const existingBookings = await this.bookingModel.find({
            serviceId: new Types.ObjectId(serviceId),
            status: { $in: [BookingStatus.CONFIRMED, BookingStatus.PENDING] },
            'bookingDetails.date': {
                $gte: dayStart,
                $lte: dayEnd
            }
        }).exec();

        this.logger.log(`Found ${existingBookings.length} existing bookings for service ${serviceId}`);

        if (existingBookings.length === 0) {
            return true;
        }

        // If service booking type is Daily, any booking on this day means NOT available
        if (bookingType === 'Daily' || bookingType === 'daily') {
            this.logger.log(`Service is Daily booking type and has bookings on this day - NOT AVAILABLE`);
            return false;
        }

        // If no time specified, consider as full day booking - not available
        if (!startTime || !endTime) {
            this.logger.log(`No time range specified, service has bookings on this day - NOT AVAILABLE`);
            return false;
        }

        const requestedStartHour = this.parseTimeToHour(startTime);
        const requestedEndHour = this.parseTimeToHour(endTime);
        this.logger.log(`Requested time: ${requestedStartHour}:00 - ${requestedEndHour}:00`);

        for (const booking of existingBookings) {
            const bookedStartHour = booking.bookingDetails.startHour;
            const bookedEndHour = booking.bookingDetails.endHour;
            
            this.logger.log(`Existing booking: ${bookedStartHour}:00 - ${bookedEndHour}:00`);

            // If existing booking has no time info, assume full day booking
            if (bookedStartHour === undefined || bookedEndHour === undefined) {
                this.logger.log(`Existing booking has no time info - NOT AVAILABLE`);
                return false;
            }

            // Check for time overlap
            const hasOverlap = 
                requestedStartHour < bookedEndHour && 
                requestedEndHour > bookedStartHour;

            if (hasOverlap) {
                this.logger.log(`Time overlap detected - NOT AVAILABLE`);
                return false;
            }
        }

        this.logger.log(`No conflicts found - AVAILABLE`);
        return true;
    }

    private parseTimeToHour(time: string): number {
        time = time.trim();

        if (time.includes(':')) {
            const [hours] = time.split(':');
            return parseInt(hours, 10);
        }

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

    private selectBestService(
        services: Service[], 
        targetTags: string[],
        maxBudget: number,
        guestCount: number
    ): Service | null {
        if (services.length === 0) return null;

        const scoredServices = services.map(service => {
            let score = 0;

            // ✅ استخدام averageRating بدلاً من rating
            const rating = (service as any).averageRating || 0;
            score += rating * 30;

            // ✅ FIX: aiAnalysis موجود على مستوى الـ service مباشرة مش داخل additionalInfo
            const serviceTags = (service as any).aiAnalysis?.tags || [];
            const tagMatches = targetTags.filter(tag => 
                serviceTags.some((sTag: string) => 
                    sTag.toLowerCase().includes(tag.toLowerCase()) ||
                    tag.toLowerCase().includes(sTag.toLowerCase())
                )
            ).length;
            score += tagMatches * 20;

            const servicePrice = this.calculateServicePrice(service, guestCount);
            const budgetDiff = Math.abs(maxBudget - servicePrice);
            const budgetScore = Math.max(0, 50 - (budgetDiff / maxBudget) * 50);
            score += budgetScore;

            return { service, score };
        });

        scoredServices.sort((a, b) => b.score - a.score);
        return scoredServices[0].service;
    }

    private calculateServicePrice(service: Service, guestCount: number): number {
        if (typeof service.price === 'object' && service.price !== null) {
            const pricing = service.price as any;
            
            if (pricing.perPerson) {
                return pricing.perPerson * guestCount;
            }
            
            if (pricing.perEvent) {
                return pricing.perEvent;
            }
            
            if (pricing.perHour) {
                return pricing.perHour * 4;
            }
            
            if (pricing.perDay) {
                return pricing.perDay;
            }
        }
        
        if (typeof service.price === 'number') {
            if (service.payType === 'per person') {
                return service.price * guestCount;
            }
            return service.price;
        }

        return 0;
    }

    /**
     * 🆕 NEW: Search for a single service type
     * البحث عن نوع واحد من الخدمات
     */
    async searchSingleServiceType(
        category: string,
        city: string,
        guestCount: number,
        budgetMin: number,
        budgetMax: number,
        eventDate: string,
        startTime?: string,
        endTime?: string,
        budgetFlexibility?: number,
    ): Promise<any[]> {
        this.logger.log(`========== SINGLE SERVICE SEARCH ==========`);
        this.logger.log(`Category: ${category}, City: ${city}`);
        this.logger.log(`Guest Count: ${guestCount}`);
        this.logger.log(`Budget: ${budgetMin} - ${budgetMax} (flexibility: ${budgetFlexibility}%)`);
        this.logger.log(`Event Date: ${eventDate}`);
        this.logger.log(`Time: ${startTime} - ${endTime}`);

        // Apply budget flexibility
        const flexibility = budgetFlexibility || 5;
        const adjustedBudgetMin = budgetMin * (1 - flexibility/100);
        const adjustedBudgetMax = budgetMax * (1 + flexibility/100);

        const filters: AiSearchFilters = {
            city: city,
            category: category,
            priceRange: { min: adjustedBudgetMin, max: adjustedBudgetMax },
            aiTags: [], // No specific tags for single search
            guestCount: guestCount,
            eventDate: eventDate,
            startTime: startTime,
            endTime: endTime,
        };

        try {
            const matchingServices = await this.serviceService.searchServices(filters);
            
            if (matchingServices.length === 0) {
                this.logger.warn(`No services found for ${category} in ${city}`);
                return [];
            }

            // Filter by availability
            const availableServices = await this.filterAvailableServices(
                matchingServices,
                eventDate,
                startTime,
                endTime,
                guestCount
            );

            if (availableServices.length === 0) {
                this.logger.warn(`No available services for ${category} on ${eventDate}`);
                return [];
            }

            // Sort by rating and return enriched data
            const enrichedServices = availableServices.map(service => {
                const price = this.calculateServicePrice(service, guestCount);
                // Get the correct provider/company name
                const providerName = (service as any).companyName || 
                                     (service as any).providerName || 
                                     'Provider';
                return {
                    _id: (service as any)._id?.toString() || service._id,
                    serviceName: service.serviceName,
                    category: service.category,
                    providerName: providerName,
                    providerId: (service as any).providerId?.toString(),
                    price: service.price,
                    payType: service.payType,
                    calculatedPrice: price,
                    averageRating: (service as any).averageRating || 0,
                    reviewCount: (service as any).totalReviews || (service as any).reviewCount || 0,
                    description: service.description,
                    imageUrl: (service as any).images?.[0] || (service as any).imageUrl || (service as any).image,
                    location: service.location,
                    bookingType: service.bookingType,
                    aiAnalysis: (service as any).aiAnalysis,
                    isAvailable: true,
                    // Additional info for booking
                    additionalInfo: service.additionalInfo,
                    maxCapacity: (service as any).maxCapacity,
                    minBookingHours: (service as any).minBookingHours,
                    maxBookingHours: (service as any).maxBookingHours,
                };
            });

            // Sort by rating (highest first)
            enrichedServices.sort((a, b) => b.averageRating - a.averageRating);

            this.logger.log(`Found ${enrichedServices.length} available services for ${category}`);
            return enrichedServices;

        } catch (error) {
            this.logger.error(`Error searching for ${category}: ${error.message}`);
            throw error;
        }
    }
}