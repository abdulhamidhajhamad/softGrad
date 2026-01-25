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
exports.AdminSchema = exports.Admin = exports.AdminRole = void 0;
const mongoose_1 = require("@nestjs/mongoose");
const mongoose_2 = require("mongoose");
var AdminRole;
(function (AdminRole) {
    AdminRole["SUPER_ADMIN"] = "super_admin";
    AdminRole["ADMIN"] = "admin";
})(AdminRole || (exports.AdminRole = AdminRole = {}));
let Admin = class Admin extends mongoose_2.Document {
    userId;
    role;
    createdAt;
};
exports.Admin = Admin;
__decorate([
    (0, mongoose_1.Prop)({ required: true, type: mongoose_2.Schema.Types.ObjectId, ref: 'User', unique: true }),
    __metadata("design:type", String)
], Admin.prototype, "userId", void 0);
__decorate([
    (0, mongoose_1.Prop)({
        type: String,
        enum: Object.values(AdminRole),
        default: AdminRole.ADMIN,
    }),
    __metadata("design:type", String)
], Admin.prototype, "role", void 0);
__decorate([
    (0, mongoose_1.Prop)({ type: Date, default: Date.now }),
    __metadata("design:type", Date)
], Admin.prototype, "createdAt", void 0);
exports.Admin = Admin = __decorate([
    (0, mongoose_1.Schema)({ collection: 'admins', timestamps: true })
], Admin);
exports.AdminSchema = mongoose_1.SchemaFactory.createForClass(Admin);
exports.AdminSchema.index({ userId: 1 }, { unique: true });
//# sourceMappingURL=admin.entity.js.map