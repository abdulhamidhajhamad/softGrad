import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Booking, BookingStatus } from './booking.entity';
import { CreateBookingDto, UpdateBookingDto } from './booking.dto';
import { User } from '../auth/user.entity';
import { Service } from '../service/service.entity';

@Injectable()
export class BookingService {
  constructor(
    @InjectRepository(Booking)
    private readonly bookingRepository: Repository<Booking>,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(Service)
    private readonly serviceRepository: Repository<Service>,
  ) {}

  // ✅ Create Booking
  async create(createBookingDto: CreateBookingDto): Promise<Booking> {
    const { userName, serviceName, bookingDate, status, totalPrice } = createBookingDto;

    // Find User
    const user = await this.userRepository.findOne({ where: { userName } });
    if (!user) throw new NotFoundException(`User '${userName}' not found`);

    // Find Service
    const service = await this.serviceRepository.findOne({ where: { name: serviceName } });
    if (!service) throw new NotFoundException(`Service '${serviceName}' not found`);

    // Create Booking
    const booking = this.bookingRepository.create({
      user,
      service,
      userId: user.id,
      serviceId: service.serviceId,
      bookingDate: new Date(bookingDate),
      totalPrice,
      status: status ?? BookingStatus.PENDING,
    });

    try {
      return await this.bookingRepository.save(booking);
    } catch (error) {
      throw new BadRequestException('Failed to create booking');
    }
  }

  // ✅ Find One Booking by user + service
  async findOneByNames(userName: string, serviceName: string): Promise<Booking> {
    const user = await this.userRepository.findOne({ where: { userName } });
    if (!user) throw new NotFoundException(`User '${userName}' not found`);

    const service = await this.serviceRepository.findOne({ where: { name: serviceName } });
    if (!service) throw new NotFoundException(`Service '${serviceName}' not found`);

    const booking = await this.bookingRepository.findOne({
      where: { userId: user.id, serviceId: service.serviceId },
    });

    if (!booking)
      throw new NotFoundException(`No booking found for '${userName}' and '${serviceName}'`);

    return booking;
  }

  // ✅ Update Booking
  async updateByNames(userName: string, serviceName: string, dto: UpdateBookingDto): Promise<Booking> {
    const booking = await this.findOneByNames(userName, serviceName);

    if (dto.userName) {
      const newUser = await this.userRepository.findOne({ where: { userName: dto.userName } });
      if (!newUser) throw new NotFoundException(`User '${dto.userName}' not found`);
      booking.user = newUser;
      booking.userId = newUser.id;
    }

    if (dto.serviceName) {
      const newService = await this.serviceRepository.findOne({ where: { name: dto.serviceName } });
      if (!newService) throw new NotFoundException(`Service '${dto.serviceName}' not found`);
      booking.service = newService;
      booking.serviceId = newService.serviceId;
    }

    if (dto.bookingDate) booking.bookingDate = new Date(dto.bookingDate);
    if (dto.status) booking.status = dto.status;
    if (dto.totalPrice) booking.totalPrice = dto.totalPrice;

    try {
      return await this.bookingRepository.save(booking);
    } catch (error) {
      throw new BadRequestException('Failed to update booking');
    }
  }

  // ✅ Delete Booking
  async deleteByNames(userName: string, serviceName: string): Promise<{ message: string }> {
    const booking = await this.findOneByNames(userName, serviceName);
    await this.bookingRepository.remove(booking);
    return { message: `Booking for '${userName}' & '${serviceName}' deleted successfully` };
  }

  // ✅ Find all bookings for user
  async findByUser(userName: string): Promise<Booking[]> {
    const user = await this.userRepository.findOne({ where: { userName } });
    if (!user) throw new NotFoundException(`User '${userName}' not found`);

    const bookings = await this.bookingRepository.find({ where: { userId: user.id } });
    if (!bookings.length)
      throw new NotFoundException(`No bookings found for user '${userName}'`);

    return bookings;
  }

  // ✅ Find all bookings
  async findAll(): Promise<Booking[]> {
    return await this.bookingRepository.find();
  }
}
