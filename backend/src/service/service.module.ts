import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ServiceController } from './service.controller';
import { ServiceService } from './service.service';
import { ServiceSchema } from './service.schema';
import { SupabaseStorageModule } from '../subbase/supabaseStorage.module';
// 🆕 استيراد نموذج المزود
import { ServiceProvider, ServiceProviderSchema } from '../providers/provider.entity'; // ⚠️ تأكد من صحة المسار
@Module({
  imports: [
    MongooseModule.forFeature([{ name: 'Service', schema: ServiceSchema }]),
    // 🆕 تسجيل نموذج ServiceProvider
    MongooseModule.forFeature([{ name: ServiceProvider.name, schema: ServiceProviderSchema }]), 
    SupabaseStorageModule, 
  ],
  controllers: [ServiceController],
  providers: [ServiceService],
  exports: [ServiceService]
})
export class ServiceModule {}