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
exports.ProviderController = void 0;
const common_1 = require("@nestjs/common");
const provider_service_1 = require("./provider.service");
const provider_dto_1 = require("./provider.dto");
const jwt_auth_guard_1 = require("../auth/jwt-auth.guard");
let ProviderController = class ProviderController {
    providerService;
    constructor(providerService) {
        this.providerService = providerService;
    }
    async create(req, dto) {
        try {
            const userId = req.user.userId;
            console.log('Creating provider for user:', userId);
            return await this.providerService.create(userId, dto);
        }
        catch (error) {
            throw error;
        }
    }
    async getAll(req) {
        const userId = req.user.userId;
        return this.providerService.findAllByUser(userId);
    }
    async update(req, companyName, dto) {
        const userId = req.user.userId;
        return this.providerService.update(userId, companyName, dto);
    }
    async remove(req, companyName) {
        const userId = req.user.userId;
        const isAdmin = req.user.role === 'admin';
        return this.providerService.remove(userId, companyName, isAdmin);
    }
    async get(req, companyName) {
        const userId = req.user.userId;
        return this.providerService.findByName(userId, companyName);
    }
};
exports.ProviderController = ProviderController;
__decorate([
    (0, common_1.Post)(),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, provider_dto_1.CreateServiceProviderDto]),
    __metadata("design:returntype", Promise)
], ProviderController.prototype, "create", null);
__decorate([
    (0, common_1.Get)(),
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], ProviderController.prototype, "getAll", null);
__decorate([
    (0, common_1.Patch)(':companyName'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('companyName')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, provider_dto_1.UpdateServiceProviderDto]),
    __metadata("design:returntype", Promise)
], ProviderController.prototype, "update", null);
__decorate([
    (0, common_1.Delete)(':companyName'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('companyName')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], ProviderController.prototype, "remove", null);
__decorate([
    (0, common_1.Get)(':companyName'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('companyName')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], ProviderController.prototype, "get", null);
exports.ProviderController = ProviderController = __decorate([
    (0, common_1.Controller)('providers'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __metadata("design:paramtypes", [provider_service_1.ProviderService])
], ProviderController);
//# sourceMappingURL=provider.controller.js.map