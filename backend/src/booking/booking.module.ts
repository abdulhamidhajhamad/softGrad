import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { BookingController } from './booking.controller';
import { BookingService } from './booking.service';
import { Booking, BookingSchema } from './booking.entity';
import { Service, ServiceSchema } from '../service/service.schema';
import { ShoppingCart, ShoppingCartSchema } from '../shoppingCart/shoppingCart.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Booking.name, schema: BookingSchema },
      { name: Service.name, schema: ServiceSchema },
      { name: ShoppingCart.name, schema: ShoppingCartSchema }, // إضافة الشوبينغ كارت
    ]),
  ],
  controllers: [BookingController],
  providers: [BookingService],
  exports: [BookingService],
})
export class BookingModule {}