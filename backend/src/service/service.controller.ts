import { 
  Controller, Get, Post, Put, Delete, Body, Param, 
  UseGuards, Request, HttpException, HttpStatus, Query 
} from '@nestjs/common';
import { ServiceService } from './service.service';
import { CreateServiceDto, UpdateServiceDto } from './service.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('services')
export class ServiceController {
  constructor(private readonly serviceService: ServiceService) {}

  // 1. Add Service (Only Vendors) - محمي بالـ JWT
  @Post()
  @UseGuards(JwtAuthGuard)
  async addService(@Body() createServiceDto: CreateServiceDto, @Request() req: any) {
    try {
      const userId = req.user.userId;
      const userRole = req.user.role;

      if (userRole !== 'vendor') {
        throw new HttpException(
          'Only vendors can add services',
          HttpStatus.FORBIDDEN
        );
      }

      return await this.serviceService.createService(userId, createServiceDto);
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to create service',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  // 2. Delete Service - محمي بالـ JWT
  @Delete('name/:serviceName')
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

  // 3. Update Service - محمي بالـ JWT
  @Put('name/:serviceName')
  @UseGuards(JwtAuthGuard)
  async updateServiceByName(
    @Param('serviceName') serviceName: string,
    @Body() updateServiceDto: UpdateServiceDto,
    @Request() req: any
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
        updateServiceDto
      );
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to update service',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  // 4. Get All Services - مفتوح للجميع
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

  // 5. Get Service by ID - مفتوح للجميع
  @Get(':id')
  async getServiceById(@Param('id') id: string) {
    try {
      return await this.serviceService.getServiceById(id);
    } catch (error) {
      throw new HttpException(
        error.message || 'Service not found',
        error.status || HttpStatus.NOT_FOUND
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

  // 8. Search services by location - مفتوح للجميع
  @Get('search/location')
  async searchServicesByLocation(
    @Query('lat') lat: string,
    @Query('lng') lng: string,
    @Query('radius') radius: string
  ) {
    try {
      const latitude = parseFloat(lat);
      const longitude = parseFloat(lng);
      const radiusInKm = radius ? parseFloat(radius) : 50;

      if (isNaN(latitude) || isNaN(longitude)) {
        throw new HttpException(
          'Invalid latitude or longitude',
          HttpStatus.BAD_REQUEST
        );
      }

      return await this.serviceService.searchServicesByLocation(
        latitude,
        longitude,
        radiusInKm
      );
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to search services by location',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  // 9. Search services by name - مفتوح للجميع
  @Get('search/name/:serviceName')
  async searchServicesByName(@Param('serviceName') serviceName: string) {
    try {
      return await this.serviceService.searchServicesByName(serviceName);
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