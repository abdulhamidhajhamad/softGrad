// package.service.ts
import { Injectable, NotFoundException, BadRequestException, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Package } from './package.entity';
import { Service } from '../service/service.schema';
import { CreatePackageDto, UpdatePackageDto, UpdatePackageStatusDto } from './package.dto';
import { ServiceProvider } from '../providers/provider.entity';
import { SupabaseStorageService } from '../subbase/supabaseStorage.service';

@Injectable()
export class PackageService {
  private readonly logger = new Logger(PackageService.name);

  constructor(
    @InjectModel(Package.name) private packageModel: Model<Package>,
    @InjectModel(Service.name) private serviceModel: Model<Service>,
    @InjectModel(ServiceProvider.name) private providerModel: Model<ServiceProvider>,
    private supabaseStorage: SupabaseStorageService, // ✅ إضافة Supabase
  ) {}

 // package.service.ts - Updated createPackage with category and image upload

async createPackage(
  providerId: string, 
  createPackageDto: CreatePackageDto,
  coverImage?: Express.Multer.File // ✅ صورة الغلاف اختيارية
): Promise<Package> {
  const provider = await this.providerModel
    .findOne({ userId: new Types.ObjectId(providerId) })
    .select('companyName location') // ✅ جلب location أيضاً
    .exec();

  if (!provider || !provider.companyName) {
    throw new BadRequestException('Provider profile not found or company name is missing.');
  }

  // ✅ رفع صورة الغلاف إذا وجدت
  let packageImageUrl: string | undefined;
  if (coverImage) {
    try {
      packageImageUrl = await this.supabaseStorage.uploadImage(coverImage, 'packages', true);
      this.logger.log(`📤 Package cover image uploaded: ${packageImageUrl}`);
    } catch (uploadError) {
      this.logger.error('⚠️ Failed to upload package cover image:', uploadError);
    }
  }

  let originalTotal = 0;
  const serviceItems: any[] = [];
  const serviceIds = createPackageDto.services.map(s => s.serviceId);

  // ✅ جلب الخدمات مع category و bookingType
  const existingServices = await this.serviceModel.find({ 
    _id: { $in: serviceIds } 
  }).select('_id serviceName category bookingType price priceOptions hasFixedLocation workingDays availableHours minBookingHours maxBookingHours').exec();

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
      category: service.category, // ✅ إضافة category
      bookingType: service.bookingType, // ✅ إضافة bookingType
      originalPrice: originalPrice,
      newPrice: newPrice,
      // 🆕 معلومات إضافية من السيرفس الأصلية
      hasFixedLocation: service.hasFixedLocation ?? true,
      workingDays: service.workingDays || [],
      availableHours: service.availableHours || [],
      minBookingHours: service.minBookingHours,
      maxBookingHours: service.maxBookingHours,
      ...(itemDto.maxHours && { maxHours: itemDto.maxHours }),
      ...(itemDto.maxCapacity && { maxCapacity: itemDto.maxCapacity }),
    };

    serviceItems.push(packageServiceItem);
  }

  const createdPackage = new this.packageModel({
    providerId: providerId,
    companyName: provider.companyName,
    city: provider.location?.city || 'Unknown', // ✅ إضافة city
    packageName: createPackageDto.packageName,
    description: createPackageDto.description,
    services: serviceItems,
    originalTotalPrice: originalTotal,
    newPrice: createPackageDto.newPrice,
    startDate: createPackageDto.startDate,
    endDate: createPackageDto.endDate,
    packageImageUrl: packageImageUrl || createPackageDto.packageImageUrl, // ✅ استخدام الصورة المرفوعة أو URL
    isActive: true,
  });

  return createdPackage.save();
}



  async updatePackage(
    packageId: string,
    providerId: string,
    updateDto: UpdatePackageDto,
    coverImage?: Express.Multer.File // ✅ صورة غلاف جديدة اختيارية
  ): Promise<Package> {
    const pkg = await this.packageModel.findOne({
      _id: new Types.ObjectId(packageId),
      providerId: providerId
    }).exec();

    if (!pkg) {
      throw new NotFoundException('Package not found or you do not have permission.');
    }

    // ✅ رفع صورة غلاف جديدة إذا وجدت
    if (coverImage) {
      try {
        // حذف الصورة القديمة إذا وجدت
        if (pkg.packageImageUrl) {
          try {
            await this.supabaseStorage.deleteFile(pkg.packageImageUrl);
            this.logger.log(`🗑️ Deleted old package cover image`);
          } catch (deleteError) {
            this.logger.error('⚠️ Failed to delete old cover image:', deleteError);
          }
        }
        // رفع الصورة الجديدة
        const newImageUrl = await this.supabaseStorage.uploadImage(coverImage, 'packages', true);
        pkg.packageImageUrl = newImageUrl;
        this.logger.log(`📤 New package cover image uploaded: ${newImageUrl}`);
      } catch (uploadError) {
        this.logger.error('⚠️ Failed to upload new cover image:', uploadError);
      }
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
          category: service.category,
          bookingType: service.bookingType,
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
    // ✅ يمكن تحديث URL الصورة مباشرة أيضاً (بدون رفع ملف)
    if (updateDto.packageImageUrl !== undefined) pkg.packageImageUrl = updateDto.packageImageUrl;

    return await pkg.save();
  }

  async getProviderPackages(providerId: string): Promise<Package[]> {
    return await this.packageModel.find({ providerId }).exec();
  }

// package.service.ts - FIXED TypeScript errors

async getActivePackages(): Promise<any[]> {
  const now = new Date();
  const packages = await this.packageModel.find({
    isActive: true,
    startDate: { $lte: now },
    endDate: { $gte: now }
  }).exec();

  const packagesWithDetails = await Promise.all(
    packages.map(async (pkg) => {
      const serviceIds = pkg.services.map(s => s.serviceId);
      
      // ✅ جلب جميع البيانات المطلوبة من السيرفس الأصلية
      const services = await this.serviceModel.find({ 
        _id: { $in: serviceIds } 
      }).select('_id bookingType category hasFixedLocation workingDays availableHours minBookingHours maxBookingHours').exec();

      const enrichedServices = pkg.services.map(pkgService => {
        const fullService = services.find(
          // ✅ FIX: استخدم as any لتجنب خطأ TypeScript
          s => (s._id as any).toString() === pkgService.serviceId.toString()
        );

        return {
          serviceId: pkgService.serviceId.toString(),
          serviceName: pkgService.serviceName,
          category: pkgService.category || fullService?.category || 'General', // ✅ استخدم category من Package أو Service
          bookingType: fullService?.bookingType || 'display',
          originalPrice: pkgService.originalPrice,
          newPrice: pkgService.newPrice,
          maxHours: pkgService.maxHours,
          maxCapacity: pkgService.maxCapacity,
          // 🆕 معلومات إضافية من السيرفس الأصلية
          hasFixedLocation: fullService?.hasFixedLocation ?? true,
          workingDays: fullService?.workingDays || [],
          availableHours: fullService?.availableHours || [],
          minBookingHours: fullService?.minBookingHours,
          maxBookingHours: fullService?.maxBookingHours,
        };
      });

      return {
        // ✅ FIX: استخدم as any لتجنب خطأ TypeScript
        _id: (pkg._id as any).toString(),
        packageName: pkg.packageName,
        companyName: pkg.companyName,
        city: pkg.city || 'Unknown', // ✅ استخدم city من Package
        startDate: pkg.startDate,
        endDate: pkg.endDate,
        categories: [...new Set(enrichedServices.map(s => s.category))], // ✅ categories فريدة
        services: enrichedServices,
        imageUrl: pkg.packageImageUrl,
        isActive: pkg.isActive,
      };
    })
  );

  return packagesWithDetails;
}

// ✅ FIX: getPackageById with same fixes
async getPackageById(packageId: string): Promise<any> {
  const pkg = await this.packageModel.findById(packageId).exec();
  if (!pkg) {
    throw new NotFoundException('Package not found');
  }

  const serviceIds = pkg.services.map(s => s.serviceId);
  // ✅ جلب جميع البيانات المطلوبة من السيرفس الأصلية
  const services = await this.serviceModel.find({ 
    _id: { $in: serviceIds } 
  }).select('_id bookingType category hasFixedLocation workingDays availableHours minBookingHours maxBookingHours').exec();

  const enrichedServices = pkg.services.map(pkgService => {
    const fullService = services.find(
      // ✅ FIX: as any
      s => (s._id as any).toString() === pkgService.serviceId.toString()
    );

    return {
      serviceId: pkgService.serviceId.toString(),
      serviceName: pkgService.serviceName,
      category: pkgService.category || fullService?.category || 'General',
      bookingType: fullService?.bookingType || 'display',
      originalPrice: pkgService.originalPrice,
      newPrice: pkgService.newPrice,
      maxHours: pkgService.maxHours,
      maxCapacity: pkgService.maxCapacity,
      // 🆕 معلومات إضافية من السيرفس الأصلية
      hasFixedLocation: fullService?.hasFixedLocation ?? true,
      workingDays: fullService?.workingDays || [],
      availableHours: fullService?.availableHours || [],
      minBookingHours: fullService?.minBookingHours,
      maxBookingHours: fullService?.maxBookingHours,
    };
  });

  return {
    // ✅ FIX: as any
    _id: (pkg._id as any).toString(),
    packageName: pkg.packageName,
    companyName: pkg.companyName,
    city: pkg.city || 'Unknown',
    startDate: pkg.startDate,
    endDate: pkg.endDate,
    categories: [...new Set(enrichedServices.map(s => s.category))],
    services: enrichedServices,
    imageUrl: pkg.packageImageUrl,
    isActive: pkg.isActive,
  };
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

  /**
   * Get random packages for homepage display
   * Returns 5 random active packages with formatted data
   */
  async getRandomPackagesForHome(limit: number = 5): Promise<any[]> {
    const now = new Date();
    
    const packages = await this.packageModel.aggregate([
      { 
        $match: { 
          isActive: true,
          startDate: { $lte: now },
          endDate: { $gte: now }
        } 
      },
      { $sample: { size: limit } },
      {
        $project: {
          _id: 1,
          packageName: 1,
          companyName: 1,
          packageImageUrl: 1,
          newPrice: 1,
          originalTotalPrice: 1,
          startDate: 1,
          endDate: 1,
          services: 1,
        }
      }
    ]).exec();

    return packages.map(pkg => ({
      id: pkg._id.toString(),
      title: pkg.packageName,
      company: pkg.companyName || 'Unknown',
      imageUrl: pkg.packageImageUrl || '',
      price: pkg.newPrice || 0,
      originalPrice: pkg.originalTotalPrice || pkg.newPrice || 0,
      validity: pkg.endDate ? `Valid until ${new Date(pkg.endDate).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}` : '',
      services: (pkg.services || []).map((s: any) => s.serviceName || 'Service'),
    }));
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