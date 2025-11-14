import { Injectable, HttpException, HttpStatus } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { ShoppingCart } from './shoppingCart.schema';
import { Service } from '../service/service.schema';
import { AddToCartDto, RemoveFromCartDto } from './shoppingCart.dto';

@Injectable()
export class ShoppingCartService {
  constructor(
    @InjectModel(ShoppingCart.name) private shoppingCartModel: Model<ShoppingCart>,
    @InjectModel(Service.name) private serviceModel: Model<Service>,
  ) {}

  private normalizeDate(date: Date): Date {
    const normalized = new Date(date);
    normalized.setHours(0, 0, 0, 0);
    return normalized;
  }

  async isDateBooked(serviceId: string, bookingDate: Date): Promise<boolean> {
    try {
      const service = await this.serviceModel.findById(serviceId);
      
      if (!service) {
        throw new HttpException('Service not found', HttpStatus.NOT_FOUND);
      }

      const targetDate = this.normalizeDate(bookingDate);

      const isBooked = service.bookedDates.some(bookedDate => {
        const booked = this.normalizeDate(bookedDate);
        return booked.getTime() === targetDate.getTime();
      });

      return isBooked;
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to check booking date',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  async checkDateAvailability(serviceId: string, bookingDate: Date): Promise<{ 
    isAvailable: boolean; 
    message: string;
    serviceName?: string;
    bookedDates?: Date[];
  }> {
    try {
      const service = await this.serviceModel.findById(serviceId);
      
      if (!service) {
        throw new HttpException('Service not found', HttpStatus.NOT_FOUND);
      }

      const targetDate = this.normalizeDate(bookingDate);

      const isBooked = service.bookedDates.some(bookedDate => {
        const booked = this.normalizeDate(bookedDate);
        return booked.getTime() === targetDate.getTime();
      });

      if (isBooked) {
        return {
          isAvailable: false,
          message: `This date (${targetDate.toDateString()}) is already booked for service: ${service.serviceName}`,
          serviceName: service.serviceName,
          bookedDates: service.bookedDates
        };
      }

      return {
        isAvailable: true,
        message: `Date ${targetDate.toDateString()} is available for booking`,
        serviceName: service.serviceName,
        bookedDates: service.bookedDates
      };
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to check date availability',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  async addToCart(userId: string, addToCartDto: AddToCartDto): Promise<{ 
    cart: ShoppingCart; 
    message: string;
    checkedDate: Date;
  }> {
    try {
      const { serviceId, bookingDate } = addToCartDto;

      const normalizedDate = this.normalizeDate(bookingDate);

      const availabilityCheck = await this.checkDateAvailability(serviceId, normalizedDate);
      
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

      let cart = await this.shoppingCartModel.findOne({ userId: new Types.ObjectId(userId) });

      if (!cart) {
        cart = new this.shoppingCartModel({
          userId: new Types.ObjectId(userId),
          services: [],
          totalPrice: 0
        });
      }

      const existingService = cart.services.find(
        item => 
          item.serviceId.toString() === serviceId && 
          this.normalizeDate(item.bookingDate).getTime() === normalizedDate.getTime()
      );

      if (existingService) {
        throw new HttpException(
          'Service already exists in cart for this date',
          HttpStatus.CONFLICT
        );
      }

      cart.services.push({
        serviceId: new Types.ObjectId(serviceId),
        bookingDate: normalizedDate 
      });

      cart.totalPrice = await this.calculateTotalPrice(cart.services);

      const savedCart = await cart.save();
      
      return {
        cart: savedCart,
        message: `Service "${service.serviceName}" added to cart for date ${normalizedDate.toDateString()}`,
        checkedDate: normalizedDate
      };
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to add to cart',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }


async removeFromCart(userId: string, removeFromCartDto: RemoveFromCartDto): Promise<{ 
  cart: ShoppingCart; 
  message: string;
  removedServices: string[];
  removedCount: number;
}> {
  try {
    const { serviceId } = removeFromCartDto;

    const cart = await this.shoppingCartModel.findOne({ userId: new Types.ObjectId(userId) });

    if (!cart) {
      throw new HttpException('Cart not found', HttpStatus.NOT_FOUND);
    }

    const servicesToRemove = cart.services.filter(
      item => item.serviceId.toString() === serviceId
    );

    if (servicesToRemove.length === 0) {
      throw new HttpException(
        'Service not found in cart',
        HttpStatus.NOT_FOUND
      );
    }

    const service = await this.serviceModel.findById(serviceId);
    const serviceName = service ? service.serviceName : 'Unknown Service';

    const removedCount = servicesToRemove.length;

    cart.services = cart.services.filter(
      item => item.serviceId.toString() !== serviceId
    );

    cart.totalPrice = await this.calculateTotalPrice(cart.services);

    const savedCart = await cart.save();
    
    return {
      cart: savedCart,
      message: `All ${removedCount} instances of "${serviceName}" removed from cart`,
      removedServices: [serviceName],
      removedCount
    };
  } catch (error) {
    throw new HttpException(
      error.message || 'Failed to remove from cart',
      error.status || HttpStatus.INTERNAL_SERVER_ERROR
    );
  }
}

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
      throw new HttpException(
        error.message || 'Failed to clear cart',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  async getCartByUserId(userId: string): Promise<any> {
    try {
      const cart = await this.shoppingCartModel
        .findOne({ userId: new Types.ObjectId(userId) })
        .populate('services.serviceId')
        .exec();

      if (!cart) {
        // إذا ما في سلة، نرجع سلة فارغة
        return {
          userId: new Types.ObjectId(userId),
          services: [],
          totalPrice: 0,
          message: 'Cart is empty'
        };
      }

      // حساب الـ total price الحقيقي
      const totalPrice = await this.calculateTotalPrice(cart.services);
      
      return {
        ...cart.toObject(),
        totalPrice,
        message: `Found ${cart.services.length} services in cart`
      };
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to get cart',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  private async calculateTotalPrice(services: any[]): Promise<number> {
    if (services.length === 0) return 0;

    // جلب جميع الـ service IDs
    const serviceIds = services.map(item => item.serviceId);

    // جلب الأسعار الحقيقية من الـ services
    const servicesWithPrices = await this.serviceModel.find({
      _id: { $in: serviceIds }
    }).select('price').exec();

    // إنشاء map للأسعار - الإصلاح هنا
    const priceMap = new Map();
    servicesWithPrices.forEach(service => {
      // استخدام type assertion لحل مشكلة TypeScript
      const serviceId = (service as any)._id?.toString();
      if (serviceId) {
        priceMap.set(serviceId, service.price);
      }
    });

    // حساب المجموع
    return services.reduce((total, item) => {
      const price = priceMap.get(item.serviceId.toString()) || 0;
      return total + price;
    }, 0);
  }
}