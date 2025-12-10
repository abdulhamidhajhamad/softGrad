// booking.module.ts

import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { BookingController } from './booking.controller';
import { BookingService } from './booking.service';
import { Booking, BookingSchema } from './booking.entity';
import { Service, ServiceSchema } from '../service/service.schema';
import { ShoppingCart, ShoppingCartSchema } from '../shoppingCart/shoppingCart.schema';
// 👇 1. استيراد وحدة الإشعارات والـ User model
import { NotificationModule } from '../notification/notification.module'; 
import { User, UserSchema } from '../auth/user.entity'; // (لجلب توكن الـ Vendor)

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Booking.name, schema: BookingSchema },
      { name: Service.name, schema: ServiceSchema },
      { name: ShoppingCart.name, schema: ShoppingCartSchema },
      { name: User.name, schema: UserSchema }, // 👈 إضافة الـ User model
    ]),
    NotificationModule, // 👈 إضافة وحدة الإشعارات
  ],
  controllers: [BookingController],
  providers: [BookingService],
  exports: [BookingService],
})
export class BookingModule {}