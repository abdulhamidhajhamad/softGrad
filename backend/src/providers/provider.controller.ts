import { Controller,HttpCode,HttpStatus, Post, Body, Patch, Delete, Get, Param, Req, UseGuards } from '@nestjs/common';
import { ProviderService } from './provider.service';
import { CreateServiceProviderDto, UpdateServiceProviderDto } from './provider.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { DeleteResult } from 'mongodb';
import { ServiceProvider } from './provider.entity';
// provider.controller.ts
@Controller('providers')
@UseGuards(JwtAuthGuard)
export class ProviderController {
  constructor(private readonly providerService: ProviderService) {}

@Post()
  @HttpCode(HttpStatus.CREATED)
  async create(@Req() req, @Body() dto: CreateServiceProviderDto): Promise<{ provider: ServiceProvider, token: string }> {
    try {
      const userId = req.user.userId;
      console.log('Creating provider for user:', userId);
     
      return await this.providerService.create(userId, dto);
    } catch (error) {
      throw error;
    }
  }


  @Get()
  async getAll(@Req() req) {
    const userId = req.user.userId;
    return this.providerService.findAllByUser(userId);
  }

  @Patch(':companyName')
  async update(
    @Req() req,
    @Param('companyName') companyName: string,
    @Body() dto: UpdateServiceProviderDto
  ) {
    const userId = req.user.userId;
    return this.providerService.update(userId, companyName, dto);
  }

  @Get('my-company-name')
  async getCompanyName(@Req() req): Promise<{ companyName: string }> {
    const userId = req.user.userId;
    const companyName = await this.providerService.findCompanyNameByUserId(userId);
    return { companyName };
  }
  
  @Delete(':companyName')
  async remove(@Req() req, @Param('companyName') companyName: string): Promise<DeleteResult> {
    const userId = req.user.userId;
    const isAdmin = req.user.role === 'admin';
    return this.providerService.remove(userId, companyName, isAdmin);
  }

  @Get(':companyName')
  async get(@Req() req, @Param('companyName') companyName: string) {
    const userId = req.user.userId;
    return this.providerService.findByName(userId, companyName);
  }
}