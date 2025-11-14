"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ServiceService = void 0;
const common_1 = require("@nestjs/common");
const mongoose_1 = require("@nestjs/mongoose");
const mongoose_2 = require("mongoose");
const service_schema_1 = require("./service.schema");
let ServiceService = class ServiceService {
    serviceModel;
    constructor(serviceModel) {
        this.serviceModel = serviceModel;
    }
    async createService(providerId, createServiceDto) {
        try {
            console.log('📦 Received createServiceDto:', JSON.stringify(createServiceDto, null, 2));
            console.log('👤 Provider ID:', providerId);
            const existingService = await this.serviceModel.findOne({
                serviceName: createServiceDto.serviceName,
                providerId
            });
            if (existingService) {
                console.log('❌ Service already exists:', createServiceDto.serviceName);
                throw new common_1.HttpException('Service with this name already exists', common_1.HttpStatus.CONFLICT);
            }
            let companyName = createServiceDto.companyName;
            if (!companyName) {
                companyName = `Vendor-${providerId.substring(0, 8)}`;
                console.log('🏢 Using default company name:', companyName);
            }
            console.log('🏢 Final company name:', companyName);
            const newServiceData = {
                providerId,
                companyName,
                ...createServiceDto,
                reviews: []
            };
            console.log('🔄 Creating service with data:', JSON.stringify(newServiceData, null, 2));
            const newService = new this.serviceModel(newServiceData);
            const savedService = await newService.save();
            console.log('✅ Service created successfully:', savedService._id);
            return savedService;
        }
        catch (error) {
            console.error('💥 ERROR in createService:', error);
            if (error instanceof common_1.HttpException) {
                throw error;
            }
            if (error.name === 'ValidationError') {
                console.log('MongoDB Validation Error:', error.errors);
                throw new common_1.HttpException(`Validation error: ${Object.values(error.errors).map((e) => e.message).join(', ')}`, common_1.HttpStatus.BAD_REQUEST);
            }
            if (error.code === 11000) {
                throw new common_1.HttpException('Service with this name already exists', common_1.HttpStatus.CONFLICT);
            }
            throw new common_1.HttpException(error.message || 'Failed to create service', common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    async deleteServiceByName(serviceName, providerId) {
        try {
            const service = await this.serviceModel.findOne({ serviceName, providerId });
            if (!service) {
                throw new common_1.HttpException('Service not found or you do not have permission to delete it', common_1.HttpStatus.NOT_FOUND);
            }
            await this.serviceModel.deleteOne({ serviceName, providerId });
            return { message: `Service '${serviceName}' deleted successfully` };
        }
        catch (error) {
            throw new common_1.HttpException(error.message || 'Failed to delete service', error.status || common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    async getAllServices() {
        try {
            return await this.serviceModel.find().exec();
        }
        catch (error) {
            throw new common_1.HttpException('Failed to fetch services', common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    async updateServiceByName(serviceName, providerId, updateServiceDto) {
        try {
            const service = await this.serviceModel.findOne({ serviceName, providerId });
            if (!service) {
                throw new common_1.HttpException('Service not found or you do not have permission to update it', common_1.HttpStatus.NOT_FOUND);
            }
            const updatedService = await this.serviceModel.findOneAndUpdate({ serviceName, providerId }, { $set: updateServiceDto }, { new: true, runValidators: true }).exec();
            if (!updatedService) {
                throw new common_1.HttpException('Failed to update service', common_1.HttpStatus.INTERNAL_SERVER_ERROR);
            }
            return updatedService;
        }
        catch (error) {
            throw new common_1.HttpException(error.message || 'Failed to update service', error.status || common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    async getServicesByVendorName(companyName) {
        try {
            const services = await this.serviceModel.find({ companyName }).exec();
            if (!services || services.length === 0) {
                throw new common_1.HttpException(`No services found for vendor '${companyName}'`, common_1.HttpStatus.NOT_FOUND);
            }
            return services;
        }
        catch (error) {
            throw new common_1.HttpException(error.message || 'Failed to fetch vendor services', error.status || common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    async getServicesByVendorId(vendorId) {
        try {
            const services = await this.serviceModel.find({ providerId: vendorId }).exec();
            if (!services || services.length === 0) {
                throw new common_1.HttpException(`No services found for vendor ID '${vendorId}'`, common_1.HttpStatus.NOT_FOUND);
            }
            return services;
        }
        catch (error) {
            throw new common_1.HttpException(error.message || 'Failed to fetch vendor services', error.status || common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    async getServiceById(serviceId) {
        try {
            const service = await this.serviceModel.findById(serviceId).exec();
            if (!service) {
                throw new common_1.HttpException('Service not found', common_1.HttpStatus.NOT_FOUND);
            }
            return service;
        }
        catch (error) {
            throw new common_1.HttpException(error.message || 'Failed to fetch service', error.status || common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    async searchServicesByLocation(latitude, longitude, radiusInKm = 50) {
        try {
            const latDelta = radiusInKm / 111;
            const lonDelta = radiusInKm / (111 * Math.cos(latitude * Math.PI / 180));
            const services = await this.serviceModel.find({
                'location.latitude': {
                    $gte: latitude - latDelta,
                    $lte: latitude + latDelta
                },
                'location.longitude': {
                    $gte: longitude - lonDelta,
                    $lte: longitude + lonDelta
                }
            }).exec();
            return services.filter(service => {
                const distance = this.calculateDistance(latitude, longitude, service.location.latitude, service.location.longitude);
                return distance <= radiusInKm;
            });
        }
        catch (error) {
            throw new common_1.HttpException('Failed to search services by location', common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    async searchServicesByName(serviceName) {
        try {
            const services = await this.serviceModel.find({
                serviceName: { $regex: serviceName, $options: 'i' }
            }).exec();
            if (!services || services.length === 0) {
                throw new common_1.HttpException(`No services found with name '${serviceName}'`, common_1.HttpStatus.NOT_FOUND);
            }
            return services;
        }
        catch (error) {
            throw new common_1.HttpException(error.message || 'Failed to search services', error.status || common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    async getServicesByCategory(category) {
        try {
            const services = await this.serviceModel.find({
                'additionalInfo.category': { $regex: category, $options: 'i' }
            }).exec();
            if (!services || services.length === 0) {
                throw new common_1.HttpException(`No services found in category '${category}'`, common_1.HttpStatus.NOT_FOUND);
            }
            return services;
        }
        catch (error) {
            throw new common_1.HttpException(error.message || 'Failed to fetch services by category', error.status || common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    calculateDistance(lat1, lon1, lat2, lon2) {
        const R = 6371;
        const dLat = (lat2 - lat1) * Math.PI / 180;
        const dLon = (lon2 - lon1) * Math.PI / 180;
        const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
                Math.sin(dLon / 2) * Math.sin(dLon / 2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }
};
exports.ServiceService = ServiceService;
exports.ServiceService = ServiceService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, mongoose_1.InjectModel)(service_schema_1.Service.name)),
    __metadata("design:paramtypes", [mongoose_2.Model])
], ServiceService);
//# sourceMappingURL=service.service.js.map