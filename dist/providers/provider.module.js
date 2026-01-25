"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ProviderModule = void 0;
const common_1 = require("@nestjs/common");
const mongoose_1 = require("@nestjs/mongoose");
const provider_controller_1 = require("./provider.controller");
const provider_service_1 = require("./provider.service");
const provider_entity_1 = require("./provider.entity");
const auth_module_1 = require("../auth/auth.module");
let ProviderModule = class ProviderModule {
};
exports.ProviderModule = ProviderModule;
exports.ProviderModule = ProviderModule = __decorate([
    (0, common_1.Module)({
        imports: [
            mongoose_1.MongooseModule.forFeature([
                { name: provider_entity_1.ServiceProvider.name, schema: provider_entity_1.ServiceProviderSchema }
            ]),
            auth_module_1.AuthModule,
        ],
        controllers: [provider_controller_1.ProviderController],
        providers: [provider_service_1.ProviderService],
        exports: [provider_service_1.ProviderService, mongoose_1.MongooseModule],
    })
], ProviderModule);
//# sourceMappingURL=provider.module.js.map