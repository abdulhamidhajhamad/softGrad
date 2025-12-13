// package.service.ts
import { Injectable, Logger, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose'; // ✅ تم فصل الاستيراد
import { Model, Types } from 'mongoose';
import { Package } from './package.entity';
import { CreatePackageDto } from './package.dto';
import { SupabaseStorageService } from '../subbase/supabaseStorage.service'; // 👈 استيراد الخدمة
// 2. ✅ تم تغيير اسم الحقل هنا ليتطابق مع ServiceSchema
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
    private supabaseService: SupabaseStorageService, // 👈 حقن الخدمة  
  ) {}

 /**
   * إنشاء باقة جديدة لـ Vendor (محدثة لاستقبال الصورة)
   * @param vendorId معرف المستخدم (الـ Vendor) من التوكن
   * @param dto بيانات الباقة
   * @param file ملف الصورة (اختياري)
   * @returns الباقة التي تم إنشاؤها
   */
  async createPackage(
    vendorId: string, 
    dto: CreatePackageDto,
    file?: Express.Multer.File,
  ): Promise<Package> {
    let imageUrl: string | undefined;

    try {
      if (file) {
        // 🚀 رفع الصورة إلى Supabase في مجلد 'packages'
        // 'packages' 👈  هنا نحدد اسم المجلد المطلوب
        imageUrl = await this.supabaseService.uploadImage(file, 'packages'); 
        this.logger.debug(`Image uploaded successfully to 'packages' folder: ${imageUrl}`);
      }
      
      // ... (بناء كائن newPackage وحفظه)
      const vendorObjectId = new Types.ObjectId(vendorId);
      
      const newPackage = new this.packageModel({
        packageName: dto.packageName,
        description: dto.description, // 🟢 الإضافة الجديدة هنا
        vendorId: vendorObjectId,
        serviceIds: dto.serviceIds.map(id => new Types.ObjectId(id)), 
        newPrice: dto.newPrice,
        startDate: new Date(dto.startDate),
        endDate: new Date(dto.endDate),
        packageImageUrl: imageUrl, 
      });
      
      const savedPackage = await newPackage.save();
      return savedPackage;
      
    } catch (error) {
      this.logger.error(`Error creating package or uploading image: ${error.message}`);
      
      // ⚠️ تنظيف: محاولة حذف الصورة من Supabase إذا فشل حفظ الباقة في الداتابيس
      if (imageUrl) {
        this.supabaseService.deleteFile(imageUrl).catch(err => {
            this.logger.error(`Failed to cleanup Supabase file after DB failure: ${err.message}`);
        });
      }
      
      throw error;
    }
  }

  /**
   * 🆕 دالة جلب الباقات للمستخدم (Vendor) مع أسماء الخدمات
   */
 async getVendorPackages(vendorId: string): Promise<any[]> {
    const vendorObjectId = new Types.ObjectId(vendorId);
    
    // 1. جلب الباقات
    const packages = await this.packageModel
      .find({ vendorId: vendorObjectId })
      .lean()
      .exec();

    if (!packages || packages.length === 0) {
      return [];
    }

    // 2. جمع جميع Service IDs الفريدة
    const allServiceIds = packages.flatMap(pkg => pkg.serviceIds);
    const uniqueServiceIds = [...new Set(allServiceIds.map(id => id.toString()))];
    
    // 3. جلب أسماء الخدمات المقابلة لـ IDs
    const services = await this.serviceModel
      .find({ _id: { $in: uniqueServiceIds } })
      .select('serviceName') 
      .lean()
      .exec();
      
    // تحويل الخدمات إلى خريطة ID -> Name لسرعة البحث
    const serviceNameMap = services.reduce((map, service) => {
      map[service._id.toString()] = service.serviceName; 
      return map;
    }, {});
    
    // 4. بناء الرد المطلوب (بما في ذلك السعر ورابط الصورة)
    return packages.map(pkg => ({
      _id: pkg._id.toString(), 
      packageName: pkg.packageName,
      description: pkg.description, // 🟢 إضافة الوصف هنا للـ Vendor  
      newPrice: pkg.newPrice,
      packageImageUrl: pkg.packageImageUrl, // 🟢 الإضافة الجديدة هنا
      serviceNames: pkg.serviceIds
        .map(id => serviceNameMap[id.toString()])
        .filter(name => name)
    }));
  }
  
  /**
   * 🆕 دالة حذف الباقة بواسطة ID والتحقق من الملكية
   */
  async deletePackage(packageId: string, vendorId: string): Promise<{ deletedCount: number }> {
    if (!Types.ObjectId.isValid(packageId)) {
      throw new NotFoundException('Invalid Package ID');
    }
    
    const result = await this.packageModel.deleteOne({ 
      _id: new Types.ObjectId(packageId),
      vendorId: new Types.ObjectId(vendorId) // التأكد من أن البائع هو المالك قبل الحذف
    }).exec();

    if (result.deletedCount === 0) {
      // إذا لم يتم حذف أي شيء، فإما أن الـ ID خطأ أو أن المستخدم ليس المالك
      throw new ForbiddenException('Package not found or access denied.');
    }

    return { deletedCount: result.deletedCount };
  }

}