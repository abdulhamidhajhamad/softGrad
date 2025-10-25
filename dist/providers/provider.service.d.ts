import { Model } from 'mongoose';
import { ServiceProvider } from './provider.entity';
import { CreateServiceProviderDto, UpdateServiceProviderDto } from './provider.dto';
import { DeleteResult } from 'mongodb';
export declare class ProviderService {
    private providerModel;
    private readonly logger;
    constructor(providerModel: Model<ServiceProvider>);
    create(userId: string, dto: CreateServiceProviderDto): Promise<ServiceProvider>;
    findAllByUser(userId: string): Promise<ServiceProvider[]>;
    update(userId: string, companyName: string, dto: UpdateServiceProviderDto): Promise<ServiceProvider>;
    remove(userId: string, companyName: string, isAdmin?: boolean): Promise<DeleteResult>;
    findByName(userId: string, companyName: string): Promise<ServiceProvider>;
}
