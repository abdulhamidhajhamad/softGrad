// payment.module.ts (Updated)
// ============================================
import { Module } from '@nestjs/common';
import { PaymentController } from './payment.controller';
import { PaymentService } from './payment.service';
import { ConfigModule } from '@nestjs/config';
import { CartModule } from '../shoppingCart/shoppingCart.module';
import { BookingModule } from '../booking/booking.module';

@Module({
  imports: [
    ConfigModule,
    CartModule,
    BookingModule,
  ],
  controllers: [PaymentController],
  providers: [PaymentService],
  exports: [PaymentService],
})
export class PaymentModule {}