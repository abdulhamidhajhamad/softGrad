import { Injectable, HttpException, HttpStatus, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { ShoppingCart } from './shoppingCart.schema';
import { Service, BookingType } from '../service/service.schema';
import { AddToCartDto, RemoveFromCartDto } from './shoppingCart.dto';

@Injectable()
export class ShoppingCartService {
  private readonly logger = new Logger(ShoppingCartService.name);

  constructor(
    @InjectModel(ShoppingCart.name) private shoppingCartModel: Model<ShoppingCart>,
    @InjectModel(Service.name) private serviceModel: Model<Service>,
  ) {}

  private normalizeDate(date: Date): Date {
    const normalized = new Date(date);
    normalized.setHours(0, 0, 0, 0);
    return normalized;
  }

  /**
   * 🆕 فحص التوافر حسب نوع الحجز
   */
  async checkAvailability(
    serviceId: string, 
    bookingDate: Date,
    startHour?: number,
    endHour?: number,
    numberOfPeople?: number,
    isFullVenueBooking?: boolean
  ): Promise<{
    isAvailable: boolean;
    message: string;
    availableSlots?: any;
  }> {
    try {
      const service = await this.serviceModel.findById(serviceId);
      
      if (!service) {
        throw new HttpException('Service not found', HttpStatus.NOT_FOUND);
      }

      // ❌ Display type لا يسمح بالحجز
      if (service.bookingType === BookingType.Display) {
        return {
          isAvailable: false,
          message: 'This service is for display only. Please use the external link to book.'
        };
      }

      const targetDate = this.normalizeDate(bookingDate);

      switch (service.bookingType) {
        case BookingType.Daily:
          return this.checkDailyAvailability(service, targetDate);
        
        case BookingType.Hourly:
          return this.checkHourlyAvailability(service, targetDate, startHour, endHour);
        
        case BookingType.Capacity:
          return this.checkCapacityAvailability(service, targetDate, numberOfPeople);
        
        case BookingType.Mixed:
          return this.checkMixedAvailability(service, targetDate, numberOfPeople, isFullVenueBooking, startHour, endHour);
        
        default:
          throw new HttpException('Invalid booking type', HttpStatus.BAD_REQUEST);
      }
    } catch (error) {
      this.logger.error('Failed to check availability:', error.stack);
      throw new HttpException(
        error.message || 'Failed to check availability',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  /**
   * فحص توافر الحجز اليومي (Daily)
   */
  private checkDailyAvailability(service: Service, targetDate: Date): {
    isAvailable: boolean;
    message: string;
  } {
    const isBooked = service.bookingSlots.dailyBookings.some(bookedDate => {
      const booked = this.normalizeDate(bookedDate);
      return booked.getTime() === targetDate.getTime();
    });

    if (isBooked) {
      return {
        isAvailable: false,
        message: `Sorry, "${service.serviceName}" is already fully booked on ${targetDate.toDateString()}. Please choose a different date.`
      };
    }

    return {
      isAvailable: true,
      message: `"${service.serviceName}" is available for booking on ${targetDate.toDateString()}`
    };
  }

  /**
   * فحص توافر الحجز بالساعة (Hourly)
   */
  private checkHourlyAvailability(
    service: Service, 
    targetDate: Date, 
    startHour?: number, 
    endHour?: number
  ): {
    isAvailable: boolean;
    message: string;
    availableSlots?: number[];
    suggestedTime?: string;
    conflictReason?: 'direct_overlap' | 'cleanup_time';
  } {
    // التحقق من إدخال الساعات
    if (startHour === undefined || endHour === undefined) {
      return {
        isAvailable: false,
        message: 'Start hour and end hour are required for hourly bookings'
      };
    }

    if (startHour >= endHour) {
      return {
        isAvailable: false,
        message: 'End hour must be greater than start hour'
      };
    }

    // التحقق من الحد الأدنى والأقصى للساعات
    if (service.minBookingHours) {
      const bookingDuration = endHour - startHour;
      if (bookingDuration < service.minBookingHours) {
        return {
          isAvailable: false,
          message: `Minimum booking duration is ${service.minBookingHours} hours`
        };
      }
    }

    if (service.maxBookingHours) {
      const bookingDuration = endHour - startHour;
      if (bookingDuration > service.maxBookingHours) {
        return {
          isAvailable: false,
          message: `Maximum booking duration is ${service.maxBookingHours} hours`
        };
      }
    }

    // التحقق من الساعات المتاحة
if (service.availableHours && service.availableHours.length > 0) {
    const requestedHours: number[] = []; // 🛠️ التصحيح 1: تحديد النوع
    for (let h = startHour; h < endHour; h++) {
        requestedHours.push(h);
    }

    const invalidHours = requestedHours.filter(h => !service.availableHours!.includes(h)); // 🛠️ التصحيح 2: إضافة !
      if (invalidHours.length > 0) {
        return {
          isAvailable: false,
          message: `Hours ${invalidHours.join(', ')} are not available for booking`,
          availableSlots: service.availableHours
        };
      }
    }

    // 🆕 حساب وقت التنظيف بالساعات (تحويل من دقائق)
    const cleanupTimeHours = service.cleanupTimeMinutes 
      ? service.cleanupTimeMinutes / 60 
      : 0;

    // التحقق من التعارض مع الحجوزات الموجودة (مع احتساب وقت التنظيف)
    const bookingsOnDate = service.bookingSlots.hourlyBookings.filter(booking => {
      const bookedDate = this.normalizeDate(booking.date);
      return bookedDate.getTime() === targetDate.getTime();
    });

    for (const booking of bookingsOnDate) {
      // إضافة وقت التنظيف لنهاية الحجز السابق
      const bookingEndWithCleanup = booking.endHour + cleanupTimeHours;

      // فحص التداخل المباشر
      const hasDirectOverlap = (
        (startHour >= booking.startHour && startHour < booking.endHour) ||
        (endHour > booking.startHour && endHour <= booking.endHour) ||
        (startHour <= booking.startHour && endHour >= booking.endHour)
      );

      if (hasDirectOverlap) {
        return {
          isAvailable: false,
          message: `Sorry, we are already booked at this time and date (${booking.startHour}:00 - ${booking.endHour}:00)`,
          conflictReason: 'direct_overlap'
        };
      }

      // 🆕 فحص التعارض مع وقت التنظيف
      const needsCleanupTime = startHour < bookingEndWithCleanup && startHour >= booking.endHour;
      
      if (needsCleanupTime && service.cleanupTimeMinutes && service.cleanupTimeMinutes > 0) {
        const suggestedStartTime = Math.ceil(bookingEndWithCleanup);
        const suggestedEndTime = suggestedStartTime + (endHour - startHour);
        
        return {
          isAvailable: false,
          message: `Sorry, we cannot accept your booking at this time because we need ${service.cleanupTimeMinutes} minutes to clean after the previous booking (ends at ${booking.endHour}:00). We can accept your booking if you start at ${suggestedStartTime}:00 or add ${service.cleanupTimeMinutes} minutes to your start time.`,
          suggestedTime: `${suggestedStartTime}:00 - ${suggestedEndTime}:00`,
          conflictReason: 'cleanup_time'
        };
      }

      // فحص إذا كان الحجز الجديد يحتاج وقت تنظيف قبل حجز لاحق
      const nextBookingStartsBeforeCleanup = endHour + cleanupTimeHours > booking.startHour && endHour <= booking.startHour;
      
      if (nextBookingStartsBeforeCleanup && service.cleanupTimeMinutes && service.cleanupTimeMinutes > 0) {
        const maxEndTime = booking.startHour - cleanupTimeHours;
        
        return {
          isAvailable: false,
          message: `Sorry, we cannot accept your booking at this time because we need ${service.cleanupTimeMinutes} minutes to clean before the next booking (starts at ${booking.startHour}:00). Please end your booking by ${maxEndTime.toFixed(2)} or choose a different time.`,
          conflictReason: 'cleanup_time'
        };
      }
    }

    return {
      isAvailable: true,
      message: `Time slot ${startHour}:00 - ${endHour}:00 is available`
    };
  }

  /**
   * فحص توافر الحجز حسب السعة (Capacity)
   */
  private checkCapacityAvailability(
    service: Service, 
    targetDate: Date, 
    numberOfPeople?: number
  ): {
    isAvailable: boolean;
    message: string;
    availableSlots?: any;
  } {
    if (!numberOfPeople || numberOfPeople <= 0) {
      return {
        isAvailable: false,
        message: 'Number of people is required for capacity-based bookings'
      };
    }

    // 🆕 إذا لم يكن هناك حد أقصى، السعة غير محدودة
    if (!service.maxCapacity || service.maxCapacity <= 0) {
      return {
        isAvailable: true,
        message: `Booking available for ${numberOfPeople} people (unlimited capacity)`,
        availableSlots: { availableCapacity: 'unlimited', totalCapacity: 'unlimited' }
      };
    }

    // حساب العدد المحجوز في هذا التاريخ
    const existingBooking = service.bookingSlots.capacityBookings.find(booking => {
      const bookedDate = this.normalizeDate(booking.date);
      return bookedDate.getTime() === targetDate.getTime();
    });

    const currentBookedCount = existingBooking ? existingBooking.bookedCount : 0;
    const availableCapacity = service.maxCapacity - currentBookedCount;

    if (numberOfPeople > availableCapacity) {
      return {
        isAvailable: false,
        message: `Sorry, we are booked on this date. Only ${availableCapacity} spot${availableCapacity !== 1 ? 's' : ''} available out of ${service.maxCapacity} total capacity, but you requested ${numberOfPeople} spot${numberOfPeople !== 1 ? 's' : ''}.`,
        availableSlots: { 
          availableCapacity, 
          totalCapacity: service.maxCapacity,
          requestedCapacity: numberOfPeople
        }
      };
    }

    return {
      isAvailable: true,
      message: `Booking confirmed for ${numberOfPeople} people. ${availableCapacity - numberOfPeople} spot${(availableCapacity - numberOfPeople) !== 1 ? 's' : ''} remaining.`,
      availableSlots: { 
        availableCapacity, 
        totalCapacity: service.maxCapacity,
        remainingAfterBooking: availableCapacity - numberOfPeople
      }
    };
  }

  /**
   * فحص توافر الحجز المختلط (Mixed)
   */
  private checkMixedAvailability(
    service: Service,
    targetDate: Date,
    numberOfPeople?: number,
    isFullVenueBooking?: boolean,
    startHour?: number,
    endHour?: number
  ): {
    isAvailable: boolean;
    message: string;
    availableSlots?: any;
  } {
    // إذا كان حجز كامل للمكان
    if (isFullVenueBooking) {
      if (!service.allowFullVenueBooking) {
        return {
          isAvailable: false,
          message: 'Full venue booking is not available for this service'
        };
      }

      // تحقق من عدم وجود أي حجوزات في هذا اليوم
      const hasAnyBooking = (
        service.bookingSlots.dailyBookings.some(d => this.normalizeDate(d).getTime() === targetDate.getTime()) ||
        service.bookingSlots.capacityBookings.some(b => this.normalizeDate(b.date).getTime() === targetDate.getTime()) ||
        service.bookingSlots.hourlyBookings.some(b => this.normalizeDate(b.date).getTime() === targetDate.getTime())
      );

      if (hasAnyBooking) {
        return {
          isAvailable: false,
          message: 'Cannot book full venue - there are existing bookings on this date'
        };
      }

      return {
        isAvailable: true,
        message: 'Full venue is available for booking'
      };
    }

    // تحقق من عدم وجود حجز كامل في هذا اليوم
    const hasFullBooking = service.bookingSlots.dailyBookings.some(d => 
      this.normalizeDate(d).getTime() === targetDate.getTime()
    );

    if (hasFullBooking) {
      return {
        isAvailable: false,
        message: 'Venue is fully booked on this date'
      };
    }

    // إذا كان حجز حسب السعة
    if (numberOfPeople) {
      return this.checkCapacityAvailability(service, targetDate, numberOfPeople);
    }

    // إذا كان حجز بالساعة
    if (startHour !== undefined && endHour !== undefined) {
      return this.checkHourlyAvailability(service, targetDate, startHour, endHour);
    }

    return {
      isAvailable: false,
      message: 'Please specify either number of people, time slot, or full venue booking'
    };
  }

  /**
   * 🆕 حساب السعر حسب نوع الحجز
   */
  private calculatePrice(
    service: Service,
    startHour?: number,
    endHour?: number,
    numberOfPeople?: number,
    isFullVenueBooking?: boolean
  ): number {
    switch (service.bookingType) {
      case BookingType.Daily:
        return service.price.perDay || service.price.basePrice || 0;

      case BookingType.Hourly:
        if (startHour !== undefined && endHour !== undefined) {
          const hours = endHour - startHour;
          return (service.price.perHour || 0) * hours;
        }
        return service.price.basePrice || 0;

      case BookingType.Capacity:
        if (numberOfPeople) {
          return (service.price.perPerson || 0) * numberOfPeople;
        }
        return service.price.basePrice || 0;

      case BookingType.Mixed:
        if (isFullVenueBooking) {
          return service.price.fullVenue || service.price.basePrice || 0;
        }
        if (numberOfPeople) {
          return (service.price.perPerson || 0) * numberOfPeople;
        }
        if (startHour !== undefined && endHour !== undefined) {
          const hours = endHour - startHour;
          return (service.price.perHour || 0) * hours;
        }
        return service.price.basePrice || 0;

      default:
        return service.price.basePrice || 0;
    }
  }

  /**
   * إضافة خدمة للسلة
   */
  async addToCart(userId: string, addToCartDto: AddToCartDto): Promise<{ 
    cart: ShoppingCart; 
    message: string;
    calculatedPrice: number;
  }> {
    try {
      const { serviceId, bookingDate, startHour, endHour, numberOfPeople, isFullVenueBooking } = addToCartDto;

      const normalizedDate = this.normalizeDate(bookingDate);

      // فحص التوافر
      const availabilityCheck = await this.checkAvailability(
        serviceId, 
        normalizedDate,
        startHour,
        endHour,
        numberOfPeople,
        isFullVenueBooking
      );
      
      if (!availabilityCheck.isAvailable) {
        throw new HttpException(
          availabilityCheck.message,
          HttpStatus.CONFLICT
        );
      }

      const service = await this.serviceModel.findById(serviceId);
      if (!service) {
        throw new HttpException('Service not found', HttpStatus.NOT_FOUND);
      }

      // حساب السعر
      const calculatedPrice = this.calculatePrice(
        service,
        startHour,
        endHour,
        numberOfPeople,
        isFullVenueBooking
      );

      let cart = await this.shoppingCartModel.findOne({ userId: new Types.ObjectId(userId) });

      if (!cart) {
        cart = new this.shoppingCartModel({
          userId: new Types.ObjectId(userId),
          services: [],
          totalPrice: 0
        });
      }

      // التحقق من وجود الخدمة بنفس التفاصيل
      const existingService = cart.services.find(item => {
        if (item.serviceId.toString() !== serviceId) return false;
        if (this.normalizeDate(item.bookingDate).getTime() !== normalizedDate.getTime()) return false;
        
        // للحجوزات بالساعة
        if (service.bookingType === BookingType.Hourly) {
          return item.startHour === startHour && item.endHour === endHour;
        }
        
        return true;
      });

      if (existingService) {
        throw new HttpException(
          'Service with same details already exists in cart',
          HttpStatus.CONFLICT
        );
      }

      // إضافة الخدمة
      cart.services.push({
        serviceId: new Types.ObjectId(serviceId),
        bookingDate: normalizedDate,
        startHour,
        endHour,
        numberOfPeople,
        isFullVenueBooking,
        calculatedPrice
      });

      cart.totalPrice = cart.services.reduce((sum, item) => sum + (item.calculatedPrice || 0), 0);

      const savedCart = await cart.save();
      
      let bookingDetails = '';
      if (service.bookingType === BookingType.Hourly) {
        bookingDetails = ` from ${startHour}:00 to ${endHour}:00`;
      } else if (service.bookingType === BookingType.Capacity) {
        bookingDetails = ` for ${numberOfPeople} people`;
      } else if (isFullVenueBooking) {
        bookingDetails = ' (full venue booking)';
      }

      return {
        cart: savedCart,
        message: `Service "${service.serviceName}" added to cart for ${normalizedDate.toDateString()}${bookingDetails}`,
        calculatedPrice
      };
    } catch (error) {
      this.logger.error('Failed to add to cart:', error.stack);
      throw new HttpException(
        error.message || 'Failed to add to cart',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  /**
   * إزالة خدمة من السلة
   */
  async removeFromCart(userId: string, removeFromCartDto: RemoveFromCartDto): Promise<{ 
    cart: ShoppingCart; 
    message: string;
    removedCount: number;
  }> {
    try {
      const { serviceId, bookingDate, startHour, endHour } = removeFromCartDto;
      const normalizedDate = this.normalizeDate(bookingDate);

      const cart = await this.shoppingCartModel.findOne({ userId: new Types.ObjectId(userId) });

      if (!cart) {
        throw new HttpException('Cart not found', HttpStatus.NOT_FOUND);
      }

      const initialLength = cart.services.length;

      // إزالة الخدمة بناءً على المعايير
      cart.services = cart.services.filter(item => {
        if (item.serviceId.toString() !== serviceId) return true;
        if (this.normalizeDate(item.bookingDate).getTime() !== normalizedDate.getTime()) return true;
        
        // للحجوزات بالساعة، تحقق من تطابق الساعات
        if (startHour !== undefined && endHour !== undefined) {
          return !(item.startHour === startHour && item.endHour === endHour);
        }
        
        return false;
      });

      const removedCount = initialLength - cart.services.length;

      if (removedCount === 0) {
        throw new HttpException('Service not found in cart', HttpStatus.NOT_FOUND);
      }

      cart.totalPrice = cart.services.reduce((sum, item) => sum + (item.calculatedPrice || 0), 0);

      const savedCart = await cart.save();

      return {
        cart: savedCart,
        message: `Removed ${removedCount} service(s) from cart`,
        removedCount
      };
    } catch (error) {
      this.logger.error('Failed to remove from cart:', error.stack);
      throw new HttpException(
        error.message || 'Failed to remove from cart',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  /**
   * تفريغ السلة
   */
  async clearCart(userId: string): Promise<{ 
    cart: ShoppingCart; 
    message: string;
    clearedCount: number;
  }> {
    try {
      const cart = await this.shoppingCartModel.findOne({ userId: new Types.ObjectId(userId) });

      if (!cart) {
        throw new HttpException('Cart not found', HttpStatus.NOT_FOUND);
      }

      const clearedCount = cart.services.length;
      cart.services = [];
      cart.totalPrice = 0;

      const savedCart = await cart.save();
      
      return {
        cart: savedCart,
        message: `Cleared ${clearedCount} services from cart`,
        clearedCount
      };
    } catch (error) {
      this.logger.error('Failed to clear cart:', error.stack);
      throw new HttpException(
        error.message || 'Failed to clear cart',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  /**
   * جلب السلة
   */
  async getCartByUserId(userId: string): Promise<any> {
    try {
      const cart = await this.shoppingCartModel
        .findOne({ userId: new Types.ObjectId(userId) })
        .populate('services.serviceId')
        .exec();

      if (!cart || cart.services.length === 0) {
        return {
          userId: new Types.ObjectId(userId),
          services: [],
          totalPrice: 0,
          message: 'Cart is empty'
        };
      }

      return {
        ...cart.toObject(),
        message: `Found ${cart.services.length} service(s) in cart`
      };
    } catch (error) {
      this.logger.error('Failed to get cart:', error.stack);
      throw new HttpException(
        error.message || 'Failed to get cart',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  /**
   * فحص توافر التاريخ (للتوافق مع الكود القديم)
   */
  async checkDateAvailability(
    serviceId: string, 
    bookingDate: Date
  ): Promise<{ 
    isAvailable: boolean; 
    message: string;
    serviceName?: string;
  }> {
    try {
      const service = await this.serviceModel.findById(serviceId);
      
      if (!service) {
        throw new HttpException('Service not found', HttpStatus.NOT_FOUND);
      }

      const result = await this.checkAvailability(serviceId, bookingDate);

      return {
        ...result,
        serviceName: service.serviceName
      };
    } catch (error) {
      this.logger.error('Failed to check date availability:', error.stack);
      throw new HttpException(
        error.message || 'Failed to check date availability',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }
}