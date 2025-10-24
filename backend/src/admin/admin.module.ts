import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { Admin, AdminSchema } from './admin.entity';
import { User, UserSchema } from '../auth/user.entity';
import { ServiceProvider, ServiceProviderSchema } from '../providers/provider.entity';
// TODO: قم باستيراد Service و Booking عندما تنشئهم
// import { Service, ServiceSchema } from '../service/service.entity';
// import { Booking, BookingSchema } from '../booking/booking.entity';

@Module({
  imports: [
    MongooseModule.forFeature([
      // 👥 نموذج المسؤولين
      { name: Admin.name, schema: AdminSchema },
      // 👤 نموذج المستخدمين
      { name: User.name, schema: UserSchema },
      // 🏢 نموذج مقدمي الخدمة
      { name: ServiceProvider.name, schema: ServiceProviderSchema },
      // TODO: أضف هذه النماذج عندما تنشئها:
      // 🔧 نموذج الخدمات
      // { name: Service.name, schema: ServiceSchema },
      // 📅 نموذج الحجوزات
      // { name: Booking.name, schema: BookingSchema },
    ]),
  ],
  controllers: [AdminController],
  providers: [AdminService],
  exports: [AdminService, MongooseModule],
})
export class AdminModule {}