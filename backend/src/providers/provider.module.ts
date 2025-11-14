import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ProviderController } from './provider.controller';
import { ProviderService } from './provider.service';
import { ServiceProvider, ServiceProviderSchema } from './provider.entity';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: ServiceProvider.name, schema: ServiceProviderSchema }
    ]),
    AuthModule, 
  ],
  controllers: [ProviderController],
  providers: [ProviderService],
  exports: [ProviderService, MongooseModule],
})
export class ProviderModule {}