import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { AuthModule } from './auth/auth.module';
import { ProviderModule } from './providers/provider.module';
import { ServiceModule } from './service/service.module';
import { BookingModule } from './booking/booking.module';
import { AdminModule } from './admin/admin.module';
import { ShoppingCartModule } from './shoppingCart/shoppingCart.module';


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

    // باقي الموديولات
    AuthModule,
    ProviderModule,
    ServiceModule,
    BookingModule,
    AdminModule,
    ShoppingCartModule,
  ],
})
export class AppModule {}
