/*
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ReviewController } from './review.controller';
import { ReviewService } from './review.service';
import { AiAnalysisModule } from '../ai-analysis/ai-analysis.module'; 
import { Service, ServiceSchema } from '../service/service.schema';
import { Booking, BookingSchema } from '../booking/booking.entity'; 

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Service.name, schema: ServiceSchema },
      { name: Booking.name, schema: BookingSchema },
    ]),
    AiAnalysisModule, 
  ],
  controllers: [ReviewController],
  providers: [ReviewService], 
  exports: [ReviewService],
})
export class ReviewModule {}
*/