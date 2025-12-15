import { Module, forwardRef } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ConfigModule } from '@nestjs/config';
import { PaymentController } from './payment.controller';
import { PaymentService } from './payment.service';
import { Cart, CartSchema } from '../shoppingCart/shoppingCart.schema';
import { User, UserSchema } from '../auth/user.entity'; // 🆕 إضافة User Schema
import { BookingModule } from '../booking/booking.module';
import { PromotionModule } from '../promotion/promotion.module';
import { MailModule } from '../mail/mail.module'; // 🆕 إضافة MailModule

@Module({
  imports: [
    ConfigModule,
    MongooseModule.forFeature([
      { name: Cart.name, schema: CartSchema },
      { name: User.name, schema: UserSchema }, // 🆕 إضافة User Schema
    ]),
    forwardRef(() => BookingModule),
    PromotionModule,
    MailModule, 
  ],
  controllers: [PaymentController],
  providers: [PaymentService],
  exports: [PaymentService],
})
export class PaymentModule {}``