/*
import { Injectable, BadRequestException, NotFoundException, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Document, Types } from 'mongoose';
import { CreateReviewDto } from './review.dto'; // يجب التأكد من وجود هذا الملف
import { Service } from '../service/service.schema'; // يجب التأكد من وجود هذا الملف
import { Booking, BookingDocument, PaymentStatus } from '../booking/booking.entity'; // يجب التأكد من وجود هذا الملف
import { AiAnalysisService, AiAnalysisUpdate } from '../ai-analysis/ai-analysis.service';

@Injectable()
export class ReviewService {
  private readonly logger = new Logger(ReviewService.name);

  constructor(
    @InjectModel(Service.name) private readonly serviceModel: Model<Service & Document>,
    @InjectModel(Booking.name) private readonly bookingModel: Model<BookingDocument>,
    private readonly aiAnalysisService: AiAnalysisService,
  ) {}
*/
  /**
   * 1. Check if the user is authorized to review (Booking status and date).
   * 2. Save the review to the Service document.
   * 3. Trigger the asynchronous AI analysis.
   */
  /*
  async createReviewAndAnalyze(
userId: string,
  dto: CreateReviewDto,
  files?: Express.Multer.File[] // استقبال الملفات
): Promise<{ reviewId: string }> {
  const { serviceId, bookingId, comment, rating } = dto;

  // 1. التحقق من الحجز (المنطق السابق يبقى كما هو)
  const booking = await this.bookingModel.findOne({
    _id: new Types.ObjectId(bookingId),
    userId: userId,
    'services.serviceId': serviceId,
  }).exec();

  if (!booking) throw new NotFoundException('Booking not found');

  // 2. رفع الصور إلى Supabase (إن وجدت)
  let imageUrls: string[] = [];
  if (files && files.length > 0) {
    // تأكد من حقن supabaseStorage في الـ constructor
    const uploadPromises = files.map(file => 
      this.supabaseStorage.uploadImage(file, 'review-images', true)
    );
    imageUrls = await Promise.all(uploadPromises);
  }

  // 3. إنشاء كائن التقييم الجديد مع الحقول المطلوبة
  const newReviewId = new Types.ObjectId(); 
  const review = {
    _id: newReviewId,
    userId: userId,
    userName: req.user?.name || 'User', 
    rating: Number(rating), // إلزامية
    comment: comment || '',  // اختيارية (وصف)
    images: imageUrls,      // اختيارية (صور)
    payType: dto.payType || 'per event', // قيمة افتراضية لتوافق السكيما
    createdAt: new Date(),
  };

  // 4. حفظ التقييم داخل مصفوفة reviews فقط
  const updatedService = await this.serviceModel.findByIdAndUpdate(
    serviceId,
    { $push: { reviews: review } },
    { new: true },
  ).exec();

  if (!updatedService) throw new NotFoundException('Service not found.');
      // ----------------------------------------------------
      // 🧠 3. تشغيل تحليل الذكاء الاصطناعي (Async/Background)
      // ----------------------------------------------------
      this.processAiAnalysis(serviceId, comment).catch(err => {
          this.logger.error(`AI Analysis failed in background for service ${serviceId}.`);
      });

      // 🛠️ FIX: الآن نرجع المعرّف الذي أنشأناه محلياً بدلاً من محاولة قراءته من الـ Array.
      return { reviewId: newReviewId.toString() };
        }

  /**
   * 🧠 دالة مساعدة لمعالجة تحليل الذكاء الاصطناعي وتحديث DB بشكل غير متزامن.
   */
  /*
  private async processAiAnalysis(serviceId: string, newComment: string): Promise<void> {
    try {
      // 💡 جلب البيانات السابقة
      const service = await this.serviceModel.findById(serviceId, 'reviews aiAnalysis').exec();
      if (!service) return;
      
      const previousComments = service.reviews.map(r => r.comment).slice(-5); // آخر 5 تعليقات

      // استدعاء خدمة الذكاء الاصطناعي (قد تُلقي خطأ هنا)
      const aiResult: AiAnalysisUpdate = await this.aiAnalysisService.analyzeReview(
        serviceId,
        newComment,
        previousComments,
      );

      // ✅ فقط إذا نجح التحليل (أي لم يتم إلقاء أي خطأ)، نقوم بالتحديث في الداتابيس
      await this.serviceModel.findByIdAndUpdate(serviceId, {
        $set: {
          'aiAnalysis.score': aiResult.score,
          'aiAnalysis.tags': aiResult.tags,
          'aiAnalysis.bestFor': aiResult.bestFor,
          'aiAnalysis.lastUpdated': new Date(),
        },
      }).exec();

      this.logger.log(`Service ${serviceId} AI analysis successfully updated.`);

    } catch (error) {
      // 🛑 عند فشل الـ AI Analysis:
      // يتم التقاط الخطأ هنا، ويتم تسجيل تحذير، وبذلك نتخطى تحديث الـ DB.
      // هذا يضمن أن بيانات aiAnalysis القديمة تبقى سليمة.
      this.logger.warn(`Skipping AI analysis update for ${serviceId} due to error: ${error.message}`);
    }
  }

}
  */
