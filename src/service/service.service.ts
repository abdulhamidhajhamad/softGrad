import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Service } from './service.entity';
import { CreateServiceDto, UpdateServiceDto } from './service.dto';

@Injectable()
export class ServiceService {
  constructor(
    @InjectRepository(Service)
    private readonly serviceRepository: Repository<Service>,
  ) {}

async create(createServiceDto: CreateServiceDto): Promise<Service> {
  try {
    const service = this.serviceRepository.create({
      ...createServiceDto,
      imageUrls: createServiceDto.imageUrls || [], // ← Set default empty array
    });
    return await this.serviceRepository.save(service);
  } catch (error) {
    throw new BadRequestException('Failed to create service. Please check provider_id exists.');
  }
}

async update(serviceId: number, updateServiceDto: UpdateServiceDto): Promise<Service> {
  const service = await this.serviceRepository.findOne({
    where: { serviceId },
  });

  if (!service) {
    throw new NotFoundException(`Service with ID ${serviceId} not found`);
  }

  try {
    // Only update imageUrls if provided, otherwise keep existing
    if (updateServiceDto.imageUrls !== undefined) {
      service.imageUrls = updateServiceDto.imageUrls;
    }
    
    Object.assign(service, updateServiceDto);
    return await this.serviceRepository.save(service);
  } catch (error) {
    throw new BadRequestException('Failed to update service');
  }
}

  async delete(serviceName: string): Promise<{ message: string }> {
    const trimmedName = serviceName.trim();
    
    const service = await this.serviceRepository.findOne({
      where: { name: trimmedName },
    });

    if (!service) {
      throw new NotFoundException(`Service with name "${trimmedName}" not found`);
    }

    await this.serviceRepository.remove(service);
    return { message: `Service "${trimmedName}" has been deleted successfully` };
  }

  async findAll(): Promise<Service[]> {
    return await this.serviceRepository.find();
  }

  async findByProvider(providerName: string): Promise<Service[]> {
    const services = await this.serviceRepository
      .createQueryBuilder('service')
      .innerJoin('service_providers', 'provider', 'provider.provider_id = service.provider_id')
      .where('provider.company_name = :providerName', { providerName: providerName.trim() })
      .getMany();

    if (!services || services.length === 0) {
      throw new NotFoundException(`No services found for provider "${providerName}"`);
    }

    return services;
  }

  async findOne(serviceId: number): Promise<Service> {
    const service = await this.serviceRepository.findOne({
      where: { serviceId },
    });

    if (!service) {
      throw new NotFoundException(`Service with ID ${serviceId} not found`);
    }

    return service;
  }
}