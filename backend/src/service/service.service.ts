import { Injectable, HttpException, HttpStatus } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Service } from './service.schema';
import { CreateServiceDto, UpdateServiceDto } from './service.dto';
import { SupabaseStorageService } from '../subbase/supabaseStorage.service';

@Injectable()
export class ServiceService {
  constructor(
    @InjectModel(Service.name) private serviceModel: Model<Service>,
    private supabaseStorage: SupabaseStorageService,
  ) {}

  async getAllServices(): Promise<Service[]> {
    try {
      return await this.serviceModel.find().exec();
    } catch (error) {
      throw new HttpException(
        'Failed to fetch services',
        HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  async createService(
    providerId: string, 
    createServiceDto: CreateServiceDto,
    files?: Express.Multer.File[] 
  ): Promise<Service> {
    try {
      console.log('📦 Received createServiceDto:', JSON.stringify(createServiceDto, null, 2));
      console.log('👤 Provider ID:', providerId);
      console.log('🖼️ Number of images:', files?.length || 0);
    if (typeof createServiceDto.price === 'string') {
        createServiceDto.price = parseFloat(createServiceDto.price);
      }
      const existingService = await this.serviceModel.findOne({ 
        serviceName: createServiceDto.serviceName,
        providerId 
      });

      if (existingService) {
        console.log('❌ Service already exists:', createServiceDto.serviceName);
        throw new HttpException(
          'Service with this name already exists',
          HttpStatus.CONFLICT
        );
      }
      let companyName = createServiceDto.companyName;
      if (!companyName) {
        companyName = `Vendor-${providerId.substring(0, 8)}`;
        console.log('🏢 Using default company name:', companyName);
      }
      console.log('🏢 Final company name:', companyName);
      let imageUrls: string[] = [];
      if (files && files.length > 0) {
        try {
          console.log('📤 Uploading service images to Supabase...');
          const uploadPromises = files.map(file => 
            this.supabaseStorage.uploadImage(file, 'services', true)
          );
          imageUrls = await Promise.all(uploadPromises);
          console.log('✅ Service images uploaded successfully:', imageUrls);
        } catch (uploadError) {
          console.error('❌ Failed to upload service images:', uploadError);
        }
      }
      const newServiceData = {
        providerId,
        companyName,
        ...createServiceDto,
        images: imageUrls,
        reviews: [],
        rating: createServiceDto.rating || 0
      };

      console.log('🔄 Creating service with data:', JSON.stringify(newServiceData, null, 2));

      const newService = new this.serviceModel(newServiceData);
      const savedService = await newService.save();
      
 const responseService = await this.serviceModel
        .findById(savedService._id)
        .select('-reviews -bookedDates -rating -aiAnalysis') // ⬅️ الإضافة هنا
        .exec();

      if (!responseService) {
         // في حالة نادرة جدًا لم يتم العثور على الخدمة بعد الحفظ
         return savedService; 
      }

      console.log('✅ Service created successfully:', responseService._id); //
      return responseService;
      
    } catch (error) {
      console.error('💥 ERROR in createService:', error);
      
      if (error instanceof HttpException) {
        throw error;
      }
      
      if (error.name === 'ValidationError') {
        console.log('MongoDB Validation Error:', error.errors);
        throw new HttpException(
          `Validation error: ${Object.values(error.errors).map((e: any) => e.message).join(', ')}`,
          HttpStatus.BAD_REQUEST
        );
      }

      if (error.code === 11000) {
        throw new HttpException(
          'Service with this name already exists',
          HttpStatus.CONFLICT
        );
      }

      throw new HttpException(
        error.message || 'Failed to create service',
        HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  // Function to update service by ID
  async updateServiceById(
    serviceId: string, 
    providerId: string,
    updateServiceDto: UpdateServiceDto,
    files?: Express.Multer.File[] 
  ): Promise<Service> {
    try {
      // 1. Find service by ID and ensure it belongs to the provider
      const service = await this.serviceModel.findOne({ _id: serviceId, providerId });

      if (!service) {
        throw new HttpException(
          'Service not found or you do not have permission to update it',
          HttpStatus.NOT_FOUND
        );
      }

      let finalImageUrls: string[] = service.images || []; // Default to existing images

      // 2. Check if new files were provided
      if (files && files.length > 0) {
        console.log('🆕 New files received. Starting replacement process...');
        
        // **A. Delete old images from Supabase**
        if (service.images && service.images.length > 0) {
          try {
            console.log('🗑️ Deleting old service images from Supabase...');
            const deletePromises = service.images.map(imageUrl => 
              // Assuming you have a deleteFile method in SupabaseStorageService
              this.supabaseStorage.deleteFile(imageUrl) 
            );
            await Promise.all(deletePromises);
            console.log('✅ Old service images deleted from Supabase');
          } catch (deleteError) {
            console.error('⚠️ Failed to delete old service images from Supabase. Proceeding with update:', deleteError);
            // We proceed with the update even if old images fail to delete
          }
        }

        // **B. Upload new images to Supabase**
        try {
          console.log('📤 Uploading new service images to Supabase...');
          const uploadPromises = files.map(file => 
            this.supabaseStorage.uploadImage(file, 'services', true)
          );
          finalImageUrls = await Promise.all(uploadPromises); // ⬅️ Overwrite the finalImageUrls
          console.log('✅ New service images uploaded successfully:', finalImageUrls);
        } catch (uploadError) {
          console.error('❌ Failed to upload new service images:', uploadError);
          throw new HttpException(
             'Failed to upload new service images',
             HttpStatus.INTERNAL_SERVER_ERROR
          );
        }
      }

      // 3. Prepare update data
      const updateData = {
        ...updateServiceDto,
        images: finalImageUrls // ⬅️ Using the new/existing list
      };
      
      // Convert price string to number if it exists in DTO
      if (typeof updateData.price === 'string') {
          updateData.price = parseFloat(updateData.price);
      }

      // 4. Perform the update
      const updatedService = await this.serviceModel.findOneAndUpdate(
        { _id: serviceId, providerId }, 
        { $set: updateData },
        { new: true, runValidators: true }
      )
      .select('-reviews -bookedDates -rating -aiAnalysis') // ⬅️ Ensure the response is clean
      .exec();

      if (!updatedService) {
        throw new HttpException(
          'Failed to update service after finding it',
          HttpStatus.INTERNAL_SERVER_ERROR
        );
      }

      return updatedService;
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to update service',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  // 🆕 Function to delete service by ID
  async deleteServiceById(serviceId: string, providerId: string): Promise<{ message: string }> {
    try {
      // 1. Find service by ID and ensure it belongs to the provider
      const service = await this.serviceModel.findOne({ _id: serviceId, providerId });

      if (!service) {
        throw new HttpException(
          'Service not found or you do not have permission to delete it',
          HttpStatus.NOT_FOUND
        );
      }

      // 2. Delete images from Supabase
      if (service.images && service.images.length > 0) {
        try {
          console.log('🗑️ Deleting service images from Supabase...');
          const deletePromises = service.images.map(imageUrl => 
            this.supabaseStorage.deleteFile(imageUrl)
          );
          await Promise.all(deletePromises);
          console.log('✅ Service images deleted from Supabase');
        } catch (deleteError) {
          console.error('❌ Failed to delete service images from Supabase:', deleteError);
          // Proceed with service deletion even if image deletion fails
        }
      }

      // 3. Delete the service document
      await this.serviceModel.deleteOne({ _id: serviceId, providerId });

      return { message: `Service with ID '${serviceId}' deleted successfully` };
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to delete service',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  async updateServiceByName(
    serviceName: string,
    providerId: string,
    updateServiceDto: UpdateServiceDto,
    files?: Express.Multer.File[] // ✅ إضافة files parameter
  ): Promise<Service> {
    try {
      const service = await this.serviceModel.findOne({ serviceName, providerId });

      if (!service) {
        throw new HttpException(
          'Service not found or you do not have permission to update it',
          HttpStatus.NOT_FOUND
        );
      }

      // ✅ رفع الصور الجديدة إلى Supabase إذا وجدت
      let newImageUrls: string[] = [];
      if (files && files.length > 0) {
        try {
          console.log('📤 Uploading new service images to Supabase...');
          const uploadPromises = files.map(file => 
            this.supabaseStorage.uploadImage(file, 'services', true)
          );
          newImageUrls = await Promise.all(uploadPromises);
          console.log('✅ New service images uploaded successfully:', newImageUrls);
        } catch (uploadError) {
          console.error('❌ Failed to upload new service images:', uploadError);

        }
      }

      const updatedImages = [
        ...(service.images || []),
        ...newImageUrls
      ];

      const updateData = {
        ...updateServiceDto,
        images: updatedImages.length > 0 ? updatedImages : service.images
      };

      const updatedService = await this.serviceModel.findOneAndUpdate(
        { serviceName, providerId },
        { $set: updateData },
        { new: true, runValidators: true }
      ).exec();

      if (!updatedService) {
        throw new HttpException(
          'Failed to update service',
          HttpStatus.INTERNAL_SERVER_ERROR
        );
      }

      return updatedService;
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to update service',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  async deleteServiceByName(serviceName: string, providerId: string): Promise<{ message: string }> {
    try {
      const service = await this.serviceModel.findOne({ serviceName, providerId });

      if (!service) {
        throw new HttpException(
          'Service not found or you do not have permission to delete it',
          HttpStatus.NOT_FOUND
        );
      }

      // ✅ حذف الصور من Supabase
      if (service.images && service.images.length > 0) {
        try {
          console.log('🗑️ Deleting service images from Supabase...');
          const deletePromises = service.images.map(imageUrl => 
            this.supabaseStorage.deleteFile(imageUrl)
          );
          await Promise.all(deletePromises);
          console.log('✅ Service images deleted from Supabase');
        } catch (deleteError) {
          console.error('❌ Failed to delete service images from Supabase:', deleteError);
          // الاستمرار في حذف السيرفس حتى لو فشل حذف الصور
        }
      }

      await this.serviceModel.deleteOne({ serviceName, providerId });

      return { message: `Service '${serviceName}' deleted successfully` };
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to delete service',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }


  async getServicesByVendorName(companyName: string): Promise<Service[]> {
    try {
      const services = await this.serviceModel.find({ companyName }).exec();
      
      if (!services || services.length === 0) {
        throw new HttpException(
          `No services found for vendor '${companyName}'`,
          HttpStatus.NOT_FOUND
        );
      }

      return services;
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to fetch vendor services',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  async getServicesByVendorId(vendorId: string): Promise<Service[]> {
    try {
      const services = await this.serviceModel.find({ providerId: vendorId }).exec();
      
      if (!services || services.length === 0) {
        throw new HttpException(
          `No services found for vendor ID '${vendorId}'`,
          HttpStatus.NOT_FOUND
        );
      }

      return services;
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to fetch vendor services',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  async searchServicesByLocation(
    latitude: number,
    longitude: number,
    radiusInKm: number = 50
  ): Promise<Service[]> {
    try {
      // Calculate rough bounding box for faster filtering
      const latDelta = radiusInKm / 111; // 1 degree latitude ≈ 111km
      const lonDelta = radiusInKm / (111 * Math.cos(latitude * Math.PI / 180));

      const services = await this.serviceModel.find({
        'location.latitude': {
          $gte: latitude - latDelta,
          $lte: latitude + latDelta
        },
        'location.longitude': {
          $gte: longitude - lonDelta,
          $lte: longitude + lonDelta
        }
      }).exec();

      // Filter by exact distance using Haversine formula
      return services.filter(service => {
        const distance = this.calculateDistance(
          latitude,
          longitude,
          service.location.latitude,
          service.location.longitude
        );
        return distance <= radiusInKm;
      });
    } catch (error) {
      throw new HttpException(
        'Failed to search services by location',
        HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  async searchServicesByName(serviceName: string): Promise<Service[]> {
    try {
      const services = await this.serviceModel.find({
        serviceName: { $regex: serviceName, $options: 'i' }
      }).exec();

      if (!services || services.length === 0) {
        throw new HttpException(
          `No services found with name '${serviceName}'`,
          HttpStatus.NOT_FOUND
        );
      }

      return services;
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to search services',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  async getServicesByCategory(category: string): Promise<Service[]> {
    try {
      const services = await this.serviceModel.find({
        category: { $regex: category, $options: 'i' }
      }).exec();

      if (!services || services.length === 0) {
        throw new HttpException(
          `No services found in category '${category}'`,
          HttpStatus.NOT_FOUND
        );
      }

      return services;
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to fetch services by category',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

 private calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371; // نصف قطر الأرض بالكيلومتر
    const dLat = this.deg2rad(lat2 - lat1);
    const dLon = this.deg2rad(lon2 - lon1);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this.deg2rad(lat1)) * Math.cos(this.deg2rad(lat2)) *
      Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }
  
  async searchServicesByCity(city: string): Promise<Service[]> {
    try {
      const services = await this.serviceModel.find({
        'location.city': { $regex: city, $options: 'i' }
      }).exec();

      if (!services || services.length === 0) {
        throw new HttpException(
          `No services found in city '${city}'`,
          HttpStatus.NOT_FOUND
        );
      }

      return services;
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to search services by city',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

 
  
  private deg2rad(deg: number): number {
    return deg * (Math.PI / 180);
  }

  async searchServices(filters: any): Promise<Service[]> {
    try {
      let query: any = {};

      // ... (منطق فلترة المدينة والسعر والتصنيف واسم الخدمة واسم الشركة كما هو)
      if (filters.city) {
        query['location.city'] = { $regex: filters.city, $options: 'i' };
      }
      if (filters.priceRange) {
        query.price = { $gte: filters.priceRange.min, $lte: filters.priceRange.max };
      }
      if (filters.category) {
        query.category = { $regex: filters.category, $options: 'i' };
      }
      if (filters.serviceName) {
        query.serviceName = { $regex: filters.serviceName, $options: 'i' };
      }
      if (filters.companyName) {
        query.companyName = { $regex: filters.companyName, $options: 'i' };
      }

      // 🆕 فلترة بواسطة العلامات المستخرجة من الذكاء الاصطناعي (AI Tags)
      if (filters.aiTags && Array.isArray(filters.aiTags) && filters.aiTags.length > 0) {
          // استخدام $in للبحث عن الخدمات التي تحتوي على أي من علامات الذكاء الاصطناعي المطلوبة.
          query['aiAnalysis.tags'] = { $in: filters.aiTags }; 
      }

      // ... (منطق فلترة الموقع كما هو)
      if (filters.location) {
        const { lat, lng, radius } = filters.location;
        const latDelta = radius / 111;
        const lonDelta = radius / (111 * Math.cos(lat * Math.PI / 180));

        query['location.latitude'] = { $gte: lat - latDelta, $lte: lat + latDelta };
        query['location.longitude'] = { $gte: lng - lonDelta, $lte: lng + lonDelta };

        const services = await this.serviceModel.find(query).exec();
        return services.filter(service => {
          const distance = this.calculateDistance(lat, lng, service.location.latitude, service.location.longitude);
          return distance <= radius;
        });
      }
      
      const services = await this.serviceModel.find(query).exec();

      if (!services || services.length === 0) {
        throw new HttpException(
          'No services found matching your criteria',
          HttpStatus.NOT_FOUND
        );
      }

      return services;
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to search services',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  async getServiceById(serviceId: string): Promise<any> { // ⬅️ تغيير نوع الإرجاع إلى 'any' أو إنشاء DTO مخصص
    try {
      const service = await this.serviceModel
        .findById(serviceId)
        .select('serviceName category location.city price additionalInfo') // ⬅️ التعديل هنا لتحديد الحقول
        .exec();

      if (!service) {
        throw new HttpException(
          'Service not found',
          HttpStatus.NOT_FOUND
        );
      }

      // تحويل النتيجة إلى كائن عادي وإعادة ترتيب الحقول
      const serviceObject = service.toObject();
      return {
          serviceName: serviceObject.serviceName,
          category: serviceObject.category,
          city: serviceObject.location?.city, // استخدام الاختيار الاختياري
          price: serviceObject.price,
          description: serviceObject.additionalInfo // إعادة تسمية additionalInfo إلى description في الرد
      };
      
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to fetch service',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }
  
}