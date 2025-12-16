// package.module.ts
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { PackageController } from './package.controller';
import { PackageService } from './package.service';
import { Package, PackageSchema } from './package.entity';
import { Service, ServiceSchema } from '../service/service.schema';
import { ServiceProvider, ServiceProviderSchema } from '../providers/provider.entity';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Package.name, schema: PackageSchema },
      { name: Service.name, schema: ServiceSchema },
      { name: ServiceProvider.name, schema: ServiceProviderSchema },
    ]),
  ],
  controllers: [PackageController],
  providers: [PackageService],
  exports: [PackageService, MongooseModule],
})
export class PackageModule {}