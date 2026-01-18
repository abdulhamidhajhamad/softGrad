// compliance-provider.module.ts
import { Module, forwardRef } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ScheduleModule } from '@nestjs/schedule';
import { ConfigModule } from '@nestjs/config';

// Entities & Schemas
import { 
  ComplianceLog, 
  ComplianceLogSchema 
} from './entities/compliance-log.entity';
import { 
  ServiceProvider, 
  ServiceProviderSchema 
} from '../providers/provider.entity';
import { Service, ServiceSchema } from '../service/service.schema';
import { User, UserSchema } from '../auth/user.entity';

// Services
import { ComplianceProviderService } from './compliance-provider.service';
import { ExpiryCheckCronService } from './tasks/expiry-check.cron';

// Controllers
import { ComplianceProviderController } from './compliance-provider.controller';

// Guards
import { VerificationGuard, SimpleVerificationGuard } from './guards/verification.guard';

// External Modules
import { NotificationModule } from '../notification/notification.module';
import { SupabaseStorageModule } from '../subbase/supabaseStorage.module';

@Module({
  imports: [
    // MongoDB Schemas
    MongooseModule.forFeature([
      { name: ComplianceLog.name, schema: ComplianceLogSchema },
      { name: ServiceProvider.name, schema: ServiceProviderSchema },
      { name: Service.name, schema: ServiceSchema },
      { name: User.name, schema: UserSchema },
    ]),
    
    // Schedule for Cron Jobs
    ScheduleModule.forRoot(),
    
    // Config for environment variables
    ConfigModule,
    
    // Notification Module for sending alerts
    forwardRef(() => NotificationModule),
    
    // Supabase for file storage
    SupabaseStorageModule,
  ],
  controllers: [ComplianceProviderController],
  providers: [
    ComplianceProviderService,
    ExpiryCheckCronService,
    VerificationGuard,
    SimpleVerificationGuard,
  ],
  exports: [
    ComplianceProviderService,
    VerificationGuard,
    SimpleVerificationGuard,
    ExpiryCheckCronService,
  ],
})
export class ComplianceProviderModule {}
