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
exports.ServiceController = void 0;
const common_1 = require("@nestjs/common");
const service_service_1 = require("./service.service");
const service_dto_1 = require("./service.dto");
const jwt_auth_guard_1 = require("../auth/jwt-auth.guard");
let ServiceController = class ServiceController {
    serviceService;
    constructor(serviceService) {
        this.serviceService = serviceService;
    }
    async addService(createServiceDto, req) {
        try {
            const userId = req.user.userId;
            const userRole = req.user.role;
            if (userRole !== 'vendor') {
                throw new common_1.HttpException('Only vendors can add services', common_1.HttpStatus.FORBIDDEN);
            }
            return await this.serviceService.createService(userId, createServiceDto);
        }
        catch (error) {
            throw new common_1.HttpException(error.message || 'Failed to create service', error.status || common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    async deleteServiceByName(serviceName, req) {
        try {
            const userId = req.user.userId;
            const userRole = req.user.role;
            if (userRole !== 'vendor') {
                throw new common_1.HttpException('Only vendors can delete services', common_1.HttpStatus.FORBIDDEN);
            }
            return await this.serviceService.deleteServiceByName(serviceName, userId);
        }
        catch (error) {
            throw new common_1.HttpException(error.message || 'Failed to delete service', error.status || common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    async updateServiceByName(serviceName, updateServiceDto, req) {
        try {
            const userId = req.user.userId;
            const userRole = req.user.role;
            if (userRole !== 'vendor') {
                throw new common_1.HttpException('Only vendors can update services', common_1.HttpStatus.FORBIDDEN);
            }
            return await this.serviceService.updateServiceByName(serviceName, userId, updateServiceDto);
        }
        catch (error) {
            throw new common_1.HttpException(error.message || 'Failed to update service', error.status || common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    async getAllServices() {
        try {
            return await this.serviceService.getAllServices();
        }
        catch (error) {
            throw new common_1.HttpException(error.message || 'Failed to fetch services', error.status || common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    async getServiceById(id) {
        try {
            return await this.serviceService.getServiceById(id);
        }
        catch (error) {
            throw new common_1.HttpException(error.message || 'Service not found', error.status || common_1.HttpStatus.NOT_FOUND);
        }
    }
    async getServicesByVendor(companyName) {
        try {
            return await this.serviceService.getServicesByVendorName(companyName);
        }
        catch (error) {
            throw new common_1.HttpException(error.message || 'Failed to fetch vendor services', error.status || common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    async getServicesByVendorId(vendorId) {
        try {
            return await this.serviceService.getServicesByVendorId(vendorId);
        }
        catch (error) {
            throw new common_1.HttpException(error.message || 'Failed to fetch vendor services', error.status || common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    async searchServicesByLocation(lat, lng, radius) {
        try {
            const latitude = parseFloat(lat);
            const longitude = parseFloat(lng);
            const radiusInKm = radius ? parseFloat(radius) : 50;
            if (isNaN(latitude) || isNaN(longitude)) {
                throw new common_1.HttpException('Invalid latitude or longitude', common_1.HttpStatus.BAD_REQUEST);
            }
            return await this.serviceService.searchServicesByLocation(latitude, longitude, radiusInKm);
        }
        catch (error) {
            throw new common_1.HttpException(error.message || 'Failed to search services by location', error.status || common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    async searchServicesByName(serviceName) {
        try {
            return await this.serviceService.searchServicesByName(serviceName);
        }
        catch (error) {
            throw new common_1.HttpException(error.message || 'Failed to search services', error.status || common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    async getServicesByCategory(category) {
        try {
            return await this.serviceService.getServicesByCategory(category);
        }
        catch (error) {
            throw new common_1.HttpException(error.message || 'Failed to fetch services by category', error.status || common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
};
exports.ServiceController = ServiceController;
__decorate([
    (0, common_1.Post)(),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [service_dto_1.CreateServiceDto, Object]),
    __metadata("design:returntype", Promise)
], ServiceController.prototype, "addService", null);
__decorate([
    (0, common_1.Delete)('name/:serviceName'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __param(0, (0, common_1.Param)('serviceName')),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], ServiceController.prototype, "deleteServiceByName", null);
__decorate([
    (0, common_1.Put)('name/:serviceName'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __param(0, (0, common_1.Param)('serviceName')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, service_dto_1.UpdateServiceDto, Object]),
    __metadata("design:returntype", Promise)
], ServiceController.prototype, "updateServiceByName", null);
__decorate([
    (0, common_1.Get)(),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], ServiceController.prototype, "getAllServices", null);
__decorate([
    (0, common_1.Get)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ServiceController.prototype, "getServiceById", null);
__decorate([
    (0, common_1.Get)('vendor/:companyName'),
    __param(0, (0, common_1.Param)('companyName')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ServiceController.prototype, "getServicesByVendor", null);
__decorate([
    (0, common_1.Get)('vendor/id/:vendorId'),
    __param(0, (0, common_1.Param)('vendorId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ServiceController.prototype, "getServicesByVendorId", null);
__decorate([
    (0, common_1.Get)('search/location'),
    __param(0, (0, common_1.Query)('lat')),
    __param(1, (0, common_1.Query)('lng')),
    __param(2, (0, common_1.Query)('radius')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String]),
    __metadata("design:returntype", Promise)
], ServiceController.prototype, "searchServicesByLocation", null);
__decorate([
    (0, common_1.Get)('search/name/:serviceName'),
    __param(0, (0, common_1.Param)('serviceName')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ServiceController.prototype, "searchServicesByName", null);
__decorate([
    (0, common_1.Get)('category/:category'),
    __param(0, (0, common_1.Param)('category')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ServiceController.prototype, "getServicesByCategory", null);
exports.ServiceController = ServiceController = __decorate([
    (0, common_1.Controller)('services'),
    __metadata("design:paramtypes", [service_service_1.ServiceService])
], ServiceController);
//# sourceMappingURL=service.controller.js.map