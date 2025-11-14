import { ServiceService } from './service.service';
import { CreateServiceDto, UpdateServiceDto } from './service.dto';
export declare class ServiceController {
    private readonly serviceService;
    constructor(serviceService: ServiceService);
    addService(createServiceDto: CreateServiceDto, req: any): Promise<import("./service.schema").Service>;
    deleteServiceByName(serviceName: string, req: any): Promise<{
        message: string;
    }>;
    updateServiceByName(serviceName: string, updateServiceDto: UpdateServiceDto, req: any): Promise<import("./service.schema").Service>;
    getAllServices(): Promise<import("./service.schema").Service[]>;
    getServiceById(id: string): Promise<import("./service.schema").Service>;
    getServicesByVendor(companyName: string): Promise<import("./service.schema").Service[]>;
    getServicesByVendorId(vendorId: string): Promise<import("./service.schema").Service[]>;
    searchServicesByLocation(lat: string, lng: string, radius: string): Promise<import("./service.schema").Service[]>;
    searchServicesByName(serviceName: string): Promise<import("./service.schema").Service[]>;
    getServicesByCategory(category: string): Promise<import("./service.schema").Service[]>;
}
