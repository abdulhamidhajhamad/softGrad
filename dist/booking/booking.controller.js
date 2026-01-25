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
exports.BookingController = void 0;
const common_1 = require("@nestjs/common");
const booking_service_1 = require("./booking.service");
const booking_dto_1 = require("./booking.dto");
let BookingController = class BookingController {
    bookingService;
    constructor(bookingService) {
        this.bookingService = bookingService;
    }
    async create(dto) {
        return this.bookingService.create(dto);
    }
    async findAll() {
        return this.bookingService.findAll();
    }
    async findOne(userName, serviceName) {
        return this.bookingService.findOneByNames(userName, serviceName);
    }
    async update(userName, serviceName, dto) {
        return this.bookingService.updateByNames(userName, serviceName, dto);
    }
    async delete(userName, serviceName) {
        return this.bookingService.deleteByNames(userName, serviceName);
    }
    async findByUser(userName) {
        return this.bookingService.findByUser(userName);
    }
};
exports.BookingController = BookingController;
__decorate([
    (0, common_1.Post)(),
    (0, common_1.HttpCode)(common_1.HttpStatus.CREATED),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [booking_dto_1.CreateBookingDto]),
    __metadata("design:returntype", Promise)
], BookingController.prototype, "create", null);
__decorate([
    (0, common_1.Get)(),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], BookingController.prototype, "findAll", null);
__decorate([
    (0, common_1.Get)(':userName/:serviceName'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Param)('userName')),
    __param(1, (0, common_1.Param)('serviceName')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", Promise)
], BookingController.prototype, "findOne", null);
__decorate([
    (0, common_1.Put)(':userName/:serviceName'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Param)('userName')),
    __param(1, (0, common_1.Param)('serviceName')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, booking_dto_1.UpdateBookingDto]),
    __metadata("design:returntype", Promise)
], BookingController.prototype, "update", null);
__decorate([
    (0, common_1.Delete)(':userName/:serviceName'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Param)('userName')),
    __param(1, (0, common_1.Param)('serviceName')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", Promise)
], BookingController.prototype, "delete", null);
__decorate([
    (0, common_1.Get)('user/:userName'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Param)('userName')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], BookingController.prototype, "findByUser", null);
exports.BookingController = BookingController = __decorate([
    (0, common_1.Controller)('bookings'),
    __metadata("design:paramtypes", [booking_service_1.BookingService])
], BookingController);
//# sourceMappingURL=booking.controller.js.map