import { ProviderService } from './provider.service';
import { CreateServiceProviderDto, UpdateServiceProviderDto } from './provider.dto';
import { DeleteResult } from 'mongodb';
export declare class ProviderController {
    private readonly providerService;
    constructor(providerService: ProviderService);
    create(req: any, dto: CreateServiceProviderDto): Promise<import("./provider.entity").ServiceProvider>;
    getAll(req: any): Promise<import("./provider.entity").ServiceProvider[]>;
    update(req: any, companyName: string, dto: UpdateServiceProviderDto): Promise<import("./provider.entity").ServiceProvider>;
    remove(req: any, companyName: string): Promise<DeleteResult>;
    get(req: any, companyName: string): Promise<import("./provider.entity").ServiceProvider>;
}
