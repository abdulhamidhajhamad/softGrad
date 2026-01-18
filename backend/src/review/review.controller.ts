// src/review/review.controller.ts
import {
  Controller,
  Post,
  Get,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
  HttpCode,
  HttpStatus,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ReviewService } from './review.service';
import { CreateReviewDto, GetReviewsQueryDto, GetMyReviewsQueryDto } from './review.dto';

@Controller('reviews')
export class ReviewController {
  constructor(private readonly reviewService: ReviewService) {}

  /**
   * ✅ POST /reviews - إضافة تقييم جديد
   */
  @Post()
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.CREATED)
  async createReview(@Body() dto: CreateReviewDto, @Request() req: any) {
    const userId = req.user?.userId || req.user?.sub || req.user?.id;
    if (!userId) {
      throw new UnauthorizedException('User ID not found in token');
    }
    return this.reviewService.createReview(userId, dto);
  }

  /**
   * ✅ GET /reviews/service/:serviceId - جلب تقييمات خدمة معينة
   */
  @Get('service/:serviceId')
  @HttpCode(HttpStatus.OK)
  async getServiceReviews(@Param('serviceId') serviceId: string, @Query() query: GetReviewsQueryDto) {
    return this.reviewService.getServiceReviews(serviceId, query);
  }

  /**
   * ✅ GET /reviews/can-review/:bookingId - التحقق من إمكانية المراجعة
   */
  @Get('can-review/:bookingId')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  async canReview(@Param('bookingId') bookingId: string, @Request() req: any) {
    const userId = req.user?.userId || req.user?.sub || req.user?.id;
    if (!userId) {
      throw new UnauthorizedException('User ID not found in token');
    }
    return this.reviewService.canUserReview(userId, bookingId);
  }

  /**
   * ✅ GET /reviews/pending - جلب الحجوزات التي لم تُراجع
   */
  @Get('pending')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  async getPendingReviews(@Request() req: any) {
    const userId = req.user?.userId || req.user?.sub || req.user?.id;
    if (!userId) {
      throw new UnauthorizedException('User ID not found in token');
    }
    return this.reviewService.getPendingReviews(userId);
  }

  /**
   * ✅ GET /reviews/my-reviews - جلب تقييمات المستخدم
   */
  @Get('my-reviews')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  async getMyReviews(@Query() query: GetMyReviewsQueryDto, @Request() req: any) {
    const userId = req.user?.userId || req.user?.sub || req.user?.id;
    if (!userId) {
      throw new UnauthorizedException('User ID not found in token');
    }
    return this.reviewService.getMyReviews(userId, query);
  }
}