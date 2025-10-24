import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ProviderService } from './provider.service';
import { CreateProviderDto, UpdateProviderDto, SearchProviderDto, ProviderResponseDto } from './provider.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ServiceProvider } from './provider.entity';
import { Types } from 'mongoose';

@Controller('providers')
export class ProviderController {
  constructor(private readonly providerService: ProviderService) {}

  // Create provider profile (requires authentication)
  @Post()
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.CREATED)
  async createProvider(
    @Request() req,
    @Body() createProviderDto: CreateProviderDto,
  ): Promise<ProviderResponseDto> {
    const userId = req.user.userId;
    const provider = await this.providerService.createProvider(userId, createProviderDto);
    return this.mapToResponseDto(provider);
  }

  // Update provider profile (requires authentication)
  @Put()
  @UseGuards(JwtAuthGuard)
  async updateProvider(
    @Request() req,
    @Body() updateProviderDto: UpdateProviderDto,
  ): Promise<ProviderResponseDto> {
    const userId = req.user.userId;
    const provider = await this.providerService.updateProvider(userId, updateProviderDto);
    return this.mapToResponseDto(provider);
  }

  // Get my provider profile (requires authentication)
  @Get('me')
  @UseGuards(JwtAuthGuard)
  async getMyProfile(@Request() req): Promise<ProviderResponseDto> {
    const userId = req.user.userId;
    const provider = await this.providerService.getProviderByUserId(userId);
    return this.mapToResponseDto(provider);
  }

  // Search providers (public)
  @Get('search')
  async searchProviders(
    @Query() searchDto: SearchProviderDto,
  ): Promise<{
    providers: ProviderResponseDto[];
    total: number;
    page: number;
    totalPages: number;
  }> {
    const result = await this.providerService.searchProviders(searchDto);
    return {
      providers: result.providers.map(provider => this.mapToResponseDto(provider)),
      total: result.total,
      page: result.page,
      totalPages: result.totalPages,
    };
  }

  // Get all providers (public)
  @Get()
  async getAllProviders(): Promise<ProviderResponseDto[]> {
    const providers = await this.providerService.getAllProviders();
    return providers.map(provider => this.mapToResponseDto(provider));
  }

  // Get providers by location (public)
  @Get('location/:location')
  async getProvidersByLocation(
    @Param('location') location: string,
  ): Promise<ProviderResponseDto[]> {
    const providers = await this.providerService.getProvidersByLocation(location);
    return providers.map(provider => this.mapToResponseDto(provider));
  }

  // Get specific provider by ID (public)
  @Get(':id')
  async getProviderById(
    @Param('id') providerId: string,
  ): Promise<ProviderResponseDto> {
    const provider = await this.providerService.getProviderById(providerId);
    return this.mapToResponseDto(provider);
  }

  @Delete()
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.NO_CONTENT)
  async deleteProvider(@Request() req): Promise<void> {
    const userId = req.user.userId;
    await this.providerService.deleteProvider(userId);
  }

  private mapToResponseDto(provider: ServiceProvider): ProviderResponseDto {
    return {
      providerId: (provider._id as Types.ObjectId).toString(),
      userId: (provider.userId as Types.ObjectId).toString(),
      companyName: provider.companyName,
      description: provider.description || '',
      location: provider.location || '',
      imageUrls: provider.imageUrls || [],
      customerType: provider.customerType,
      details: provider.details || {},
    };
  }
}