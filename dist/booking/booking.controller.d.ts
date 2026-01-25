import { BookingService } from './booking.service';
import { CreateBookingDto, UpdateBookingDto } from './booking.dto';
import { Booking } from './booking.entity';
export declare class BookingController {
    private readonly bookingService;
    constructor(bookingService: BookingService);
    create(dto: CreateBookingDto): Promise<Booking>;
    findAll(): Promise<Booking[]>;
    findOne(userName: string, serviceName: string): Promise<Booking>;
    update(userName: string, serviceName: string, dto: UpdateBookingDto): Promise<Booking>;
    delete(userName: string, serviceName: string): Promise<{
        message: string;
    }>;
    findByUser(userName: string): Promise<Booking[]>;
}
