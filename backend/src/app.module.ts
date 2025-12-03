// src/app.module.ts
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { BullModule } from '@nestjs/bull'; // 👈 NEW IMPORT

import { AuthModule } from './auth/auth.module';
import { ProviderModule } from './providers/provider.module';
import { ServiceModule } from './service/service.module';
import { BookingModule } from './booking/booking.module';
import { AdminModule } from './admin/admin.module';
import { ShoppingCartModule } from './shoppingCart/shoppingCart.module';
import { FirebaseModule } from './firebase/firebase.module';
import { ChatModule } from './chatingService/chat.module';
import { PaymentModule } from './payment/payment.module';

// ✅ NEW MODULE IMPORTS
import { NotificationModule } from './notification/notification.module';
import { PromotionModule } from './promotion/promotion.module'; 

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),

    MongooseModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: async (configService: ConfigService) => ({
        uri: configService.get<string>('MONGO_URI') || 'mongodb://localhost:27017/WeddingPlanner',
      }),
      inject: [ConfigService],
    }),

    // 🌟 SOLUTION: Initialize BullModule with Redis connection details
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
    ShoppingCartModule,
    FirebaseModule,
    ChatModule,
    PaymentModule,
    NotificationModule,
    PromotionModule,

  ],
  controllers: [],
  providers: [],
})
export class AppModule {}