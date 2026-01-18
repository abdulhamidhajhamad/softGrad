// cart.service.ts
import { Injectable, HttpException, HttpStatus, Logger, BadRequestException, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Cart, CartItem } from './shoppingCart.schema';
import { Service, BookingType } from '../service/service.schema';
import { AddToCartDto, RemoveFromCartDto, UpdateCartItemDto } from './shoppingCart.dto';
import { AddPackageToCartDto } from '../Package/package.dto';
import { PackageService } from '../Package/package.service';
import { BookingStatus } from 'src/booking/booking.entity';
import { Booking } from 'src/booking/booking.entity'; 

@Injectable()
export class CartService {
  private readonly logger = new Logger(CartService.name);

  constructor(
    @InjectModel(Cart.name) private cartModel: Model<Cart>,
    @InjectModel(Service.name) private serviceModel: Model<Service>,
    @InjectModel(Booking.name) private bookingModel: Model<Booking>,
    private packageService: PackageService,
  ) {}

  // ... (addToCart, removeFromCart, updateCartItem, getCart, clearCart كما هي بدون تغيير) ...
  async addToCart(userId: string, addToCartDto: AddToCartDto): Promise<Cart> {
      // (نفس الكود الأصلي)
      try {
        const service = await this.serviceModel.findById(addToCartDto.serviceId);
        if (!service) {
          throw new HttpException('Service not found', HttpStatus.NOT_FOUND);
        }
  
        const bookingDate = new Date(addToCartDto.bookingDetails.date);
        const dayName = this.getDayName(bookingDate);
        
        if (!service.workingDays || !service.workingDays.includes(dayName)) {
          throw new HttpException(
            `Service is not available on ${dayName}. Working days: ${service.workingDays.join(', ')}`,
            HttpStatus.BAD_REQUEST
          );
        }
  
        this.validateServiceLimits(service, addToCartDto.bookingDetails);
  
        // 🚨 هنا سيتم استخدام دالة التحقق المعدلة
        const isAvailable = await this.checkAvailability(
          service,
          bookingDate,
          addToCartDto.bookingDetails
        );
  
        if (!isAvailable) {
          throw new HttpException(
            'Service is not available for the selected date/time (Fully Booked)',
            HttpStatus.CONFLICT
          );
        }
  
        const price = this.calculatePrice(service, addToCartDto.bookingDetails);
  
        let cart = await this.cartModel.findOne({ userId: new Types.ObjectId(userId) });
  
        if (!cart) {
          cart = new this.cartModel({
            userId: new Types.ObjectId(userId),
            items: [],
            totalAmount: 0
          });
        }
  
        const existingItemIndex = cart.items.findIndex(
          item => item.serviceId.toString() === addToCartDto.serviceId
        );
  
        if (existingItemIndex > -1) {
          throw new HttpException(
            'Service already in cart. Please update or remove it first.',
            HttpStatus.CONFLICT
          );
        }
  
        const cartItem: CartItem = {
          serviceId: new Types.ObjectId(addToCartDto.serviceId),
          serviceName: service.serviceName,
          providerId: service.providerId,
          companyName: service.companyName,
          bookingType: service.bookingType,
          bookingDetails: {
            date: new Date(addToCartDto.bookingDetails.date),
            startHour: addToCartDto.bookingDetails.startHour,
            endHour: addToCartDto.bookingDetails.endHour,
            numberOfPeople: addToCartDto.bookingDetails.numberOfPeople,
            isFullVenue: addToCartDto.bookingDetails.isFullVenue,
            // 🆕 موقع العميل ووصف الحجز
            clientLocation: addToCartDto.bookingDetails.clientLocation,
            bookingDescription: addToCartDto.bookingDetails.bookingDescription,
          },
          price,
          imageUrl: service.images?.[0]
        } as CartItem;
  
        cart.items.push(cartItem);
        cart.totalAmount = cart.items.reduce((sum, item) => sum + item.price, 0);
  
        await cart.save();
        return cart;
  
      } catch (error) {
        this.logger.error('Failed to add to cart:', error.stack);
        if (error instanceof HttpException) throw error;
        throw new HttpException('Failed to add to cart', HttpStatus.INTERNAL_SERVER_ERROR);
      }
    }
    
    async removeFromCart(userId: string, removeFromCartDto: RemoveFromCartDto): Promise<Cart> {
        try {
          const cart = await this.cartModel.findOne({ userId: new Types.ObjectId(userId) });
          
          if (!cart) {
            throw new HttpException('Cart not found', HttpStatus.NOT_FOUND);
          }
    
          cart.items = cart.items.filter(
            item => item.serviceId.toString() !== removeFromCartDto.serviceId
          );
    
          cart.totalAmount = cart.items.reduce((sum, item) => sum + item.price, 0);
    
          await cart.save();
          return cart;
    
        } catch (error) {
          this.logger.error('Failed to remove from cart:', error.stack);
          if (error instanceof HttpException) throw error;
          throw new HttpException('Failed to remove from cart', HttpStatus.INTERNAL_SERVER_ERROR);
        }
      }
    
      async updateCartItem(userId: string, updateCartItemDto: UpdateCartItemDto): Promise<Cart> {
        try {
          const cart = await this.cartModel.findOne({ userId: new Types.ObjectId(userId) });
          
          if (!cart) {
            throw new HttpException('Cart not found', HttpStatus.NOT_FOUND);
          }
    
          const itemIndex = cart.items.findIndex(
            item => item.serviceId.toString() === updateCartItemDto.serviceId
          );
    
          if (itemIndex === -1) {
            throw new HttpException('Item not found in cart', HttpStatus.NOT_FOUND);
          }
    
          const service = await this.serviceModel.findById(updateCartItemDto.serviceId);
          if (!service) {
            throw new HttpException('Service not found', HttpStatus.NOT_FOUND);
          }
    
          const bookingDate = new Date(updateCartItemDto.bookingDetails.date);
          const dayName = this.getDayName(bookingDate);
          
          if (!service.workingDays || !service.workingDays.includes(dayName)) {
            throw new HttpException(
              `Service is not available on ${dayName}. Working days: ${service.workingDays.join(', ')}`,
              HttpStatus.BAD_REQUEST
            );
          }
    
          this.validateServiceLimits(service, updateCartItemDto.bookingDetails);
    
          const isAvailable = await this.checkAvailability(
            service,
            bookingDate,
            updateCartItemDto.bookingDetails
          );
    
          if (!isAvailable) {
            throw new HttpException(
              'Service is not available for the selected date/time',
              HttpStatus.CONFLICT
            );
          }
    
          const price = this.calculatePrice(service, updateCartItemDto.bookingDetails);
    
          cart.items[itemIndex].bookingDetails = {
            date: new Date(updateCartItemDto.bookingDetails.date),
            startHour: updateCartItemDto.bookingDetails.startHour,
            endHour: updateCartItemDto.bookingDetails.endHour,
            numberOfPeople: updateCartItemDto.bookingDetails.numberOfPeople,
            isFullVenue: updateCartItemDto.bookingDetails.isFullVenue,
            // 🆕 موقع العميل ووصف الحجز
            clientLocation: updateCartItemDto.bookingDetails.clientLocation,
            bookingDescription: updateCartItemDto.bookingDetails.bookingDescription,
          };
          cart.items[itemIndex].price = price;
    
          cart.totalAmount = cart.items.reduce((sum, item) => sum + item.price, 0);
    
          await cart.save();
          return cart;
    
        } catch (error) {
          this.logger.error('Failed to update cart item:', error.stack);
          if (error instanceof HttpException) throw error;
          throw new HttpException('Failed to update cart item', HttpStatus.INTERNAL_SERVER_ERROR);
        }
      }
    
      async getCart(userId: string): Promise<Cart | null> {
        return this.cartModel.findOne({ userId: new Types.ObjectId(userId) }).exec();
      }
    
      async clearCart(userId: string): Promise<void> {
        await this.cartModel.findOneAndDelete({ userId: new Types.ObjectId(userId) });
      }

  // ----------------------------------------------------------------
  // ✅ التعديلات الأساسية هنا في الـ Availability Logic
  // ----------------------------------------------------------------

  private async checkAvailability(
    service: Service,
    date: Date,
    bookingDetails: any
  ): Promise<boolean> {
    const dateOnly = new Date(date);
    dateOnly.setHours(0, 0, 0, 0);

    // 1. Global Check: Operating Hours
    if (service.availableHours && service.availableHours.length > 0 && bookingDetails.startHour !== undefined) {
      if (!service.availableHours.includes(Math.floor(bookingDetails.startHour))) {
        throw new BadRequestException(`The service is not operational at ${bookingDetails.startHour}:00.`);
      }
    }

    switch (service.bookingType) {
      case BookingType.Hourly:
        return await this.checkHourlyAvailability(service, dateOnly, bookingDetails.startHour, bookingDetails.endHour);
      
      case BookingType.Daily:
        return await this.checkDailyAvailability(service, dateOnly);
      
      case BookingType.Capacity:
      case BookingType.Mixed:
        if (bookingDetails.isFullVenue) {
          return await this.checkDailyAvailability(service, dateOnly);
        }
        return await this.checkCapacityAvailability(service, dateOnly, bookingDetails.numberOfPeople);
      
      case BookingType.Display:
        return true;
      
      default:
        throw new BadRequestException('Unsupported booking type.');
    }
  }

  /**
   * ✅ تم التعديل: التحقق من التوفر بالساعة مع دعم الـ Concurrency
   */
  private async checkHourlyAvailability(
    service: Service, 
    date: Date, 
    newStart: number, 
    newEnd: number
  ): Promise<boolean> {
    if (newStart === undefined || newEnd === undefined) {
      throw new BadRequestException('Start and End hours are required for hourly bookings.');
    }

    const buffer = (service.cleanupTimeMinutes || 0) / 60;
    // 🆕 استخدام القيمة الجديدة (default: 1)
    const maxConcurrency = service.maxConcurrency || 1;

    // جلب جميع الحجوزات القائمة لهذا اليوم
    const existingBookings = await this.bookingModel.find({
      serviceId: service._id,
      'bookingDetails.date': date,
      status: { $ne: BookingStatus.CANCELLED } 
    }).exec();

    let concurrentConflicts = 0;

    for (const booking of existingBookings) {
      const exStart = booking.bookingDetails.startHour ?? 0;
      const exEnd = booking.bookingDetails.endHour ?? 0;    
      
      const exEndWithBuffer = exEnd + buffer;
      const newEndWithBuffer = newEnd + buffer;

      // هل يوجد تقاطع؟
      // (Start A < End B) and (End A > Start B)
      if (newStart < exEndWithBuffer && newEndWithBuffer > exStart) {
        concurrentConflicts++;
      }
    }

    // 🆕 المقارنة مع الحد الأقصى المسموح به
    if (concurrentConflicts >= maxConcurrency) {
      throw new HttpException(
        `Time slot conflict: The selected time (${newStart}:00-${newEnd}:00) is fully booked. (Max capacity reached: ${maxConcurrency})`,
        HttpStatus.CONFLICT
      );
    }

    return true; // مسموح بالحجز
  }

  /**
   * ✅ تم التعديل: التحقق من التوفر اليومي مع دعم الـ Concurrency
   */
  private async checkDailyAvailability(service: Service, date: Date): Promise<boolean> {
    const maxConcurrency = service.maxConcurrency || 1;

    const existingCount = await this.bookingModel.countDocuments({
      serviceId: service._id,
      'bookingDetails.date': date,
      status: { $ne: BookingStatus.CANCELLED }
    }).exec();

    // 🆕 المقارنة بالعدد المسموح
    if (existingCount >= maxConcurrency) {
      throw new HttpException(
        `Service is fully booked for the selected date. (Max daily events: ${maxConcurrency})`,
        HttpStatus.CONFLICT
      );
    }
    return true;
  }

  /**
   * Capacity Availability (لم يتم تغييره لأنه يعتمد على عدد الأشخاص وليس عدد الفعاليات)
   * ولكن يمكن إضافة منطق مشابه إذا أردت تقييد عدد المجموعات المنفصلة في القاعة الواحدة،
   * لكن الكود الحالي يعتمد على مجموع الأشخاص وهو الأصح للـ Capacity.
   */
  private async checkCapacityAvailability(
    service: Service, 
    date: Date, 
    numberOfPeople: number
  ): Promise<boolean> {
    if (!service.maxCapacity) return true;

    if (!numberOfPeople || numberOfPeople <= 0) {
      throw new BadRequestException('Please specify the number of people.');
    }

    if (numberOfPeople > service.maxCapacity) {
      throw new BadRequestException(`Maximum capacity is ${service.maxCapacity}.`);
    }

    const bookingsAtSameDate = await this.bookingModel.find({
      serviceId: service._id,
      'bookingDetails.date': date,
      status: { $ne: BookingStatus.CANCELLED }
    }).exec();

    const currentBookedCount = bookingsAtSameDate.reduce(
      (sum, b) => sum + (b.bookingDetails.numberOfPeople || 0), 0
    );

    const availableSlots = service.maxCapacity - currentBookedCount;

    if (numberOfPeople > availableSlots) {
      throw new HttpException(
        `Insufficient space: Only ${availableSlots} slots remaining for this date.`,
        HttpStatus.CONFLICT
      );
    }

    return true;
  }

  // ... (calculatePrice, getDayName, validateServiceLimits, addPackageToCart كما هي بدون تغيير) ...
  private calculatePrice(service: Service, bookingDetails: any): number {
    const simplePrice = service.price || 0;
    const priceOpts = service.priceOptions;

    switch (service.bookingType) {
      case BookingType.Hourly:
        const hours = bookingDetails.endHour - bookingDetails.startHour;
        const perHour = priceOpts?.perHour || simplePrice;
        return perHour * hours;
      
      case BookingType.Daily:
        return priceOpts?.perDay || simplePrice;
      
      case BookingType.Capacity:
        const perPerson = priceOpts?.perPerson || simplePrice;
        return perPerson * bookingDetails.numberOfPeople;
      
      case BookingType.Display:
        return priceOpts?.basePrice || simplePrice;
      
      case BookingType.Mixed:
        if (bookingDetails.isFullVenue) {
          return priceOpts?.fullVenue || simplePrice;
        }
        const perPersonMixed = priceOpts?.perPerson || simplePrice;
        return perPersonMixed * bookingDetails.numberOfPeople;
      
      default:
        return priceOpts?.basePrice || simplePrice;
    }
  }

  private getDayName(date: Date): string {
    const days = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
    return days[date.getDay()];
  }

  private validateServiceLimits(service: Service, bookingDetails: any): void {
    if (service.bookingType === BookingType.Hourly) {
      if (!bookingDetails.startHour || !bookingDetails.endHour) {
        throw new HttpException(
          'Start hour and end hour are required for hourly bookings',
          HttpStatus.BAD_REQUEST
        );
      }
      
      const hours = bookingDetails.endHour - bookingDetails.startHour;
      
      if (hours <= 0) {
        throw new HttpException(
          'End hour must be greater than start hour',
          HttpStatus.BAD_REQUEST
        );
      }

      if (hours > 24) {
        throw new HttpException(
          'Cannot book more than 24 hours',
          HttpStatus.BAD_REQUEST
        );
      }
    }

    if (service.bookingType === BookingType.Capacity || service.bookingType === BookingType.Mixed) {
      if (!bookingDetails.isFullVenue && !bookingDetails.numberOfPeople) {
        throw new HttpException(
          'Number of people is required for capacity bookings',
          HttpStatus.BAD_REQUEST
        );
      }

      if (bookingDetails.numberOfPeople && service.maxCapacity) {
        if (bookingDetails.numberOfPeople > service.maxCapacity) {
          throw new HttpException(
            `This service has a maximum capacity of ${service.maxCapacity} people. You requested ${bookingDetails.numberOfPeople} people.`,
            HttpStatus.BAD_REQUEST
          );
        }
      }

      if (bookingDetails.numberOfPeople && bookingDetails.numberOfPeople <= 0) {
        throw new HttpException(
          'Number of people must be greater than 0',
          HttpStatus.BAD_REQUEST
        );
      }
    }
  }

async addPackageToCart(userId: string, dto: AddPackageToCartDto): Promise<Cart> {
  const userObjectId = new Types.ObjectId(userId);
  
  // ✅ Reuse existing package validation
  const pkg = await this.packageService.getPackageById(dto.packageId);
  
  if (!pkg.isActive) {
    throw new BadRequestException('This package is not currently available.');
  }

  if (dto.serviceBookings.length !== pkg.services.length) {
    throw new BadRequestException(
      `Package requires booking all ${pkg.services.length} services. You provided ${dto.serviceBookings.length}.`
    );
  }

  // ✅ Validate each service using EXISTING validation methods
  for (const booking of dto.serviceBookings) {
    const serviceInPackage = pkg.services.find(
      s => s.serviceId.toString() === booking.serviceId.toString()
    );

    if (!serviceInPackage) {
      throw new BadRequestException(`Service ${booking.serviceId} is not part of this package.`);
    }

    const service = await this.serviceModel.findById(booking.serviceId).exec();
    if (!service) {
      throw new NotFoundException(`Service ${booking.serviceId} not found.`);
    }

    const bookingDate = new Date(booking.bookingDetails.date);

    // ✅ Reuse package date validation
    await this.packageService.validatePackageBookingDate(dto.packageId, bookingDate);

    // ✅ Reuse day validation
    const dayName = this.getDayName(bookingDate);
    if (!service.workingDays || !service.workingDays.includes(dayName)) {
      throw new BadRequestException(
        `Service "${service.serviceName}" is not available on ${dayName}. Working days: ${service.workingDays.join(', ')}`
      );
    }

    // ✅ Validate service limits (hours/capacity constraints)
    this.validateServiceLimits(service, booking.bookingDetails);

    // ✅ Validate package-specific limits
    if (serviceInPackage.maxHours) {
      if (service.bookingType === BookingType.Hourly) {
        if (booking.bookingDetails.startHour === undefined || booking.bookingDetails.endHour === undefined) {
          throw new BadRequestException(
            `Service "${service.serviceName}" requires startHour and endHour for hourly bookings.`
          );
        }
        
        const hoursBooked = booking.bookingDetails.endHour - booking.bookingDetails.startHour;
        if (hoursBooked > serviceInPackage.maxHours) {
          throw new BadRequestException(
            `Service "${service.serviceName}" allows maximum ${serviceInPackage.maxHours} hours in this package. You requested ${hoursBooked} hours.`
          );
        }
      }
    }

    if (serviceInPackage.maxCapacity) {
      if (!booking.bookingDetails.numberOfPeople) {
        throw new BadRequestException(
          `Service "${service.serviceName}" requires numberOfPeople (max: ${serviceInPackage.maxCapacity} people).`
        );
      }
      if (booking.bookingDetails.numberOfPeople > serviceInPackage.maxCapacity) {
        throw new BadRequestException(
          `Service "${service.serviceName}" allows maximum ${serviceInPackage.maxCapacity} people in this package.`
        );
      }
    }

    // ✅ Properly prepare booking details for availability check
    const bookingDetailsForCheck = {
      date: bookingDate,
      startHour: booking.bookingDetails.startHour,
      endHour: booking.bookingDetails.endHour,
      numberOfPeople: booking.bookingDetails.numberOfPeople,
      isFullVenue: false
    };

    // ✅ **CRITICAL:** Reuse existing availability check method
    // This checks: availableHours, maxConcurrency, daily limits, capacity limits
    const isAvailable = await this.checkAvailability(
      service,
      bookingDate,
      bookingDetailsForCheck
    );

    if (!isAvailable) {
      throw new BadRequestException(
        `Service "${service.serviceName}" is not available on ${bookingDate.toDateString()}.`
      );
    }
  }

  // ✅ Add to cart (remove old package items if re-adding)
  let cart = await this.cartModel.findOne({ userId: userObjectId }).exec();
  if (!cart) {
    cart = new this.cartModel({ userId: userObjectId, items: [], totalAmount: 0 });
  }

  // Remove existing package items
  cart.items = cart.items.filter(item => item.packageId?.toString() !== dto.packageId);

  // 🆕 Calculate actual total based on user input
  let calculatedTotal = 0;

  // Add new package items with CORRECT pricing
  for (const booking of dto.serviceBookings) {
    const serviceInPackage = pkg.services.find(
      s => s.serviceId.toString() === booking.serviceId
    );

    if (!serviceInPackage) {
      throw new BadRequestException('Service details not found in package definition.');
    }

    const service = await this.serviceModel.findById(booking.serviceId).exec();
    if (!service) {
      throw new NotFoundException(`Service ${booking.serviceId} not found.`);
    }

    let startHour: number | undefined;
    let endHour: number | undefined;
    let actualPrice = serviceInPackage.newPrice; // Default to package price

    // 🆕 Calculate actual price based on booking type and user input
    if (service.bookingType === BookingType.Hourly) {
      if (booking.bookingDetails.startHour !== undefined && booking.bookingDetails.endHour !== undefined) {
        startHour = booking.bookingDetails.startHour;
        endHour = booking.bookingDetails.endHour;
        const hoursBooked = endHour - startHour;
        
        // ✅ السعر الجديد × عدد الساعات المطلوبة
        actualPrice = serviceInPackage.newPrice * hoursBooked;
      }
    } else if (service.bookingType === BookingType.Capacity) {
      const numberOfPeople = booking.bookingDetails.numberOfPeople || 0;
      
      // ✅ السعر الجديد × عدد الأشخاص المطلوب
      actualPrice = serviceInPackage.newPrice * numberOfPeople;
    } else if (service.bookingType === BookingType.Daily) {
      // ✅ السعر الثابت للباقة (يوم واحد)
      actualPrice = serviceInPackage.newPrice;
    } /*else if (service.bookingType === BookingType.Mixed) {
      if (booking.bookingDetails.isFullVenue) {
        actualPrice = serviceInPackage.newPrice; // Full venue price
      } else {
        const numberOfPeople = booking.bookingDetails.numberOfPeople || 0;
        actualPrice = serviceInPackage.newPrice * numberOfPeople;
      }
    } */

    // 🆕 Add to total
    calculatedTotal += actualPrice;

    cart.items.push({
      serviceId: new Types.ObjectId(booking.serviceId),
      serviceName: service.serviceName,
      providerId: service.providerId,
      companyName: service.companyName,
      bookingType: service.bookingType,
      bookingDetails: {
        date: new Date(booking.bookingDetails.date),
        startHour: startHour,
        endHour: endHour,
        numberOfPeople: booking.bookingDetails.numberOfPeople,
        //isFullVenue: booking.bookingDetails.isFullVenue || false,
      },
      price: actualPrice, // 🆕 Use calculated price
      imageUrl: service.images?.[0],
      packageId: new Types.ObjectId(dto.packageId),
      packageName: pkg.packageName,
    } as CartItem);
  }

  // 🆕 Set total to calculated amount
  cart.totalAmount = calculatedTotal;
  
  return await cart.save();
}

}