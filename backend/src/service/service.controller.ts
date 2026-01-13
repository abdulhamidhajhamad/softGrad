import { 
  Controller, Get, Post, Put, Delete, Body, Param, 
  UseGuards, Request, HttpException, HttpStatus, Query,
  UseInterceptors,
  UploadedFiles,
  DefaultValuePipe,
  ParseIntPipe
} from '@nestjs/common';
import { FilesInterceptor } from '@nestjs/platform-express';
import { ServiceService } from './service.service';
import { CreateServiceDto, UpdateServiceDto } from './service.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('services')
export class ServiceController {
  constructor(private readonly serviceService: ServiceService) {}
  
  // 13. Get Vendor Services Details (ID, Name, Price) - محمي للـ Vendor
  @Get('vendor-services-details') // مسار جديد لعدم التعارض
  @UseGuards(JwtAuthGuard)
  async getVendorServicesDetails(@Request() req: any): Promise<any[]> {
    try {
      const providerId = req.user.userId; 
      // استدعاء الدالة التي تم إنشاؤها في الخدمة
      return await this.serviceService.getVendorServicesDetails(providerId);
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to fetch vendor services details',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }
  @Get('home-service')
async getHomepageCategoriesPreview() {
  try {
    return await this.serviceService.getHomepageServicesByCategories();
  } catch (error) {
    throw new HttpException(
      error.message || 'Failed to fetch homepage services',
      error.status || HttpStatus.INTERNAL_SERVER_ERROR
    );
  }
}

  // ✅ Homepage endpoint - Get 5 random trending services (Public - no auth required)
  @Get('home/trending')
  async getRandomServicesForHome() {
    try {
      return await this.serviceService.getRandomServicesForHome(5);
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to fetch trending services',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  // ✅ Search/Browse endpoint - Get all services formatted for search display (Public)
  @Get('browse/all')
  async getAllServicesForBrowse() {
    try {
      return await this.serviceService.getAllServicesForBrowse();
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to fetch services for browse',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  @Post()
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(FilesInterceptor('images', 10)) 
  async addService(
    @Body('data') data: string, // ⬅️ يتوقع 'data' من form-data
    @Request() req: any,
    @UploadedFiles() files?: Express.Multer.File[] 
  ) {
    try {
      // 🆕 التحقق من data لتجنب خطأ JSON.parse
      if (!data) {
        throw new HttpException(
          'Missing required field: "data" (JSON string of CreateServiceDto)',
          HttpStatus.BAD_REQUEST
        );
      }
      const createServiceDto: CreateServiceDto = JSON.parse(data); //
      const userId = req.user.userId;
      const userRole = req.user.role
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
  @Put('id/:serviceId')
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(FilesInterceptor('images', 10)) 
  async updateServiceById( 
    @Param('serviceId') serviceId: string, 
    @Body('data') data: string, // ⬅️ تم التعديل لاستقبال 'data' كـ string
    @Request() req: any,
    @UploadedFiles() files?: Express.Multer.File[]
  ) {
    try {
      // 🆕 يجب تحليل JSON يدوياً هنا أيضاً
      if (!data) {
        throw new HttpException(
          'Missing required field: "data" (JSON string of UpdateServiceDto)',
          HttpStatus.BAD_REQUEST
        );
      }
      const updateServiceDto: UpdateServiceDto = JSON.parse(data);
      
      const userId = req.user.userId;
      const userRole = req.user.role;

      if (userRole !== 'vendor') {
        throw new HttpException(
          'Only vendors can update services',
          HttpStatus.FORBIDDEN
        );
      }

      return await this.serviceService.updateServiceById( 
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
  @Delete('id/:serviceId') //
  @UseGuards(JwtAuthGuard)
  async deleteServiceById(@Param('serviceId') serviceId: string, @Request() req: any) { //
    try {
      const userId = req.user.userId;
      const userRole = req.user.role;

      if (userRole !== 'vendor') {
        throw new HttpException(
          'Only vendors can delete services',
          HttpStatus.FORBIDDEN
        );
      }

      return await this.serviceService.deleteServiceById(serviceId, userId); //
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
    @Body('data') data: string, // ⬅️ تم التعديل لاستقبال 'data' كـ string
    @Request() req: any,
    @UploadedFiles() files?: Express.Multer.File[]
  ) {
    try {
      // 🆕 يجب تحليل JSON يدوياً هنا أيضاً
      if (!data) {
        throw new HttpException(
          'Missing required field: "data" (JSON string of UpdateServiceDto)',
          HttpStatus.BAD_REQUEST
        );
      }
      const updateServiceDto: UpdateServiceDto = JSON.parse(data);
      
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

  // 5. Delete Service By Name
  @Delete('name/:serviceName')
  @UseGuards(JwtAuthGuard)
  async deleteServiceByName(
    @Param('serviceName') serviceName: string,
    @Request() req: any
  ) {
    try {
      const providerId = req.user.userId;
      return await this.serviceService.deleteServiceByName(serviceName, providerId);
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to delete service by name',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  // 6. Get All Services (Public)
  @Get()
  async getAllServices() {
    try {
      return await this.serviceService.getAllServices();
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to fetch all services',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }
  
  // 7. Get Services By Vendor Company Name (Public)
  @Get('vendor/name/:companyName')
  async getServicesByVendorName(@Param('companyName') companyName: string) {
    try {
      return await this.serviceService.getServicesByVendorName(companyName); // ✅ تم التأكد من وجود هذه الدالة في الـ Service
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to fetch services by vendor name',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  // 8. Get Services By Vendor ID (Protected)
  @Get('my-services') 
  @UseGuards(JwtAuthGuard)
  async getMyServices(@Request() req: any) {
    try {
      const userId = req.user.userId;
      // 🚨 تم تعديل الاستدعاء من getServicesByVendorId إلى getServicesByVendor
      return await this.serviceService.getServicesByVendor(userId); 
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to fetch my services',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  // 9. Get Services By Vendor ID (Public - used for profile viewing)
  @Get('vendor/:vendorId') 
  async getServicesByVendorId(@Param('vendorId') vendorId: string) {
    try {
       // 🚨 تم تعديل الاستدعاء من getServicesByVendorId إلى getServicesByVendor
      return await this.serviceService.getServicesByVendor(vendorId); 
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to fetch services by vendor ID',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  // 10. Search Services (Public)
  @Get('search')
  async searchServices(@Query() query: any) {
    try {
      // تحويل سلاسل JSON في الـ Query إلى كائنات
      const filters = {};
      for (const key in query) {
        try {
          filters[key] = JSON.parse(query[key]);
        } catch (e) {
          filters[key] = query[key];
        }
      }
      return await this.serviceService.searchServices(filters);
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to search services',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  // 11. Get Services By Category (Public)
  @Get('category/:category')
  async getServicesByCategory(@Param('category') category: string) {
    try {
      return await this.serviceService.getServicesByCategory(category); // ✅ تم التأكد من وجود هذه الدالة في الـ Service
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to fetch services by category',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }


  // 12. Get Service Details by ID - مفتوح للجميع ويرجع حقول محددة
  @Get(':serviceId') // ⬅️ استخدام مسار محدد لتجنب التعارض مع Get()
async getServiceDetailsById(@Param('serviceId') serviceId: string) {
  try {
    // هذه الدالة الآن ترجع الـ Object المفلتر تماماً كما طلبت
    return await this.serviceService.getServiceById(serviceId); 
  } catch (error) {
    throw new HttpException(
      error.message || 'Failed to fetch service details',
      error.status || HttpStatus.INTERNAL_SERVER_ERROR
    );
  }
}




  // ✅ NEW ENDPOINT: جلب الخدمات مع تفاصيل محددة لدعم التمرير اللانهائي
  @Get('public/paginate-details')
  // @Public() // 👈 يجب إضافة هذا الـ Decorator أو الترتيب لتجاوز JwtAuthGuard
  async getPaginatedServicesDetails(
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number, // افتراضياً 20 عنصر
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,   // افتراضياً الصفحة الأولى
  ) {
    if (limit > 50) limit = 50; 
    
    return this.serviceService.getPaginatedServicesWithDetails(limit, page);
  }



  
}