import { Model } from 'mongoose';
import { Service } from './service.schema';
import { CreateServiceDto, UpdateServiceDto } from './service.dto';
export declare class ServiceService {
    private serviceModel;
    constructor(serviceModel: Model<Service>);
    createService(providerId: string, createServiceDto: CreateServiceDto): Promise<Service>;
    deleteServiceByName(serviceName: string, providerId: string): Promise<{
        message: string;
    }>;
    getAllServices(): Promise<Service[]>;
    updateServiceByName(serviceName: string, providerId: string, updateServiceDto: UpdateServiceDto): Promise<Service>;
    getServicesByVendorName(companyName: string): Promise<Service[]>;
    getServicesByVendorId(vendorId: string): Promise<Service[]>;
    getServiceById(serviceId: string): Promise<Service>;
    searchServicesByLocation(latitude: number, longitude: number, radiusInKm?: number): Promise<Service[]>;
    searchServicesByName(serviceName: string): Promise<Service[]>;
    getServicesByCategory(category: string): Promise<Service[]>;
    private calculateDistance;
}
