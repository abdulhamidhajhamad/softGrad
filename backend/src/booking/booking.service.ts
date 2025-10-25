// src/booking/booking.service.ts

import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
// FIX: Import all required document types from booking.entity
import { Booking, BookingStatus, BookingDocument, UserDocument, ServiceDocument } from './booking.entity'; 
import { CreateBookingDto, UpdateBookingDto } from './booking.dto';
import { User } from '../auth/user.entity';
import { Service } from '../service/service.entity';


@Injectable()
export class BookingService {
  constructor(
    @InjectModel(Booking.name)
    private readonly bookingModel: Model<BookingDocument>,
    @InjectModel(User.name)
    private readonly userModel: Model<UserDocument>,
    @InjectModel(Service.name)
    private readonly serviceModel: Model<ServiceDocument>,
  ) {}

  // --- Private Helper to map Mongoose results to the expected return type (with populated fields) ---
  private async populateBooking(query: any): Promise<Booking | null> {
    const booking = await query
      .populate('user')
      .populate('service')
      .exec();
    
    if (booking) return booking.toObject() as Booking;
    return null;
  }
  
  private async populateBookings(query: any): Promise<Booking[]> {
    const bookings = await query
      .populate('user')
      .populate('service')
      .exec();
    
    return bookings.map(b => b.toObject() as Booking);
  }

  // ✅ Create Booking
  async create(createBookingDto: CreateBookingDto): Promise<Booking> {
    const { userName, serviceName, bookingDate, status, totalPrice } = createBookingDto;

    // Find User (Mongoose)
    const user = await this.userModel.findOne({ userName }).exec();
    if (!user) throw new NotFoundException(`User '${userName}' not found`);

    // Find Service (Mongoose)
    const service = await this.serviceModel.findOne({ serviceName: serviceName }).exec();
    if (!service) throw new NotFoundException(`Service '${serviceName}' not found`);

    // Create Booking (in Mongoose)
    const newBooking = new this.bookingModel({
      userId: user.id, 
      serviceId: service.serviceId, 
      bookingDate: new Date(bookingDate),
      totalPrice,
      status: status ?? BookingStatus.PENDING,
    });

    try {
      const savedBooking = await newBooking.save();
      
      // FIX TS2322: Check for null after population lookup to ensure a Booking is returned
      const populatedBooking = await this.populateBooking(this.bookingModel.findById(savedBooking._id));
      
      if (!populatedBooking) {
         // This is highly unlikely after a save, but ensures the return type is Booking
         throw new BadRequestException('Failed to retrieve and populate the newly created booking.');
      }
      return populatedBooking;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to create booking';
      throw new BadRequestException(errorMessage);
    }
  }

  // ✅ Find One Booking by user + service
  async findOneByNames(userName: string, serviceName: string): Promise<Booking> {
    const user = await this.userModel.findOne({ userName }).exec();
    if (!user) throw new NotFoundException(`User '${userName}' not found`);

    const service = await this.serviceModel.findOne({ serviceName: serviceName }).exec();
    if (!service) throw new NotFoundException(`Service '${serviceName}' not found`);

    const booking = await this.populateBooking(
      this.bookingModel.findOne({
        userId: user.id,
        serviceId: service.serviceId,
      })
    );
    
    if (!booking)
      throw new NotFoundException(`No booking found for '${userName}' and '${serviceName}'`);

    return booking;
  }

  // ✅ Update Booking
  async updateByNames(userName: string, serviceName: string, dto: UpdateBookingDto): Promise<Booking> {
    const user = await this.userModel.findOne({ userName }).exec();
    if (!user) throw new NotFoundException(`User '${userName}' not found`);

    const service = await this.serviceModel.findOne({ serviceName: serviceName }).exec();
    if (!service) throw new NotFoundException(`Service '${serviceName}' not found`);
    
    const booking = await this.bookingModel.findOne({
      userId: user.id,
      serviceId: service.serviceId,
    }).exec();

    if (!booking)
      throw new NotFoundException(`No booking found for '${userName}' and '${serviceName}'`);

    if (dto.userName) {
      const newUser = await this.userModel.findOne({ userName: dto.userName }).exec();
      if (!newUser) throw new NotFoundException(`User '${dto.userName}' not found`);
      booking.userId = newUser.id;
    }

    if (dto.serviceName) {
      const newService = await this.serviceModel.findOne({ serviceName: dto.serviceName }).exec();
      if (!newService) throw new NotFoundException(`Service '${dto.serviceName}' not found`);
      booking.serviceId = newService.serviceId;
    }

    if (dto.bookingDate) booking.bookingDate = new Date(dto.bookingDate);
    if (dto.status) booking.status = dto.status;
    if (dto.totalPrice) booking.totalPrice = dto.totalPrice;

    try {
      const updatedBooking = await booking.save();
      
      // FIX TS2322: Check for null after population lookup
      const populatedBooking = await this.populateBooking(this.bookingModel.findById(updatedBooking._id));
       if (!populatedBooking) {
         throw new BadRequestException('Failed to retrieve and populate the updated booking.');
      }
      return populatedBooking;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to update booking';
      throw new BadRequestException(errorMessage);
    }
  }

  // ✅ Delete Booking
  async deleteByNames(userName: string, serviceName: string): Promise<{ message: string }> {
    const user = await this.userModel.findOne({ userName }).exec();
    if (!user) throw new NotFoundException(`User '${userName}' not found`);

    const service = await this.serviceModel.findOne({ serviceName: serviceName }).exec();
    if (!service) throw new NotFoundException(`Service '${serviceName}' not found`);

    const result = await this.bookingModel.deleteOne({
      userId: user.id,
      serviceId: service.serviceId,
    }).exec();

    if (result.deletedCount === 0) {
       throw new NotFoundException(`No booking found for '${userName}' and '${serviceName}'`);
    }

    return { message: `Booking for '${userName}' & '${serviceName}' deleted successfully` };
  }

  // ✅ Find all bookings for user
  async findByUser(userName: string): Promise<Booking[]> {
    const user = await this.userModel.findOne({ userName }).exec();
    if (!user) throw new NotFoundException(`User '${userName}' not found`);

    return await this.populateBookings(
      this.bookingModel.find({ userId: user.id })
    );
  }

  // ✅ Find all bookings
  async findAll(): Promise<Booking[]> {
    return await this.populateBookings(this.bookingModel.find());
  }
}