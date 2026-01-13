// booking.service.ts
import { Injectable, HttpException, HttpStatus, Logger, NotFoundException, BadRequestException, Inject, forwardRef } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Booking, BookingStatus } from './booking.entity';
import { Service, BookingType } from '../service/service.schema';
import { Cart } from '../shoppingCart/shoppingCart.schema';
import { NotificationService } from '../notification/notification.service';
import { NotificationType, RecipientType } from '../notification/notification.schema';
import { User } from '../auth/user.entity';
import Stripe from 'stripe';
import { ConfigService } from '@nestjs/config';
import { PaymentService } from '../payment/payment.service';

@Injectable()
export class BookingService {
  private readonly logger = new Logger(BookingService.name);
  private stripe: Stripe;

  constructor(
    @InjectModel(Booking.name) private bookingModel: Model<Booking>,
    @InjectModel(Service.name) private serviceModel: Model<Service>,
    @InjectModel(Cart.name) private cartModel: Model<Cart>,
    @InjectModel(User.name) private userModel: Model<User>,
    private notificationService: NotificationService,
    private configService: ConfigService,
    @Inject(forwardRef(() => PaymentService)) // ✅ استخدام forwardRef في الحقن
    private paymentService: PaymentService,
  ) {
    const secretKey = this.configService.get<string>('STRIPE_SECRET_KEY');
    if (!secretKey) {
      throw new Error('STRIPE_SECRET_KEY is not set');
    }
this.stripe = new Stripe(secretKey);
  }


  /**
   * 📌 إنشاء حجوزات منفصلة من السلة بعد نجاح الدفع
   * كل خدمة في السلة = booking منفصل
   */
  /**
 * 📌 إنشاء حجوزات منفصلة من السلة بعد نجاح الدفع (مع دعم الباقات)
 */
async createBookingsFromCart(userId: string, paymentIntentId: string): Promise<Booking[]> {
  const userObjectId = new Types.ObjectId(userId);
  const cart = await this.cartModel.findOne({ userId: userObjectId }).populate('items.serviceId').exec();

  if (!cart || cart.items.length === 0) {
    this.logger.warn(`Cart is empty for user ${userId}. No bookings created.`);
    return [];
  }

  // 💤 جلب معلومات المستخدم لإرساله في الإشعار
  const user = await this.userModel.findById(userObjectId).select('name email').lean().exec();
  const clientName = (user as any)?.name || (user as any)?.email || 'Client';

  const createdBookings: Booking[] = [];
  
  // لتجميع الإشعارات حسب الـ vendor (لإرسال إشعار واحد لكل vendor عن الباقة)
  const packageNotifications: Map<string, { 
    packageName: string, 
    services: string[], 
    date: string,
    fcmToken?: string 
  }> = new Map();

  // 🔄 التكرار على كل عنصر في السلة لإنشاء حجز منفصل
  for (const item of cart.items) {
    const service = item.serviceId as any;

    const newBooking = new this.bookingModel({
      userId: userObjectId,
      paymentIntentId: paymentIntentId,
      serviceId: service._id,
      serviceName: service.serviceName,
      providerId: service.providerId,
      companyName: service.companyName,
      bookingType: service.bookingType,
      bookingDetails: {
        date: item.bookingDetails.date,
        startHour: item.bookingDetails.startHour,
        endHour: item.bookingDetails.endHour,
        numberOfPeople: item.bookingDetails.numberOfPeople,
        isFullVenue: item.bookingDetails.isFullVenue,
      },
      price: item.price,
      status: BookingStatus.CONFIRMED,
      refunded: false,
      seen: false,
    });

    const booking = await newBooking.save();
    createdBookings.push(booking);

    // 📅 تنسيق التاريخ
    const bookingDateStr = new Date(item.bookingDetails.date).toLocaleDateString('en-GB');

    // إذا كان الحجز جزء من باقة
    if (item.packageId && item.packageName) {
      const vendorId = service.providerId.toString();
      
      if (!packageNotifications.has(vendorId)) {
        // جلب FCM token للـ vendor
        const vendor = await this.userModel.findById(service.providerId).select('fcmToken').lean().exec();
        
        packageNotifications.set(vendorId, {
          packageName: item.packageName,
          services: [service.serviceName],
          date: bookingDateStr,
          fcmToken: (vendor as any)?.fcmToken
        });
      } else {
        const notification = packageNotifications.get(vendorId);      
      if (notification) {
             notification.services.push(service.serviceName);
        }
      }
    } else {
      // 🔧 جلب FCM token للـ vendor (للحجوزات العادية)
      const vendor = await this.userModel.findById(service.providerId).select('fcmToken').lean().exec();
      const vendorFcmToken = (vendor as any)?.fcmToken as string | undefined;

      // 🔔 إرسال الإشعار للـ vendor (حجز عادي)
      const notificationBody = `${service.serviceName} has been booked successfully at ${bookingDateStr} by ${clientName}`;
      
      try {
        await this.notificationService.createNotification(
          {
            recipientId: new Types.ObjectId(service.providerId),
            recipientType: RecipientType.VENDOR,
            title: 'New Booking Confirmed',
            body: notificationBody,
            type: NotificationType.BOOKING_CONFIRMED,
            metadata: { 
              bookingId: (booking._id as Types.ObjectId).toString(), 
              serviceId: service._id.toString(),
              clientName: clientName,
              bookingDate: bookingDateStr,
            }
          },
          vendorFcmToken || ''
        );
      } catch (notifError) {
        this.logger.error(`Failed to send notification for booking ${booking._id}:`, notifError.message);
      }
    }
  }

  // 📦 إرسال إشعارات الباقات (إشعار واحد لكل vendor)
  for (const [vendorId, data] of packageNotifications.entries()) {
    const servicesText = data.services.join(', ');
    const notificationBody = `${clientName} booked "${data.packageName}" package (${servicesText}) at ${data.date}`;
    
    try {
      await this.notificationService.createNotification(
        {
          recipientId: new Types.ObjectId(vendorId),
          recipientType: RecipientType.VENDOR,
          title: 'New Package Booking',
          body: notificationBody,
          type: NotificationType.BOOKING_CONFIRMED,
          metadata: { 
            packageName: data.packageName,
            services: data.services,
            clientName: clientName,
            bookingDate: data.date,
          }
        },
        data.fcmToken || ''
      );
    } catch (notifError) {
      this.logger.error(`Failed to send package notification to vendor ${vendorId}:`, notifError.message);
    }
  }
  
  this.logger.log(`✅ ${createdBookings.length} separate bookings created for user ${userId}`);
  return createdBookings;
}

  /**
   * 🆕 حساب عدد الحجوزات غير المقروءة للفندر
   */
  async getUnseenCount(vendorId: string): Promise<number> {
    return this.bookingModel.countDocuments({
      providerId: vendorId, // تأكدنا من الـ Entity أن هذا الحقل String
      seen: false           // نبحث عن غير المقروء فقط
    }).exec();
  }


  /**
   * 🚫 إلغاء الحجز من قبل الـ Vendor مع Refund
   */
  async cancelBookingByVendor(
    bookingId: string, 
    vendorId: string, 
    reason: string = 'Vendor cancelled the service'
  ): Promise<Booking> {
    const booking = await this.bookingModel.findOne({
      _id: new Types.ObjectId(bookingId),
      providerId: vendorId, // 🛡️ التأكد من أن الـ vendor يملك هذا الحجز
      status: { $in: [BookingStatus.CONFIRMED, BookingStatus.PENDING] }
    }).exec();

    if (!booking) {
      throw new NotFoundException('Booking not found or not owned by this vendor');
    }
      
    if (booking.refunded) {
      throw new BadRequestException('This booking has already been refunded.');
    }

    // 1️⃣ طلب الـ Refund الجزئي
    try {
      await this.paymentService.processPartialRefund(booking.paymentIntentId, booking.price);
      this.logger.log(`✅ Refund of $${booking.price} processed for booking ${bookingId}`);
    } catch (error) {
      this.logger.error(`❌ Refund failed: ${error.message}`);
      throw new BadRequestException('Refund processing failed. Please try again later.');
    }
      
    // 2️⃣ تحديث حالة الحجز في DB
    booking.status = BookingStatus.CANCELLED;
    booking.refunded = true;
    booking.cancellationReason = reason;
    await booking.save();

    // 3️⃣ إرسال إشعار للعميل
    await this.sendCancellationNotification(booking);

    return booking;
  }
    
  /**
   * 📧 دالة مساعدة لإرسال إشعار الإلغاء للمستخدم
   */
  private async sendCancellationNotification(booking: Booking): Promise<void> {
    try {
      const user = await this.userModel.findById(booking.userId).select('fcmToken').lean().exec();
      const fcmToken = (user as any)?.fcmToken as string | undefined;
      
      const notificationDto = {
        recipientId: booking.userId,
        recipientType: RecipientType.USER,
        title: 'Booking Cancelled',
        body: `Your booking for ${booking.serviceName} has been cancelled. A refund of $${booking.price.toFixed(2)} has been initiated.${booking.cancellationReason ? ` Reason: ${booking.cancellationReason}` : ''}`,
        type: NotificationType.BOOKING_CANCELLED,
        metadata: {
          bookingId: (booking._id as Types.ObjectId).toString(),
          serviceId: booking.serviceId.toString(),
          refunded: true,
          refundAmount: booking.price,
          cancellationReason: booking.cancellationReason,
        }
      };

      await this.notificationService.createNotification(
        notificationDto,
        fcmToken || ''
      );

      this.logger.log(`✅ Cancellation notification sent to user ${booking.userId}`);
    } catch (error) {
      this.logger.error('Failed to send cancellation notification:', error.message);
    }
  }

  /**
   * 🆕 تحديد الحجز كـ "تمت مشاهدته" بواسطة الـ vendor
   */
  async markBookingAsSeen(bookingId: string, vendorId: string): Promise<Booking> {
    const booking = await this.bookingModel.findOneAndUpdate(
      { 
        _id: new Types.ObjectId(bookingId), 
        providerId: vendorId,
        seen: false
      },
      { $set: { seen: true } },
      { new: true }
    ).exec();

    if (!booking) {
      const existingBooking = await this.bookingModel.findOne({ 
        _id: new Types.ObjectId(bookingId), 
        providerId: vendorId 
      }).exec();
      
      if (existingBooking) return existingBooking;
      
      throw new NotFoundException('Booking not found or not owned by this vendor.');
    }

    return booking;
  }

  /**
   * 🆕 جلب الحجوزات بناءً على دور المستخدم مع تصفية الحقول المطلوبة
   */
  async getBookingsByRole(userId: string, role: string): Promise<any[]> {
    let query: any;
    let populateOptions: any[] = [];
    const clientRoles = ['user', 'client']; 
    const isVendor = role === 'vendor';

    // --- 1. تحديد الـ Query والـ Population ---
    if (isVendor) {
      // 👑 لـ Vendor: يحتاج اسم العميل (Client Name) من جدول User
      query = { providerId: userId };
      // 🔗 ربط حقل userId لجلب اسم العميل (name) فقط
      // يجب أن يكون ref 'User' معرفًا في booking.entity.ts
      populateOptions.push({ path: 'userId', select: 'name -_id' }); 
      
    } else if (clientRoles.includes(role)) {
      // 👤 لـ Client: يبحث بـ userId
      if (!Types.ObjectId.isValid(userId)) {
          throw new BadRequestException('Invalid user ID format.');
      }
      query = { userId: new Types.ObjectId(userId) };
    } else {
      throw new BadRequestException('User role is not recognized.');
    }

    const rawBookings = await this.bookingModel
      .find(query)
      .sort({ createdAt: -1 })
      .populate(populateOptions) 
      .exec();

    // 🔄 2. تحويل النتائج لتطابق الهيكل المطلوب (Projection)
    return rawBookings.map(booking => {
        // Mongoose document conversion
        const bookingObject: any = booking.toObject({ virtuals: true });
        
        if (isVendor) {
            // 📝 الحقول المطلوبة للـ Vendor: اسم العميل، اسم السيرفس، تاريخ الحجز
            
            // 💡Fix: تم حل مشكلة TypeError/Compilation error عبر التحقق من الـ Population
            const populatedUser = bookingObject.userId as { name: string } | Types.ObjectId | null;
            const clientName = (populatedUser && typeof populatedUser === 'object' && 'name' in populatedUser)
                               ? populatedUser.name 
                               : 'Unknown Client';
            
            return {
                bookingId: bookingObject._id,
                clientName: clientName, // ✅ اسم الشخص الذي قام بالحجز (من جدول User)
                serviceName: bookingObject.serviceName, // ✅ اسم الخدمة
                bookingDate: bookingObject.bookingDetails?.date, // ✅ تاريخ الحجز
                status: bookingObject.status,
                seen: bookingObject.seen
            };
        } else {
            // 📝 الحقول المطلوبة للـ Client: اسم الحجز، status، Cancellation Reason
            return {
                bookingId: bookingObject._id,
                serviceName: bookingObject.serviceName, // ✅ اسم الحجز
                serviceId: bookingObject.serviceId, //  معرف الخدمة للريفيو
                status: bookingObject.status, // ✅ حالته
                cancellationReason: bookingObject.cancellationReason || null, // ✅ سبب الإلغاء
                bookingDate: bookingObject.bookingDetails?.date , // إضافة التاريخ للمستخدم
                isReviewed: bookingObject.isReviewed || false, //  حالة الريفيو
            };
        }
    });
  }

  // 🗑️ تم حذف الدوال القديمة (getUserBookings و getVendorBookings)
  /*
  async getUserBookings(userId: string): Promise<Booking[]> { ... }
  async getVendorBookings(vendorId: string): Promise<Booking[]> { ... }
  */
  
  /**
   * 🔍 جلب حجز واحد بالـ ID
   */
  async getBookingById(bookingId: string): Promise<Booking> {
    const booking = await this.bookingModel.findById(bookingId);
    if (!booking) {
      throw new HttpException('Booking not found', HttpStatus.NOT_FOUND);
    }
    return booking;
  }

  /**
   * 🆕 4. تحديد جميع حجوزات البائع التي لم تتم مشاهدتها كـ "تمت مشاهدتها"
   * @param vendorId معرف البائع
   * @returns نتيجة عملية التحديث (كم بوكينج تم تعديله)
   */
  async markAllVendorBookingsAsSeen(vendorId: string): Promise<any> {
    const result = await this.bookingModel.updateMany(
      { 
        providerId: vendorId, // 👈 الفلترة بالـ Vendor ID فقط
        seen: false // 👈 فقط التي لم تتم مشاهدتها بعد
      },
      { $set: { seen: true } } // 👈 تحديث قيمة seen إلى true
    ).exec();
    
    this.logger.log(`✅ Marked ${result.modifiedCount} bookings as seen for vendor ${vendorId}`);
    return result; // ترجع { acknowledged: true, modifiedCount: N }
  }

  // داخل كلاس BookingService

async getSalesStats(vendorId?: string) {
  const matchQuery: any = {};
  if (vendorId) matchQuery.providerId = vendorId;

  const now = new Date();
  const startOfCurrentMonth = new Date(now.getFullYear(), now.getMonth(), 1);
  const startOfLastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
  const endOfLastMonth = new Date(now.getFullYear(), now.getMonth(), 0);

  const stats = await this.bookingModel.aggregate([
    { $match: matchQuery },
    {
      $facet: {
        // الإحصائيات العامة (التي عملناها سابقاً)
        "overallStats": [
          {
            $group: {
              _id: null,
              totalSalesAmount: { $sum: { $cond: [{ $in: ["$status", ["confirmed", "completed"]] }, "$price", 0] } },
              totalSalesCount: { $sum: { $cond: [{ $in: ["$status", ["confirmed", "completed"]] }, 1, 0] } },
              totalCancelledAmount: { $sum: { $cond: [{ $eq: ["$status", "cancelled"] }, "$price", 0] } },
              totalCancelledCount: { $sum: { $cond: [{ $eq: ["$status", "cancelled"] }, 1, 0] } }
            }
          }
        ],
        // مبيعات الشهر الحالي
        "currentMonthSales": [
          { $match: { createdAt: { $gte: startOfCurrentMonth }, status: { $in: ["confirmed", "completed"] } } },
          { $group: { _id: null, amount: { $sum: "$price" } } }
        ],
        // مبيعات الشهر الماضي (لحساب النمو)
        "lastMonthSales": [
          { $match: { createdAt: { $gte: startOfLastMonth, $lte: endOfLastMonth }, status: { $in: ["confirmed", "completed"] } } },
          { $group: { _id: null, amount: { $sum: "$price" } } }
        ]
      }
    }
  ]);

  const result = stats[0];
  const overall = result.overallStats[0] || { totalSalesAmount: 0, totalSalesCount: 0, totalCancelledAmount: 0, totalCancelledCount: 0 };
  const currentMonthAmount = result.currentMonthSales[0]?.amount || 0;
  const lastMonthAmount = result.lastMonthSales[0]?.amount || 0;

  // حساب نسبة النمو
  let growthRate = 0;
  if (lastMonthAmount > 0) {
    growthRate = ((currentMonthAmount - lastMonthAmount) / lastMonthAmount) * 100;
  } else if (currentMonthAmount > 0) {
    growthRate = 100; // نمو 100% إذا لم تكن هناك مبيعات سابقاً
  }

  return {
    ...overall,
    currentMonthSales: currentMonthAmount,
    growthRate: parseFloat(growthRate.toFixed(2)) // تقريب الرقم
  };
}


}