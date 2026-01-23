import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { User } from '../auth/user.entity';
import { ServiceProvider } from '../providers/provider.entity';
import { Complaint, ComplaintStatus, ComplaintPriority, ComplaintType } from './complaint/complaint.schema';
import { IComplaint } from './complaint/complaint.interface';
import { 
  CreateComplaintDto, UpdateComplaintStatusDto, 
  AddComplaintNoteDto, ComplaintFilterDto, ComplaintStatsDto 
} from './complaint/complaint.dto';
import { Booking, BookingStatus } from '../booking/booking.entity'; // ✅ إضافة
import { Service } from '../service/service.schema'; // ✅ إضافة
import { Package } from '../Package/package.entity'; // ✅ إضافة
import { Review } from '../review/review.schema';
@Injectable()
export class AdminService {
  constructor(
    @InjectModel(User.name)
    private readonly userModel: Model<User>,
    @InjectModel(ServiceProvider.name)
    private readonly providerModel: Model<ServiceProvider>,
    @InjectModel(Complaint.name)
    private readonly complaintModel: Model<Complaint>,
    @InjectModel(Booking.name) // ✅ إضافة
    private readonly bookingModel: Model<Booking>,
    @InjectModel(Service.name) // ✅ إضافة
    private readonly serviceModel: Model<Service>,
    @InjectModel(Package.name) // ✅ إضافة
    private readonly packageModel: Model<Package>,
    @InjectModel(Review.name)
private readonly reviewModel: Model<Review>,
  ) {}


  // Get all users with count
  async getAllUsers() {
    try {
      const users = await this.userModel.find().exec();
      return {
        totalUsers: users.length,
        users: users,
      };
    } catch (error) {
      throw new BadRequestException('Failed to fetch users');
    }
  }

  // Get all providers with count
  async getAllProviders() {
    try {
      const providers = await this.providerModel.find().exec();
      return {
        totalProviders: providers.length,
        providers: providers,
      };
    } catch (error) {
      throw new BadRequestException('Failed to fetch providers');
    }
  }

  // Get all services with count - مؤقتاً تعيد مصفوفة فارغة
  async getAllServices() {
    try {
      return {
        totalServices: 0,
        services: [],
      };
    } catch (error) {
      throw new BadRequestException('Failed to fetch services');
    }
  }

  // Get all bookings with count - مؤقتاً تعيد مصفوفة فارغة
  async getAllBookings() {
    try {
      return {
        totalBookings: 0,
        bookings: [],
      };
    } catch (error) {
      throw new BadRequestException('Failed to fetch bookings');
    }
  }

  // ============ خدمات الشكاوي ============

  // 1. إنشاء شكوى جديدة (للمستخدم)
async createComplaint(
  userId: string,
  userName: string,
  userEmail: string,
  createComplaintDto: CreateComplaintDto
): Promise<any> {
  try {
    // 1. إنشاء الشكوى كاملة
    const newComplaint = new this.complaintModel({
      userId,
      userName,
      userEmail,
      ...createComplaintDto,
      isArchived: false
    });

    // 2. ✅ الحفظ في الداتا بيس (كامل البيانات)
  const savedComplaint = await newComplaint.save();
  const complaintData = savedComplaint.toObject() as any;

  return {
    success: true,
    message: 'creat succ',
  };
  } catch (error) {
    throw new BadRequestException(error.message || 'Failed to create complaint');
  }
}

  // 2. جلب جميع الشكاوى مع فلتر
  async getAllComplaints(filters: ComplaintFilterDto): Promise<Complaint[]> {
    try {
      const query: any = {};

      if (filters.status) query.status = filters.status;
      if (filters.type) query.type = filters.type;
      if (filters.priority) query.priority = filters.priority;
      if (filters.assignedTo) query.assignedTo = filters.assignedTo;
      if (filters.isArchived !== undefined) query.isArchived = filters.isArchived;
      
      if (filters.fromDate || filters.toDate) {
        query.createdAt = {};
        if (filters.fromDate) query.createdAt.$gte = filters.fromDate;
        if (filters.toDate) query.createdAt.$lte = filters.toDate;
      }

      if (filters.search) {
        query.$or = [
          { title: { $regex: filters.search, $options: 'i' } },
          { description: { $regex: filters.search, $options: 'i' } },
          { userName: { $regex: filters.search, $options: 'i' } },
          { userEmail: { $regex: filters.search, $options: 'i' } }
        ];
      }

      return await this.complaintModel
        .find(query)
        .sort({ priority: -1, createdAt: -1 })
        .exec();
    } catch (error) {
      throw new BadRequestException('Failed to fetch complaints');
    }
  }

  // 3. جلب شكوى محددة
  async getComplaintById(complaintId: string): Promise<Complaint> {
    try {
      const complaint = await this.complaintModel.findById(complaintId).exec();
      
      if (!complaint) {
        throw new BadRequestException('Complaint not found');
      }

      return complaint;
    } catch (error) {
      throw new BadRequestException(error.message || 'Failed to fetch complaint');
    }
  }

  // 4. تحديث حالة الشكوى (مع التصحيح)
  async updateComplaintStatus(
    complaintId: string,
    adminId: string,
    adminName: string,
    updateDto: UpdateComplaintStatusDto
  ): Promise<Complaint> {
    try {
      const updateData: any = {
        status: updateDto.status,
        updatedAt: new Date()
      };

      if (updateDto.status === ComplaintStatus.RESOLVED) {
        updateData.resolvedBy = adminId;
        updateData.resolvedAt = new Date();
        if (updateDto.resolution) {
          updateData.resolution = updateDto.resolution;
        }
        
        // حساب وقت الاستجابة - التصحيح
        const complaint = await this.complaintModel.findById(complaintId);
        if (complaint) {
          // التحويل إلى IComplaint interface
          const complaintData = complaint.toObject() as IComplaint;
          const createdAt = complaintData.createdAt || new Date();
          
          const responseTime = Math.round(
            (new Date().getTime() - new Date(createdAt).getTime()) / (1000 * 60 * 60)
          );
          updateData.responseTimeHours = responseTime;
        }
      }

      const updatedComplaint = await this.complaintModel.findByIdAndUpdate(
        complaintId,
        {
          $set: updateData,
          $push: {
            activityLog: {
              action: 'STATUS_CHANGED',
              adminId,
              details: `Status changed to ${updateDto.status} by ${adminName}`,
              timestamp: new Date()
            }
          }
        },
        { new: true, runValidators: true }
      ).exec();

      if (!updatedComplaint) {
        throw new BadRequestException('Complaint not found');
      }

      return updatedComplaint;
    } catch (error) {
      throw new BadRequestException(error.message || 'Failed to update complaint status');
    }
  }

  // 5. إضافة ملاحظة للشكوى
  async addComplaintNote(
    complaintId: string,
    adminId: string,
    adminName: string,
    noteDto: AddComplaintNoteDto
  ): Promise<Complaint> {
    try {
      const updatedComplaint = await this.complaintModel.findByIdAndUpdate(
        complaintId,
        {
          $push: {
            notes: {
              adminId,
              adminName,
              note: noteDto.note,
              timestamp: new Date()
            },
            activityLog: {
              action: 'NOTE_ADDED',
              adminId,
              details: `Note added by ${adminName}`,
              timestamp: new Date()
            }
          }
        },
        { new: true }
      ).exec();

      if (!updatedComplaint) {
        throw new BadRequestException('Complaint not found');
      }

      return updatedComplaint;
    } catch (error) {
      throw new BadRequestException(error.message || 'Failed to add note');
    }
  }

  // 6. تعيين شكوى لإدمن
  async assignComplaint(
    complaintId: string,
    assignerAdminId: string,
    assignerName: string,
    assigneeAdminId: string
  ): Promise<Complaint> {
    try {
      const updatedComplaint = await this.complaintModel.findByIdAndUpdate(
        complaintId,
        {
          $set: { assignedTo: assigneeAdminId },
          $push: {
            activityLog: {
              action: 'ASSIGNED',
              adminId: assignerAdminId,
              details: `Assigned to admin ${assigneeAdminId} by ${assignerName}`,
              timestamp: new Date()
            }
          }
        },
        { new: true }
      ).exec();

      if (!updatedComplaint) {
        throw new BadRequestException('Complaint not found');
      }

      return updatedComplaint;
    } catch (error) {
      throw new BadRequestException(error.message || 'Failed to assign complaint');
    }
  }

  // 7. أرشفة شكوى
  async archiveComplaint(complaintId: string): Promise<Complaint> {
    try {
      const updatedComplaint = await this.complaintModel.findByIdAndUpdate(
        complaintId,
        { $set: { isArchived: true } },
        { new: true }
      ).exec();

      if (!updatedComplaint) {
        throw new BadRequestException('Complaint not found');
      }

      return updatedComplaint;
    } catch (error) {
      throw new BadRequestException(error.message || 'Failed to archive complaint');
    }
  }

  // 8. إحصائيات الشكاوى (مع التصحيح)
  async getComplaintStats(): Promise<any> {
    try {
      const [
        total,
        pending,
        urgent,
        resolved,
        byType,
        byStatus,
        byPriority
      ] = await Promise.all([
        this.complaintModel.countDocuments({ isArchived: false }),
        this.complaintModel.countDocuments({ 
          status: ComplaintStatus.PENDING,
          isArchived: false 
        }),
        this.complaintModel.countDocuments({ 
          priority: ComplaintPriority.URGENT,
          isArchived: false 
        }),
        this.complaintModel.countDocuments({ 
          status: ComplaintStatus.RESOLVED,
          isArchived: false 
        }),
        this.complaintModel.aggregate([
          { $match: { isArchived: false } },
          { $group: { _id: '$type', count: { $sum: 1 } } }
        ]),
        this.complaintModel.aggregate([
          { $match: { isArchived: false } },
          { $group: { _id: '$status', count: { $sum: 1 } } }
        ]),
        this.complaintModel.aggregate([
          { $match: { isArchived: false } },
          { $group: { _id: '$priority', count: { $sum: 1 } } }
        ])
      ]);

      // حساب متوسط وقت الاستجابة - التصحيح
      const resolvedComplaints = await this.complaintModel.find({
        status: ComplaintStatus.RESOLVED,
        responseTimeHours: { $gt: 0 }
      }).lean(); // استخدام lean() للحصول على objects عادية
      
      const avgResponseTime = resolvedComplaints.length > 0
        ? Math.round(
            resolvedComplaints.reduce((sum: number, c: any) => {
              return sum + (c.responseTimeHours || 0);
            }, 0) / resolvedComplaints.length
          )
        : 0;

      return {
        total,
        pending,
        urgent,
        resolved,
        avgResponseTime,
        byType,
        byStatus,
        byPriority
      };
    } catch (error) {
      throw new BadRequestException('Failed to get complaint stats');
    }
  }

  // 9. جلب شكاوى المستخدم
  async getUserComplaints(userId: string): Promise<Complaint[]> {
    try {
      return await this.complaintModel
        .find({ userId, isArchived: false })
        .sort({ createdAt: -1 })
        .exec();
    } catch (error) {
      throw new BadRequestException('Failed to fetch user complaints');
    }
  }

  // 10. حذف شكوى نهائياً (للإدمن فقط)
  async deleteComplaint(complaintId: string): Promise<{ message: string }> {
    try {
      const complaint = await this.complaintModel.findById(complaintId);
      
      if (!complaint) {
        throw new BadRequestException('Complaint not found');
      }

      // يمكنك إضافة حذف المرفقات من التخزين هنا إذا كان لديك
      // if (complaint.attachments && complaint.attachments.length > 0) {
      //   await this.storageService.deleteFiles(complaint.attachments);
      // }

      await this.complaintModel.deleteOne({ _id: complaintId });

      return { message: 'Complaint deleted successfully' };
    } catch (error) {
      throw new BadRequestException(error.message || 'Failed to delete complaint');
    }
  }

  // Get complete dashboard stats
  async getDashboardStats() {
    try {
      const users = await this.userModel.find().exec();
      const providers = await this.providerModel.find().exec();
      const complaintStats = await this.getComplaintStats();

      return {
        summary: {
          totalUsers: users.length,
          totalProviders: providers.length,
          totalServices: 0,
          totalBookings: 0,
          totalRevenue: "0.00",
          totalComplaints: complaintStats.total,
          pendingComplaints: complaintStats.pending,
          urgentComplaints: complaintStats.urgent
        },
        bookingStats: {
          pending: 0,
          confirmed: 0,
          cancelled: 0,
          completed: 0,
        },
        complaintStats: complaintStats,
        data: {
          users: users,
          providers: providers,
          services: [],
          bookings: [],
        },
      };
    } catch (error) {
      throw new BadRequestException('Failed to fetch dashboard stats');
    }
  }

  // Get detailed analytics
  async getAnalytics() {
    try {
      const users = await this.userModel.find().exec();
      const providers = await this.providerModel.find().exec();
      const complaintStats = await this.getComplaintStats();

      return {
        userMetrics: {
          totalUsers: users.length,
        },
        providerMetrics: {
          totalProviders: providers.length,
          servicesPerProvider: {},
        },
        serviceMetrics: {
          totalServices: 0,
          averageRating: "0",
          bookingsPerService: {},
        },
        bookingMetrics: {
          totalBookings: 0,
          averageBookingPrice: "0",
          totalRevenue: "0",
        },
        complaintMetrics: {
          ...complaintStats,
          recentComplaints: await this.complaintModel
            .find({ isArchived: false })
            .sort({ createdAt: -1 })
            .limit(10)
            .exec()
        }
      };
    } catch (error) {
      throw new BadRequestException('Failed to fetch analytics');
    }
  }

  private async sendUrgentComplaintNotification(complaint: Complaint): Promise<void> {
    console.log(`🔴 URGENT Complaint: ${complaint.title} from ${complaint.userName}`);
    console.log(`📧 Email: ${complaint.userEmail}`);
    console.log(`📞 Notify admins immediately!`);
  }

  // ========== ✅ الدوال الجديدة ==========

/**
 * ✅ إحصائيات الحجوزات (عدد ومجموع)
 */
async getBookingStats() {
  try {
    const [successfulStats, cancelledStats] = await Promise.all([
      // الحجوزات الناجحة (confirmed + completed)
      this.bookingModel. aggregate([
        { $match: { status:  { $in: ['confirmed', 'completed'] } } },
        { $group: { _id:  null, count: { $sum: 1 }, totalAmount: { $sum: '$price' } } }
      ]),
      // الحجوزات الملغية
      this.bookingModel. aggregate([
        { $match: { status: 'cancelled' } },
        { $group: { _id: null, count: { $sum: 1 }, totalAmount: { $sum: '$price' } } }
      ])
    ]);

    return {
      successfulBookings:  {
        count: successfulStats[0]?.count || 0,
        totalAmount: successfulStats[0]?.totalAmount || 0
      },
      cancelledBookings: {
        count: cancelledStats[0]?. count || 0,
        totalAmount:  cancelledStats[0]?.totalAmount || 0
      }
    };
  } catch (error) {
    throw new BadRequestException('Failed to fetch booking stats');
  }
}

/**
 * ✅ عدد السيرفس
 */
async getServicesCount() {
  try {
    const [total, active] = await Promise.all([
      this. serviceModel.countDocuments(),
      this.serviceModel.countDocuments({ isActive: true })
    ]);

    return {
      totalServices: total,
      activeServices: active,
      inactiveServices: total - active
    };
  } catch (error) {
    throw new BadRequestException('Failed to fetch services count');
  }
}

/**
 * ✅ عدد اليوزر العاديين
 */
async getRegularUsersCount() {
  try {
    const count = await this.userModel.countDocuments({ role: 'user' });
    return { regularUsersCount:  count };
  } catch (error) {
    throw new BadRequestException('Failed to fetch users count');
  }
}

/**
 * ✅ عدد الـ Providers
 */
async getProvidersCount() {
  try {
    const count = await this. providerModel.countDocuments();
    return { providersCount: count };
  } catch (error) {
    throw new BadRequestException('Failed to fetch providers count');
  }
}

/**
 * ✅ عدد الباقات
 */
async getPackagesCount() {
  try {
    const [total, active] = await Promise.all([
      this.packageModel.countDocuments(),
      this.packageModel.countDocuments({ isActive:  true })
    ]);

    return {
      totalPackages: total,
      activePackages: active,
      inactivePackages: total - active
    };
  } catch (error) {
    throw new BadRequestException('Failed to fetch packages count');
  }
}

/**
 * ✅ مبيعات السيرفس والباقات (عدد ومجموع)
 */
async getSalesBreakdown() {
  try {
    const salesStats = await this.bookingModel.aggregate([
      { $match: { status: { $in: ['confirmed', 'completed'] } } },
      { $group: { _id: null, totalAmount: { $sum:  '$price' }, count: { $sum:  1 } } }
    ]);

    return {
      totalSales:  {
        count: salesStats[0]?.count || 0,
        totalAmount: salesStats[0]?. totalAmount || 0
      }
    };
  } catch (error) {
    throw new BadRequestException('Failed to fetch sales breakdown');
  }
}

/**
 * ✅ Top Provider Sales (آخر 30 يوم)
 */
async getTopProviderSales(limit:  number = 10) {
  try {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    // إجمالي المبيعات
    const totalResult = await this.bookingModel.aggregate([
      { $match: { status: { $in:  ['confirmed', 'completed'] }, createdAt: { $gte: thirtyDaysAgo } } },
      { $group: { _id: null, total: { $sum:  '$price' } } }
    ]);
    const totalSales = totalResult[0]?. total || 0;

    // Top Providers
    const topProviders = await this.bookingModel.aggregate([
      { $match: { status: { $in: ['confirmed', 'completed'] }, createdAt: { $gte: thirtyDaysAgo } } },
      {
        $group:  {
          _id: '$providerId',
          companyName: { $first: '$companyName' },
          totalSales: { $sum: '$price' },
          bookingsCount: { $sum: 1 }
        }
      },
      { $sort:  { totalSales:  -1 } },
      { $limit: limit }
    ]);

    return {
      period: 'Last 30 days',
      totalPlatformSales: totalSales,
      topProviders: topProviders. map(p => ({
        providerId: p._id,
        companyName: p.companyName || 'Unknown',
        totalSales:  p.totalSales,
        bookingsCount: p.bookingsCount,
        percentage: totalSales > 0 ? parseFloat(((p.totalSales / totalSales) * 100).toFixed(2)) : 0
      }))
    };
  } catch (error) {
    throw new BadRequestException('Failed to fetch top providers');
  }
}

/**
 * ✅ حذف يوزر بالإيميل
 */
async deleteUserByEmail(email:  string) {
  try {
    const user = await this.userModel.findOne({ email, role: 'user' });
    if (!user) throw new BadRequestException('User not found');

    await this.userModel. deleteOne({ _id: user._id });
    return { message: `User ${email} deleted successfully` };
  } catch (error) {
    throw new BadRequestException(error.message || 'Failed to delete user');
  }
}

/**
 * ✅ حذف Provider بالإيميل
 */
async deleteProviderByEmail(email: string) {
  try {
    const user = await this.userModel.findOne({ email, role: 'vendor' });
    if (!user) throw new BadRequestException('Provider not found');

  const userId = (user._id as Types.ObjectId).toString();

    await Promise.all([
      this.providerModel.deleteOne({ userId:  user._id }),
      this.userModel. deleteOne({ _id: user._id }),
      this.serviceModel.deleteMany({ providerId: userId }),
      this.packageModel.deleteMany({ providerId: userId })
    ]);

    return { message: `Provider ${email} and related data deleted successfully` };
  } catch (error) {
    throw new BadRequestException(error.message || 'Failed to delete provider');
  }
}

/**
 * ✅ حذف Service بالاسم
 */
async deleteServiceByName(serviceName: string) {
  try {
    const result = await this.serviceModel.deleteMany({
      serviceName:  { $regex: new RegExp(`^${serviceName}$`, 'i') }
    });

    if (result.deletedCount === 0) {
      throw new BadRequestException('Service not found');
    }

    return { message: `Service "${serviceName}" deleted`, deletedCount: result.deletedCount };
  } catch (error) {
    throw new BadRequestException(error.message || 'Failed to delete service');
  }
}

/**
 * ✅ حذف Package بالاسم
 */
async deletePackageByName(packageName: string) {
  try {
    const result = await this.packageModel.deleteMany({
      packageName:  { $regex: new RegExp(`^${packageName}$`, 'i') }
    });

    if (result.deletedCount === 0) {
      throw new BadRequestException('Package not found');
    }

    return { message: `Package "${packageName}" deleted`, deletedCount: result.deletedCount };
  } catch (error) {
    throw new BadRequestException(error.message || 'Failed to delete package');
  }
}

/**
 * ✅ إحصائيات شاملة (أعداد فقط)
 */
async getComprehensiveStats() {
  try {
    const [bookings, services, packages, users, providers, topProviders] = await Promise.all([
      this.getBookingStats(),
      this.getServicesCount(),
      this.getPackagesCount(),
      this.getRegularUsersCount(),
      this.getProvidersCount(),
      this.getTopProviderSales(5)
    ]);

    return { bookings, services, packages, users, providers, topProviders };
  } catch (error) {
    throw new BadRequestException('Failed to fetch stats');
  }
}

// أضف هذه الدوال في نهاية الـ AdminService class (قبل القوس الأخير)

// ========== ✅ Dashboard Stats ==========

/**
 * ✅ Total Revenue (كل المبيعات)
 */
async getTotalRevenue() {
  try {
    const result = await this.bookingModel. aggregate([
      { $match: { status: { $in: ['confirmed', 'completed'] } } },
      { $group: { _id: null, totalRevenue: { $sum: '$price' } } }
    ]);
    
    return {
      totalRevenue: result[0]?.totalRevenue || 0
    };
  } catch (error) {
    throw new BadRequestException('Failed to fetch total revenue');
  }
}

/**
 * ✅ Financial Growth (آخر 7 أشهر)
 */
async getFinancialGrowth() {
  try {
    const sevenMonthsAgo = new Date();
    sevenMonthsAgo. setMonth(sevenMonthsAgo.getMonth() - 7);

    const monthlyData = await this.bookingModel. aggregate([
      { 
        $match:  { 
          status: { $in:  ['confirmed', 'completed'] },
          createdAt: { $gte: sevenMonthsAgo }
        } 
      },
      {
        $group:  {
          _id: { 
            year: { $year: '$createdAt' },
            month: { $month:  '$createdAt' }
          },
          revenue: { $sum:  '$price' },
          count: { $sum:  1 }
        }
      },
      { $sort: { '_id. year': 1, '_id.month':  1 } }
    ]);

    return {
      period: 'Last 7 months',
      data: monthlyData. map(m => ({
        year: m._id. year,
        month: m._id. month,
        revenue: m.revenue,
        bookingsCount: m.count
      }))
    };
  } catch (error) {
    throw new BadRequestException('Failed to fetch financial growth');
  }
}

/**
 * ✅ Service Sales (مبيعات كل خدمة)
 */
async getServiceSales() {
  try {
    const serviceSales = await this.bookingModel. aggregate([
      {
        $group: {
          _id: '$serviceId',
          serviceName: { $first: '$serviceName' },
          companyName: { $first: '$companyName' },
          totalBookings: { $sum: 1 },
          confirmedBookings: {
            $sum:  { $cond:  [{ $in: ['$status', ['confirmed', 'completed']] }, 1, 0] }
          },
          cancelledBookings: {
            $sum:  { $cond:  [{ $eq: ['$status', 'cancelled'] }, 1, 0] }
          },
          totalRevenue: {
            $sum:  { $cond: [{ $in: ['$status', ['confirmed', 'completed']] }, '$price', 0] }
          }
        }
      },
      { $sort: { totalRevenue: -1 } }
    ]);

    // Get service images
    const serviceIds = serviceSales. map(s => s._id);
    const services = await this.serviceModel.find({ _id: { $in: serviceIds } }).select('_id images').lean();
    const serviceImageMap = new Map(services.map(s => [s._id. toString(), s.images?.[0] || '']));

    return serviceSales.map(s => ({
      serviceId: s._id,
      serviceName: s.serviceName || 'Unknown Service',
      companyName: s.companyName || 'Unknown',
      imageUrl: serviceImageMap.get(s._id?. toString()) || '',
      totalBookings:  s.totalBookings,
      confirmedBookings: s.confirmedBookings,
      cancelledBookings: s.cancelledBookings,
      totalRevenue: s.totalRevenue
    }));
  } catch (error) {
    throw new BadRequestException('Failed to fetch service sales');
  }
}

/**
 * ✅ Package Sales (مبيعات كل باقة)
 */
async getPackageSales() {
  try {
    // Since packages may not have direct bookings, we get package info with their services
    const packages = await this.packageModel.find({ isActive: true }).lean();
    
    const packageSales = await Promise.all(packages.map(async (pkg) => {
      const serviceIds = pkg.services?. map(s => s.serviceId) || [];
      
      const bookingStats = await this.bookingModel.aggregate([
        { $match: { serviceId: { $in: serviceIds } } },
        {
          $group: {
            _id:  null,
            totalBookings: { $sum: 1 },
            confirmedBookings: {
              $sum:  { $cond:  [{ $in:  ['$status', ['confirmed', 'completed']] }, 1, 0] }
            },
            cancelledBookings:  {
              $sum: { $cond: [{ $eq: ['$status', 'cancelled'] }, 1, 0] }
            },
            totalRevenue: {
              $sum: { $cond: [{ $in: ['$status', ['confirmed', 'completed']] }, '$price', 0] }
            }
          }
        }
      ]);

      const stats = bookingStats[0] || { totalBookings: 0, confirmedBookings: 0, cancelledBookings: 0, totalRevenue: 0 };

      return {
        packageId: pkg._id,
        packageName: pkg.packageName,
        companyName: pkg. companyName,
        imageUrl: pkg.packageImageUrl || '',
        originalPrice: pkg.originalTotalPrice,
        discountedPrice: pkg.newPrice,
        totalBookings: stats.totalBookings,
        confirmedBookings:  stats.confirmedBookings,
        cancelledBookings: stats.cancelledBookings,
        totalRevenue: stats.totalRevenue
      };
    }));

    return packageSales. sort((a, b) => b.totalRevenue - a.totalRevenue);
  } catch (error) {
    throw new BadRequestException('Failed to fetch package sales');
  }
}

/**
 * ✅ All Reviews for Admin
 */
async getAllReviews(filter?:  'all' | 'good' | 'bad') {
  try {
    // Import Review model - add to constructor if not exists
    const Review = this.bookingModel.db.model('Review');
    
    let query:  any = { isVisible: true };
    
    if (filter === 'good') {
      query. rating = { $gte: 4 };
    } else if (filter === 'bad') {
      query.rating = { $lte:  2 };
    }

    const reviews = await Review.find(query)
      .populate('userId', 'userName imageUrl')
      .populate('serviceId', 'serviceName images providerId')
      .sort({ createdAt:  -1 })
      .lean();

    // Get all unique provider IDs (as strings)
    const providerIds = [...new Set(reviews.map((r: any) => r.serviceId?.providerId).filter(Boolean))];
    
    // Fetch all providers at once - using ServiceProvider model
    // Convert string IDs to ObjectId for matching
    const mongoose = require('mongoose');
    const objectIdProviderIds = providerIds.map(id => {
      try {
        return new mongoose.Types.ObjectId(id);
      } catch {
        return id;
      }
    });
    
    const ServiceProvider = this.bookingModel.db.model('ServiceProvider');
    const providers = await ServiceProvider.find({ 
      userId: { $in: objectIdProviderIds } 
    }).select('userId companyName').lean();
    
    // Create map with string keys for comparison
    const providerMap = new Map(providers.map((p: any) => [p.userId?.toString(), p.companyName]));
    
    console.log('🔍 Provider IDs:', providerIds);
    console.log('🏢 Providers found:', providers.length, providers.map((p: any) => ({ userId: p.userId?.toString(), companyName: p.companyName })));

    return {
      total: reviews.length,
      goodCount: reviews.filter((r: any) => r.rating >= 4).length,
      badCount: reviews.filter((r: any) => r.rating <= 2).length,
      reviews: reviews.map((r: any) => {
        const provId = r.serviceId?.providerId?.toString();
        const provName = providerMap.get(provId);
        console.log(`📝 Review mapping: providerId=${provId}, providerName=${provName}`);
        return {
          _id: r._id,
          userId: r.userId?._id || r.userId,
          userName: r.userId?.userName || r.userName || 'Anonymous',
          userImage: r.userId?.imageUrl || '',
          serviceId: r.serviceId?._id || r.serviceId,
          serviceName: r.serviceId?.serviceName || 'Unknown Service',
          serviceImage: r.serviceId?.images?.[0] || '',
          providerId: provId,
          providerName: provName || null,
          rating: r.rating,
          comment: r.comment,
          images: r.images || [],
          isPositive: r.rating >= 4,
          createdAt: r.createdAt
        };
      })
    };
  } catch (error) {
    console.error('❌ Error in getAllReviews:', error);
    throw new BadRequestException('Failed to fetch reviews');
  }
}

/**
 * ✅ Dashboard Summary (كل البيانات مرة واحدة)
 */
async getAdminDashboardSummary() {
  try {
    const [
      revenue,
      bookingStats,
      servicesCount,
      packagesCount,
      usersCount,
      providersCount,
      topProviders,
      financialGrowth
    ] = await Promise.all([
      this.getTotalRevenue(),
      this.getBookingStats(),
      this.getServicesCount(),
      this.getPackagesCount(),
      this.getRegularUsersCount(),
      this.getProvidersCount(),
      this.getTopProviderSales(5),
      this.getFinancialGrowth()
    ]);

    return {
      totalRevenue: revenue. totalRevenue,
      successfulBookings: bookingStats. successfulBookings,
      cancelledBookings: bookingStats.cancelledBookings,
      totalServices: servicesCount. totalServices,
      totalPackages: packagesCount.totalPackages,
      totalUsers: usersCount.regularUsersCount,
      totalProviders: providersCount.providersCount,
      topProviders: topProviders.topProviders,
      financialGrowth: financialGrowth.data
    };
  } catch (error) {
    throw new BadRequestException('Failed to fetch dashboard summary');
  }
}
}
