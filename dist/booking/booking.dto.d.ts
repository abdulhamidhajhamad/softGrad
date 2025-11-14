import { BookingStatus } from './booking.entity';
export declare class CreateBookingDto {
    userName: string;
    serviceName: string;
    bookingDate: string;
    status?: BookingStatus;
    totalPrice: number;
}
export declare class UpdateBookingDto {
    userName?: string;
    serviceName?: string;
    bookingDate?: string;
    status?: BookingStatus;
    totalPrice?: number;
}
