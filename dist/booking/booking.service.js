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
exports.BookingService = void 0;
const common_1 = require("@nestjs/common");
const mongoose_1 = require("@nestjs/mongoose");
const mongoose_2 = require("mongoose");
const booking_entity_1 = require("./booking.entity");
const user_entity_1 = require("../auth/user.entity");
const service_entity_1 = require("../service/service.entity");
let BookingService = class BookingService {
    bookingModel;
    userModel;
    serviceModel;
    constructor(bookingModel, userModel, serviceModel) {
        this.bookingModel = bookingModel;
        this.userModel = userModel;
        this.serviceModel = serviceModel;
    }
    async populateBooking(query) {
        const booking = await query
            .populate('user')
            .populate('service')
            .exec();
        if (booking)
            return booking.toObject();
        return null;
    }
    async populateBookings(query) {
        const bookings = await query
            .populate('user')
            .populate('service')
            .exec();
        return bookings.map(b => b.toObject());
    }
    async create(createBookingDto) {
        const { userName, serviceName, bookingDate, status, totalPrice } = createBookingDto;
        const user = await this.userModel.findOne({ userName }).exec();
        if (!user)
            throw new common_1.NotFoundException(`User '${userName}' not found`);
        const service = await this.serviceModel.findOne({ serviceName: serviceName }).exec();
        if (!service)
            throw new common_1.NotFoundException(`Service '${serviceName}' not found`);
        const newBooking = new this.bookingModel({
            userId: user.id,
            serviceId: service.serviceId,
            bookingDate: new Date(bookingDate),
            totalPrice,
            status: status ?? booking_entity_1.BookingStatus.PENDING,
        });
        try {
            const savedBooking = await newBooking.save();
            const populatedBooking = await this.populateBooking(this.bookingModel.findById(savedBooking._id));
            if (!populatedBooking) {
                throw new common_1.BadRequestException('Failed to retrieve and populate the newly created booking.');
            }
            return populatedBooking;
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Failed to create booking';
            throw new common_1.BadRequestException(errorMessage);
        }
    }
    async findOneByNames(userName, serviceName) {
        const user = await this.userModel.findOne({ userName }).exec();
        if (!user)
            throw new common_1.NotFoundException(`User '${userName}' not found`);
        const service = await this.serviceModel.findOne({ serviceName: serviceName }).exec();
        if (!service)
            throw new common_1.NotFoundException(`Service '${serviceName}' not found`);
        const booking = await this.populateBooking(this.bookingModel.findOne({
            userId: user.id,
            serviceId: service.serviceId,
        }));
        if (!booking)
            throw new common_1.NotFoundException(`No booking found for '${userName}' and '${serviceName}'`);
        return booking;
    }
    async updateByNames(userName, serviceName, dto) {
        const user = await this.userModel.findOne({ userName }).exec();
        if (!user)
            throw new common_1.NotFoundException(`User '${userName}' not found`);
        const service = await this.serviceModel.findOne({ serviceName: serviceName }).exec();
        if (!service)
            throw new common_1.NotFoundException(`Service '${serviceName}' not found`);
        const booking = await this.bookingModel.findOne({
            userId: user.id,
            serviceId: service.serviceId,
        }).exec();
        if (!booking)
            throw new common_1.NotFoundException(`No booking found for '${userName}' and '${serviceName}'`);
        if (dto.userName) {
            const newUser = await this.userModel.findOne({ userName: dto.userName }).exec();
            if (!newUser)
                throw new common_1.NotFoundException(`User '${dto.userName}' not found`);
            booking.userId = newUser.id;
        }
        if (dto.serviceName) {
            const newService = await this.serviceModel.findOne({ serviceName: dto.serviceName }).exec();
            if (!newService)
                throw new common_1.NotFoundException(`Service '${dto.serviceName}' not found`);
            booking.serviceId = newService.serviceId;
        }
        if (dto.bookingDate)
            booking.bookingDate = new Date(dto.bookingDate);
        if (dto.status)
            booking.status = dto.status;
        if (dto.totalPrice)
            booking.totalPrice = dto.totalPrice;
        try {
            const updatedBooking = await booking.save();
            const populatedBooking = await this.populateBooking(this.bookingModel.findById(updatedBooking._id));
            if (!populatedBooking) {
                throw new common_1.BadRequestException('Failed to retrieve and populate the updated booking.');
            }
            return populatedBooking;
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Failed to update booking';
            throw new common_1.BadRequestException(errorMessage);
        }
    }
    async deleteByNames(userName, serviceName) {
        const user = await this.userModel.findOne({ userName }).exec();
        if (!user)
            throw new common_1.NotFoundException(`User '${userName}' not found`);
        const service = await this.serviceModel.findOne({ serviceName: serviceName }).exec();
        if (!service)
            throw new common_1.NotFoundException(`Service '${serviceName}' not found`);
        const result = await this.bookingModel.deleteOne({
            userId: user.id,
            serviceId: service.serviceId,
        }).exec();
        if (result.deletedCount === 0) {
            throw new common_1.NotFoundException(`No booking found for '${userName}' and '${serviceName}'`);
        }
        return { message: `Booking for '${userName}' & '${serviceName}' deleted successfully` };
    }
    async findByUser(userName) {
        const user = await this.userModel.findOne({ userName }).exec();
        if (!user)
            throw new common_1.NotFoundException(`User '${userName}' not found`);
        return await this.populateBookings(this.bookingModel.find({ userId: user.id }));
    }
    async findAll() {
        return await this.populateBookings(this.bookingModel.find());
    }
};
exports.BookingService = BookingService;
exports.BookingService = BookingService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, mongoose_1.InjectModel)(booking_entity_1.Booking.name)),
    __param(1, (0, mongoose_1.InjectModel)(user_entity_1.User.name)),
    __param(2, (0, mongoose_1.InjectModel)(service_entity_1.Service.name)),
    __metadata("design:paramtypes", [mongoose_2.Model,
        mongoose_2.Model,
        mongoose_2.Model])
], BookingService);
//# sourceMappingURL=booking.service.js.map