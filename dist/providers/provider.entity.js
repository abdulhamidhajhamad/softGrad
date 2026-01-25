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
exports.ServiceProviderSchema = exports.ServiceProvider = void 0;
const mongoose_1 = require("@nestjs/mongoose");
const mongoose_2 = require("mongoose");
let ServiceProvider = class ServiceProvider extends mongoose_2.Document {
    userId;
    companyName;
    description;
    location;
    details;
    venueType;
    hasGoogleMapLocation;
    targetCustomerType;
};
exports.ServiceProvider = ServiceProvider;
__decorate([
    (0, mongoose_1.Prop)({ type: mongoose_2.Types.ObjectId, ref: 'User', required: true }),
    __metadata("design:type", mongoose_2.Types.ObjectId)
], ServiceProvider.prototype, "userId", void 0);
__decorate([
    (0, mongoose_1.Prop)({ required: true, trim: true }),
    __metadata("design:type", String)
], ServiceProvider.prototype, "companyName", void 0);
__decorate([
    (0, mongoose_1.Prop)({ type: String, default: null }),
    __metadata("design:type", String)
], ServiceProvider.prototype, "description", void 0);
__decorate([
    (0, mongoose_1.Prop)({
        type: {
            city: { type: String, default: null },
            country: { type: String, default: null },
            coordinates: {
                latitude: { type: Number, default: null },
                longitude: { type: Number, default: null },
            },
        },
        default: {},
    }),
    __metadata("design:type", Object)
], ServiceProvider.prototype, "location", void 0);
__decorate([
    (0, mongoose_1.Prop)({ type: Object, default: {} }),
    __metadata("design:type", Object)
], ServiceProvider.prototype, "details", void 0);
__decorate([
    (0, mongoose_1.Prop)({ type: String, default: null }),
    __metadata("design:type", String)
], ServiceProvider.prototype, "venueType", void 0);
__decorate([
    (0, mongoose_1.Prop)({ type: Boolean, default: false }),
    __metadata("design:type", Boolean)
], ServiceProvider.prototype, "hasGoogleMapLocation", void 0);
__decorate([
    (0, mongoose_1.Prop)({ type: String, enum: ['regular', 'mid', 'high'], default: 'regular' }),
    __metadata("design:type", String)
], ServiceProvider.prototype, "targetCustomerType", void 0);
exports.ServiceProvider = ServiceProvider = __decorate([
    (0, mongoose_1.Schema)({ timestamps: { createdAt: true, updatedAt: false }, collection: 'service_providers' })
], ServiceProvider);
exports.ServiceProviderSchema = mongoose_1.SchemaFactory.createForClass(ServiceProvider);
//# sourceMappingURL=provider.entity.js.map