// src/review/review.service.ts
import { Injectable, BadRequestException, NotFoundException, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { CreateReviewDto, GetReviewsQueryDto, GetMyReviewsQueryDto } from './review.dto';
import { Review } from './review.schema';
import { Service } from '../service/service.schema';
import { Booking, BookingStatus } from '../booking/booking.entity';
import { User } from '../auth/user.entity';
import { AiAnalysisService, AiAnalysisUpdate } from '../ai-analysis/ai-analysis.service';
import { NotificationService } from '../notification/notification.service';
import { NotificationType, RecipientType } from '../notification/notification.schema';

@Injectable()
export class ReviewService {
  private readonly logger = new Logger(ReviewService.name);

  constructor(
    @InjectModel(Review.name) private readonly reviewModel: Model<Review>,
    @InjectModel(Service.name) private readonly serviceModel: Model<Service>,
    @InjectModel(Booking.name) private readonly bookingModel: Model<Booking>,
    @InjectModel(User.name) private readonly userModel: Model<User>,
    private readonly aiAnalysisService: AiAnalysisService,
    private readonly notificationService: NotificationService,
  ) {}

  /**
   * ✅ 1. التحقق من إمكانية المراجعة
   */
  async canUserReview(userId: string, bookingId: string): Promise<{ canReview: boolean; reason?: string }> {
    try {
      const booking = await this.bookingModel.findOne({
        _id: new Types.ObjectId(bookingId),
        userId: new Types.ObjectId(userId),
      }).exec();

      if (!booking) {
        return { canReview: false, reason: 'Booking not found or does not belong to you' };
      }

      if (booking.status !== BookingStatus.CONFIRMED && booking.status !== BookingStatus.COMPLETED) {
        return { canReview: false, reason: 'Booking must be confirmed or completed' };
      }

      const bookingDate = new Date(booking.bookingDetails.date);
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      if (bookingDate >= today) {
        return { canReview: false, reason: 'Cannot review before the booking date has passed' };
      }

      if (booking.isReviewed) {
        return { canReview: false, reason: 'You have already reviewed this booking' };
      }

      return { canReview: true };
    } catch (error) {
      this.logger.error(`Error in canUserReview: ${error.message}`);
      throw new BadRequestException('Failed to check review eligibility');
    }
  }

  /**
   * ✅ 2. إنشاء Review + تحديث Booking + تحديث Service Stats + AI Analysis + Notification
   */
  async createReview(userId: string, dto: CreateReviewDto): Promise<Review> {
    const { serviceId, bookingId, rating, comment, images } = dto;

    // 🔍 1. التحقق من الصلاحية
    const eligibility = await this.canUserReview(userId, bookingId);
    if (!eligibility.canReview) {
      throw new BadRequestException(eligibility.reason);
    }

    // 🔍 2. جلب بيانات المستخدم والخدمة
    const user = await this.userModel.findById(userId).select('userName').exec();
    if (!user) throw new NotFoundException('User not found');

    const service = await this.serviceModel.findById(serviceId).exec();
    if (!service) throw new NotFoundException('Service not found');

    // 💾 3. حفظ الـ Review في الجدول الجديد
    const newReview = await this.reviewModel.create({
      userId: new Types.ObjectId(userId),
      serviceId: new Types.ObjectId(serviceId),
      bookingId: new Types.ObjectId(bookingId),
      rating: Number(rating),
      comment: comment || '',
      images: images || [],
      userName: user.userName,
      isVisible: true,
    });

    this.logger.log(`✅ Review created with ID: ${newReview._id}`);

    // 📝 4. تحديث حالة الـ Booking
    await this.bookingModel.findByIdAndUpdate(bookingId, {
      $set: {
        isReviewed: true,
        reviewedAt: new Date(),
      },
    }).exec();

    // 📊 5. تحديث إحصائيات الخدمة (averageRating & totalReviews)
    await this.updateServiceRatingStats(serviceId);

    // 🧠 6. تشغيل AI Analysis في الخلفية (Async)
    this.processAiAnalysis(serviceId, comment || '').catch(err => {
      this.logger.error(`AI Analysis failed for service ${serviceId}: ${err.message}`);
    });

    // 🔔 7. إرسال إشعار للـ Vendor
    await this.sendReviewNotificationToVendor(
      service, 
      user.userName, 
      rating, 
      (newReview._id as Types.ObjectId).toString()
    );

    return newReview;
  }

  /**
   * ✅ 3. تحديث إحصائيات التقييم (averageRating & totalReviews)
   */
  private async updateServiceRatingStats(serviceId: string): Promise<void> {
    const stats = await this.reviewModel.aggregate([
      { $match: { serviceId: new Types.ObjectId(serviceId), isVisible: true } },
      {
        $group: {
          _id: null,
          averageRating: { $avg: '$rating' },
          totalReviews: { $sum: 1 },
        },
      },
    ]).exec();

    const { averageRating = 0, totalReviews = 0 } = stats[0] || {};

    await this.serviceModel.findByIdAndUpdate(serviceId, {
      $set: {
        averageRating: Math.round(averageRating * 10) / 10, // تقريب لأقرب رقم عشري
        totalReviews,
      },
    }).exec();

    this.logger.log(`📊 Service ${serviceId} stats updated: ${averageRating.toFixed(1)} (${totalReviews} reviews)`);
  }

  /**
   * 🧠 4. معالجة AI Analysis باستخدام Gemini
   */
  private async processAiAnalysis(serviceId: string, newComment: string): Promise<void> {
    try {
      // 📖 جلب آخر 5 تعليقات من الجدول الجديد
      const recentReviews = await this.reviewModel
        .find({ serviceId: new Types.ObjectId(serviceId), isVisible: true })
        .sort({ createdAt: -1 })
        .limit(5)
        .select('comment')
        .exec();

      const previousComments = recentReviews.map(r => r.comment).filter(c => c);

      // 🤖 استدعاء Gemini API
      const aiResult: AiAnalysisUpdate = await this.aiAnalysisService.analyzeReview(
        serviceId,
        newComment,
        previousComments,
      );

      // ✅ تحديث حقل aiAnalysis في Service
      await this.serviceModel.findByIdAndUpdate(serviceId, {
        $set: {
          'aiAnalysis.score': aiResult.score,
          'aiAnalysis.tags': aiResult.tags,
          'aiAnalysis.bestFor': aiResult.bestFor,
          'aiAnalysis.lastUpdated': new Date(),
        },
      }).exec();

      this.logger.log(`🧠 AI Analysis updated for service ${serviceId}: Score ${aiResult.score.toFixed(2)}`);
    } catch (error) {
      this.logger.warn(`⚠️ AI Analysis skipped for ${serviceId}: ${error.message}`);
    }
  }

  /**
   * 🔔 5. إرسال إشعار للـ Vendor
   */
  private async sendReviewNotificationToVendor(
    service: Service,
    userName: string,
    rating: number,
    reviewId: string,
  ): Promise<void> {
    try {
      const vendor = await this.userModel.findById(service.providerId).select('fcmToken').lean().exec();
      const fcmToken = (vendor as any)?.fcmToken;

      await this.notificationService.createNotification(
        {
          recipientId: new Types.ObjectId(service.providerId),
          recipientType: RecipientType.VENDOR,
          title: 'New Review Received',
          body: `${userName} rated "${service.serviceName}" with ${rating} stars`,
          type: NotificationType.NEW_REVIEW,
          metadata: {
            reviewId,
            serviceId: (service._id as Types.ObjectId).toString(),
            serviceName: service.serviceName,
            rating,
            userName,
          },
        },
        fcmToken || '',
      );

      this.logger.log(`🔔 Review notification sent to vendor ${service.providerId}`);
    } catch (error) {
      this.logger.error(`❌ Failed to send review notification: ${error.message}`);
    }
  }

  /**
   * ✅ 6. جلب Reviews لخدمة معينة (مع Pagination)
   */
  async getServiceReviews(serviceId: string, query: GetReviewsQueryDto) {
    const { page = 1, limit = 10 } = query;
    const skip = (page - 1) * limit;

    const [reviews, totalCount] = await Promise.all([
      this.reviewModel
        .find({ serviceId: new Types.ObjectId(serviceId), isVisible: true })
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .populate('userId', 'userName imageUrl')
        .lean()
        .exec(),
      this.reviewModel.countDocuments({ serviceId: new Types.ObjectId(serviceId), isVisible: true }),
    ]);

    const service = await this.serviceModel.findById(serviceId).select('averageRating totalReviews').lean().exec();

    return {
      reviews,
      totalCount,
      page,
      totalPages: Math.ceil(totalCount / limit),
      averageRating: service?.averageRating || 0,
      totalReviews: service?.totalReviews || 0,
    };
  }

  /**
   * ✅ 7. جلب الحجوزات المعلقة (Pending Reviews)
   */
  async getPendingReviews(userId: string) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const bookings = await this.bookingModel
      .find({
        userId: new Types.ObjectId(userId),
        status: { $in: [BookingStatus.CONFIRMED, BookingStatus.COMPLETED] },
        'bookingDetails.date': { $lt: today },
        isReviewed: false,
      })
      .populate('serviceId', 'serviceName images')
      .sort({ 'bookingDetails.date': -1 })
      .lean()
      .exec();

    return bookings.map(b => ({
      bookingId: b._id,
      serviceId: (b.serviceId as any)?._id,
      serviceName: (b.serviceId as any)?.serviceName,
      serviceImage: (b.serviceId as any)?.images?.[0],
      bookingDate: b.bookingDetails.date,
    }));
  }

  /**
   * ✅ 8. جلب Reviews الخاصة بالمستخدم
   */
  async getMyReviews(userId: string, query: GetMyReviewsQueryDto) {
    const { page = 1, limit = 10 } = query;
    const skip = (page - 1) * limit;

    const [reviews, totalCount] = await Promise.all([
      this.reviewModel
        .find({ userId: new Types.ObjectId(userId) })
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .populate('serviceId', 'serviceName images companyName')
        .lean()
        .exec(),
      this.reviewModel.countDocuments({ userId: new Types.ObjectId(userId) }),
    ]);

    return {
      reviews,
      totalCount,
      page,
      totalPages: Math.ceil(totalCount / limit),
    };
  }
}