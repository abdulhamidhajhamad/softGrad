import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ServiceProvider } from './provider.entity';
import { CreateProviderDto, UpdateProviderDto, SearchProviderDto } from './provider.dto';

@Injectable()
export class ProviderService {
  constructor(
    @InjectRepository(ServiceProvider)
    private readonly providerRepository: Repository<ServiceProvider>,
  ) {}
  async createProvider(userId: number, createProviderDto: CreateProviderDto): Promise<ServiceProvider> {
    const existingProvider = await this.providerRepository.findOne({
      where: { userId }
    });
    if (existingProvider) {
      throw new ConflictException('User already has a provider profile');
    }
    const provider = this.providerRepository.create({
      userId,
      companyName: createProviderDto.companyName,
      description: createProviderDto.description,
      location: createProviderDto.location,
    });
    return await this.providerRepository.save(provider);
  }
  async updateProvider(userId: number, updateProviderDto: UpdateProviderDto): Promise<ServiceProvider> {
    const provider = await this.providerRepository.findOne({
      where: { userId }
    });

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

    return await this.providerRepository.save(provider);
  }

  async getProviderById(providerId: number): Promise<ServiceProvider> {
    const provider = await this.providerRepository.findOne({
      where: { providerId },
      relations: ['user']
    });

    if (!provider) {
      throw new NotFoundException('Provider not found');
    }
    return provider;
  }
  async getProviderByUserId(userId: number): Promise<ServiceProvider> {
    const provider = await this.providerRepository.findOne({
      where: { userId },
      relations: ['user']
    });

    if (!provider) {
      throw new NotFoundException('Provider profile not found');
    }

    return provider;
  }

  async searchProviders(searchDto: SearchProviderDto): Promise<{ 
    providers: ServiceProvider[], 
    total: number, 
    page: number, 
    totalPages: number 
  }> {
    const { page = 1, limit = 10, location, searchTerm } = searchDto;
    
    const queryBuilder = this.providerRepository.createQueryBuilder('provider');

    if (location) {
      queryBuilder.andWhere('provider.location LIKE :location', { 
        location: `%${location}%` 
      });
    }

    if (searchTerm) {
      queryBuilder.andWhere(
        '(provider.company_name LIKE :searchTerm OR provider.description LIKE :searchTerm)',
        { searchTerm: `%${searchTerm}%` }
      );
    }

    const total = await queryBuilder.getCount();
    const providers = await queryBuilder
      .orderBy('provider.provider_id', 'DESC')
      .skip((page - 1) * limit)
      .take(limit)
      .getMany();

    return {
      providers,
      total,
      page,
      totalPages: Math.ceil(total / limit)
    };
  }

  async getAllProviders(): Promise<ServiceProvider[]> {
    return await this.providerRepository.find({
      relations: ['user'],
      order: {
        providerId: 'DESC'
      }
    });
  }

  async deleteProvider(userId: number): Promise<void> {
    const provider = await this.providerRepository.findOne({
      where: { userId }
    });

    if (!provider) {
      throw new NotFoundException('Provider profile not found');
    }

    await this.providerRepository.remove(provider);
  }

  async getProvidersByLocation(location: string): Promise<ServiceProvider[]> {
    return await this.providerRepository
      .createQueryBuilder('provider')
      .where('provider.location LIKE :location', { location: `%${location}%` })
      .getMany();
  }
}