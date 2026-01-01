// cart.service.ts
import { Injectable, HttpException, HttpStatus, Logger, BadRequestException, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Cart, CartItem } from './shoppingCart.schema';
import { Service, BookingType } from '../service/service.schema';
import { AddToCartDto, RemoveFromCartDto, UpdateCartItemDto } from './shoppingCart.dto';
import { AddPackageToCartDto } from '../Package/package.dto';
import { PackageService } from '../Package/package.service';

@Injectable()
export class CartService {
  private readonly logger = new Logger(CartService.name);

  constructor(
    @InjectModel(Cart.name) private cartModel: Model<Cart>,
    @InjectModel(Service.name) private serviceModel: Model<Service>,
    private packageService: PackageService,
  ) {}

  async addToCart(userId: string, addToCartDto: AddToCartDto): Promise<Cart> {
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

      const isAvailable = await this.checkAvailability(
        service,
        bookingDate,
        addToCartDto.bookingDetails
      );

      if (!isAvailable) {
        throw new HttpException(
          'Service is not available for the selected date/time',
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
          isFullVenue: addToCartDto.bookingDetails.isFullVenue
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
        isFullVenue: updateCartItemDto.bookingDetails.isFullVenue
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

  private async checkAvailability(
    service: Service,
    date: Date,
    bookingDetails: any
  ): Promise<boolean> {
    const dateOnly = new Date(date);
    dateOnly.setHours(0, 0, 0, 0);

    switch (service.bookingType) {
      case BookingType.Hourly:
        return this.checkHourlyAvailability(service, dateOnly, bookingDetails.startHour, bookingDetails.endHour);
      
      case BookingType.Daily:
        return this.checkDailyAvailability(service, dateOnly);
      
      case BookingType.Capacity:
        return this.checkCapacityAvailability(service, dateOnly, bookingDetails.numberOfPeople);
      
      case BookingType.Display:
        return true;
      
      case BookingType.Mixed:
        if (bookingDetails.isFullVenue) {
          return this.checkDailyAvailability(service, dateOnly);
        }
        return this.checkCapacityAvailability(service, dateOnly, bookingDetails.numberOfPeople);
      
      default:
        return false;
    }
  }

  private checkHourlyAvailability(service: Service, date: Date, startHour: number, endHour: number): boolean {
    if (!startHour || !endHour || startHour >= endHour) {
      return false;
    }
    // ✅ بما إنه تم حذف bookingSlots، نفترض الخدمة متاحة دائماً
    // يمكن تطوير هذا لاحقاً للتحقق من جدول الحجوزات
    return true;
  }

  private checkDailyAvailability(service: Service, date: Date): boolean {
    // ✅ بما إنه تم حذف bookingSlots، نفترض الخدمة متاحة دائماً
    return true;
  }

  private checkCapacityAvailability(service: Service, date: Date, numberOfPeople: number): boolean {
    if (!service.maxCapacity) {
      return true;
    }
    // ✅ بما إنه تم حذف bookingSlots، نفترض الخدمة متاحة دائماً
    // التحقق فقط من أن العدد لا يتجاوز السعة القصوى
    return numberOfPeople <= service.maxCapacity;
  }

  private calculatePrice(service: Service, bookingDetails: any): number {
    // ✅ استخدام price البسيط أولاً، ثم priceOptions للتوافق
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
    
    const pkg = await this.packageService.getPackageById(dto.packageId);
    
    if (!pkg.isActive) {
      throw new BadRequestException('This package is not currently available.');
    }

    if (dto.serviceBookings.length !== pkg.services.length) {
      throw new BadRequestException(
        `Package requires booking all ${pkg.services.length} services. You provided ${dto.serviceBookings.length}.`
      );
    }

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

      await this.packageService.validatePackageBookingDate(dto.packageId, bookingDate);

      const dayName = this.getDayName(bookingDate);
      if (!service.workingDays || !service.workingDays.includes(dayName)) {
        throw new BadRequestException(
          `Service "${service.serviceName}" is not available on ${dayName}. Working days: ${service.workingDays.join(', ')}`
        );
      }

      if (serviceInPackage.maxHours) {
        if (!booking.bookingDetails.numberOfHours) {
          throw new BadRequestException(
            `Service "${service.serviceName}" requires numberOfHours (max: ${serviceInPackage.maxHours} hours).`
          );
        }
        if (booking.bookingDetails.numberOfHours > serviceInPackage.maxHours) {
          throw new BadRequestException(
            `Service "${service.serviceName}" allows maximum ${serviceInPackage.maxHours} hours in this package. You requested ${booking.bookingDetails.numberOfHours} hours.`
          );
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
            `Service "${service.serviceName}" allows maximum ${serviceInPackage.maxCapacity} people in this package. You requested ${booking.bookingDetails.numberOfPeople} people.`
          );
        }
      }

      let isAvailable = false;

      if (service.bookingType === BookingType.Hourly) {
        if (!booking.bookingDetails.numberOfHours) {
          throw new BadRequestException(`Service "${service.serviceName}" requires numberOfHours.`);
        }
        
        const startHour = 9;
        const endHour = startHour + booking.bookingDetails.numberOfHours;
        
        isAvailable = this.checkHourlyAvailability(service, bookingDate, startHour, endHour);

      } else if (service.bookingType === BookingType.Capacity) {
        if (!booking.bookingDetails.numberOfPeople) {
          throw new BadRequestException(`Service "${service.serviceName}" requires numberOfPeople.`);
        }
        
        isAvailable = this.checkCapacityAvailability(service, bookingDate, booking.bookingDetails.numberOfPeople);

      } else if (service.bookingType === BookingType.Daily) {
        isAvailable = this.checkDailyAvailability(service, bookingDate);

      } else {
        isAvailable = true;
      }

      if (!isAvailable) {
        throw new BadRequestException(
          `Service "${service.serviceName}" is not available on ${bookingDate.toDateString()}.`
        );
      }
    }

    let cart = await this.cartModel.findOne({ userId: userObjectId }).exec();
    if (!cart) {
      cart = new this.cartModel({ userId: userObjectId, items: [], totalAmount: 0 });
    }

    cart.items = cart.items.filter(item => item.packageId?.toString() !== dto.packageId);

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

      if (service.bookingType === BookingType.Hourly && booking.bookingDetails.numberOfHours) {
        startHour = 9;
        endHour = startHour + booking.bookingDetails.numberOfHours;
      }

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
          isFullVenue: false,
        },
        price: serviceInPackage.newPrice, 
        imageUrl: service.images?.[0],
        packageId: new Types.ObjectId(dto.packageId),
        packageName: pkg.packageName,
      } as CartItem);
    }

    cart.totalAmount = pkg.newPrice;
    
    return await cart.save();
  }
}