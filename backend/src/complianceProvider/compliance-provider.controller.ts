// compliance-provider.controller.ts
import {
  Controller,
  Post,
  Get,
  Put,
  Body,
  Param,
  Query,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  ParseFilePipe,
  MaxFileSizeValidator,
  FileTypeValidator,
  HttpCode,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiConsumes,
  ApiBearerAuth,
  ApiQuery,
  ApiParam,
} from '@nestjs/swagger';

import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { User as UserDecorator } from '../auth/user.decorator';

import { ComplianceProviderService } from './compliance-provider.service';
import { 
  UploadDocumentDto, 
  AdminVerificationDto,
  SearchProvidersDto 
} from './dto/upload-document.dto';
import {
  VerificationResponseDto,
  ProviderVerificationStatusDto,
  VerificationStatsDto,
} from './dto/verification-response.dto';
import { VerificationStatus } from './constants/compliance.constants';

@ApiTags('Compliance - التوثيق والامتثال')
@Controller('compliance')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class ComplianceProviderController {
  private readonly logger = new Logger(ComplianceProviderController.name);

  constructor(
    private readonly complianceService: ComplianceProviderService,
  ) {}

  // ==================== Provider Endpoints ====================

  @Post('upload-document')
  @UseInterceptors(FileInterceptor('document'))
  @ApiOperation({ 
    summary: 'رفع وثيقة التحقق',
    description: 'يقوم المزود برفع وثيقة الهوية أو السجل التجاري للتحقق منها باستخدام Google Vision OCR',
  })
  @ApiConsumes('multipart/form-data')
  @ApiResponse({ 
    status: 201, 
    description: 'تم رفع الوثيقة ومعالجتها بنجاح',
    type: VerificationResponseDto,
  })
  @ApiResponse({ status: 400, description: 'بيانات غير صالحة' })
  @ApiResponse({ status: 401, description: 'غير مصرح' })
  async uploadDocument(
    @UserDecorator('_id') userId: string,
    @UploadedFile(
      new ParseFilePipe({
        validators: [
          new MaxFileSizeValidator({ maxSize: 10 * 1024 * 1024 }), // 10MB
          new FileTypeValidator({ fileType: /(jpeg|jpg|png|pdf|webp)$/i }),
        ],
      }),
    )
    file: Express.Multer.File,
    @Body() dto: UploadDocumentDto,
  ): Promise<VerificationResponseDto> {
    this.logger.log(`📤 رفع وثيقة من المستخدم: ${userId}`);
    return this.complianceService.uploadAndVerifyDocument(userId, file, dto);
  }

  @Get('status')
  @ApiOperation({ 
    summary: 'جلب حالة التحقق',
    description: 'يجلب حالة التحقق الحالية للمزود مع تفاصيل الصلاحية',
  })
  @ApiResponse({ 
    status: 200, 
    description: 'حالة التحقق',
    type: ProviderVerificationStatusDto,
  })
  async getMyVerificationStatus(
    @UserDecorator('_id') userId: string,
  ): Promise<ProviderVerificationStatusDto> {
    return this.complianceService.getVerificationStatus(userId);
  }

  @Get('logs')
  @ApiOperation({ 
    summary: 'جلب سجلات التحقق',
    description: 'يجلب سجل جميع عمليات التحقق للمزود',
  })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async getMyComplianceLogs(
    @UserDecorator('_id') userId: string,
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 20,
  ) {
    // جلب provider ID أولاً
    const status = await this.complianceService.getVerificationStatus(userId);
    return this.complianceService.getComplianceLogs(status.providerId, page, limit);
  }

  // ==================== Admin Endpoints ====================

  @Get('admin/stats')
  @UseGuards(RolesGuard)
  @Roles('admin')
  @ApiOperation({ 
    summary: 'إحصائيات التحقق (مشرف)',
    description: 'يجلب إحصائيات شاملة عن حالات التحقق لجميع المزودين',
  })
  @ApiResponse({ 
    status: 200, 
    description: 'إحصائيات التحقق',
    type: VerificationStatsDto,
  })
  async getVerificationStats(): Promise<VerificationStatsDto> {
    return this.complianceService.getVerificationStats();
  }

  @Get('admin/providers')
  @UseGuards(RolesGuard)
  @Roles('admin')
  @ApiOperation({ 
    summary: 'جلب المزودين حسب حالة التحقق (مشرف)',
    description: 'يجلب قائمة المزودين مع إمكانية الفلترة حسب حالة التحقق',
  })
  @ApiQuery({ 
    name: 'status', 
    required: false, 
    enum: VerificationStatus,
    description: 'فلترة حسب حالة التحقق',
  })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async getProvidersByStatus(
    @Query('status') status?: VerificationStatus,
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 20,
  ) {
    return this.complianceService.getProvidersByStatus(status, page, limit);
  }

  @Get('admin/providers/:providerId')
  @UseGuards(RolesGuard)
  @Roles('admin')
  @ApiOperation({ 
    summary: 'تفاصيل مزود محدد (مشرف)',
    description: 'يجلب تفاصيل التحقق لمزود محدد مع سجلاته',
  })
  @ApiParam({ name: 'providerId', description: 'معرف المزود' })
  async getProviderDetails(
    @Param('providerId') providerId: string,
  ) {
    const logs = await this.complianceService.getComplianceLogs(providerId, 1, 50);
    return logs;
  }

  @Put('admin/verify')
  @UseGuards(RolesGuard)
  @Roles('admin')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ 
    summary: 'المراجعة اليدوية (مشرف)',
    description: 'يقوم المشرف بالموافقة أو رفض وثائق المزود يدوياً',
  })
  @ApiResponse({ 
    status: 200, 
    description: 'تمت المراجعة بنجاح',
    type: VerificationResponseDto,
  })
  async adminVerification(
    @UserDecorator('_id') adminId: string,
    @Body() dto: AdminVerificationDto,
  ): Promise<VerificationResponseDto> {
    this.logger.log(`🔍 مراجعة يدوية من المشرف: ${adminId}`);
    return this.complianceService.adminVerification(adminId, dto);
  }

  @Get('admin/pending-review')
  @UseGuards(RolesGuard)
  @Roles('admin')
  @ApiOperation({ 
    summary: 'المزودين في انتظار المراجعة (مشرف)',
    description: 'يجلب قائمة المزودين الذين يحتاجون مراجعة يدوية',
  })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async getPendingReviewProviders(
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 20,
  ) {
    return this.complianceService.getProvidersByStatus(
      VerificationStatus.ADMIN_REVIEW, 
      page, 
      limit
    );
  }

  @Get('admin/expired')
  @UseGuards(RolesGuard)
  @Roles('admin')
  @ApiOperation({ 
    summary: 'المزودين منتهيي الصلاحية (مشرف)',
    description: 'يجلب قائمة المزودين الذين انتهت صلاحية وثائقهم',
  })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async getExpiredProviders(
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 20,
  ) {
    return this.complianceService.getProvidersByStatus(
      VerificationStatus.EXPIRED, 
      page, 
      limit
    );
  }

  @Get('admin/logs/:providerId')
  @UseGuards(RolesGuard)
  @Roles('admin')
  @ApiOperation({ 
    summary: 'سجلات التحقق لمزود (مشرف)',
    description: 'يجلب سجل جميع عمليات التحقق لمزود محدد',
  })
  @ApiParam({ name: 'providerId', description: 'معرف المزود' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async getProviderLogs(
    @Param('providerId') providerId: string,
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 20,
  ) {
    return this.complianceService.getComplianceLogs(providerId, page, limit);
  }

  // ==================== Utility Endpoints ====================

  @Get('check-verified/:providerId')
  @ApiOperation({ 
    summary: 'التحقق من حالة مزود',
    description: 'يتحقق مما إذا كان المزود موثقاً (للاستخدام الداخلي)',
  })
  @ApiParam({ name: 'providerId', description: 'معرف المزود' })
  @ApiResponse({ 
    status: 200, 
    schema: { 
      type: 'object', 
      properties: { 
        isVerified: { type: 'boolean' },
        status: { type: 'string' },
      } 
    } 
  })
  async checkIfVerified(
    @Param('providerId') providerId: string,
  ): Promise<{ isVerified: boolean; status: VerificationStatus }> {
    try {
      // البحث عن المزود مباشرة
      const status = await this.complianceService.getVerificationStatus(providerId);
      return {
        isVerified: status.verificationStatus === VerificationStatus.VERIFIED,
        status: status.verificationStatus,
      };
    } catch {
      return {
        isVerified: false,
        status: VerificationStatus.PENDING,
      };
    }
  }
}
