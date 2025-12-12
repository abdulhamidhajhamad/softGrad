// cart.module.ts
// ============================================
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { CartController } from './shoppingCart.controller';
import { CartService } from './shoppingCart.service';
import { Cart, CartSchema } from './shoppingCart.schema';
import { Service, ServiceSchema } from '../service/service.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Cart.name, schema: CartSchema },
      { name: Service.name, schema: ServiceSchema },
    ]),
  ],
  controllers: [CartController],
  providers: [CartService],
  exports: [CartService, MongooseModule],
})
export class CartModule {}