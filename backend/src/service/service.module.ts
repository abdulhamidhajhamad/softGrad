import { Module, forwardRef } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ServiceController } from './service.controller';
import { ServiceService } from './service.service';
import { ServiceSchema } from './service.schema';
import { SupabaseStorageModule } from '../subbase/supabaseStorage.module';
import { ServiceProvider, ServiceProviderSchema } from '../providers/provider.entity';
import { Review, ReviewSchema } from '../review/review.schema'; // ✅ NEW
import { OfferCleanupScheduler } from './offer-cleanup.scheduler'; // ✅ SCHEDULER
import { ComplianceProviderModule } from '../complianceProvider/compliance-provider.module'; // ✅ COMPLIANCE

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: 'Service', schema: ServiceSchema },
      { name: ServiceProvider.name, schema: ServiceProviderSchema },
      { name: Review.name, schema: ReviewSchema }, // ✅ NEW
    ]),
    SupabaseStorageModule, 
    forwardRef(() => ComplianceProviderModule), // ✅ COMPLIANCE
  ],
  controllers: [ServiceController],
  providers: [ServiceService, OfferCleanupScheduler], // ✅ ADD SCHEDULER
  exports: [ServiceService]
})
export class ServiceModule {}