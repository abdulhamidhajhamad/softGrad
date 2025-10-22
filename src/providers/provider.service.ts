import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { ServiceProvider } from './provider.entity';
import { CreateProviderDto, UpdateProviderDto, SearchProviderDto } from './provider.dto';

@Injectable()
export class ProviderService {
  constructor(
    @InjectModel(ServiceProvider.name)
    private readonly providerModel: Model<ServiceProvider>,
  ) {}

  async createProvider(userId: string, createProviderDto: CreateProviderDto): Promise<ServiceProvider> {
    const existingProvider = await this.providerModel.findOne({ 
      userId: new Types.ObjectId(userId) 
    }).exec();
    
    if (existingProvider) {
      throw new ConflictException('User already has a provider profile');
    }

    const provider = new this.providerModel({
      userId: new Types.ObjectId(userId),
      companyName: createProviderDto.companyName,
      description: createProviderDto.description || '',
      location: createProviderDto.location || '',
      imageUrls: createProviderDto.imageUrls || [],
      customerType: createProviderDto.customerType,
      details: createProviderDto.details || {},
    });

    return await provider.save();
  }

  async updateProvider(userId: string, updateProviderDto: UpdateProviderDto): Promise<ServiceProvider> {
    const provider = await this.providerModel.findOne({ 
      userId: new Types.ObjectId(userId) 
    }).exec();

    if (!provider) {
      throw new NotFoundException('Provider profile not found');
    }

    if (updateProviderDto.companyName !== undefined) {
      provider.companyName = updateProviderDto.companyName;
    }
    if (updateProviderDto.description !== undefined) {
      provider.description = updateProviderDto.description;
    }
    if (updateProviderDto.location !== undefined) {
      provider.location = updateProviderDto.location;
    }
    if (updateProviderDto.imageUrls !== undefined) {
      provider.imageUrls = updateProviderDto.imageUrls;
    }
    if (updateProviderDto.customerType !== undefined) {
      provider.customerType = updateProviderDto.customerType;
    }
    if (updateProviderDto.details !== undefined) {
      // Merge details instead of replacing
      provider.details = { ...provider.details, ...updateProviderDto.details };
    }

    return await provider.save();
  }

  async searchProviders(searchDto: SearchProviderDto): Promise<{ 
    providers: ServiceProvider[], 
    total: number, 
    page: number, 
    totalPages: number 
  }> {
    const { page = 1, limit = 10, location, searchTerm, customerType } = searchDto;
    
    const query: any = {};

    if (location) {
      query.location = { $regex: location, $options: 'i' };
    }

    if (searchTerm) {
      query.$or = [
        { companyName: { $regex: searchTerm, $options: 'i' } },
        { description: { $regex: searchTerm, $options: 'i' } }
      ];
    }

    if (customerType) {
      query.customerType = customerType;
    }

    const total = await this.providerModel.countDocuments(query).exec();
    const providers = await this.providerModel
      .find(query)
      .sort({ _id: -1 })
      .skip((page - 1) * limit)
      .limit(limit)
      .exec();

    return {
      providers,
      total,
      page,
      totalPages: Math.ceil(total / limit)
    };
  }

  async getProviderById(providerId: string): Promise<ServiceProvider> {
    const provider = await this.providerModel
      .findById(providerId)
      .populate('userId')
      .exec();

    if (!provider) {
      throw new NotFoundException('Provider not found');
    }
    return provider;
  }

  async getProviderByUserId(userId: string): Promise<ServiceProvider> {
    const provider = await this.providerModel
      .findOne({ userId: new Types.ObjectId(userId) })
      .populate('userId')
      .exec();

    if (!provider) {
      throw new NotFoundException('Provider profile not found');
    }

    return provider;
  }

  async getAllProviders(): Promise<ServiceProvider[]> {
    return await this.providerModel
      .find()
      .populate('userId')
      .sort({ _id: -1 })
      .exec();
  }

  async deleteProvider(userId: string): Promise<void> {
    const result = await this.providerModel.deleteOne({ 
      userId: new Types.ObjectId(userId) 
    }).exec();

    if (result.deletedCount === 0) {
      throw new NotFoundException('Provider profile not found');
    }
  }

  async getProvidersByLocation(location: string): Promise<ServiceProvider[]> {
    return await this.providerModel
      .find({ location: { $regex: location, $options: 'i' } })
      .exec();
  }
}