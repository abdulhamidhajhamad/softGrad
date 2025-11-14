import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ShoppingCartController } from './shoppingCart.controller';
import { ShoppingCartService } from './shoppingCart.service';
import { ShoppingCart, ShoppingCartSchema } from './shoppingCart.schema';
import { Service, ServiceSchema } from '../service/service.schema';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: ShoppingCart.name, schema: ShoppingCartSchema },
      { name: Service.name, schema: ServiceSchema }
    ]),
    AuthModule 
  ],
  controllers: [ShoppingCartController],
  providers: [ShoppingCartService],
  exports: [ShoppingCartService]
})
export class ShoppingCartModule {}