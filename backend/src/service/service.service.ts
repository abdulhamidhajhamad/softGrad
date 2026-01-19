import { Injectable, HttpException, HttpStatus, Logger, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose'; 
import { Model, Types } from 'mongoose'; 

import { Service, BookingType, PayType } from './service.schema'; 
import { CreateServiceDto, UpdateServiceDto } from './service.dto'; 
import { SupabaseStorageService } from '../subbase/supabaseStorage.service';
import { ServiceProvider } from '../providers/provider.entity'; 
import { Review } from '../review/review.schema';

@Injectable()
export class ServiceService {
  private readonly logger = new Logger(ServiceService.name);
  
constructor(
  @InjectModel(Service.name) private serviceModel: Model<Service>,
  @InjectModel(ServiceProvider.name) private providerModel: Model<ServiceProvider>,
  @InjectModel(Review.name) private reviewModel: Model<Review>, // ✅ NEW
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

  // 2. إنشاء خدمة جديدة
  async createService(
    providerId: string, 
    createServiceDto: CreateServiceDto,
    files?: Express.Multer.File[] 
  ): Promise<Service> {
    try {
      // ✅ تصحيح الخطأ: التعامل مع السعر كرقم مباشرة وإلغاء JSON.parse
      if (createServiceDto.price) {
        // تحويل القيمة إلى نص أولاً لإرضاء TypeScript ثم تحويلها لرقم
        const priceVal = parseFloat(createServiceDto.price as unknown as string);
        createServiceDto.price = isNaN(priceVal) ? 0 : priceVal;
      }

      // جلب اسم الشركة من نموذج المزود
      const provider = await this.providerModel
        .findOne({ userId: new Types.ObjectId(providerId) })
        .select('companyName')
        .exec();

      if (!provider || !provider.companyName) {
        throw new HttpException(
          'Service Provider profile not found or company name is missing. Please complete your vendor profile.',
          HttpStatus.BAD_REQUEST
        );
      }
      
      const companyName = provider.companyName;
      this.logger.log(`🏢 Fetched company name for service provider ${providerId}: ${companyName}`);
      
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
        companyName,
        ...createServiceDto,
        images: imageUrls,
        reviews: [],
        rating: createServiceDto.rating || 0,
        //  Extract venueType from additionalInfo if present
        venueType: createServiceDto.venueType || createServiceDto.additionalInfo?.venueType,
        //  Persist timeSlots if provided
        timeSlots: createServiceDto.timeSlots || []
      };

      const newService = new this.serviceModel(newServiceData);
      const savedService = await newService.save();
      
      const responseService = await this.serviceModel
        .findById(savedService._id)
        .select('-reviews -rating -aiAnalysis')
        .exec();

      return responseService || savedService;
      
    } catch (error) {
      this.logger.error('💥 ERROR in createService:', error.stack);
      if (error instanceof HttpException) throw error;
      throw new HttpException(error.message || 'Failed to create service', HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }

  // 3. تحديث خدمة بالـ ID
  async updateServiceById(
    serviceId: string, 
    providerId: string,
    updateServiceDto: UpdateServiceDto,
    files?: Express.Multer.File[] 
  ): Promise<Service> {
    try {
      // ✅ تصحيح الخطأ: معالجة السعر في التحديث أيضاً
      if (updateServiceDto.price !== undefined) {
         const priceVal = parseFloat(updateServiceDto.price as unknown as string);
         updateServiceDto.price = isNaN(priceVal) ? undefined : priceVal;
      }

      const service = await this.serviceModel.findOne({ _id: serviceId, providerId });
      if (!service) {
        throw new HttpException('Service not found or you do not have permission to update it', HttpStatus.NOT_FOUND);
      }

      // ✅ Get existing images that frontend wants to keep
      const existingImagesToKeep: string[] = updateServiceDto.images || [];
      
      // ✅ Find images that need to be deleted (old images not in the keep list)
      const currentImages = service.images || [];
      const imagesToDelete = currentImages.filter(img => !existingImagesToKeep.includes(img));
      
      // ✅ Delete removed images from Supabase
      if (imagesToDelete.length > 0) {
        try {
          const deletePromises = imagesToDelete.map(imageUrl => 
            this.supabaseStorage.deleteFile(imageUrl) 
          );
          await Promise.all(deletePromises);
          this.logger.log(`🗑️ Deleted ${imagesToDelete.length} old images`);
        } catch (deleteError) {
          this.logger.error('⚠️ Failed to delete old service images:', deleteError);
        }
      }

      // ✅ Start with images that frontend wants to keep
      let finalImageUrls: string[] = [...existingImagesToKeep];

      // ✅ Upload new images and ADD them to the existing ones
      if (files && files.length > 0) {
        try {
          const uploadPromises = files.map(file => 
            this.supabaseStorage.uploadImage(file, 'services', true)
          );
          const newImageUrls = await Promise.all(uploadPromises);
          finalImageUrls = [...finalImageUrls, ...newImageUrls]; // ✅ Merge old + new
          this.logger.log(`📤 Uploaded ${newImageUrls.length} new images`);
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
      .select('-reviews -rating -aiAnalysis')
      .exec();

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

  // 5. تحديث خدمة بالاسم
  async updateServiceByName(
    serviceName: string, 
    providerId: string,
    updateServiceDto: UpdateServiceDto,
    files?: Express.Multer.File[]
  ): Promise<Service> {
    try {
      // ✅ تصحيح الخطأ: معالجة السعر
      if (updateServiceDto.price !== undefined) {
        const priceVal = parseFloat(updateServiceDto.price as unknown as string);
        updateServiceDto.price = isNaN(priceVal) ? undefined : priceVal;
      }

      const service = await this.serviceModel.findOne({ serviceName, providerId });
      if (!service) {
        throw new HttpException('Service not found or you do not have permission to update it', HttpStatus.NOT_FOUND);
      }
      
      let finalImageUrls: string[] = service.images || []; 

      if (files && files.length > 0) {
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
      ).select('-reviews -rating -aiAnalysis').exec();

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

  // 7. جلب خدمات المورد بالـ Provider ID
  async getServicesByVendor(providerId: string): Promise<Service[]> {
    try {
      return await this.serviceModel.find({ providerId }).exec();
    } catch (error) {
      throw new HttpException('Failed to fetch vendor services', HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }
  
  // 8. جلب خدمات المورد بالـ Company Name
  async getServicesByVendorName(companyName: string): Promise<Service[]> {
    try {
      const services = await this.serviceModel.find({ companyName: { $regex: companyName, $options: 'i' } }).exec();
      if (!services || services.length === 0) {
        throw new HttpException(`No services found for vendor '${companyName}'`, HttpStatus.NOT_FOUND);
      }
      return services;
    } catch (error) {
      throw new HttpException(error.message || 'Failed to fetch vendor services', error.status || HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }

  // 9. دالة البحث الشامل
  async searchServices(filters: any): Promise<Service[]> {
    try {
      let query: any = {};

      if (filters.city) {
        query['location.city'] = { $regex: filters.city, $options: 'i' };
      }

      // ✅ فلترة السعر - بسيطة الآن لأن price أصبح number واحد
      if (filters.priceRange) {
        const { min, max } = filters.priceRange;
        query['price'] = { $gte: min, $lte: max };
      }

      if (filters.category) {
        query.category = { $regex: filters.category, $options: 'i' };
      }
      if (filters.serviceName) {
        query.serviceName = { $regex: filters.serviceName, $options: 'i' };
      }
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

  async getServicesByCategory(category: string): Promise<Service[]> {
    try {
      const services = await this.serviceModel.find({ category: { $regex: category, $options: 'i' } }).exec();
      if (!services || services.length === 0) {
        throw new HttpException(`No services found in category '${category}'`, HttpStatus.NOT_FOUND);
      }
      return services;
    } catch (error) {
      throw new HttpException(error.message || 'Failed to fetch services by category', error.status || HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }

async getServiceById(serviceId: string): Promise<any> {
  try {
    const service = await this.serviceModel.findById(serviceId).lean().exec();

    if (!service) {
      throw new NotFoundException('Service not found');
    }

    const searchId = Types.ObjectId.isValid(service.providerId)
      ? new Types.ObjectId(service.providerId)
      : service.providerId;

    const provider: any = await this.providerModel.findOne({
      $or: [
        { userId: searchId },
        { _id: searchId }
      ]
    }).lean().exec();

    const priceDisplay = service.price ? `${service.price}` : "N/A";

    // ✅ جلب آخر تقييمين من جدول Reviews المنفصل
    const lastTwoReviews = await this.reviewModel
      .find({ serviceId: new Types.ObjectId(serviceId), isVisible: true })
      .sort({ createdAt: -1 })
      .limit(2)
      .select('rating images createdAt comment')
      .lean()
      .exec();

    // ✅ Get company name from service or provider
    const companyName = service.companyName || 
                        provider?.details?.companyName || 
                        provider?.companyName || 
                        provider?.details?.name ||
                        'Unknown';

    return {
      serviceName: service.serviceName,
      companyName: companyName,
      providerId: service.providerId?.toString() || '', // ✅ Added providerId for chat
      bookingType: service.bookingType,
      description: service.description,
      additionalInfo: service.additionalInfo,
      price: priceDisplay,
      payType: service.payType,
      city: service.location?.city || "N/A",
      longitude: service.location?.longitude || null,
      latitude: service.location?.latitude || null,
      hasFixedLocation: service.hasFixedLocation ?? true, // 🆕 إضافة hasFixedLocation
      rating: service.averageRating || 0, // ✅ استخدام averageRating
      totalReviews: service.totalReviews || 0, // ✅ إضافة عدد التقييمات
      
      // ✅ إضافة الصور للـ slider
      images: service.images || [],

      // 🆕 إضافة حقول التحقق من الحجز
      workingDays: service.workingDays || [],
      availableHours: service.availableHours || [],
      minBookingHours: service.minBookingHours || null,
      maxBookingHours: service.maxBookingHours || null,
      maxCapacity: service.maxCapacity || null,
      cleanupTimeMinutes: service.cleanupTimeMinutes || 0,

      lastTwoReviews: lastTwoReviews.map((rev: any) => ({
        rating: rev.rating,
        images: rev.images || [],
        date: rev.createdAt,
        description: rev.comment
      })),

      companyInfo: {
        name: companyName,
        email: provider?.details?.email || provider?.email || "N/A",
        phone: provider?.details?.phone || provider?.phone || "N/A"
      }
    };
  } catch (error) {
    if (error instanceof NotFoundException) throw error;
    this.logger.error(`Error in getServiceById: ${error.message}`);
    throw new HttpException('Error retrieving service details', HttpStatus.INTERNAL_SERVER_ERROR);
  }
}

  // 12. دالة جلب تفاصيل خدمات الفيندور
  async getVendorServicesDetails(providerId: string): Promise<any[]> {
    try {
      const services = await this.serviceModel
        .find({ providerId: providerId })
        .select('_id serviceName price bookingType payType') 
        .lean() 
        .exec();

      return services.map(service => ({
        _id: service._id.toString(),
        name: service.serviceName, 
        price: service.price || 0,
        bookingType: service.bookingType,
        payType: service.payType
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

  async getPaginatedServicesWithDetails(limit: number, page: number): Promise<{ 
    services: any[], 
    totalCount: number 
  }> {
    const skip = (page - 1) * limit;

    const totalCount = await this.serviceModel.countDocuments({ isActive: true }).exec();

    const services = await this.serviceModel.aggregate([
      { $match: { isActive: true } }, 
      { $sort: { createdAt: -1 } }, 
      { $skip: skip },
      { $limit: limit },
      { $project: {
          _id: 1,
          serviceName: 1,
          firstImage: { $arrayElemAt: [{ $ifNull: ['$images', []] }, 0] },
          price: 1, // ✅ السعر الآن number بسيط
          city: '$location.city', 
          companyName: '$companyName',
          reviewCount: { $size: { $ifNull: ['$reviews', []] } }
      }},
      { $project: {
          id: '$_id', 
          serviceName: 1,
          firstImage: 1,
          price: 1,
          city: 1,
          companyName: 1,
          reviewCount: 1,
          _id: 0, 
      }}
    ]).exec();
    
    return { services, totalCount };
  }

  async getHomepageServicesByCategories(): Promise<any> {
    const categories = [
      'Venues', 'Photographers', 'Catering', 'Cake', 
      'Music & Entertainment', 'Wedding Planners', 'Decor & Lighting', 
      'Car Rental', 'Flower Shops', 'Card Printing', 
      'Jewelry & Accessories', 'Gift & Souvenir'
    ];

    const results = {};

    try {
      for (const category of categories) {
        const services = await this.serviceModel.aggregate([
          { $match: { category: category, isActive: true } },
          { $sample: { size: 4 } },
          {
            $project: {
              serviceName: 1,
              companyName: 1,
              firstImage: { $arrayElemAt: ["$images", 0] },
              rating: 1,
              price: 1, // ✅ السعر الآن number بسيط
              city: "$location.city",
              _id: 1
            }
          }
        ]).exec();

        // ✅ تنسيق البيانات - السعر الآن بسيط
        results[category] = services.map(service => ({
          id: service._id,
          serviceName: service.serviceName,
          companyName: service.companyName || "N/A",
          image: service.firstImage || null,
          rating: service.rating || 0,
          price: service.price ? `${service.price}` : "N/A",
          city: service.city || "N/A"
        }));
      }

      return results;
    } catch (error) {
      this.logger.error('Failed to fetch services by categories', error.stack);
      throw new HttpException('Failed to fetch categorised services', HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }

  /**
   * Get random services for homepage display
   * Returns 5 random active services with formatted data for trending section
   */
  async getRandomServicesForHome(limit: number = 5): Promise<any[]> {
    try {
      const services = await this.serviceModel.aggregate([
        { $match: { isActive: true } },
        { $sample: { size: limit } },
        {
          $lookup: {
            from: 'serviceproviders',
            let: { providerId: '$providerId' },
            pipeline: [
              {
                $match: {
                  $expr: {
                    $or: [
                      { $eq: ['$userId', { $toObjectId: '$$providerId' }] },
                      { $eq: ['$_id', { $toObjectId: '$$providerId' }] }
                    ]
                  }
                }
              }
            ],
            as: 'provider'
          }
        },
        { $unwind: { path: '$provider', preserveNullAndEmptyArrays: true } },
        {
          $project: {
            _id: 1,
            serviceName: 1,
            companyName: 1,
            providerId: 1,
            category: 1,
            description: 1,
            price: 1,
            averageRating: 1,
            firstImage: { $arrayElemAt: ['$images', 0] },
            latitude: '$location.latitude',
            longitude: '$location.longitude',
            providerCompanyName: { 
              $ifNull: [
                '$provider.details.companyName', 
                { $ifNull: ['$provider.companyName', '$provider.details.name'] }
              ] 
            },
          }
        }
      ]).exec();

      return services.map(service => ({
        id: service._id.toString(),
        name: service.serviceName || 'Unknown Service',
        company: service.companyName || service.providerCompanyName || 'Unknown',
        providerId: service.providerId?.toString() || '',
        category: service.category || 'General',
        desc: service.description || '',
        price: service.price || 0,
        rating: service.averageRating || 0,
        imageUrl: service.firstImage || '',
        latitude: service.latitude || null,
        longitude: service.longitude || null,
      }));
    } catch (error) {
      this.logger.error('Failed to fetch random services for home', error.stack);
      throw new HttpException('Failed to fetch trending services', HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }

  /**
   * Get all services for browse/search display
   * Returns all active services formatted for SearchResultModel in Flutter
   */
  async getAllServicesForBrowse(): Promise<any[]> {
    try {
      const services = await this.serviceModel.aggregate([
        { $match: { isActive: true } },
        {
          $lookup: {
            from: 'serviceproviders',
            let: { providerId: '$providerId' },
            pipeline: [
              {
                $match: {
                  $expr: {
                    $or: [
                      { $eq: ['$userId', { $toObjectId: '$$providerId' }] },
                      { $eq: ['$_id', { $toObjectId: '$$providerId' }] }
                    ]
                  }
                }
              }
            ],
            as: 'provider'
          }
        },
        { $unwind: { path: '$provider', preserveNullAndEmptyArrays: true } },
        {
          $project: {
            _id: 1,
            serviceName: 1,
            companyName: 1,
            category: 1,
            description: 1,
            price: 1,
            discountPrice: 1,
            city: '$location.city',
            firstImage: { $arrayElemAt: ['$images', 0] },
            providerEmail: { $ifNull: ['$provider.details.email', '$provider.email'] },
            providerPhone: { $ifNull: ['$provider.details.phone', '$provider.phone'] },
          }
        }
      ]).exec();

      return services.map(service => ({
        id: service._id.toString(),
        serviceName: service.serviceName || 'Unknown Service',
        providerName: service.companyName || 'Unknown',
        providerEmail: service.providerEmail || '',
        providerPhone: service.providerPhone || '',
        imageUrl: service.firstImage || '',
        city: service.city || 'Unknown',
        category: service.category || 'General',
        price: service.discountPrice && service.discountPrice < service.price 
          ? service.discountPrice 
          : (service.price || 0),
        oldPrice: service.discountPrice && service.discountPrice < service.price 
          ? service.price 
          : null,
        description: service.description || '',
      }));
    } catch (error) {
      this.logger.error('Failed to fetch services for browse', error.stack);
      throw new HttpException('Failed to fetch services', HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }

  // ============================================================================
  // ✅ OFFER MANAGEMENT METHODS
  // ============================================================================

  /**
   * Create or update an offer for a service
   */
  async createOffer(
    serviceId: string,
    providerId: string,
    offerData: {
      discountedPrice: number;
      discountPercentage?: number;
      startDate: string;
      endDate: string;
      description?: string;
    }
  ): Promise<Service> {
    try {
      const service = await this.serviceModel.findOne({ _id: serviceId, providerId });
      
      if (!service) {
        throw new HttpException('Service not found or you do not have permission', HttpStatus.NOT_FOUND);
      }

      // Validate dates
      const startDate = new Date(offerData.startDate);
      const endDate = new Date(offerData.endDate);
      const now = new Date();

      if (endDate <= startDate) {
        throw new HttpException('End date must be after start date', HttpStatus.BAD_REQUEST);
      }

      if (endDate <= now) {
        throw new HttpException('End date must be in the future', HttpStatus.BAD_REQUEST);
      }

      // Calculate discount percentage if not provided
      let discountPercentage = offerData.discountPercentage;
      if (!discountPercentage && service.price && service.price > 0) {
        discountPercentage = Math.round(((service.price - offerData.discountedPrice) / service.price) * 100);
      }

      const offer = {
        isActive: true,
        discountedPrice: offerData.discountedPrice,
        discountPercentage: discountPercentage || 0,
        startDate: startDate,
        endDate: endDate,
        description: offerData.description || ''
      };

      const updatedService = await this.serviceModel.findByIdAndUpdate(
        serviceId,
        { $set: { offer } },
        { new: true }
      ).exec();

      this.logger.log(`✅ Offer created for service ${serviceId}`);
      return updatedService!;
    } catch (error) {
      this.logger.error('Failed to create offer:', error.stack);
      if (error instanceof HttpException) throw error;
      throw new HttpException('Failed to create offer', HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }

  /**
   * Remove offer from a service
   */
  async removeOffer(serviceId: string, providerId: string): Promise<Service> {
    try {
      const service = await this.serviceModel.findOne({ _id: serviceId, providerId });
      
      if (!service) {
        throw new HttpException('Service not found or you do not have permission', HttpStatus.NOT_FOUND);
      }

      const updatedService = await this.serviceModel.findByIdAndUpdate(
        serviceId,
        { $set: { offer: null } },
        { new: true }
      ).exec();

      this.logger.log(`🗑️ Offer removed from service ${serviceId}`);
      return updatedService!;
    } catch (error) {
      this.logger.error('Failed to remove offer:', error.stack);
      if (error instanceof HttpException) throw error;
      throw new HttpException('Failed to remove offer', HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }

  /**
   * Get all services for a provider with offer status
   */
  async getProviderServicesWithOffers(providerId: string): Promise<{
    activeOffers: any[];
    availableServices: any[];
  }> {
    try {
      const services = await this.serviceModel.find({ providerId }).exec();
      const now = new Date();

      const activeOffers: any[] = [];
      const availableServices: any[] = [];

      for (const service of services) {
        const svc = service as any; // Type assertion for flexibility
        const serviceData = {
          id: svc._id.toString(),
          _id: svc._id.toString(),
          name: svc.serviceName || svc.name,
          serviceName: svc.serviceName,
          category: svc.category,
          price: svc.price || 0,
          gallery: svc.images || svc.gallery || [],
          offer: svc.offer,
        };

        // Check if offer is active and not expired
        if (svc.offer?.isActive && svc.offer.endDate > now) {
          activeOffers.push({
            ...serviceData,
            discountedPrice: svc.offer.discountedPrice,
            discountPercentage: svc.offer.discountPercentage,
            startDate: svc.offer.startDate,
            endDate: svc.offer.endDate,
            description: svc.offer.description,
          });
        } else {
          availableServices.push(serviceData);
        }
      }

      return { activeOffers, availableServices };
    } catch (error) {
      this.logger.error('Failed to get provider services with offers:', error.stack);
      throw new HttpException('Failed to get services', HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }

  /**
   * Clean up expired offers - to be called by a scheduled job
   */
  async cleanupExpiredOffers(): Promise<number> {
    try {
      const now = new Date();
      
      const result = await this.serviceModel.updateMany(
        {
          'offer.isActive': true,
          'offer.endDate': { $lte: now }
        },
        {
          $set: { offer: null }
        }
      ).exec();

      this.logger.log(`🧹 Cleaned up ${result.modifiedCount} expired offers`);
      return result.modifiedCount;
    } catch (error) {
      this.logger.error('Failed to cleanup expired offers:', error.stack);
      return 0;
    }
  }

  /**
   * ✅ PUBLIC: Get all active offers for customers
   * Returns services with active offers that haven't expired
   */
  async getActiveOffers(): Promise<any[]> {
    try {
      const now = new Date();
      
      const services = await this.serviceModel.aggregate([
        { 
          $match: { 
            isActive: true,
            'offer.isActive': true,
            'offer.endDate': { $gt: now },
            'offer.startDate': { $lte: now }
          } 
        },
        {
          $lookup: {
            from: 'serviceproviders',
            let: { providerId: '$providerId' },
            pipeline: [
              {
                $match: {
                  $expr: {
                    $or: [
                      { $eq: ['$userId', { $toObjectId: '$$providerId' }] },
                      { $eq: ['$_id', { $toObjectId: '$$providerId' }] }
                    ]
                  }
                }
              }
            ],
            as: 'provider'
          }
        },
        { $unwind: { path: '$provider', preserveNullAndEmptyArrays: true } },
        { $sort: { 'offer.discountPercentage': -1 } }, // Sort by highest discount first
        {
          $project: {
            _id: 1,
            serviceName: 1,
            companyName: 1,
            providerId: 1,
            category: 1,
            description: 1,
            price: 1,
            bookingType: 1,
            payType: 1,
            averageRating: 1,
            totalReviews: 1,
            hasFixedLocation: 1,
            firstImage: { $arrayElemAt: ['$images', 0] },
            images: 1,
            latitude: '$location.latitude',
            longitude: '$location.longitude',
            city: '$location.city',
            offer: 1,
            workingDays: 1,
            availableHours: 1,
            minBookingHours: 1,
            maxBookingHours: 1,
            maxCapacity: 1,
            cleanupTimeMinutes: 1,
            providerCompanyName: { 
              $ifNull: [
                '$provider.details.companyName', 
                { $ifNull: ['$provider.companyName', '$provider.details.name'] }
              ] 
            },
          }
        }
      ]).exec();

      return services.map(service => ({
        id: service._id.toString(),
        name: service.serviceName || 'Unknown Service',
        company: service.companyName || service.providerCompanyName || 'Unknown',
        providerId: service.providerId?.toString() || '',
        category: service.category || 'General',
        description: service.description || '',
        bookingType: service.bookingType || 'daily',
        payType: service.payType || 'per day',
        hasFixedLocation: service.hasFixedLocation ?? true,
        
        // Prices
        originalPrice: service.price || 0,
        discountedPrice: service.offer?.discountedPrice || service.price || 0,
        discountPercentage: service.offer?.discountPercentage || 0,
        
        // Offer details
        offerStartDate: service.offer?.startDate,
        offerEndDate: service.offer?.endDate,
        offerDescription: service.offer?.description || '',
        
        // Media
        imageUrl: service.firstImage || '',
        images: service.images || [],
        
        // Location
        latitude: service.latitude || null,
        longitude: service.longitude || null,
        city: service.city || 'Unknown',
        
        // Reviews
        rating: service.averageRating || 0,
        totalReviews: service.totalReviews || 0,
        
        // Booking constraints
        workingDays: service.workingDays || [],
        availableHours: service.availableHours || [],
        minBookingHours: service.minBookingHours || null,
        maxBookingHours: service.maxBookingHours || null,
        maxCapacity: service.maxCapacity || null,
        cleanupTimeMinutes: service.cleanupTimeMinutes || 0,
      }));
    } catch (error) {
      this.logger.error('Failed to fetch active offers:', error.stack);
      throw new HttpException('Failed to fetch active offers', HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }
}