// src/promotion/promotion.controller.ts
import { Controller, Post, Body, UseGuards, Req } from '@nestjs/common';
import { PromotionService } from './promotion.service';
import { CreatePromotionCodeDto, BroadcastMessageDto } from './promotion.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

@ApiTags('Admin/Promotion')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard) // Protect all endpoints in this controller
@Roles('admin') // Only users with the 'admin' role can access this controller
@Controller('promotion')
export class PromotionController {
  constructor(private readonly promotionService: PromotionService) {}

  // Endpoint to create a new promo code and broadcast it
  @Post('promocode')
  async createPromoCode(@Body() dto: CreatePromotionCodeDto, @Req() req) {
    // req.user.userId is available from JwtAuthGuard
    return this.promotionService.createAndBroadcastPromoCode(dto, req.user.userId);
  }

  // Endpoint to send a general broadcast email and notification
  @Post('broadcast')
  async sendBroadcast(@Body() dto: BroadcastMessageDto) {
    return this.promotionService.broadcastGeneralMessage(dto);
  }
}