// payment.module.ts
import { Module, forwardRef } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ConfigModule } from '@nestjs/config';
import { PaymentController } from './payment.controller';
import { PaymentService } from './payment.service';
import { Cart, CartSchema } from '../shoppingCart/shoppingCart.schema';
import { User, UserSchema } from '../auth/user.entity';
import { BookingModule } from '../booking/booking.module';
import { PromotionModule } from '../promotion/promotion.module';
import { MailModule } from '../mail/mail.module';
import { NotificationModule } from '../notification/notification.module'; // ✅ إضافة فقط

@Module({
  imports: [
    ConfigModule,
    MongooseModule.forFeature([
      { name:  Cart.name, schema: CartSchema },
      { name: User. name, schema: UserSchema },
    ]),
    forwardRef(() => BookingModule),
    PromotionModule,
    MailModule,
    NotificationModule, // ✅ إضافة فقط
  ],
  controllers: [PaymentController],
  providers: [PaymentService],
  exports: [PaymentService],
})
export class PaymentModule {}