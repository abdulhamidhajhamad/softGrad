import { Document } from 'mongoose';
import { User } from '../auth/user.entity';
import { Service } from '../service/service.entity';
export type UserDocument = User & Document;
export type ServiceDocument = Service & Document;
export declare enum BookingStatus {
    PENDING = "pending",
    CONFIRMED = "confirmed",
    CANCELLED = "cancelled",
    COMPLETED = "completed"
}
export declare class Booking extends Document {
    userId: number;
    serviceId: number;
    bookingDate: Date;
    status: BookingStatus;
    totalPrice: number;
    user?: User;
    service?: Service;
}
export declare const BookingSchema: import("mongoose").Schema<Booking, import("mongoose").Model<Booking, any, any, any, Document<unknown, any, Booking, any, {}> & Booking & Required<{
    _id: unknown;
}> & {
    __v: number;
}, any>, {}, {}, {}, {}, import("mongoose").DefaultSchemaOptions, Booking, Document<unknown, {}, import("mongoose").FlatRecord<Booking>, {}, import("mongoose").ResolveSchemaOptions<import("mongoose").DefaultSchemaOptions>> & import("mongoose").FlatRecord<Booking> & Required<{
    _id: unknown;
}> & {
    __v: number;
}>;
export type BookingDocument = Booking & Document;
