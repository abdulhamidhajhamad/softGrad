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
Object.defineProperty(exports, "__esModule", { value: true });
exports.BookingSchema = exports.Booking = exports.BookingStatus = void 0;
const mongoose_1 = require("@nestjs/mongoose");
const mongoose_2 = require("mongoose");
var BookingStatus;
(function (BookingStatus) {
    BookingStatus["PENDING"] = "pending";
    BookingStatus["CONFIRMED"] = "confirmed";
    BookingStatus["CANCELLED"] = "cancelled";
    BookingStatus["COMPLETED"] = "completed";
})(BookingStatus || (exports.BookingStatus = BookingStatus = {}));
let Booking = class Booking extends mongoose_2.Document {
    userId;
    serviceId;
    bookingDate;
    status;
    totalPrice;
    user;
    service;
};
exports.Booking = Booking;
__decorate([
    (0, mongoose_1.Prop)({ required: true, ref: 'User' }),
    __metadata("design:type", Number)
], Booking.prototype, "userId", void 0);
__decorate([
    (0, mongoose_1.Prop)({ required: true, ref: 'Service' }),
    __metadata("design:type", Number)
], Booking.prototype, "serviceId", void 0);
__decorate([
    (0, mongoose_1.Prop)({ type: Date, required: true }),
    __metadata("design:type", Date)
], Booking.prototype, "bookingDate", void 0);
__decorate([
    (0, mongoose_1.Prop)({
        type: String,
        enum: Object.values(BookingStatus),
        default: BookingStatus.PENDING,
    }),
    __metadata("design:type", String)
], Booking.prototype, "status", void 0);
__decorate([
    (0, mongoose_1.Prop)({ type: Number, required: true }),
    __metadata("design:type", Number)
], Booking.prototype, "totalPrice", void 0);
exports.Booking = Booking = __decorate([
    (0, mongoose_1.Schema)({
        collection: 'bookings',
        timestamps: true,
        toJSON: { virtuals: true },
        toObject: { virtuals: true }
    })
], Booking);
exports.BookingSchema = mongoose_1.SchemaFactory.createForClass(Booking);
exports.BookingSchema.virtual('user', {
    ref: 'User',
    localField: 'userId',
    foreignField: 'id',
    justOne: true,
});
exports.BookingSchema.virtual('service', {
    ref: 'Service',
    localField: 'serviceId',
    foreignField: 'serviceId',
    justOne: true,
});
//# sourceMappingURL=booking.entity.js.map