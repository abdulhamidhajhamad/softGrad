import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  ParseIntPipe,
  HttpCode,
  HttpStatus,
  UseGuards,
  BadRequestException,
} from '@nestjs/common';
import { ServiceService } from './service.service';
import { CreateServiceDto, UpdateServiceDto } from './service.dto';
import { Service } from './service.entity';

@Controller('services')
export class ServiceController {
  constructor(private readonly serviceService: ServiceService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(@Body() createServiceDto: CreateServiceDto): Promise<Service> {
    return await this.serviceService.create(createServiceDto);
  }

  @Put(':id')
  @HttpCode(HttpStatus.OK)
  async update(
    @Param('id', ParseIntPipe) id: number,
    @Body() updateServiceDto: UpdateServiceDto,
  ): Promise<Service> {
    return await this.serviceService.update(id, updateServiceDto);
  }

  @Delete()
  @HttpCode(HttpStatus.OK)
  async delete(@Query('name') name: string): Promise<{ message: string }> {
    if (!name) {
      throw new BadRequestException('Service name is required');
    }
    return await this.serviceService.delete(name);
  }

  @Get()
  @HttpCode(HttpStatus.OK)
  async findAll(): Promise<Service[]> {
    return await this.serviceService.findAll();
  }

  @Get('provider')
  @HttpCode(HttpStatus.OK)
  async findByProvider(@Query('name') name: string): Promise<Service[]> {
    if (!name) {
      throw new BadRequestException('Provider name is required');
    }
    return await this.serviceService.findByProvider(name);
  }

  @Get(':id')
  @HttpCode(HttpStatus.OK)
  async findOne(@Param('id', ParseIntPipe) id: number): Promise<Service> {
    return await this.serviceService.findOne(id);
  }
}