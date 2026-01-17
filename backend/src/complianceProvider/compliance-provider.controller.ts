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

@ApiTags('Compliance')
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
    summary: 'Upload verification document',
    description: 'Provider uploads ID or business license document for verification using Google Vision OCR',
  })
  @ApiConsumes('multipart/form-data')
  @ApiResponse({ 
    status: 201, 
    description: 'Document uploaded and processed successfully',
    type: VerificationResponseDto,
  })
  @ApiResponse({ status: 400, description: 'Invalid data' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async uploadDocument(
    @UserDecorator('userId') userId: string,
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
    this.logger.log(`📤 Document upload from user: ${userId}`);
    return this.complianceService.uploadAndVerifyDocument(userId, file, dto);
  }

  @Get('status')
  @ApiOperation({ 
    summary: 'Get verification status',
    description: 'Gets the current verification status for the provider with validity details',
  })
  @ApiResponse({ 
    status: 200, 
    description: 'Verification status',
    type: ProviderVerificationStatusDto,
  })
  async getMyVerificationStatus(
    @UserDecorator('userId') userId: string,
  ): Promise<ProviderVerificationStatusDto> {
    return this.complianceService.getVerificationStatus(userId);
  }

  @Get('logs')
  @ApiOperation({ 
    summary: 'Get verification logs',
    description: 'Gets the log of all verification operations for the provider',
  })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async getMyComplianceLogs(
    @UserDecorator('userId') userId: string,
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 20,
  ) {
    // Get provider ID first
    const status = await this.complianceService.getVerificationStatus(userId);
    return this.complianceService.getComplianceLogs(status.providerId, page, limit);
  }

  // ==================== Admin Endpoints ====================

  @Get('admin/stats')
  @UseGuards(RolesGuard)
  @Roles('admin')
  @ApiOperation({ 
    summary: 'Verification statistics (Admin)',
    description: 'Gets comprehensive verification statistics for all providers',
  })
  @ApiResponse({ 
    status: 200, 
    description: 'Verification statistics',
    type: VerificationStatsDto,
  })
  async getVerificationStats(): Promise<VerificationStatsDto> {
    return this.complianceService.getVerificationStats();
  }

  @Get('admin/providers')
  @UseGuards(RolesGuard)
  @Roles('admin')
  @ApiOperation({ 
    summary: 'Get providers by verification status (Admin)',
    description: 'Gets list of providers with filtering by verification status',
  })
  @ApiQuery({ 
    name: 'status', 
    required: false, 
    enum: VerificationStatus,
    description: 'Filter by verification status',
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
    summary: 'Specific provider details (Admin)',
    description: 'Gets verification details for a specific provider with logs',
  })
  @ApiParam({ name: 'providerId', description: 'Provider ID' })
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
    summary: 'Manual review (Admin)',
    description: 'Admin approves or rejects provider documents manually',
  })
  @ApiResponse({ 
    status: 200, 
    description: 'Review completed successfully',
    type: VerificationResponseDto,
  })
  async adminVerification(
    @UserDecorator('userId') adminId: string,
    @Body() dto: AdminVerificationDto,
  ): Promise<VerificationResponseDto> {
    this.logger.log(`🔍 Manual review by admin: ${adminId}`);
    return this.complianceService.adminVerification(adminId, dto);
  }

  @Get('admin/pending-review')
  @UseGuards(RolesGuard)
  @Roles('admin')
  @ApiOperation({ 
    summary: 'Providers awaiting review (Admin)',
    description: 'Gets list of providers that need manual review',
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
    summary: 'Expired providers (Admin)',
    description: 'Gets list of providers whose documents have expired',
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
    summary: 'Provider verification logs (Admin)',
    description: 'Gets log of all verification operations for a specific provider',
  })
  @ApiParam({ name: 'providerId', description: 'Provider ID' })
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
    summary: 'Check provider status',
    description: 'Checks if provider is verified (for internal use)',
  })
  @ApiParam({ name: 'providerId', description: 'Provider ID' })
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
      // Search for provider directly
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
