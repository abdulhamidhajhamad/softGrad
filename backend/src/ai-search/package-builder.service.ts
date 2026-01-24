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

    /**
     * ✅ NEW: Calculate hours between start and end time
     * حساب عدد الساعات بين وقت البداية والنهاية
     */
    private calculateHours(startTime?: string, endTime?: string): number {
        if (!startTime || !endTime) {
            return 1; // Default to 1 hour if times not provided
        }
        
        try {
            const [startHour, startMin] = startTime.split(':').map(Number);
            const [endHour, endMin] = endTime.split(':').map(Number);
            
            const startMinutes = startHour * 60 + (startMin || 0);
            const endMinutes = endHour * 60 + (endMin || 0);
            
            const diffMinutes = endMinutes - startMinutes;
            const hours = Math.ceil(diffMinutes / 60);
            
            return hours > 0 ? hours : 1; // Minimum 1 hour
        } catch (error) {
            this.logger.warn(`Error calculating hours: ${error.message}, defaulting to 1`);
            return 1;
        }
    }

    async buildPackages(blueprint: AiSearchBlueprint): Promise<AggregatedPackage[]> {
        const aggregatedPackages: AggregatedPackage[] = [];
        
        // ✅ Calculate actual hours from event times
        const eventHours = this.calculateHours(blueprint.startTime, blueprint.endTime);
        this.logger.log(`📅 Event duration: ${eventHours} hours (${blueprint.startTime} - ${blueprint.endTime})`);
        
        // ✅ NEW: Track used services per category to avoid duplicates across packages
        // Map: category -> Set of service IDs used in previous packages
        const usedServicesPerCategory: Map<string, Set<string>> = new Map();

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
                // ✅ BALANCED: Search within reasonable range but allow flexibility
                const priceRange = { 
                    min: 1,                               // Find all services
                    max: maxBudgetForService * 3          // Allow up to 3x allocated budget for high-cost services
                };
                
                this.logger.log(
                    `Category ${requiredService.categoryName}: Budget allocation ${maxBudgetForService.toFixed(0)}, ` +
                    `Search max: ${priceRange.max.toFixed(0)}`
                );
                
                const filters: AiSearchFilters = {
                    city: blueprint.city,
                    category: requiredService.categoryName,
                    priceRange: priceRange,
                    aiTags: requiredService.aiTags,
                    guestCount: blueprint.guestCount,
                    eventDate: blueprint.eventDate,
                    startTime: blueprint.startTime,
                    endTime: blueprint.endTime,
                    eventType: blueprint.eventCategory, // ✅ NEW: Pass event type for bestFor sorting
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
                            // ✅ NEW: Get services already used in this category for other packages
                            const usedInCategory = usedServicesPerCategory.get(requiredService.categoryName) || new Set();
                            
                            // ✅ NEW: Filter out already used services
                            const unusedServices = availableServices.filter(service => {
                                const serviceId = (service as any)._id?.toString() || (service as any).id;
                                return !usedInCategory.has(serviceId);
                            });

                            this.logger.log(
                                `Category ${requiredService.categoryName}: ${availableServices.length} available, ` +
                                `${unusedServices.length} unused (${usedInCategory.size} already used in other packages)`
                            );

                            // ✅ NEW: Use unused services if available, otherwise fall back to all available
                            const candidateServices = unusedServices.length > 0 ? unusedServices : availableServices;
                            
                            const bestService = this.selectBestService(
                                candidateServices, 
                                requiredService.aiTags,
                                maxBudgetForService,
                                blueprint.guestCount,
                                blueprint.eventCategory,  // ✅ NEW: Pass event type for bestFor matching
                                eventHours  // ✅ FIX: Pass actual event hours for price calculation
                            );
                            
                            if (bestService) {
                                const serviceId = (bestService as any)._id?.toString() || (bestService as any).id;
                                // ✅ FIX: Pass eventHours for accurate price calculation
                                const servicePrice = this.calculateServicePrice(bestService, blueprint.guestCount, eventHours);
                                
                                // ✅ FIX: Create enriched service with calculatedPrice for frontend display
                                const enrichedService = {
                                    ...((bestService as any).toObject ? (bestService as any).toObject() : bestService),
                                    calculatedPrice: servicePrice,
                                    // ✅ Override price with calculated price so frontend displays correct amount
                                    displayPrice: servicePrice,
                                };
                                aggregated.services.push(enrichedService);
                                totalServiceCost += servicePrice;

                                // ✅ NEW: Mark this service as used for this category
                                if (!usedServicesPerCategory.has(requiredService.categoryName)) {
                                    usedServicesPerCategory.set(requiredService.categoryName, new Set());
                                }
                                usedServicesPerCategory.get(requiredService.categoryName)!.add(serviceId);

                                // ✅ FIX: استخدام averageRating بدلاً من rating
                                const rating = (bestService as any).averageRating || 0;
                                this.logger.log(
                                    `Added ${requiredService.categoryName}: ${bestService.serviceName} ` +
                                    `(Calculated Price: ${servicePrice}, Rating: ${rating})`
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
            
            // ✅ BALANCED: Accept packages within reasonable range
            // Allow 30%-200% of target to accommodate different service combinations
            const maxAllowedPrice = pkgBlueprint.targetPrice * 2.0;   // Allow 100% over for high-cost events
            const minAllowedPrice = pkgBlueprint.targetPrice * 0.30;  // At least 30% of target
            
            // ✅ Package must have at least 2 services to be useful
            const minRequiredServices = Math.min(2, pkgBlueprint.requiredServices.length);
            
            if (aggregated.services.length >= minRequiredServices && 
                totalServiceCost <= maxAllowedPrice &&
                totalServiceCost >= minAllowedPrice) {
                aggregatedPackages.push(aggregated);
                this.logger.log(
                    `✅ Package ${pkgBlueprint.packageName} ACCEPTED. ` +
                    `Target: ${pkgBlueprint.targetPrice}, Final: ${totalServiceCost} ` +
                    `(Services: ${aggregated.services.length}/${pkgBlueprint.requiredServices.length}, ` +
                    `Range: ${minAllowedPrice.toFixed(0)}-${maxAllowedPrice.toFixed(0)})`
                );
            } else if (aggregated.services.length < minRequiredServices) {
                this.logger.warn(
                    `❌ Package ${pkgBlueprint.packageName} REJECTED: Only ${aggregated.services.length} services ` +
                    `(need at least ${minRequiredServices})`
                );
            } else {
                this.logger.warn(
                    `❌ Package ${pkgBlueprint.packageName} REJECTED: Price ${totalServiceCost} ` +
                    `outside allowed range ${minAllowedPrice.toFixed(0)}-${maxAllowedPrice.toFixed(0)}`
                );
            }
        }

        // ✅ NEW: Remove packages that have identical services to previous ones
        const uniquePackages = this.removeDuplicatePackages(aggregatedPackages);
        this.logger.log(`Final: ${uniquePackages.length} unique packages out of ${aggregatedPackages.length}`);
        
        return uniquePackages;
    }

    // ✅ NEW: Remove packages with identical service sets
    private removeDuplicatePackages(packages: AggregatedPackage[]): AggregatedPackage[] {
        const seen = new Set<string>();
        const unique: AggregatedPackage[] = [];

        for (const pkg of packages) {
            // Create a unique key from service IDs
            const serviceIds = pkg.services
                .map(s => (s as any)._id?.toString() || (s as any).id)
                .sort()
                .join(',');
            
            if (!seen.has(serviceIds)) {
                seen.add(serviceIds);
                unique.push(pkg);
            } else {
                this.logger.log(`Removing duplicate package: ${pkg.packageName} (same services as another package)`);
            }
        }

        return unique;
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
        guestCount: number,
        eventType?: string,  // 🆕 Pass event type for bestFor matching
        hours: number = 1    // ✅ FIX: Pass hours for price calculation
    ): Service | null {
        if (services.length === 0) return null;
        
        // ✅ NEW: Allow up to 200% of allocated budget for a single service
        // The total package budget will be checked at the end
        const hardMaxBudget = maxBudget * 2.0;

        const scoredServices = services.map(service => {
            let score = 0;
            // ✅ FIX: Pass hours to calculateServicePrice
            const servicePrice = this.calculateServicePrice(service, guestCount, hours);

            // ✅ SOFT BUDGET CHECK: Only reject if way over budget (200%)
            if (servicePrice > hardMaxBudget) {
                this.logger.log(
                    `Service ${service.serviceName} rejected: price ${servicePrice} > hard max ${hardMaxBudget.toFixed(0)} (200% of allocated)`
                );
                return { service, score: -1000, price: servicePrice }; // Very low score to exclude
            }

            // ✅ 1. AI Tags matching (MEDIUM PRIORITY - 30 points max)
            const serviceTags = (service as any).aiAnalysis?.tags || [];
            const tagMatches = targetTags.filter(tag => 
                serviceTags.some((sTag: string) => 
                    sTag.toLowerCase().includes(tag.toLowerCase()) ||
                    tag.toLowerCase().includes(sTag.toLowerCase())
                )
            ).length;
            score += tagMatches * 10; // 10 points per tag match (up to ~30 points)

            // ✅ 2. BestFor matching (HIGH PRIORITY - 35 points max)
            const bestFor = (service as any).aiAnalysis?.bestFor || [];
            if (eventType && bestFor.length > 0) {
                const eventTypeLower = eventType.toLowerCase();
                const bestForMatches = bestFor.filter((bf: string) =>
                    bf.toLowerCase().includes(eventTypeLower) ||
                    eventTypeLower.includes(bf.toLowerCase())
                ).length;
                score += bestForMatches * 35; // Strong bonus for bestFor match
                
                if (bestForMatches > 0) {
                    this.logger.log(
                        `Service ${service.serviceName} bestFor match: ${bestFor.join(', ')} for event ${eventType}`
                    );
                }
            }

            // ✅ 3. Rating score (MEDIUM PRIORITY - 15 points max)
            const rating = (service as any).averageRating || 0;
            score += rating * 3; // 3 * 5 = 15 max points for 5-star rating

            // ✅ 4. Budget proximity score (HIGHEST PRIORITY - 40 points max)
            // Services closest to allocated budget (100%) get highest score
            // Services over budget get progressively lower scores
            const budgetUsage = servicePrice / maxBudget;
            
            if (budgetUsage >= 0.85 && budgetUsage <= 1.15) {
                // 85-115% of budget = OPTIMAL
                score += 40;
                this.logger.log(`Service ${service.serviceName}: OPTIMAL ${(budgetUsage*100).toFixed(0)}% of budget - +40 points`);
            } else if (budgetUsage > 1.15 && budgetUsage <= 1.5) {
                // 115-150% of budget = Slightly over but acceptable
                score += 30;
                this.logger.log(`Service ${service.serviceName}: OVER BUDGET ${(budgetUsage*100).toFixed(0)}% - +30 points`);
            } else if (budgetUsage > 1.5 && budgetUsage <= 2.0) {
                // 150-200% of budget = Over budget but might be only option
                score += 15;
                this.logger.log(`Service ${service.serviceName}: WAY OVER ${(budgetUsage*100).toFixed(0)}% - +15 points`);
            } else if (budgetUsage >= 0.5 && budgetUsage < 0.85) {
                // 50-85% of budget = Under budget
                score += 25;
            } else if (budgetUsage >= 0.3 && budgetUsage < 0.5) {
                // 30-50% of budget = Too cheap
                score += 10;
            } else {
                // <30% = Very cheap, minimal score
                score += 5;
            }

            return { service, score, price: servicePrice };
        });

        // ✅ Filter out services with negative scores (over budget)
        const validServices = scoredServices.filter(s => s.score >= 0);
        
        if (validServices.length === 0) {
            this.logger.warn(`No services within budget ${maxBudget}`);
            return null;
        }

        validServices.sort((a, b) => b.score - a.score);
        
        const selected = validServices[0];
        this.logger.log(
            `Selected ${selected.service.serviceName} with score ${selected.score}, price ${selected.price}`
        );
        
        return selected.service;
    }

    /**
     * ✅ FIX: Calculate service price based on payType and actual hours/guests
     * حساب السعر بناءً على نوع الدفع (بالساعة، بالشخص، باليوم، بالحدث)
     */
    private calculateServicePrice(service: Service, guestCount: number, hours: number = 1): number {
        if (typeof service.price === 'object' && service.price !== null) {
            const pricing = service.price as any;
            
            if (pricing.perPerson) {
                return pricing.perPerson * guestCount;
            }
            
            if (pricing.perEvent) {
                return pricing.perEvent;
            }
            
            if (pricing.perHour) {
                // ✅ FIX: Use actual hours instead of hardcoded 4
                return pricing.perHour * hours;
            }
            
            if (pricing.perDay) {
                return pricing.perDay;
            }
        }
        
        if (typeof service.price === 'number') {
            if (service.payType === 'per person') {
                return service.price * guestCount;
            }
            // ✅ FIX: Handle per hour payType
            if (service.payType === 'per hour') {
                return service.price * hours;
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
        eventType?: string,  // 🆕 NEW: For bestFor matching
    ): Promise<any[]> {
        this.logger.log(`========== SINGLE SERVICE SEARCH ==========`);
        this.logger.log(`Category: ${category}, City: ${city}`);
        this.logger.log(`Guest Count: ${guestCount}`);
        this.logger.log(`Budget: ${budgetMin} - ${budgetMax} (flexibility: ${budgetFlexibility}%)`);
        this.logger.log(`Event Date: ${eventDate}`);
        this.logger.log(`Time: ${startTime} - ${endTime}`);
        this.logger.log(`Event Type: ${eventType}`);

        // ✅ FIX: Calculate actual event hours
        const eventHours = this.calculateHours(startTime, endTime);
        this.logger.log(`📅 Event duration: ${eventHours} hours`);

        // ✅ FIX: Apply budget flexibility only if specified, otherwise STRICT
        const flexibility = budgetFlexibility || 0; // Default to 0 (strict) if not specified
        const adjustedBudgetMin = budgetMin * (1 - flexibility/100);
        const adjustedBudgetMax = budgetMax * (1 + flexibility/100);

        this.logger.log(`Adjusted Budget Range: ${adjustedBudgetMin} - ${adjustedBudgetMax}`);

        // ✅ Search with a wider price range initially (will filter after calculating per-person prices)
        const filters: AiSearchFilters = {
            city: city,
            category: category,
            priceRange: { min: 0, max: adjustedBudgetMax * 2 }, // Wider range to catch per-person services
            aiTags: [],
            guestCount: guestCount,
            eventDate: eventDate,
            startTime: startTime,
            endTime: endTime,
            eventType: eventType, // ✅ NEW: Pass event type for bestFor sorting
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

            // ✅ FIX: Calculate actual price with hours and STRICTLY filter by budget
            const enrichedServices = availableServices.map(service => {
                // ✅ Pass eventHours to calculateServicePrice
                const calculatedPrice = this.calculateServicePrice(service, guestCount, eventHours);
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
                    calculatedPrice: calculatedPrice,
                    averageRating: (service as any).averageRating || 0,
                    reviewCount: (service as any).totalReviews || (service as any).reviewCount || 0,
                    description: service.description,
                    imageUrl: (service as any).images?.[0] || (service as any).imageUrl || (service as any).image,
                    location: service.location,
                    bookingType: service.bookingType,
                    aiAnalysis: (service as any).aiAnalysis,
                    isAvailable: true,
                    additionalInfo: service.additionalInfo,
                    maxCapacity: (service as any).maxCapacity,
                    minBookingHours: (service as any).minBookingHours,
                    maxBookingHours: (service as any).maxBookingHours,
                };
            });

            // ✅ STRICT BUDGET FILTER: Only include services within the adjusted budget range
            const budgetFilteredServices = enrichedServices.filter(service => {
                const withinBudget = service.calculatedPrice >= adjustedBudgetMin && 
                                     service.calculatedPrice <= adjustedBudgetMax;
                if (!withinBudget) {
                    this.logger.log(
                        `Service ${service.serviceName} filtered out: price ${service.calculatedPrice} ` +
                        `not in range ${adjustedBudgetMin}-${adjustedBudgetMax}`
                    );
                }
                return withinBudget;
            });

            this.logger.log(
                `Budget filter: ${enrichedServices.length} services -> ${budgetFilteredServices.length} within budget`
            );

            // ✅ Sort by: 1) bestFor match, 2) aiTags match, 3) rating
            budgetFilteredServices.sort((a, b) => {
                let aScore = 0;
                let bScore = 0;

                // bestFor matching (high priority)
                if (eventType) {
                    const eventTypeLower = eventType.toLowerCase();
                    const aBestFor = a.aiAnalysis?.bestFor || [];
                    const bBestFor = b.aiAnalysis?.bestFor || [];
                    
                    const aBestForMatch = aBestFor.some((bf: string) => 
                        bf.toLowerCase().includes(eventTypeLower) || 
                        eventTypeLower.includes(bf.toLowerCase())
                    );
                    const bBestForMatch = bBestFor.some((bf: string) => 
                        bf.toLowerCase().includes(eventTypeLower) || 
                        eventTypeLower.includes(bf.toLowerCase())
                    );
                    
                    if (aBestForMatch) aScore += 30;
                    if (bBestForMatch) bScore += 30;
                }

                // Rating
                aScore += (a.averageRating || 0) * 5;
                bScore += (b.averageRating || 0) * 5;

                return bScore - aScore;
            });

            this.logger.log(`Found ${budgetFilteredServices.length} available services for ${category} within budget`);
            return budgetFilteredServices;

        } catch (error) {
            this.logger.error(`Error searching for ${category}: ${error.message}`);
            throw error;
        }
    }
}