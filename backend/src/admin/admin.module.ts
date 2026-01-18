import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AdminController } from './admin.controller';
import { UserComplaintController } from './user-complaint.controller';
import { AdminService } from './admin.service';
import { Admin, AdminSchema } from './admin.entity';
import { User, UserSchema } from '../auth/user.entity';
import { ServiceProvider, ServiceProviderSchema } from '../providers/provider.entity';
import { Complaint, ComplaintSchema } from './complaint/complaint.schema';
import { AdminStats, AdminStatsSchema } from './admin-stats.schema';
import { Booking, BookingSchema } from '../booking/booking.entity';
import { Service, ServiceSchema } from '../service/service.schema';
import { Package, PackageSchema } from '../Package/package.entity';
import { Review, ReviewSchema } from '../review/review.schema'; // ✅ إضافة

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Admin.name, schema: AdminSchema },
      { name: User.name, schema: UserSchema },
      { name:  ServiceProvider.name, schema: ServiceProviderSchema },
      { name: Complaint. name, schema: ComplaintSchema },
      { name: AdminStats.name, schema: AdminStatsSchema },
      { name:  Booking.name, schema: BookingSchema },
      { name: Service.name, schema: ServiceSchema },
      { name:  Package.name, schema: PackageSchema },
      { name:  Review.name, schema: ReviewSchema }, // ✅ إضافة
    ]),
  ],
  controllers:  [AdminController, UserComplaintController],
  providers: [AdminService],
  exports: [AdminService, MongooseModule],
})
export class AdminModule {}