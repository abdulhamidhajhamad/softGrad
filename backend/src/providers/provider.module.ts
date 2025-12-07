// provider.module.ts (تأكد من هذه النسخة)

import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ProviderController } from './provider.controller';
import { ProviderService } from './provider.service';
import { ServiceProvider, ServiceProviderSchema } from './provider.entity';
// ✅ يجب استيراد User و UserSchema
import { User, UserSchema } from '../auth/user.entity'; 
import { AuthModule } from '../auth/auth.module'; // ✅ يجب استيرادها

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: ServiceProvider.name, schema: ServiceProviderSchema },
      // ✅ يجب إضافة نموذج المستخدم
      { name: User.name, schema: UserSchema }, 
    ]),
    // ✅ التأكد من وجود AuthModule هنا
    AuthModule, 
  ],
  controllers: [ProviderController],
  providers: [ProviderService],
  exports: [ProviderService, MongooseModule],
})
export class ProviderModule {}