import { Injectable, NotFoundException, BadRequestException, ForbiddenException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Booking, BookingDocument, PaymentStatus } from './booking.entity';
import { CreateBookingDto } from './booking.dto';
import { Service } from '../service/service.entity';
import { ShoppingCart } from '../shoppingCart/shoppingCart.schema';

interface PreparedService {
  serviceId: string;
  bookingDate: Date;
}

@Injectable()
export class BookingService {
  constructor(
    @InjectModel(Booking.name)
    private readonly bookingModel: Model<BookingDocument>,
    @InjectModel(Service.name)
    private readonly serviceModel: Model<Service & Document>,
    @InjectModel(ShoppingCart.name)
    private readonly shoppingCartModel: Model<ShoppingCart & Document>,
  ) {}

  private extractServiceId(serviceId: any): string {
    if (!serviceId) {
      throw new BadRequestException('Invalid service ID');
    }

    if (typeof serviceId === 'string') {
      if (serviceId.includes('bookedDates') || serviceId.includes('_id: new ObjectId')) {
        try {
          const cleanedString = serviceId
            .replace(/new ObjectId\(['"]([^'"]+)['"]\)/g, '"$1"')
            .replace(/(\w+):/g, '"$1":') // إضافة quotes للمفاتيح
            .replace(/'/g, '"'); // استبدال single quotes بdouble quotes
          
          const serviceObj = JSON.parse(cleanedString);
          return serviceObj._id;
        } catch (error) {
          const idMatch = serviceId.match(/_id: new ObjectId\('([^']+)'\)/);
          if (idMatch && idMatch[1]) {
            return idMatch[1];
          }
          const objectIdMatch = serviceId.match(/'([0-9a-fA-F]{24})'/);
          if (objectIdMatch && objectIdMatch[1]) {
            return objectIdMatch[1];
          }
          throw new BadRequestException('Invalid service ID format');
        }
      }
      return serviceId;
    }
    
    if (typeof serviceId === 'object') {
      return serviceId._id?.toString() || serviceId.toString();
    }
    
    return serviceId.toString();
  }

  async findByUser(userId: string): Promise<any[]> {
    const bookings = await this.bookingModel.find({ userId }).exec();
    
    return bookings.map(booking => this.formatBookingResponse(booking));
  }

  async createFromCart(userId: string): Promise<any> {
    const shoppingCart = await this.shoppingCartModel
      .findOne({ userId: new Types.ObjectId(userId) })
      .exec();

    if (!shoppingCart || shoppingCart.services.length === 0) {
      throw new BadRequestException('Shopping cart is empty');
    }

    const preparedServices: PreparedService[] = [];
    
    for (const cartService of shoppingCart.services) {
      const serviceId = this.extractServiceId(cartService.serviceId);
      
      const service = await this.serviceModel.findById(serviceId).exec();
      if (!service) {
        throw new NotFoundException(`Service with ID '${serviceId}' not found`);
      }

      const serviceDoc = service as any;
      if (serviceDoc.bookedDates && serviceDoc.bookedDates.includes(cartService.bookingDate)) {
        throw new BadRequestException(
          `Date ${cartService.bookingDate} is already booked for service ${serviceDoc.name}`
        );
      }

      preparedServices.push({
        serviceId: serviceId, // تخزين الـ ID فقط
        bookingDate: cartService.bookingDate,
      });
    }

    let totalAmount = 0;
    for (const service of preparedServices) {
      const serviceDoc = await this.serviceModel.findById(service.serviceId).exec();
      if (serviceDoc) {
        totalAmount += (serviceDoc as any).price || 0;
      }
    }

    const newBooking = new this.bookingModel({
      userId,
      services: preparedServices, // بيانات مرتبة
      totalAmount,
      paymentStatus: PaymentStatus.SUCCESSFUL,
    });

    try {
      const savedBooking = await newBooking.save();

      for (const service of preparedServices) {
        await this.serviceModel.findByIdAndUpdate(
          service.serviceId,
          { 
            $push: { 
              bookedDates: service.bookingDate 
            } 
          }
        ).exec();
      }

      await this.shoppingCartModel.findOneAndUpdate(
        { userId: new Types.ObjectId(userId) },
        { 
          $set: { 
            services: [],
            totalPrice: 0 
          } 
        }
      ).exec();

      return this.formatBookingResponse(savedBooking);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to create booking';
      throw new BadRequestException(errorMessage);
    }
  }

  async create(userId: string, createBookingDto: CreateBookingDto): Promise<any> {
    const { services, totalAmount } = createBookingDto;

    const preparedServices: PreparedService[] = services.map(service => ({
      serviceId: service.serviceId, // التأكد من أن الـ ID صحيح
      bookingDate: new Date(service.bookingDate),
    }));

    const serviceIds = preparedServices.map(s => s.serviceId);
    const foundServices = await this.serviceModel.find({ 
      _id: { $in: serviceIds } 
    }).exec();

    if (foundServices.length !== serviceIds.length) {
      throw new NotFoundException('One or more services not found');
    }

    const newBooking = new this.bookingModel({
      userId,
      services: preparedServices,
      totalAmount,
      paymentStatus: PaymentStatus.SUCCESSFUL,
    });

    try {
      const savedBooking = await newBooking.save();

      for (const service of preparedServices) {
        await this.serviceModel.findByIdAndUpdate(
          service.serviceId,
          { 
            $push: { 
              bookedDates: service.bookingDate 
            } 
          }
        ).exec();
      }

      return this.formatBookingResponse(savedBooking);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to create booking';
      throw new BadRequestException(errorMessage);
    }
  }

  async cancelBooking(userId: string, bookingId: string): Promise<{ message: string }> {
    const booking = await this.bookingModel.findById(bookingId).exec();
    
    if (!booking) {
      throw new NotFoundException(`Booking with ID '${bookingId}' not found`);
    }

    if (booking.userId !== userId) {
      throw new ForbiddenException('You can only cancel your own bookings');
    }

    for (const serviceItem of booking.services) {
      const serviceId = this.extractServiceId(serviceItem.serviceId);
      
      if (serviceId && Types.ObjectId.isValid(serviceId)) {
        await this.serviceModel.findByIdAndUpdate(
          serviceId,
          { 
            $pull: { 
              bookedDates: serviceItem.bookingDate 
            } 
          }
        ).exec();
      }
    }

    booking.paymentStatus = PaymentStatus.CANCELLED;
    await booking.save();

    return { 
      message: `Booking ${bookingId} cancelled successfully and dates removed from services` 
    };
  }

  async findAll(): Promise<any[]> {
    const bookings = await this.bookingModel.find().exec();
    return bookings.map(booking => this.formatBookingResponse(booking));
  }

  private formatBookingResponse(booking: any): any {
    const formattedBooking = booking.toObject ? booking.toObject() : { ...booking };
    
    if (formattedBooking.services && Array.isArray(formattedBooking.services)) {
      formattedBooking.services = formattedBooking.services.map(service => ({
        serviceId: this.extractServiceId(service.serviceId),
        bookingDate: service.bookingDate
      }));
    }

    delete formattedBooking.__v;
    
    return formattedBooking;
  }

  async fixExistingBookings(): Promise<{ message: string; fixedCount: number }> {
    const bookings = await this.bookingModel.find().exec();
    let fixedCount = 0;

    for (const booking of bookings) {
      let needsUpdate = false;
      const fixedServices: PreparedService[] = [];

      for (const serviceItem of booking.services) {
        const originalServiceId = serviceItem.serviceId;
        const fixedServiceId = this.extractServiceId(originalServiceId);

        if (originalServiceId !== fixedServiceId) {
          needsUpdate = true;
        }

        fixedServices.push({
          serviceId: fixedServiceId,
          bookingDate: serviceItem.bookingDate
        });
      }

      if (needsUpdate) {
        await this.bookingModel.findByIdAndUpdate(booking._id, {
          services: fixedServices
        }).exec();
        fixedCount++;
      }
    }

    return { 
      message: `Fixed ${fixedCount} bookings with invalid service IDs`,
      fixedCount 
    };
  }

  async debugServiceId(serviceId: any): Promise<{ original: any; extracted: string; type: string }> {
    return {
      original: serviceId,
      extracted: this.extractServiceId(serviceId),
      type: typeof serviceId
    };
  }
}