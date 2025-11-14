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
exports.AdminService = void 0;
const common_1 = require("@nestjs/common");
const mongoose_1 = require("@nestjs/mongoose");
const mongoose_2 = require("mongoose");
const user_entity_1 = require("../auth/user.entity");
const provider_entity_1 = require("../providers/provider.entity");
let AdminService = class AdminService {
    userModel;
    providerModel;
    constructor(userModel, providerModel) {
        this.userModel = userModel;
        this.providerModel = providerModel;
    }
    async getAllUsers() {
        try {
            const users = await this.userModel.find().exec();
            return {
                totalUsers: users.length,
                users: users,
            };
        }
        catch (error) {
            throw new common_1.BadRequestException('Failed to fetch users');
        }
    }
    async getAllProviders() {
        try {
            const providers = await this.providerModel.find().exec();
            return {
                totalProviders: providers.length,
                providers: providers,
            };
        }
        catch (error) {
            throw new common_1.BadRequestException('Failed to fetch providers');
        }
    }
    async getAllServices() {
        try {
            return {
                totalServices: 0,
                services: [],
            };
        }
        catch (error) {
            throw new common_1.BadRequestException('Failed to fetch services');
        }
    }
    async getAllBookings() {
        try {
            return {
                totalBookings: 0,
                bookings: [],
            };
        }
        catch (error) {
            throw new common_1.BadRequestException('Failed to fetch bookings');
        }
    }
    async getDashboardStats() {
        try {
            const users = await this.userModel.find().exec();
            const providers = await this.providerModel.find().exec();
            return {
                summary: {
                    totalUsers: users.length,
                    totalProviders: providers.length,
                    totalServices: 0,
                    totalBookings: 0,
                    totalRevenue: "0.00",
                },
                bookingStats: {
                    pending: 0,
                    confirmed: 0,
                    cancelled: 0,
                    completed: 0,
                },
                data: {
                    users: users,
                    providers: providers,
                    services: [],
                    bookings: [],
                },
            };
        }
        catch (error) {
            throw new common_1.BadRequestException('Failed to fetch dashboard stats');
        }
    }
    async getAnalytics() {
        try {
            const users = await this.userModel.find().exec();
            const providers = await this.providerModel.find().exec();
            return {
                userMetrics: {
                    totalUsers: users.length,
                },
                providerMetrics: {
                    totalProviders: providers.length,
                    servicesPerProvider: {},
                },
                serviceMetrics: {
                    totalServices: 0,
                    averageRating: "0",
                    bookingsPerService: {},
                },
                bookingMetrics: {
                    totalBookings: 0,
                    averageBookingPrice: "0",
                    totalRevenue: "0",
                },
            };
        }
        catch (error) {
            throw new common_1.BadRequestException('Failed to fetch analytics');
        }
    }
};
exports.AdminService = AdminService;
exports.AdminService = AdminService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, mongoose_1.InjectModel)(user_entity_1.User.name)),
    __param(1, (0, mongoose_1.InjectModel)(provider_entity_1.ServiceProvider.name)),
    __metadata("design:paramtypes", [mongoose_2.Model,
        mongoose_2.Model])
], AdminService);
//# sourceMappingURL=admin.service.js.map