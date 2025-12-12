// booking.service.ts
import { Injectable, HttpException, HttpStatus, Logger } from '@nestjs/common';
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
  ) {
    const secretKey = this.configService.get<string>('STRIPE_SECRET_KEY');
    if (!secretKey) {
      throw new Error('STRIPE_SECRET_KEY is not set');
    }
    this.stripe = new Stripe(secretKey!, { apiVersion: '2025-11-17.clover' });
  }

  async createBookingsFromCart(userId: string, paymentIntentId: string): Promise<Booking[]> {
    try {
      const cart = await this.cartModel.findOne({ userId: new Types.ObjectId(userId) });
      
      if (!cart || cart.items.length === 0) {
        throw new HttpException('Cart is empty', HttpStatus.BAD_REQUEST);
      }

      const bookings: Booking[] = [];
      const serviceUpdates: Map<string, any> = new Map();

      for (const item of cart.items) {
        const service = await this.serviceModel.findById(item.serviceId);
        if (!service) {
          this.logger.warn(`Service ${item.serviceId} not found, skipping`);
          continue;
        }

        // Create booking
        const booking = await this.bookingModel.create({
          userId: new Types.ObjectId(userId),
          serviceId: item.serviceId,
          serviceName: item.serviceName,
          providerId: item.providerId,
          companyName: item.companyName,
          bookingType: item.bookingType,
          bookingDetails: item.bookingDetails,
          price: item.price,
          status: BookingStatus.CONFIRMED,
          paymentIntentId,
        });

        bookings.push(booking);

        // Update service booking slots
        if (!serviceUpdates.has(item.serviceId.toString())) {
          serviceUpdates.set(item.serviceId.toString(), {
            service,
            updates: []
          });
        }

        const serviceData = serviceUpdates.get(item.serviceId.toString());
        serviceData.updates.push(item);

        // Send notification to vendor
        await this.sendBookingNotificationToVendor(booking, item.providerId);
      }

      // Apply all service updates
      for (const [serviceId, data] of serviceUpdates) {
        await this.updateServiceBookingSlots(data.service, data.updates);
      }

      // Clear cart
      await this.cartModel.findOneAndDelete({ userId: new Types.ObjectId(userId) });

      return bookings;

    } catch (error) {
      this.logger.error('Failed to create bookings:', error.stack);
      if (error instanceof HttpException) throw error;
      throw new HttpException('Failed to create bookings', HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }

  private async updateServiceBookingSlots(service: Service, updates: any[]): Promise<void> {
    for (const update of updates) {
      const date = new Date(update.bookingDetails.date);
      
      switch (service.bookingType) {
        case BookingType.Hourly:
          if (!service.bookingSlots) {
            service.bookingSlots = { dailyBookings: [], hourlyBookings: [], capacityBookings: [] };
          }
          service.bookingSlots.hourlyBookings.push({
            date,
            startHour: update.bookingDetails.startHour,
            endHour: update.bookingDetails.endHour,
          });
          break;

        case BookingType.Daily:
          if (!service.bookingSlots) {
            service.bookingSlots = { dailyBookings: [], hourlyBookings: [], capacityBookings: [] };
          }
          service.bookingSlots.dailyBookings.push(date);
          break;

        case BookingType.Capacity:
          if (!service.bookingSlots) {
            service.bookingSlots = { dailyBookings: [], hourlyBookings: [], capacityBookings: [] };
          }
          const existingCapacity = service.bookingSlots.capacityBookings.find(
            cb => new Date(cb.date).getTime() === date.getTime()
          );
          if (existingCapacity) {
            existingCapacity.bookedCount += update.bookingDetails.numberOfPeople;
          } else {
            service.bookingSlots.capacityBookings.push({
              date,
              bookedCount: update.bookingDetails.numberOfPeople,
            });
          }
          break;

        case BookingType.Mixed:
          if (!service.bookingSlots) {
            service.bookingSlots = { dailyBookings: [], hourlyBookings: [], capacityBookings: [] };
          }
          if (update.bookingDetails.isFullVenue) {
            service.bookingSlots.dailyBookings.push(date);
          } else {
            const existingCapacity = service.bookingSlots.capacityBookings.find(
              cb => new Date(cb.date).getTime() === date.getTime()
            );
            if (existingCapacity) {
              existingCapacity.bookedCount += update.bookingDetails.numberOfPeople;
            } else {
              service.bookingSlots.capacityBookings.push({
                date,
                bookedCount: update.bookingDetails.numberOfPeople,
              });
            }
          }
          break;
      }
    }

    await service.save();
  }

  private async sendBookingNotificationToVendor(booking: Booking, providerId: string): Promise<void> {
    try {
      const vendor = await this.userModel.findById(providerId);
      if (!vendor || !vendor['fcmToken']) {
        this.logger.warn(`Vendor ${providerId} not found or no FCM token`);
        return;
      }

      const dateStr = booking.bookingDetails.date.toLocaleDateString();
      let timeStr = '';
      
      if (booking.bookingType === BookingType.Hourly) {
        timeStr = ` from ${booking.bookingDetails.startHour}:00 to ${booking.bookingDetails.endHour}:00`;
      }

      const notificationDto = {
        recipientId: new Types.ObjectId(providerId),
        recipientType: RecipientType.VENDOR,
        title: 'New Booking Confirmed',
        body: `New booking for ${booking.serviceName} on ${dateStr}${timeStr}. Amount: $${booking.price}`,
        type: NotificationType.BOOKING_CONFIRMED,
        metadata: {
          bookingId: booking._id,
          serviceId: booking.serviceId,
          userId: booking.userId,
        }
      };

      await this.notificationService.createNotification(
        notificationDto,
        vendor['fcmToken'] as string
      );

    } catch (error) {
      this.logger.error('Failed to send notification to vendor:', error);
    }
  }

  async cancelBookingByVendor(
    bookingId: string,
    vendorId: string,
    reason?: string
  ): Promise<{ booking: Booking; refund: any }> {
    try {
      const booking = await this.bookingModel.findById(bookingId);
      
      if (!booking) {
        throw new HttpException('Booking not found', HttpStatus.NOT_FOUND);
      }

      if (booking.providerId !== vendorId) {
        throw new HttpException('Unauthorized', HttpStatus.FORBIDDEN);
      }

      if (booking.status === BookingStatus.CANCELLED) {
        throw new HttpException('Booking already cancelled', HttpStatus.BAD_REQUEST);
      }

      // Process refund
      const refund = await this.stripe.refunds.create({
        payment_intent: booking.paymentIntentId,
        amount: Math.round(booking.price * 100), // Convert to cents
      });

      // Update booking
      booking.status = BookingStatus.CANCELLED;
      booking.cancellationReason = reason || 'We apologize, but we are unable to provide this service at the requested time. Your payment has been refunded.';
      booking.cancelledAt = new Date();
      booking.cancelledBy = 'vendor';
      booking.refunded = true;
      booking.refundId = refund.id;

      await booking.save();

      // Update service booking slots (remove the booking)
      await this.removeBookingFromService(booking);

      // Send notification to user
      await this.sendCancellationNotificationToUser(booking);

      return { booking, refund };

    } catch (error) {
      this.logger.error('Failed to cancel booking:', error.stack);
      if (error instanceof HttpException) throw error;
      throw new HttpException('Failed to cancel booking', HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }

  private async removeBookingFromService(booking: Booking): Promise<void> {
    try {
      const service = await this.serviceModel.findById(booking.serviceId);
      if (!service || !service.bookingSlots) return;

      const date = new Date(booking.bookingDetails.date);
      date.setHours(0, 0, 0, 0);

      switch (booking.bookingType) {
        case BookingType.Hourly:
          service.bookingSlots.hourlyBookings = service.bookingSlots.hourlyBookings.filter(
            hb => !(
              new Date(hb.date).getTime() === date.getTime() &&
              hb.startHour === booking.bookingDetails.startHour &&
              hb.endHour === booking.bookingDetails.endHour
            )
          );
          break;

        case BookingType.Daily:
          service.bookingSlots.dailyBookings = service.bookingSlots.dailyBookings.filter(
            db => new Date(db).getTime() !== date.getTime()
          );
          break;

        case BookingType.Capacity:
        case BookingType.Mixed:
          const capacityBooking = service.bookingSlots.capacityBookings.find(
            cb => new Date(cb.date).getTime() === date.getTime()
          );
          if (capacityBooking) {
            capacityBooking.bookedCount -= booking.bookingDetails.numberOfPeople || 0;
            if (capacityBooking.bookedCount <= 0) {
              service.bookingSlots.capacityBookings = service.bookingSlots.capacityBookings.filter(
                cb => new Date(cb.date).getTime() !== date.getTime()
              );
            }
          }
          break;
      }

      await service.save();
    } catch (error) {
      this.logger.error('Failed to remove booking from service:', error);
    }
  }

  private async sendCancellationNotificationToUser(booking: Booking): Promise<void> {
    try {
      const user = await this.userModel.findById(booking.userId);
      if (!user || !user['fcmToken']) {
        this.logger.warn(`User ${booking.userId} not found or no FCM token`);
        return;
      }

      const notificationDto = {
        recipientId: booking.userId,
        recipientType: RecipientType.USER,
        title: 'Booking Cancelled',
        body: `Your booking for ${booking.serviceName} has been cancelled. ${booking.cancellationReason}`,
        type: NotificationType.BOOKING_CANCELLED,
        metadata: {
          bookingId: booking._id,
          serviceId: booking.serviceId,
          refunded: booking.refunded,
          refundAmount: booking.price,
        }
      };

      await this.notificationService.createNotification(
        notificationDto,
        user['fcmToken'] as string
      );

    } catch (error) {
      this.logger.error('Failed to send cancellation notification:', error);
    }
  }

  async getUserBookings(userId: string): Promise<Booking[]> {
    return this.bookingModel
      .find({ userId: new Types.ObjectId(userId) })
      .sort({ createdAt: -1 })
      .exec();
  }

  async getVendorBookings(vendorId: string): Promise<Booking[]> {
    return this.bookingModel
      .find({ providerId: vendorId })
      .sort({ createdAt: -1 })
      .exec();
  }

  async getBookingById(bookingId: string): Promise<Booking> {
    const booking = await this.bookingModel.findById(bookingId);
    if (!booking) {
      throw new HttpException('Booking not found', HttpStatus.NOT_FOUND);
    }
    return booking;
  }
}