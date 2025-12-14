import { Module, forwardRef } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { BookingController } from './booking.controller';
import { BookingService } from './booking.service';
import { Booking, BookingSchema } from './booking.entity';
import { Service, ServiceSchema } from '../service/service.schema';
import { Cart, CartSchema } from '../shoppingCart/shoppingCart.schema';
import { User, UserSchema } from '../auth/user.entity';
import { NotificationModule } from '../notification/notification.module';
import { PaymentModule } from '../payment/payment.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Booking.name, schema: BookingSchema },
      { name: Service.name, schema: ServiceSchema },
      { name: Cart.name, schema: CartSchema },
      { name: User.name, schema: UserSchema },
    ]),
    NotificationModule,
    forwardRef(() => PaymentModule), // ✅ استخدام forwardRef لحل المشكلة
  ],
  controllers: [BookingController],
  providers: [BookingService],
  exports: [BookingService, MongooseModule],
})
export class BookingModule {}