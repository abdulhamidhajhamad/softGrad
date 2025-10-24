import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { BookingService } from './booking.service';
import { CreateBookingDto, UpdateBookingDto } from './booking.dto';
import { Booking } from './booking.entity';

@Controller('bookings')
export class BookingController {
  constructor(private readonly bookingService: BookingService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(@Body() dto: CreateBookingDto): Promise<Booking> {
    return this.bookingService.create(dto);
  }

  @Get()
  @HttpCode(HttpStatus.OK)
  async findAll(): Promise<Booking[]> {
    return this.bookingService.findAll();
  }

  @Get(':userName/:serviceName')
  @HttpCode(HttpStatus.OK)
  async findOne(
    @Param('userName') userName: string,
    @Param('serviceName') serviceName: string,
  ): Promise<Booking> {
    return this.bookingService.findOneByNames(userName, serviceName);
  }

  @Put(':userName/:serviceName')
  @HttpCode(HttpStatus.OK)
  async update(
    @Param('userName') userName: string,
    @Param('serviceName') serviceName: string,
    @Body() dto: UpdateBookingDto,
  ): Promise<Booking> {
    return this.bookingService.updateByNames(userName, serviceName, dto);
  }

  @Delete(':userName/:serviceName')
  @HttpCode(HttpStatus.OK)
  async delete(
    @Param('userName') userName: string,
    @Param('serviceName') serviceName: string,
  ): Promise<{ message: string }> {
    return this.bookingService.deleteByNames(userName, serviceName);
  }

  @Get('user/:userName')
  @HttpCode(HttpStatus.OK)
  async findByUser(@Param('userName') userName: string): Promise<Booking[]> {
    return this.bookingService.findByUser(userName);
  }
}