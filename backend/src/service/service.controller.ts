import { 
  Controller, Get, Post, Put, Delete, Body, Param, 
  UseGuards, Request, HttpException, HttpStatus, Query,
  UseInterceptors,
  UploadedFiles
} from '@nestjs/common';
import { FilesInterceptor } from '@nestjs/platform-express';
import { ServiceService } from './service.service';
import { CreateServiceDto, UpdateServiceDto } from './service.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('services')
export class ServiceController {
  constructor(private readonly serviceService: ServiceService) {}
  //test
  @Post()
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(FilesInterceptor('images', 10)) 
  async addService(
    @Body() createServiceDto: CreateServiceDto, 
    @Request() req: any,
    @UploadedFiles() files?: Express.Multer.File[] 
  ) {
    try {
      const userId = req.user.userId;
      const userRole = req.user.role;
      if (userRole !== 'vendor') {
        throw new HttpException(
          'Only vendors can add services',
          HttpStatus.FORBIDDEN
        );
      }
      return await this.serviceService.createService(userId, createServiceDto, files);
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to create service',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  // 🆕 3. Update Service by ID - Protected (Vendor)
  @Put('id/:serviceId') // ⬅️ Changed endpoint to use ID
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(FilesInterceptor('images', 10)) 
  async updateServiceById( // ⬅️ Changed function name
    @Param('serviceId') serviceId: string, // ⬅️ Using serviceId
    @Body() updateServiceDto: UpdateServiceDto,
    @Request() req: any,
    @UploadedFiles() files?: Express.Multer.File[]
  ) {
    try {
      const userId = req.user.userId;
      const userRole = req.user.role;

      if (userRole !== 'vendor') {
        throw new HttpException(
          'Only vendors can update services',
          HttpStatus.FORBIDDEN
        );
      }

      return await this.serviceService.updateServiceById( // ⬅️ Calling new service function
        serviceId,
        userId,
        updateServiceDto,
        files
      );
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to update service',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  // 🆕 4. Delete Service by ID - Protected (Vendor)
  @Delete('id/:serviceId') // ⬅️ Changed endpoint to use ID
  @UseGuards(JwtAuthGuard)
  async deleteServiceById(@Param('serviceId') serviceId: string, @Request() req: any) { // ⬅️ Changed function name and parameter
    try {
      const userId = req.user.userId;
      const userRole = req.user.role;

      if (userRole !== 'vendor') {
        throw new HttpException(
          'Only vendors can delete services',
          HttpStatus.FORBIDDEN
        );
      }

      return await this.serviceService.deleteServiceById(serviceId, userId); // ⬅️ Calling new service function
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to delete service',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  @Put('/:serviceName')
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(FilesInterceptor('images', 10)) 
  async updateServiceByName(
    @Param('serviceName') serviceName: string,
    @Body() updateServiceDto: UpdateServiceDto,
    @Request() req: any,
    @UploadedFiles() files?: Express.Multer.File[]
  ) {
    try {
      const userId = req.user.userId;
      const userRole = req.user.role;

      if (userRole !== 'vendor') {
        throw new HttpException(
          'Only vendors can update services',
          HttpStatus.FORBIDDEN
        );
      }

      return await this.serviceService.updateServiceByName(
        serviceName,
        userId,
        updateServiceDto,
        files
      );
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to update service',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }
  
  @Get()
  async getAllServices() {
    try {
      return await this.serviceService.getAllServices();
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to fetch services',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }


  // 2. Delete Service - محمي بالـ JWT
  @Delete('/:serviceName')
  @UseGuards(JwtAuthGuard)
  async deleteServiceByName(@Param('serviceName') serviceName: string, @Request() req: any) {
    try {
      const userId = req.user.userId;
      const userRole = req.user.role;

      if (userRole !== 'vendor') {
        throw new HttpException(
          'Only vendors can delete services',
          HttpStatus.FORBIDDEN
        );
      }

      return await this.serviceService.deleteServiceByName(serviceName, userId);
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to delete service',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  // 6. Get Services by Vendor Name - مفتوح للجميع
  @Get('vendor/:companyName')
  async getServicesByVendor(@Param('companyName') companyName: string) {
    try {
      return await this.serviceService.getServicesByVendorName(companyName);
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to fetch vendor services',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  // API جديد: يحصل على خدمات المزود الحالي المسجل دخولاً
  @Get('my-services')
  @UseGuards(JwtAuthGuard)
  async getMyServices(@Request() req: any) {
    try {
      const userId = req.user.userId;
      const userRole = req.user.role;
      
      if (userRole !== 'vendor') {
        throw new HttpException(
          'Only vendors can access their services',
          HttpStatus.FORBIDDEN
        );
      }
      return await this.serviceService.getServicesByVendorId(userId);
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to fetch your services',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }
  
  // 7. Get Services by Vendor ID - مفتوح للجميع
  @Get('vendor/id/:vendorId')
  async getServicesByVendorId(@Param('vendorId') vendorId: string) {
    try {
      return await this.serviceService.getServicesByVendorId(vendorId);
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to fetch vendor services',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  // 8. Search services with multiple filters - مفتوح للجميع
  @Get('search')
  async searchServices(
    @Query('city') city: string,
    @Query('minPrice') minPrice: string,
    @Query('maxPrice') maxPrice: string,
    @Query('category') category: string,
    @Query('serviceName') serviceName: string,
    @Query('companyName') companyName: string,
    @Query('lat') lat: string,
    @Query('lng') lng: string,
    @Query('radius') radius: string
  ) {
    try {
      const filters: any = {};
      if (city && city.trim() !== '') {
        filters.city = city.trim();
      }
      if (minPrice || maxPrice) {
        filters.priceRange = {
          min: minPrice ? parseFloat(minPrice) : 0,
          max: maxPrice ? parseFloat(maxPrice) : Number.MAX_SAFE_INTEGER
        };
      }
      if (category && category.trim() !== '') {
        filters.category = category.trim();
      }

      if (serviceName && serviceName.trim() !== '') {
        filters.serviceName = serviceName.trim();
      }

      if (companyName && companyName.trim() !== '') {
        filters.companyName = companyName.trim();
      }

      if (lat && lng) {
        const latitude = parseFloat(lat);
        const longitude = parseFloat(lng);
        const radiusInKm = radius ? parseFloat(radius) : 50;

        if (isNaN(latitude) || isNaN(longitude)) {
          throw new HttpException(
            'Invalid latitude or longitude',
            HttpStatus.BAD_REQUEST
          );
        }

        filters.location = {
          lat: latitude,
          lng: longitude,
          radius: radiusInKm
        };
      }

      if (Object.keys(filters).length === 0) {
        throw new HttpException(
          'At least one search filter is required',
          HttpStatus.BAD_REQUEST
        );
      }

      return await this.serviceService.searchServices(filters);
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to search services',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }
  // 10. Get services by category - مفتوح للجميع
  @Get('category/:category')
  async getServicesByCategory(@Param('category') category: string) {
    try {
      return await this.serviceService.getServicesByCategory(category);
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to fetch services by category',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }
}