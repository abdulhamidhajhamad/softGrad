// src/app.module.ts
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { BullModule } from '@nestjs/bull'; // 👈 NEW IMPORT
import { ScheduleModule } from '@nestjs/schedule'; // 👈 NEW IMPORT FOR CRON JOBS

import { AuthModule } from './auth/auth.module';
import { ProviderModule } from './providers/provider.module';
import { ServiceModule } from './service/service.module';
import { BookingModule } from './booking/booking.module';
import { AdminModule } from './admin/admin.module';
import { CartModule } from './shoppingCart/shoppingCart.module';
import { ChatModule } from './chatingService/chat.module';
import { PaymentModule } from './payment/payment.module';
import { PackageModule } from './Package/package.module'; // 💡 يجب استيراد هذه الوحدة
// ✅ NEW MODULE IMPORTS
import { NotificationModule } from './notification/notification.module';
import { PromotionModule } from './promotion/promotion.module';
import { ReviewModule } from './review/review.module';
import { AiSearchModule } from './ai-search/ai-search.module';
import { ComplianceProviderModule } from './complianceProvider/compliance-provider.module'; // ✅ COMPLIANCE
import { HealthModule } from './health/health.module'; // ✅ HEALTH & KEEP-ALIVE
import { ServeStaticModule } from '@nestjs/serve-static';
import { join } from 'path';
@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    ScheduleModule.forRoot(), // 👈 ADD SCHEDULE MODULE FOR CRON JOBS
    ServeStaticModule.forRoot({
      rootPath: join(__dirname, '..', 'public'),
      exclude: ['/auth*'], // استثني routes الـ API
    }),

    MongooseModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: async (configService: ConfigService) => ({
        uri:
          configService.get<string>('MONGO_URI') ||
          'mongodb+srv://fordep:0592370454@weddingplanner.ledafad.mongodb.net/?appName=weddingplanner',
        connectionFactory: (connection) => {
          connection.on('connected', () => {
            console.log('✅ MongoDB connected successfully to Atlas!');
            console.log(`📦 Database: ${connection.name}`);
          });
          connection.on('error', (err) => {
            console.error('❌ MongoDB connection error:', err.message);
          });
          connection.on('disconnected', () => {
            console.log('⚠️ MongoDB disconnected');
          });
          return connection;
        },
      }),
      inject: [ConfigService],
    }),

    BullModule.forRoot({
      redis: {
        host: process.env.REDIS_HOST || 'localhost',
        port: parseInt(process.env.REDIS_PORT || '6379'),
        password: process.env.REDIS_PASSWORD || undefined,
        maxRetriesPerRequest: 3, // Reduce from default 20
        enableReadyCheck: false,
        retryStrategy: (times) => {
          const delay = Math.min(times * 50, 2000);
          return delay;
        },
      },
    }),
    AuthModule,
    ProviderModule,
    ServiceModule,
    BookingModule,
    AdminModule,
    PackageModule,
    CartModule,
    ChatModule,
    ReviewModule,
    PaymentModule,
    NotificationModule,
    PromotionModule,
    AiSearchModule,
    ComplianceProviderModule, // ✅ COMPLIANCE MODULE
    HealthModule, // ✅ HEALTH CHECK & KEEP-ALIVE
  ],
  controllers: [],
  providers: [],
})
export class AppModule {}
