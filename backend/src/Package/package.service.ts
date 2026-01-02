// package.service.ts
import { Injectable, NotFoundException, BadRequestException, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Package } from './package.entity';
import { Service } from '../service/service.schema';
import { CreatePackageDto, UpdatePackageDto, UpdatePackageStatusDto } from './package.dto';
import { ServiceProvider } from '../providers/provider.entity';

@Injectable()
export class PackageService {
  private readonly logger = new Logger(PackageService.name);

  constructor(
    @InjectModel(Package.name) private packageModel: Model<Package>,
    @InjectModel(Service.name) private serviceModel: Model<Service>,
    @InjectModel(ServiceProvider.name) private providerModel: Model<ServiceProvider>,
  ) {}

  async createPackage(providerId: string, createPackageDto: CreatePackageDto): Promise<Package> {
    const provider = await this.providerModel
      .findOne({ userId: new Types.ObjectId(providerId) })
      .select('companyName')
      .exec();

    if (!provider || !provider.companyName) {
      throw new BadRequestException('Provider profile not found or company name is missing.');
    }

    let originalTotal = 0;
    const serviceItems: any[] = [];
    const serviceIds = createPackageDto.services.map(s => s.serviceId);

    const existingServices = await this.serviceModel.find({ 
      _id: { $in: serviceIds } 
    }).exec();

    if (existingServices.length !== serviceIds.length) {
      throw new NotFoundException('One or more services not found.');
    }

    for (const itemDto of createPackageDto.services) {
      const service = existingServices.find(s => (s as any)._id.toString() === itemDto.serviceId);
      
      if (!service) {
        throw new NotFoundException(`Service with ID ${itemDto.serviceId} not found.`);
      }

      let originalPrice: number;
      let newPrice: number;

      // ✅ استخدام price البسيط أولاً، ثم priceOptions للتوافق
      const simplePrice = service.price;
      const priceOpts = service.priceOptions;
      
      if (service.bookingType === 'hourly') {
        const perHour = priceOpts?.perHour || simplePrice;
        
        if (!perHour) {
          throw new BadRequestException(`Service "${service.serviceName}" has invalid pricing configuration`);
        }

        if (itemDto.maxHours && itemDto.maxHours > 0) {
          originalPrice = perHour * itemDto.maxHours;
          newPrice = itemDto.newPrice !== undefined ? itemDto.newPrice : originalPrice;
        } else {
          originalPrice = perHour;
          newPrice = itemDto.newPrice !== undefined ? itemDto.newPrice : originalPrice;
        }

      } else if (service.bookingType === 'capacity') {
        const perPerson = priceOpts?.perPerson || simplePrice;
        
        if (!perPerson) {
          throw new BadRequestException(`Service "${service.serviceName}" has invalid pricing configuration`);
        }

        if (itemDto.maxCapacity && itemDto.maxCapacity > 0) {
          originalPrice = perPerson * itemDto.maxCapacity;
          newPrice = itemDto.newPrice !== undefined ? itemDto.newPrice : originalPrice;
        } else {
          originalPrice = perPerson;
          newPrice = itemDto.newPrice !== undefined ? itemDto.newPrice : originalPrice;
        }

      } else {
        const basePrice = priceOpts?.basePrice || simplePrice;
        
        if (!basePrice) {
          throw new BadRequestException(`Service "${service.serviceName}" has invalid base pricing`);
        }
        originalPrice = basePrice;
        newPrice = itemDto.newPrice !== undefined ? itemDto.newPrice : originalPrice;
      }

      originalTotal += originalPrice;

      const packageServiceItem = {
        serviceId: service._id,
        serviceName: service.serviceName,
        originalPrice: originalPrice,
        newPrice: newPrice,
        ...(itemDto.maxHours && { maxHours: itemDto.maxHours }),
        ...(itemDto.maxCapacity && { maxCapacity: itemDto.maxCapacity }),
      };

      serviceItems.push(packageServiceItem);
    }

    const createdPackage = new this.packageModel({
      providerId: providerId,
      companyName: provider.companyName,
      packageName: createPackageDto.packageName,
      description: createPackageDto.description,
      services: serviceItems,
      originalTotalPrice: originalTotal,
      newPrice: createPackageDto.newPrice,
      startDate: createPackageDto.startDate,
      endDate: createPackageDto.endDate,
      packageImageUrl: createPackageDto.packageImageUrl,
      isActive: true,
    });

    return createdPackage.save();
  }

  async updatePackage(
    packageId: string,
    providerId: string,
    updateDto: UpdatePackageDto
  ): Promise<Package> {
    const pkg = await this.packageModel.findOne({
      _id: new Types.ObjectId(packageId),
      providerId: providerId
    }).exec();

    if (!pkg) {
      throw new NotFoundException('Package not found or you do not have permission.');
    }

    if (updateDto.services) {
      let originalTotal = 0;
      const serviceItems: any[] = [];
      const serviceIds = updateDto.services.map(s => s.serviceId);

      const existingServices = await this.serviceModel.find({ 
        _id: { $in: serviceIds } 
      }).exec();

      if (existingServices.length !== serviceIds.length) {
        throw new NotFoundException('One or more services not found.');
      }

      for (const itemDto of updateDto.services) {
        const service = existingServices.find(s => (s as any)._id.toString() === itemDto.serviceId);
        
        if (!service) {
          throw new NotFoundException(`Service ${itemDto.serviceId} not found.`);
        }

        let originalPrice: number;
        let newPrice: number;

        // ✅ استخدام price البسيط أولاً، ثم priceOptions للتوافق
        const simplePrice = service.price;
        const priceOpts = service.priceOptions;

        if (service.bookingType === 'hourly') {
          const perHour = priceOpts?.perHour || simplePrice;
          
          if (!perHour) {
            throw new BadRequestException(`Service "${service.serviceName}" has invalid pricing configuration`);
          }

          if (itemDto.maxHours && itemDto.maxHours > 0) {
            originalPrice = perHour * itemDto.maxHours;
            newPrice = itemDto.newPrice !== undefined ? itemDto.newPrice : originalPrice;
          } else {
            originalPrice = perHour;
            newPrice = itemDto.newPrice !== undefined ? itemDto.newPrice : originalPrice;
          }

        } else if (service.bookingType === 'capacity') {
          const perPerson = priceOpts?.perPerson || simplePrice;
          
          if (!perPerson) {
            throw new BadRequestException(`Service "${service.serviceName}" has invalid pricing configuration`);
          }

          if (itemDto.maxCapacity && itemDto.maxCapacity > 0) {
            originalPrice = perPerson * itemDto.maxCapacity;
            newPrice = itemDto.newPrice !== undefined ? itemDto.newPrice : originalPrice;
          } else {
            originalPrice = perPerson;
            newPrice = itemDto.newPrice !== undefined ? itemDto.newPrice : originalPrice;
          }

        } else {
          const basePrice = priceOpts?.basePrice || simplePrice;
          
          if (!basePrice) {
            throw new BadRequestException(`Service "${service.serviceName}" has invalid base pricing`);
          }
          originalPrice = basePrice;
          newPrice = itemDto.newPrice !== undefined ? itemDto.newPrice : originalPrice;
        }

        originalTotal += originalPrice;

        serviceItems.push({
          serviceId: service._id,
          serviceName: service.serviceName,
          originalPrice: originalPrice,
          newPrice: newPrice,
          ...(itemDto.maxHours && { maxHours: itemDto.maxHours }),
          ...(itemDto.maxCapacity && { maxCapacity: itemDto.maxCapacity }),
        });
      }

      pkg.services = serviceItems;
      pkg.originalTotalPrice = originalTotal;
    }

    if (updateDto.packageName) pkg.packageName = updateDto.packageName;
    if (updateDto.newPrice !== undefined) pkg.newPrice = updateDto.newPrice;
    if (updateDto.startDate) pkg.startDate = new Date(updateDto.startDate);
    if (updateDto.description) pkg.description = updateDto.description;
    if (updateDto.endDate) pkg.endDate = new Date(updateDto.endDate);
    if (updateDto.packageImageUrl) pkg.packageImageUrl = updateDto.packageImageUrl;

    return await pkg.save();
  }

  async getProviderPackages(providerId: string): Promise<Package[]> {
    return await this.packageModel.find({ providerId }).exec();
  }

  async getActivePackages(): Promise<Package[]> {
    const now = new Date();
    return await this.packageModel.find({
      isActive: true,
      startDate: { $lte: now },
      endDate: { $gte: now }
    }).exec();
  }

  async getPackageById(packageId: string): Promise<Package> {
    const pkg = await this.packageModel.findById(packageId).exec();
    if (!pkg) {
      throw new NotFoundException('Package not found');
    }
    return pkg;
  }

  async updatePackageStatus(
    packageId: string,
    providerId: string,
    statusDto: UpdatePackageStatusDto
  ): Promise<Package> {
    const pkg = await this.packageModel.findOneAndUpdate(
      { _id: new Types.ObjectId(packageId), providerId: providerId },
      { $set: { isActive: statusDto.isActive } },
      { new: true }
    ).exec();

    if (!pkg) {
      throw new NotFoundException('Package not found or you do not have permission.');
    }

    return pkg;
  }

  async deletePackage(packageId: string, providerId: string): Promise<void> {
    const result = await this.packageModel.deleteOne({
      _id: new Types.ObjectId(packageId),
      providerId: providerId
    }).exec();

    if (result.deletedCount === 0) {
      throw new NotFoundException('Package not found or you do not have permission.');
    }
  }

  async validatePackageBookingDate(packageId: string, bookingDate: Date): Promise<boolean> {
    const pkg = await this.getPackageById(packageId);
    
    const startDate = new Date(pkg.startDate);
    const endDate = new Date(pkg.endDate);
    
    startDate.setHours(0, 0, 0, 0);
    endDate.setHours(23, 59, 59, 999);
    bookingDate.setHours(0, 0, 0, 0);

    if (bookingDate < startDate || bookingDate > endDate) {
      throw new BadRequestException(
        `Booking date must be within package validity period (${startDate.toDateString()} - ${endDate.toDateString()})`
      );
    }

    return true;
  }

  /**
 * Get active packages with their service details populated
 * Useful for frontend display
 */
async getActivePackagesWithDetails(): Promise<any[]> {
  const now = new Date();
  const packages = await this.packageModel.find({
    isActive: true,
    startDate: { $lte: now },
    endDate: { $gte: now }
  }).exec();

  // Populate service details
  const packagesWithDetails = await Promise.all(
    packages.map(async (pkg) => {
      const serviceIds = pkg.services.map(s => s.serviceId);
      const services = await this.serviceModel.find({ 
        _id: { $in: serviceIds } 
      }).select('serviceName bookingType images availableHours workingDays').exec();

      return {
        ...pkg.toObject(),
        servicesDetails: services.map(svc => ({
          serviceId: svc._id,
          serviceName: svc.serviceName,
          bookingType: svc.bookingType,
          image: svc.images?.[0],
          availableHours: svc.availableHours,
          workingDays: svc.workingDays
        }))
      };
    })
  );

  return packagesWithDetails;
}
}