import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { User } from '../auth/user.entity';
import { ServiceProvider } from '../providers/provider.entity';
import { Complaint, ComplaintStatus, ComplaintPriority, ComplaintType } from './complaint/complaint.schema';
import { IComplaint } from './complaint/complaint.interface';
import { 
  CreateComplaintDto, UpdateComplaintStatusDto, 
  AddComplaintNoteDto, ComplaintFilterDto, ComplaintStatsDto 
} from './complaint/complaint.dto';

@Injectable()
export class AdminService {
  constructor(
    @InjectModel(User.name)
    private readonly userModel: Model<User>,
    @InjectModel(ServiceProvider.name)
    private readonly providerModel: Model<ServiceProvider>,
    @InjectModel(Complaint.name)
    private readonly complaintModel: Model<Complaint>,
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
}
