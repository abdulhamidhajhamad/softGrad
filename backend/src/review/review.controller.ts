import { Controller, Post, Body, UseGuards, Request, HttpCode, HttpStatus, UnauthorizedException } from '@nestjs/common';import { JwtAuthGuard } from '../auth/jwt-auth.guard'; 
import { ReviewService } from './review.service';
import { CreateReviewDto } from './review.dto'; 

@Controller('reviews')
export class ReviewController {
    constructor(private readonly reviewService: ReviewService) {}

    @Post()
    @UseGuards(JwtAuthGuard)
    @HttpCode(HttpStatus.CREATED)
    async addReview(
        @Body() dto: CreateReviewDto, 
        @Request() req: any
    ) {
        const userId = req.user?.userId || req.user?.sub || req.user?.id;
        if (!userId) {
            throw new UnauthorizedException('User ID not found in token payload. Please ensure you are logged in.');
        }
        return this.reviewService.createReviewAndAnalyze(userId, dto);
    }
}