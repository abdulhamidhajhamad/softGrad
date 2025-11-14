"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Service = void 0;
class Service {
    serviceId;
    providerId;
    serviceName;
    images;
    reviews;
    location;
    price;
    additionalInfo;
    createdAt;
    updatedAt;
    constructor(data) {
        Object.assign(this, data);
    }
}
exports.Service = Service;
//# sourceMappingURL=service.entity.js.map