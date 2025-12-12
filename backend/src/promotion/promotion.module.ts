// src/promotion/promotion.module.ts
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { PromotionController } from './promotion.controller';
import { PromotionService } from './promotion.service';
import { PromotionCode, PromotionCodeSchema } from './promotion-code.schema';
import { User, UserSchema } from '../auth/user.entity';
import { AuthModule } from '../auth/auth.module';
import { NotificationModule } from '../notification/notification.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: PromotionCode.name, schema: PromotionCodeSchema },
      { name: User.name, schema: UserSchema },
    ]),
    AuthModule,
    NotificationModule,
  ],
  controllers: [PromotionController],
  providers: [PromotionService],
  exports: [PromotionService],
})
export class PromotionModule {} 