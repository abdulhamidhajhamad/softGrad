import { Injectable, HttpException, HttpStatus, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose'; 
import { Model, Types } from 'mongoose'; 

// 🚨 التصحيح 1: تأكد من استيراد Service من ملف service.schema
import { Service, BookingType, PayType } from './service.schema'; 
// التصحيح 2: تأكد من استيراد DTOs
import { CreateServiceDto, UpdateServiceDto, PricingOptionsDto } from './service.dto'; 
import { SupabaseStorageService } from '../subbase/supabaseStorage.service';

// 🚨 التصحيح 3: تأكد من صحة مسار ملف ServiceProvider (من provider.entity)
// بناءً على ملفاتك السابقة، المسار الصحيح هو '../provider/provider.entity'
import { ServiceProvider } from '../providers/provider.entity'; 

@Injectable()
export class ServiceService {
  private readonly logger = new Logger(ServiceService.name);
  constructor(
    @InjectModel(Service.name) private serviceModel: Model<Service>,
    @InjectModel(ServiceProvider.name) private providerModel: Model<ServiceProvider>, // تم تغيير ترتيب الحقن
    private supabaseStorage: SupabaseStorageService,
  ) {}

  // 1. جلب جميع الخدمات
  async getAllServices(): Promise<Service[]> {
    try {
      return await this.serviceModel.find().exec();
    } catch (error) {
      this.logger.error('Failed to fetch services', error.stack);
      throw new HttpException('Failed to fetch services', HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }

  // 2. إنشاء خدمة جديدة (تم التعديل للتعامل مع Price Object)
  async createService(
    providerId: string, 
    createServiceDto: CreateServiceDto,
    files?: Express.Multer.File[] 
  ): Promise<Service> {
    try {
      // 🆕 معالجة الـ Price Object
      if (typeof createServiceDto.price === 'string') {
        try {
            createServiceDto.price = JSON.parse(createServiceDto.price as string) as PricingOptionsDto;
        } catch (e) {
            const singlePrice = parseFloat(createServiceDto.price as string);
            if (!isNaN(singlePrice)) {
                createServiceDto.price = { basePrice: singlePrice } as PricingOptionsDto;
            } else {
                createServiceDto.price = {} as PricingOptionsDto;
            }
        }
      }

      // 🆕 1. جلب اسم الشركة من نموذج المزود (ServiceProvider)
      const provider = await this.providerModel
.findOne({ userId: new Types.ObjectId(providerId) }) // 🚨 تحويل providerId إلى ObjectId          .select('companyName')
          .exec();

      if (!provider || !provider.companyName) {
          throw new HttpException(
              'Service Provider profile not found or company name is missing. Please complete your vendor profile.',
              HttpStatus.BAD_REQUEST
          );
      }
      
      const companyName = provider.companyName;
      this.logger.log(`🏢 Fetched company name for service provider ${providerId}: ${companyName}`);
      
      // 🚨 تم تصحيح الخطأ: تم إزالة التعريف المكرر للمتغير existingService
      const existingService = await this.serviceModel.findOne({ 
        serviceName: createServiceDto.serviceName,
        providerId 
      });

      if (existingService) {
        throw new HttpException('Service with this name already exists for this provider', HttpStatus.CONFLICT);
      }
      
      let imageUrls: string[] = [];
      if (files && files.length > 0) {
        try {
          const uploadPromises = files.map(file => 
            this.supabaseStorage.uploadImage(file, 'services', true)
          );
          imageUrls = await Promise.all(uploadPromises);
        } catch (uploadError) {
          this.logger.error('Failed to upload service images:', uploadError);
        }
      }

      const newServiceData = {
        providerId,
        companyName, // ⬅️ استخدام companyName الذي تم جلبه
        ...createServiceDto,
        images: imageUrls,
        reviews: [],
        rating: createServiceDto.rating || 0
      };

      const newService = new this.serviceModel(newServiceData);
      const savedService = await newService.save();
      
      const responseService = await this.serviceModel
        .findById(savedService._id)
        .select('-reviews -bookedDates -rating -aiAnalysis')
        .exec();

      return responseService || savedService;
      
    } catch (error) {
      this.logger.error('💥 ERROR in createService:', error.stack);
      if (error instanceof HttpException) throw error;
      throw new HttpException(error.message || 'Failed to create service', HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }

  // 3. تحديث خدمة بالـ ID (تم التعديل للتعامل مع Price Object وتصحيح العودة)
  async updateServiceById(
    serviceId: string, 
    providerId: string,
    updateServiceDto: UpdateServiceDto,
    files?: Express.Multer.File[] 
  ): Promise<Service> {
    try {
      // 🆕 معالجة الـ Price Object عند التحديث
      if (updateServiceDto.price && typeof updateServiceDto.price === 'string') {
        try {
             updateServiceDto.price = JSON.parse(updateServiceDto.price as string) as PricingOptionsDto;
        } catch (e) {
             // تجاهل
        }
      }

      const service = await this.serviceModel.findOne({ _id: serviceId, providerId });
      if (!service) {
        throw new HttpException('Service not found or you do not have permission to update it', HttpStatus.NOT_FOUND);
      }

      let finalImageUrls: string[] = service.images || []; 

      if (files && files.length > 0) {
        // حذف الصور القديمة ورفع الجديدة 
        if (service.images && service.images.length > 0) {
            try {
              const deletePromises = service.images.map(imageUrl => 
                this.supabaseStorage.deleteFile(imageUrl) 
              );
              await Promise.all(deletePromises);
            } catch (deleteError) {
              this.logger.error('⚠️ Failed to delete old service images:', deleteError);
            }
        }
        try {
          const uploadPromises = files.map(file => 
            this.supabaseStorage.uploadImage(file, 'services', true)
          );
          finalImageUrls = await Promise.all(uploadPromises); 
        } catch (uploadError) {
          throw new HttpException('Failed to upload new service images', HttpStatus.INTERNAL_SERVER_ERROR);
        }
      }

      const updateData = {
        ...updateServiceDto,
        images: finalImageUrls
      };
      
      const updatedService = await this.serviceModel.findOneAndUpdate(
        { _id: serviceId, providerId }, 
        { $set: updateData },
        { new: true, runValidators: true }
      )
      .select('-reviews -bookedDates -rating -aiAnalysis')
      .exec();

      // 🚨 تصحيح خطأ TS2322: فحص القيمة المرجعة
      if (!updatedService) {
         throw new HttpException('Service not found or update failed unexpectedly', HttpStatus.NOT_FOUND);
      }

      return updatedService;
    } catch (error) {
      this.logger.error('Failed to update service:', error.stack);
      if (error instanceof HttpException) throw error;
      throw new HttpException(error.message || 'Failed to update service', HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }

  // 4. حذف خدمة بالـ ID 
  async deleteServiceById(serviceId: string, providerId: string): Promise<{ message: string }> {
    try {
      const service = await this.serviceModel.findOne({ _id: serviceId, providerId });

      if (!service) {
        throw new HttpException('Service not found or you do not have permission to delete it', HttpStatus.NOT_FOUND);
      }

      if (service.images && service.images.length > 0) {
        try {
          const deletePromises = service.images.map(imageUrl => 
            this.supabaseStorage.deleteFile(imageUrl)
          );
          await Promise.all(deletePromises);
        } catch (deleteError) {
          this.logger.error('❌ Failed to delete service images from Supabase:', deleteError);
        }
      }

      await this.serviceModel.deleteOne({ _id: serviceId, providerId });

      return { message: `Service with ID '${serviceId}' deleted successfully` };
    } catch (error) {
      throw new HttpException(error.message || 'Failed to delete service', error.status || HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }

  // 5. تحديث خدمة بالاسم (تم التعديل لـ Price Object و لإضافة files parameter)
  async updateServiceByName(
    serviceName: string, 
    providerId: string,
    updateServiceDto: UpdateServiceDto,
    files?: Express.Multer.File[] // 🚨 تم إضافة files
  ): Promise<Service> {
    try {
        // 🆕 معالجة الـ Price Object عند التحديث
        if (updateServiceDto.price && typeof updateServiceDto.price === 'string') {
            try { updateServiceDto.price = JSON.parse(updateServiceDto.price as string) as PricingOptionsDto; } catch (e) {}
        }

        const service = await this.serviceModel.findOne({ serviceName, providerId });
        if (!service) {
            throw new HttpException('Service not found or you do not have permission to update it', HttpStatus.NOT_FOUND);
        }
        
        let finalImageUrls: string[] = service.images || []; 

        if (files && files.length > 0) {
            // حذف الصور القديمة ورفع الجديدة
            if (service.images && service.images.length > 0) {
                try {
                  const deletePromises = service.images.map(imageUrl => 
                    this.supabaseStorage.deleteFile(imageUrl) 
                  );
                  await Promise.all(deletePromises);
                } catch (deleteError) {
                  this.logger.error('⚠️ Failed to delete old service images:', deleteError);
                }
            }
            try {
              const uploadPromises = files.map(file => 
                this.supabaseStorage.uploadImage(file, 'services', true)
              );
              finalImageUrls = await Promise.all(uploadPromises); 
            } catch (uploadError) {
              throw new HttpException('Failed to upload new service images', HttpStatus.INTERNAL_SERVER_ERROR);
            }
        }
        
        const updateData = {
            ...updateServiceDto,
            images: finalImageUrls
        };
        
        const updatedService = await this.serviceModel.findOneAndUpdate(
            { serviceName: serviceName, providerId },
            { $set: updateData },
            { new: true, runValidators: true }
        ).select('-reviews -bookedDates -rating -aiAnalysis').exec();

        if (!updatedService) {
            throw new HttpException('Service not found or update failed unexpectedly', HttpStatus.NOT_FOUND);
        }
        return updatedService;
    } catch (error) {
        if (error instanceof HttpException) throw error;
        throw new HttpException('Failed to update service by name', HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }

  // 6. حذف خدمة بالاسم
  async deleteServiceByName(serviceName: string, providerId: string): Promise<{ message: string }> {
    try {
        const service = await this.serviceModel.findOne({ serviceName, providerId });

        if (!service) {
            throw new HttpException('Service not found or you do not have permission to delete it', HttpStatus.NOT_FOUND);
        }

        if (service.images && service.images.length > 0) {
            try {
              const deletePromises = service.images.map(imageUrl => this.supabaseStorage.deleteFile(imageUrl));
              await Promise.all(deletePromises);
            } catch (deleteError) {
              this.logger.error('❌ Failed to delete service images from Supabase:', deleteError);
            }
        }
        await this.serviceModel.deleteOne({ serviceName, providerId });

        return { message: `Service '${serviceName}' deleted successfully` };
    } catch (error) {
        throw new HttpException(error.message || 'Failed to delete service', error.status || HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }

  // 7. جلب خدمات المورد بالـ Provider ID (مطابقة لـ getServicesByVendorId في الـ Controller)
  async getServicesByVendor(providerId: string): Promise<Service[]> {
    try {
        return await this.serviceModel.find({ providerId }).exec();
    } catch (error) {
        throw new HttpException('Failed to fetch vendor services', HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }
  
  // 8. جلب خدمات المورد بالـ Company Name (🚨 تم استرجاع هذه الدالة)
  async getServicesByVendorName(companyName: string): Promise<Service[]> {
    try {
        const services = await this.serviceModel.find({ companyName: { $regex: companyName, $options: 'i' } }).exec();
        if (!services || services.length === 0) {
             throw new HttpException( `No services found for vendor '${companyName}'`, HttpStatus.NOT_FOUND );
        }
        return services;
    } catch (error) {
        throw new HttpException( error.message || 'Failed to fetch vendor services', error.status || HttpStatus.INTERNAL_SERVER_ERROR );
    }
  }

  // 9. دالة البحث الشامل (تم التعديل لدعم منطق الأسعار الجديدة ونوع الحجز)
  async searchServices(filters: any): Promise<Service[]> {
    try {
      let query: any = {};

      if (filters.city) {
        query['location.city'] = { $regex: filters.city, $options: 'i' };
      }

      // 🆕 منطق فلترة السعر الجديد: البحث في جميع حقول الأسعار الممكنة
      if (filters.priceRange) {
        const { min, max } = filters.priceRange;
        query['$or'] = [
            { 'price.perHour': { $gte: min, $lte: max } },
            { 'price.perDay': { $gte: min, $lte: max } },
            { 'price.perPerson': { $gte: min, $lte: max } },
            { 'price.fullVenue': { $gte: min, $lte: max } },
            { 'price.basePrice': { $gte: min, $lte: max } }
        ];
        if (query['$or'].length === 0) delete query['$or'];
      }

      if (filters.category) {
        query.category = { $regex: filters.category, $options: 'i' };
      }
      if (filters.serviceName) {
        query.serviceName = { $regex: filters.serviceName, $options: 'i' };
      }
      // 🆕 فلترة حسب نوع الحجز المطلوب
      if (filters.bookingType) {
        query.bookingType = filters.bookingType; 
      }
      if (filters.aiTags && Array.isArray(filters.aiTags) && filters.aiTags.length > 0) { 
         query['aiAnalysis.tags'] = { $in: filters.aiTags };
      }
      
      let services = await this.serviceModel.find(query).exec();
      
      // معالجة فلترة الموقع بناءً على المسافة
      if (filters.location && filters.location.lat && filters.location.lng && filters.location.radius) {
         const { lat, lng, radius } = filters.location;
         services = services.filter(service => {
            const distance = this.calculateDistance(lat, lng, service.location.latitude, service.location.longitude);
            return distance <= radius;
         });
      }

      return services;
    } catch (error) {
      this.logger.error('Failed to search services:', error.stack);
      throw new HttpException(error.message || 'Failed to search services', HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }

  // 10. دالة جلب خدمات بالـ Category (🚨 تم استرجاع هذه الدالة)
  async getServicesByCategory(category: string): Promise<Service[]> {
    try {
        const services = await this.serviceModel.find({ category: { $regex: category, $options: 'i' } }).exec();
        if (!services || services.length === 0) {
            throw new HttpException( `No services found in category '${category}'`, HttpStatus.NOT_FOUND );
        }
        return services;
    } catch (error) {
        throw new HttpException( error.message || 'Failed to fetch services by category', error.status || HttpStatus.INTERNAL_SERVER_ERROR );
    }
  }

  // 11. دالة جلب تفاصيل الخدمة ID (تم التعديل للحقول الجديدة)
  async getServiceById(serviceId: string): Promise<any> {
    try {
      const service = await this.serviceModel
        .findById(serviceId)
        .select('serviceName category location.city price additionalInfo bookingType externalLink images') 
        .exec();

      if (!service) throw new HttpException('Service not found', HttpStatus.NOT_FOUND);

      const serviceObject = service.toObject();
      return {
          ...serviceObject,
          description: serviceObject.additionalInfo, 
          externalLink: serviceObject.externalLink || null 
      };
      
    } catch (error) {
      this.logger.error(`Failed to fetch service with ID ${serviceId}: ${error.stack}`);
      throw new HttpException('Failed to fetch service', HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }

  // 12. دالة جلب تفاصيل خدمات الفيندور (تم التعديل للحقول الجديدة)
  async getVendorServicesDetails(providerId: string): Promise<any[]> {
    try {
        const services = await this.serviceModel
            .find({ providerId: providerId })
            .select('_id serviceName price bookingType') 
            .lean() 
            .exec();

        return services.map(service => ({
            _id: service._id.toString(),
            name: service.serviceName, 
            price: service.price, 
            bookingType: service.bookingType
        }));

    } catch (error) {
        this.logger.error(`Failed to fetch services for provider ${providerId}: ${error.stack}`);
        throw new HttpException('Failed to fetch vendor services details', HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }
  
  // دالة مساعدة لحساب المسافة (كيلومتر)
  private calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371; 
    const dLat = this.deg2rad(lat2 - lat1);
    const dLon = this.deg2rad(lon2 - lon1);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this.deg2rad(lat1)) * Math.cos(this.deg2rad(lat2)) *
      Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }
  private deg2rad(deg: number): number { return deg * (Math.PI / 180); }
}