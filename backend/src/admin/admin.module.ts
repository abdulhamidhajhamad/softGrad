
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AdminController } from './admin.controller';
import { UserComplaintController } from './user-complaint.controller'; // جديد
import { AdminService } from './admin.service';
import { Admin, AdminSchema } from './admin.entity';
import { User, UserSchema } from '../auth/user.entity';
import { ServiceProvider, ServiceProviderSchema } from '../providers/provider.entity';
import { Complaint, ComplaintSchema } from './complaint/complaint.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Admin.name, schema: AdminSchema },
      { name: User.name, schema: UserSchema },
      { name: ServiceProvider.name, schema: ServiceProviderSchema },
      { name: Complaint.name, schema: ComplaintSchema },
    ]),
  ],
  controllers: [AdminController, UserComplaintController], // إضافة الـ Controller الجديد
  providers: [AdminService],
  exports: [AdminService, MongooseModule],
})
export class AdminModule {}
