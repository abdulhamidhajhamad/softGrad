import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { Admin } from './admin.entity';
import { User } from '../auth/user.entity';
import { ServiceProvider } from '../providers/provider.entity';
import { Service } from '../service/service.entity';
import { Booking } from '../booking/booking.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Admin, User, ServiceProvider, Service, Booking])],
  controllers: [AdminController],
  providers: [AdminService],
  exports: [AdminService],
})
export class AdminModule {}