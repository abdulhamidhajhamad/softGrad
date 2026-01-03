import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ServiceController } from './service.controller';
import { ServiceService } from './service.service';
import { ServiceSchema } from './service.schema';
import { SupabaseStorageModule } from '../subbase/supabaseStorage.module';
import { ServiceProvider, ServiceProviderSchema } from '../providers/provider.entity';
import { Review, ReviewSchema } from '../review/review.schema'; // ✅ NEW

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: 'Service', schema: ServiceSchema },
      { name: ServiceProvider.name, schema: ServiceProviderSchema },
      { name: Review.name, schema: ReviewSchema }, // ✅ NEW
    ]),
    SupabaseStorageModule, 
  ],
  controllers: [ServiceController],
  providers: [ServiceService],
  exports: [ServiceService]
})
export class ServiceModule {}