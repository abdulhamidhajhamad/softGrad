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
        const requestedDate = new Date(eventDate);
        const availableServices: Service[] = [];

        for (const service of services) {
            if (service.additionalInfo?.capacity) {
                const capacity = service.additionalInfo.capacity;
                if (guestCount && guestCount > capacity) {
                    this.logger.log(
                        `Service ${service.serviceName} rejected: ` +
                        `capacity ${capacity} < required ${guestCount}`
                    );
                    continue;
                }
            }

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

    private async checkServiceAvailability(
        serviceId: string,
        requestedDate: Date,
        startTime?: string,
        endTime?: string
    ): Promise<boolean> {
        const dayStart = new Date(requestedDate);
        dayStart.setUTCHours(0, 0, 0, 0);
        
        const dayEnd = new Date(requestedDate);
        dayEnd.setUTCHours(23, 59, 59, 999);

        const existingBookings = await this.bookingModel.find({
            serviceId: new Types.ObjectId(serviceId),
            status: { $in: [BookingStatus.CONFIRMED, BookingStatus.PENDING] },
            'bookingDetails.date': {
                $gte: dayStart,
                $lte: dayEnd
            }
        }).exec();

        if (existingBookings.length === 0) {
            return true;
        }

        if (!startTime || !endTime) {
            return false;
        }

        const requestedStartHour = this.parseTimeToHour(startTime);
        const requestedEndHour = this.parseTimeToHour(endTime);

        for (const booking of existingBookings) {
            const bookedStartHour = booking.bookingDetails.startHour;
            const bookedEndHour = booking.bookingDetails.endHour;

            if (bookedStartHour === undefined || bookedEndHour === undefined) {
                return false;
            }

            const hasOverlap = 
                requestedStartHour < bookedEndHour && 
                requestedEndHour > bookedStartHour;

            if (hasOverlap) {
                return false;
            }
        }

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

            // ✅ FIX: استخدام averageRating بدلاً من rating
            const rating = (service as any).averageRating || 0;
            score += rating * 30;

            const serviceTags = service.additionalInfo?.aiAnalysis?.tags || [];
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
}