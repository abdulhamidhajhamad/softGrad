// package.module.ts
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { PackageController } from './package.controller';
import { PackageService } from './package.service';
import { Package, PackageSchema } from './package.entity'; 
import { User, UserSchema } from '../auth/user.entity'; 
import { AuthModule } from '../auth/auth.module'; 
import { Service, ServiceSchema } from '../service/service.schema';
import { SupabaseStorageModule } from '../subbase/supabaseStorage.module'; // 👈 استيراد جديد
@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Package.name, schema: PackageSchema }, 
      { name: User.name, schema: UserSchema },
      { name: Service.name, schema: ServiceSchema }, 
    ]),
    AuthModule,
    SupabaseStorageModule, // 👈 إضافة Module 
  ],
  controllers: [PackageController], 
  providers: [PackageService], 
  exports: [PackageService, MongooseModule],
})
export class PackageModule {} 

