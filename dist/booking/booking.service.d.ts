import { Model } from 'mongoose';
import { Booking, BookingDocument, UserDocument, ServiceDocument } from './booking.entity';
import { CreateBookingDto, UpdateBookingDto } from './booking.dto';
export declare class BookingService {
    private readonly bookingModel;
    private readonly userModel;
    private readonly serviceModel;
    constructor(bookingModel: Model<BookingDocument>, userModel: Model<UserDocument>, serviceModel: Model<ServiceDocument>);
    private populateBooking;
    private populateBookings;
    create(createBookingDto: CreateBookingDto): Promise<Booking>;
    findOneByNames(userName: string, serviceName: string): Promise<Booking>;
    updateByNames(userName: string, serviceName: string, dto: UpdateBookingDto): Promise<Booking>;
    deleteByNames(userName: string, serviceName: string): Promise<{
        message: string;
    }>;
    findByUser(userName: string): Promise<Booking[]>;
    findAll(): Promise<Booking[]>;
}
