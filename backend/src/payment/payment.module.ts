import { Module, forwardRef } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ConfigModule } from '@nestjs/config';
import { PaymentController } from './payment.controller';
import { PaymentService } from './payment.service';
import { Cart, CartSchema } from '../shoppingCart/shoppingCart.schema';
import { BookingModule } from '../booking/booking.module';
import { PromotionModule } from '../promotion/promotion.module';

@Module({
  imports: [
    ConfigModule,
    MongooseModule.forFeature([
      { name: Cart.name, schema: CartSchema },
    ]),
    forwardRef(() => BookingModule), // ✅ استخدام forwardRef لحل المشكلة
    PromotionModule,
  ],
  controllers: [PaymentController],
  providers: [PaymentService],
  exports: [PaymentService],
})
export class PaymentModule {}