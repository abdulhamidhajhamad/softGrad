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
var ProviderService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.ProviderService = void 0;
const common_1 = require("@nestjs/common");
const mongoose_1 = require("@nestjs/mongoose");
const mongoose_2 = require("mongoose");
const provider_entity_1 = require("./provider.entity");
let ProviderService = ProviderService_1 = class ProviderService {
    providerModel;
    logger = new common_1.Logger(ProviderService_1.name);
    constructor(providerModel) {
        this.providerModel = providerModel;
    }
    async create(userId, dto) {
        try {
            this.logger.debug(`Creating company for user: ${userId}`);
            if (!mongoose_2.Types.ObjectId.isValid(userId)) {
                throw new Error(`Invalid user ID: ${userId}`);
            }
            const userObjectId = new mongoose_2.Types.ObjectId(userId);
            const existingCompany = await this.providerModel.findOne({
                userId: userObjectId,
                companyName: dto.companyName
            });
            if (existingCompany) {
                throw new common_1.ConflictException('You already have a company with this name');
            }
            const company = new this.providerModel({
                ...dto,
                userId: userObjectId
            });
            const savedCompany = await company.save();
            this.logger.debug(`Company created successfully: ${savedCompany.companyName}`);
            return savedCompany;
        }
        catch (error) {
            this.logger.error(`Error creating company: ${error.message}`);
            this.logger.error(`Stack: ${error.stack}`);
            throw error;
        }
    }
    async findAllByUser(userId) {
        const userObjectId = new mongoose_2.Types.ObjectId(userId);
        return this.providerModel.find({ userId: userObjectId }).exec();
    }
    async update(userId, companyName, dto) {
        const userObjectId = new mongoose_2.Types.ObjectId(userId);
        const company = await this.providerModel.findOne({
            userId: userObjectId,
            companyName
        });
        if (!company)
            throw new common_1.NotFoundException('Company not found or you do not own this company');
        const updatedCompany = await this.providerModel.findOneAndUpdate({ userId: userObjectId, companyName }, dto, { new: true });
        if (!updatedCompany)
            throw new common_1.NotFoundException('Company not found after update');
        return updatedCompany;
    }
    async remove(userId, companyName, isAdmin = false) {
        const userObjectId = new mongoose_2.Types.ObjectId(userId);
        const company = await this.providerModel.findOne({
            userId: userObjectId,
            companyName
        });
        if (!company)
            throw new common_1.NotFoundException('Company not found or you do not own this company');
        if (!isAdmin && company.userId.toString() !== userId) {
            throw new common_1.ForbiddenException('You cannot delete this company');
        }
        return this.providerModel.deleteOne({ userId: userObjectId, companyName });
    }
    async findByName(userId, companyName) {
        const userObjectId = new mongoose_2.Types.ObjectId(userId);
        const company = await this.providerModel.findOne({
            userId: userObjectId,
            companyName
        });
        if (!company)
            throw new common_1.NotFoundException('Company not found or you do not have access');
        return company;
    }
};
exports.ProviderService = ProviderService;
exports.ProviderService = ProviderService = ProviderService_1 = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, mongoose_1.InjectModel)(provider_entity_1.ServiceProvider.name)),
    __metadata("design:paramtypes", [mongoose_2.Model])
], ProviderService);
//# sourceMappingURL=provider.service.js.map