// src/promotion/promotion.controller.ts (Enhanced)
import { 
  Controller, 
  Post, 
  Get,
  Put,
  Delete,
  Body, 
  Param,
  Query,
  UseGuards, 
  Req,
  HttpCode,
  HttpStatus 
} from '@nestjs/common';
import { PromotionService } from './promotion.service';
import { 
  CreatePromotionCodeDto, 
  UpdatePromotionCodeDto,
  ApplyPromoCodeDto,
  BroadcastMessageDto 
} from './promotion.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { ApiBearerAuth, ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';

@ApiTags('Promotion')
@ApiBearerAuth()
@Controller('promotion')
export class PromotionController {
  constructor(private readonly promotionService: PromotionService) {}

  // ============ ADMIN ENDPOINTS ============
  
  @Post('admin/create-code')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create new promo code and broadcast to users' })
  @ApiResponse({ status: 201, description: 'Promo code created successfully' })
  async createPromoCode(@Body() dto: CreatePromotionCodeDto, @Req() req) {
    return this.promotionService.createAndBroadcastPromoCode(dto, req.user.userId);
  }

  @Get('admin/codes')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Get all promo codes' })
  async getAllPromoCodes() {
    return this.promotionService.getAllPromoCodes();
  }

  @Get('admin/stats')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Get promo code statistics' })
  async getPromoCodeStats() {
    return this.promotionService.getPromoCodeStats();
  }

  @Get('admin/codes/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Get promo code by ID' })
  async getPromoCodeById(@Param('id') id: string) {
    return this.promotionService.getPromoCodeById(id);
  }

  @Put('admin/codes/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Update promo code' })
  async updatePromoCode(
    @Param('id') id: string,
    @Body() dto: UpdatePromotionCodeDto
  ) {
    return this.promotionService.updatePromoCode(id, dto);
  }

  @Delete('admin/codes/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Delete promo code' })
  async deletePromoCode(@Param('id') id: string) {
    return this.promotionService.deletePromoCode(id);
  }

  @Post('admin/broadcast-message')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Send general broadcast message to all users' })
  async sendBroadcast(@Body() dto: BroadcastMessageDto) {
    return this.promotionService.broadcastGeneralMessage(dto);
  }

  // ============ USER ENDPOINTS ============
  
  @Post('validate-code')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Validate promo code for current cart amount' })
  @ApiResponse({ status: 200, description: 'Validation result with discount details' })
  async validatePromoCode(
    @Req() req,
    @Body() dto: ApplyPromoCodeDto,
    @Query('amount') amount: string
  ) {
    const cartAmount = parseFloat(amount);
    if (isNaN(cartAmount) || cartAmount <= 0) {
      return {
        valid: false,
        message: 'Invalid cart amount'
      };
    }

    return this.promotionService.validatePromoCode(
      req.user.userId,
      dto.promoCode,
      cartAmount
    );
  }

  // Legacy endpoint for backward compatibility
  @Post('promocode')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: '[LEGACY] Create promo code - use /admin/create-code instead' })
  async createPromoCodeLegacy(@Body() dto: CreatePromotionCodeDto, @Req() req) {
    return this.promotionService.createAndBroadcastPromoCode(dto, req.user.userId);
  }

  // Legacy endpoint
  @Post('broadcast')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: '[LEGACY] Broadcast message - use /admin/broadcast-message instead' })
  async sendBroadcastLegacy(@Body() dto: BroadcastMessageDto) {
    return this.promotionService.broadcastGeneralMessage(dto);
  }
}