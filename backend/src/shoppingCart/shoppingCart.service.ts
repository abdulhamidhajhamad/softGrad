// cart.service.ts
import { Injectable, HttpException, HttpStatus, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Cart, CartItem } from './shoppingCart.schema';
import { Service, BookingType } from '../service/service.schema';
import { AddToCartDto, RemoveFromCartDto, UpdateCartItemDto } from './shoppingCart.dto';

@Injectable()
export class CartService {
  private readonly logger = new Logger(CartService.name);

  constructor(
    @InjectModel(Cart.name) private cartModel: Model<Cart>,
    @InjectModel(Service.name) private serviceModel: Model<Service>,
  ) {}

  async addToCart(userId: string, addToCartDto: AddToCartDto): Promise<Cart> {
    try {
      const service = await this.serviceModel.findById(addToCartDto.serviceId);
      if (!service) {
        throw new HttpException('Service not found', HttpStatus.NOT_FOUND);
      }

      // 🆕 التحقق من يوم العمل
      const bookingDate = new Date(addToCartDto.bookingDetails.date);
      const dayName = this.getDayName(bookingDate);
      
      if (!service.workingDays || !service.workingDays.includes(dayName)) {
        throw new HttpException(
          `Service is not available on ${dayName}. Working days: ${service.workingDays.join(', ')}`,
          HttpStatus.BAD_REQUEST
        );
      }

      // Check availability
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

      // Calculate price based on booking type
      const price = this.calculatePrice(service, addToCartDto.bookingDetails);

      let cart = await this.cartModel.findOne({ userId: new Types.ObjectId(userId) });

      if (!cart) {
        cart = new this.cartModel({
          userId: new Types.ObjectId(userId),
          items: [],
          totalAmount: 0
        });
      }

      // Check if item already exists in cart
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

      // 🆕 التحقق من يوم العمل
      const bookingDate = new Date(updateCartItemDto.bookingDetails.date);
      const dayName = this.getDayName(bookingDate);
      
      if (!service.workingDays || !service.workingDays.includes(dayName)) {
        throw new HttpException(
          `Service is not available on ${dayName}. Working days: ${service.workingDays.join(', ')}`,
          HttpStatus.BAD_REQUEST
        );
      }

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
        return true; // Display type doesn't require availability check
      
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

    const hourlyBookings = service.bookingSlots?.hourlyBookings || [];
    
    for (const booking of hourlyBookings) {
      const bookingDate = new Date(booking.date);
      bookingDate.setHours(0, 0, 0, 0);
      
      if (bookingDate.getTime() === date.getTime()) {
        if (
          (startHour >= booking.startHour && startHour < booking.endHour) ||
          (endHour > booking.startHour && endHour <= booking.endHour) ||
          (startHour <= booking.startHour && endHour >= booking.endHour)
        ) {
          return false;
        }
      }
    }

    return true;
  }

  private checkDailyAvailability(service: Service, date: Date): boolean {
    const dailyBookings = service.bookingSlots?.dailyBookings || [];
    
    return !dailyBookings.some(bookedDate => {
      const bookedDateOnly = new Date(bookedDate);
      bookedDateOnly.setHours(0, 0, 0, 0);
      return bookedDateOnly.getTime() === date.getTime();
    });
  }

  private checkCapacityAvailability(service: Service, date: Date, numberOfPeople: number): boolean {
    if (!service.maxCapacity) {
      return true;
    }

    const capacityBookings = service.bookingSlots?.capacityBookings || [];
    
    let totalBooked = 0;
    for (const booking of capacityBookings) {
      const bookingDate = new Date(booking.date);
      bookingDate.setHours(0, 0, 0, 0);
      
      if (bookingDate.getTime() === date.getTime()) {
        totalBooked += booking.bookedCount;
      }
    }

    return (totalBooked + numberOfPeople) <= service.maxCapacity;
  }

  private calculatePrice(service: Service, bookingDetails: any): number {
    switch (service.bookingType) {
      case BookingType.Hourly:
        const hours = bookingDetails.endHour - bookingDetails.startHour;
        return (service.price.perHour || 0) * hours;
      
      case BookingType.Daily:
        return service.price.perDay || 0;
      
      case BookingType.Capacity:
        return (service.price.perPerson || 0) * bookingDetails.numberOfPeople;
      
      case BookingType.Display:
        return service.price.basePrice || 0;
      
      case BookingType.Mixed:
        if (bookingDetails.isFullVenue) {
          return service.price.fullVenue || 0;
        }
        return (service.price.perPerson || 0) * bookingDetails.numberOfPeople;
      
      default:
        return service.price.basePrice || 0;
    }
  }

  // 🆕 دالة للحصول على اسم اليوم من التاريخ
  private getDayName(date: Date): string {
    const days = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
    return days[date.getDay()];
  }
}