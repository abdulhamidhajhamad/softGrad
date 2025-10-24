import { Injectable, HttpException, HttpStatus } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Service } from './service.schema';
import { CreateServiceDto, UpdateServiceDto } from './service.dto';

@Injectable()
export class ServiceService {
  constructor(
    @InjectModel(Service.name) private serviceModel: Model<Service>,
  ) {}

  // 1. Create Service (Only Vendors)
  async createService(providerId: string, createServiceDto: CreateServiceDto): Promise<Service> {
    try {
      console.log('📦 Received createServiceDto:', JSON.stringify(createServiceDto, null, 2));
      console.log('👤 Provider ID:', providerId);

      // تحقق إذا كان في خدمة بنفس الاسم لنفس المزود
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

      // 🔄 تحديد companyName
      let companyName = createServiceDto.companyName;
      
      // إذا لم يرسل companyName، استخدم الافتراضي
      if (!companyName) {
        companyName = `Vendor-${providerId.substring(0, 8)}`;
        console.log('🏢 Using default company name:', companyName);
      }

      console.log('🏢 Final company name:', companyName);

      const newServiceData = {
        providerId,
        companyName,
        ...createServiceDto,
        reviews: []
      };

      console.log('🔄 Creating service with data:', JSON.stringify(newServiceData, null, 2));

      const newService = new this.serviceModel(newServiceData);
      const savedService = await newService.save();
      
      console.log('✅ Service created successfully:', savedService._id);
      return savedService;

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

  // 2. Delete Service by Name
  async deleteServiceByName(serviceName: string, providerId: string): Promise<{ message: string }> {
    try {
      const service = await this.serviceModel.findOne({ serviceName, providerId });

      if (!service) {
        throw new HttpException(
          'Service not found or you do not have permission to delete it',
          HttpStatus.NOT_FOUND
        );
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

  // 3. Get All Services
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

  // 4. Update Service by Name
  async updateServiceByName(
    serviceName: string,
    providerId: string,
    updateServiceDto: UpdateServiceDto
  ): Promise<Service> {
    try {
      const service = await this.serviceModel.findOne({ serviceName, providerId });

      if (!service) {
        throw new HttpException(
          'Service not found or you do not have permission to update it',
          HttpStatus.NOT_FOUND
        );
      }

      const updatedService = await this.serviceModel.findOneAndUpdate(
        { serviceName, providerId },
        { $set: updateServiceDto },
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

  // 5. Get Services by Vendor Name (Company)
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

  // 6. Get Services by Vendor ID
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

  // 7. Get Service by ID
  async getServiceById(serviceId: string): Promise<Service> {
    try {
      const service = await this.serviceModel.findById(serviceId).exec();

      if (!service) {
        throw new HttpException(
          'Service not found',
          HttpStatus.NOT_FOUND
        );
      }

      return service;
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to fetch service',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  // 8. Search services by location (within radius)
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

  // 9. Search services by name
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

  // 10. Get services by category
  async getServicesByCategory(category: string): Promise<Service[]> {
    try {
      const services = await this.serviceModel.find({
        'additionalInfo.category': { $regex: category, $options: 'i' }
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

  // Haversine formula to calculate distance
  private calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371; // Earth's radius in km
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
      Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }
}