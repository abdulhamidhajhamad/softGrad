import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../auth/user.entity';
import { ServiceProvider } from '../providers/provider.entity';
import { Service } from '../service/service.entity';
import { Booking } from '../booking/booking.entity';

@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(ServiceProvider)
    private readonly providerRepository: Repository<ServiceProvider>,
    @InjectRepository(Service)
    private readonly serviceRepository: Repository<Service>,
    @InjectRepository(Booking)
    private readonly bookingRepository: Repository<Booking>,
  ) {}

  // Get all users with count
  async getAllUsers() {
    try {
      const users = await this.userRepository.find();
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
      const providers = await this.providerRepository.find();
      return {
        totalProviders: providers.length,
        providers: providers,
      };
    } catch (error) {
      throw new BadRequestException('Failed to fetch providers');
    }
  }

  // Get all services with count
  async getAllServices() {
    try {
      const services = await this.serviceRepository.find();
      return {
        totalServices: services.length,
        services: services,
      };
    } catch (error) {
      throw new BadRequestException('Failed to fetch services');
    }
  }

  // Get all bookings with count
  async getAllBookings() {
    try {
      const bookings = await this.bookingRepository.find();
      return {
        totalBookings: bookings.length,
        bookings: bookings,
      };
    } catch (error) {
      throw new BadRequestException('Failed to fetch bookings');
    }
  }

  // Get complete dashboard stats
  async getDashboardStats() {
    try {
      const users = await this.userRepository.find();
      const providers = await this.providerRepository.find();
      const services = await this.serviceRepository.find();
      const bookings = await this.bookingRepository.find();

      // Calculate booking stats
      const pendingBookings = bookings.filter((b) => b.status === 'pending').length;
      const confirmedBookings = bookings.filter((b) => b.status === 'confirmed').length;
      const cancelledBookings = bookings.filter((b) => b.status === 'cancelled').length;
      const completedBookings = bookings.filter((b) => b.status === 'completed').length;

      // Calculate total revenue
      const totalRevenue = bookings.reduce((sum, b) => sum + (typeof b.totalPrice === 'number' ? b.totalPrice : parseFloat(b.totalPrice)), 0);

      return {
        summary: {
          totalUsers: users.length,
          totalProviders: providers.length,
          totalServices: services.length,
          totalBookings: bookings.length,
          totalRevenue: totalRevenue.toFixed(2),
        },
        bookingStats: {
          pending: pendingBookings,
          confirmed: confirmedBookings,
          cancelled: cancelledBookings,
          completed: completedBookings,
        },
        data: {
          users: users,
          providers: providers,
          services: services,
          bookings: bookings,
        },
      };
    } catch (error) {
      throw new BadRequestException('Failed to fetch dashboard stats');
    }
  }

  // Get detailed analytics
  async getAnalytics() {
    try {
      const users = await this.userRepository.find();
      const providers = await this.providerRepository.find();
      const services = await this.serviceRepository.find();
      const bookings = await this.bookingRepository.find();

      // Average service rating
      const avgRating =
        services.length > 0
          ? (services.reduce((sum, s) => sum + (typeof s.rating === 'number' ? s.rating : parseFloat(s.rating) || 0), 0) / services.length).toFixed(2)
          : '0';

      // Average booking price
      const avgBookingPrice =
        bookings.length > 0
          ? (bookings.reduce((sum, b) => sum + (typeof b.totalPrice === 'number' ? b.totalPrice : parseFloat(b.totalPrice)), 0) / bookings.length).toFixed(2)
          : '0';

      // Services per provider
      const servicesPerProvider = services.reduce((acc, service) => {
        const key = String(service.providerId);
        acc[key] = (acc[key] || 0) + 1;
        return acc;
      }, {} as Record<string, number>);

      // Bookings per service
      const bookingsPerService = bookings.reduce((acc, booking) => {
        const key = String(booking.serviceId);
        acc[key] = (acc[key] || 0) + 1;
        return acc;
      }, {} as Record<string, number>);

      return {
        userMetrics: {
          totalUsers: users.length,
        },
        providerMetrics: {
          totalProviders: providers.length,
          servicesPerProvider: servicesPerProvider,
        },
        serviceMetrics: {
          totalServices: services.length,
          averageRating: avgRating,
          bookingsPerService: bookingsPerService,
        },
        bookingMetrics: {
          totalBookings: bookings.length,
          averageBookingPrice: avgBookingPrice,
          totalRevenue: bookings.reduce((sum, b) => sum + (typeof b.totalPrice === 'number' ? b.totalPrice : parseFloat(b.totalPrice)), 0).toFixed(2),
        },
      };
    } catch (error) {
      throw new BadRequestException('Failed to fetch analytics');
    }
  }
}