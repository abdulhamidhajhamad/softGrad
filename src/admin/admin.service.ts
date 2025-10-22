import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { User } from '../auth/user.entity';
import { ServiceProvider } from '../providers/provider.entity';

@Injectable()
export class AdminService {
  constructor(
    @InjectModel(User.name)
    private readonly userModel: Model<User>,
    @InjectModel(ServiceProvider.name)
    private readonly providerModel: Model<ServiceProvider>,
    // إزالة Service و Booking مؤقتاً
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

  // Get complete dashboard stats
  async getDashboardStats() {
    try {
      const users = await this.userModel.find().exec();
      const providers = await this.providerModel.find().exec();

      return {
        summary: {
          totalUsers: users.length,
          totalProviders: providers.length,
          totalServices: 0,
          totalBookings: 0,
          totalRevenue: "0.00",
        },
        bookingStats: {
          pending: 0,
          confirmed: 0,
          cancelled: 0,
          completed: 0,
        },
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
      };
    } catch (error) {
      throw new BadRequestException('Failed to fetch analytics');
    }
  }
}