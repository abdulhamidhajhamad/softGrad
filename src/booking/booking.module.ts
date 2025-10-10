import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BookingController } from './booking.controller';
import { BookingService } from './booking.service';
import { Booking } from './booking.entity';
import { User } from '../auth/user.entity';
import { Service } from '../service/service.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Booking, User, Service])],
  controllers: [BookingController],
  providers: [BookingService],
  exports: [BookingService],
})
export class BookingModule {}
