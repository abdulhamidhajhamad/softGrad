// package.service.ts
import { Injectable, Logger, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Package } from './package.entity';
import { CreatePackageDto } from './package.dto';
import { SupabaseStorageService } from '../subbase/supabaseStorage.service';

interface IService {
  _id: Types.ObjectId;
  serviceName: string; 
}

@Injectable()
export class PackageService {
  private readonly logger = new Logger(PackageService.name);

  constructor(  
    @InjectModel(Package.name) private packageModel: Model<Package>,
    @InjectModel('Service') private serviceModel: Model<IService>,
    private supabaseService: SupabaseStorageService,
  ) {}

  async createPackage(
    vendorId: string, 
    dto: CreatePackageDto,
    file?: Express.Multer.File,
  ): Promise<Package> {
    let imageUrl: string | undefined;

    try {
      if (file) {
        imageUrl = await this.supabaseService.uploadImage(file, 'packages'); 
        this.logger.debug(`Image uploaded successfully to 'packages' folder: ${imageUrl}`);
      }
      
      const vendorObjectId = new Types.ObjectId(vendorId);
      
      const newPackage = new this.packageModel({
        packageName: dto.packageName,
        description: dto.description,
        vendorId: vendorObjectId,
        serviceIds: dto.serviceIds.map(id => new Types.ObjectId(id)), 
        newPrice: dto.newPrice,
        startDate: new Date(dto.startDate),
        endDate: new Date(dto.endDate),
        packageImageUrl: imageUrl,
        isActive: true, // ✅ افتراضياً true عند الإنشاء
      });
      
      const savedPackage = await newPackage.save();
      return savedPackage;
      
    } catch (error) {
      this.logger.error(`Error creating package or uploading image: ${error.message}`);
      
      if (imageUrl) {
        this.supabaseService.deleteFile(imageUrl).catch(err => {
            this.logger.error(`Failed to cleanup Supabase file after DB failure: ${err.message}`);
        });
      }
      
      throw error;
    }
  }

  async getVendorPackages(vendorId: string): Promise<any[]> {
    const vendorObjectId = new Types.ObjectId(vendorId);
    
    const packages = await this.packageModel
      .find({ vendorId: vendorObjectId })
      .lean()
      .exec();

    if (!packages || packages.length === 0) {
      return [];
    }

    const allServiceIds = packages.flatMap(pkg => pkg.serviceIds);
    const uniqueServiceIds = [...new Set(allServiceIds.map(id => id.toString()))];
    
    const services = await this.serviceModel
      .find({ _id: { $in: uniqueServiceIds } })
      .select('serviceName') 
      .lean()
      .exec();
      
    const serviceNameMap = services.reduce((map, service) => {
      map[service._id.toString()] = service.serviceName; 
      return map;
    }, {});
    
    // ✅ نتأكد من إرجاع isActive مع البيانات
    return packages.map(pkg => ({
      _id: pkg._id.toString(), 
      packageName: pkg.packageName,
      description: pkg.description,
      newPrice: pkg.newPrice,
      startDate: pkg.startDate,
      endDate: pkg.endDate,
      packageImageUrl: pkg.packageImageUrl,
      isActive: pkg.isActive ?? true, // ✅ إذا مش موجود، نرجع true
      serviceIds: pkg.serviceIds.map(id => id.toString()), // ✅ مهم للتعديل
      serviceNames: pkg.serviceIds
        .map(id => serviceNameMap[id.toString()])
        .filter(name => name)
    }));
  }
  
  async deletePackage(packageId: string, vendorId: string): Promise<{ deletedCount: number }> {
    if (!Types.ObjectId.isValid(packageId)) {
      throw new NotFoundException('Invalid Package ID');
    }
    
    const result = await this.packageModel.deleteOne({ 
      _id: new Types.ObjectId(packageId),
      vendorId: new Types.ObjectId(vendorId)
    }).exec();

    if (result.deletedCount === 0) {
      throw new ForbiddenException('Package not found or access denied.');
    }

    return { deletedCount: result.deletedCount };
  }

  async getPackageById(packageId: string, vendorId: string): Promise<any> {
    const vendorObjectId = new Types.ObjectId(vendorId);
    const packageObjectId = new Types.ObjectId(packageId);
    
    const pkg = await this.packageModel
      .findOne({ _id: packageObjectId, vendorId: vendorObjectId })
      .lean()
      .exec();

    if (!pkg) {
      throw new NotFoundException('Package not found or access denied');
    }

    return pkg;
  }

  async updatePackage(
    packageId: string,
    vendorId: string,
    dto: CreatePackageDto,
  ): Promise<Package> {
    const vendorObjectId = new Types.ObjectId(vendorId);
    const packageObjectId = new Types.ObjectId(packageId);

    const updatedPackage = await this.packageModel.findOneAndUpdate(
      { _id: packageObjectId, vendorId: vendorObjectId },
      {
        packageName: dto.packageName,
        description: dto.description,
        serviceIds: dto.serviceIds.map(id => new Types.ObjectId(id)),
        newPrice: dto.newPrice,
        startDate: new Date(dto.startDate),
        endDate: new Date(dto.endDate),
      },
      { new: true }
    ).exec();

    if (!updatedPackage) {
      throw new NotFoundException('Package not found or access denied');
    }

    return updatedPackage;
  }

  async updatePackageStatus(
    packageId: string,
    vendorId: string,
    isActive: boolean,
  ): Promise<Package> {
    const vendorObjectId = new Types.ObjectId(vendorId);
    const packageObjectId = new Types.ObjectId(packageId);

    this.logger.log(`Updating package ${packageId} status to: ${isActive}`); // ✅ للتتبع

    const updatedPackage = await this.packageModel.findOneAndUpdate(
      { _id: packageObjectId, vendorId: vendorObjectId },
      { isActive },
      { new: true } // ✅ مهم جداً: يرجع الوثيقة المحدثة
    ).exec();

    if (!updatedPackage) {
      throw new NotFoundException('Package not found or access denied');
    }

    this.logger.log(`Package updated successfully. New isActive value: ${updatedPackage.isActive}`); // ✅ للتأكد

    return updatedPackage;
  }


  /**
   * جلب عدد محدد من روابط صور الباقات النشطة بشكل عشوائي.
   * @param count العدد المطلوب من الصور (افتراضياً 10).
   */
  async getShuffledPackageImages(count: number = 10): Promise<string[]> {
    const randomImages = await this.packageModel.aggregate([
      // 1. تصفية الباقات النشطة، والتي لم تنتهِ صلاحيتها، والتي تحتوي على صور
      { $match: { 
          isActive: true, 
          endDate: { $gt: new Date() },
         packageImageUrl: { $nin: [null, '', undefined] }
        } 
      }, 
      // 2. اختيار عينة عشوائية بالحجم المطلوب
      { $sample: { size: count } },
      // 3. عرض حقل packageImageUrl فقط
      { $project: {
          _id: 0, // لا نحتاج المعرّف
          packageImageUrl: 1,
        }
      }
    ]).exec();
    
    // 4. استخراج الروابط كـ Array of strings (ليكون أسهل لـ Flutter)
    return randomImages.map(item => item.packageImageUrl);
  }
} 