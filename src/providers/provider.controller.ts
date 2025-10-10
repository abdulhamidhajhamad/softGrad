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
  ParseIntPipe,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ProviderService } from './provider.service';
import { CreateProviderDto, UpdateProviderDto, SearchProviderDto, ProviderResponseDto } from './provider.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

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
    return await this.providerService.createProvider(userId, createProviderDto);
  }

  // Update provider profile (requires authentication)
  @Put()
  @UseGuards(JwtAuthGuard)
  async updateProvider(
    @Request() req,
    @Body() updateProviderDto: UpdateProviderDto,
  ): Promise<ProviderResponseDto> {
    const userId = req.user.userId;
    return await this.providerService.updateProvider(userId, updateProviderDto);
  }

  // Get my provider profile (requires authentication)
  @Get('me')
  @UseGuards(JwtAuthGuard)
  async getMyProfile(@Request() req): Promise<ProviderResponseDto> {
    const userId = req.user.userId;
    return await this.providerService.getProviderByUserId(userId);
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
    return await this.providerService.searchProviders(searchDto);
  }

  // Get all providers (public)
  @Get()
  async getAllProviders(): Promise<ProviderResponseDto[]> {
    return await this.providerService.getAllProviders();
  }

  // Get providers by location (public)
  @Get('location/:location')
  async getProvidersByLocation(
    @Param('location') location: string,
  ): Promise<ProviderResponseDto[]> {
    return await this.providerService.getProvidersByLocation(location);
  }

  // Get specific provider by ID (public)
  @Get(':id')
  async getProviderById(
    @Param('id', ParseIntPipe) providerId: number,
  ): Promise<ProviderResponseDto> {
    return await this.providerService.getProviderById(providerId);
  }

  @Delete()
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.NO_CONTENT)
  async deleteProvider(@Request() req): Promise<void> {
    const userId = req.user.userId;
    await this.providerService.deleteProvider(userId);
  }
}