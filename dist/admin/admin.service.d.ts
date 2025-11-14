import { Model } from 'mongoose';
import { User } from '../auth/user.entity';
import { ServiceProvider } from '../providers/provider.entity';
export declare class AdminService {
    private readonly userModel;
    private readonly providerModel;
    constructor(userModel: Model<User>, providerModel: Model<ServiceProvider>);
    getAllUsers(): Promise<{
        totalUsers: number;
        users: (import("mongoose").Document<unknown, {}, User, {}, {}> & User & Required<{
            _id: unknown;
        }> & {
            __v: number;
        })[];
    }>;
    getAllProviders(): Promise<{
        totalProviders: number;
        providers: (import("mongoose").Document<unknown, {}, ServiceProvider, {}, {}> & ServiceProvider & Required<{
            _id: unknown;
        }> & {
            __v: number;
        })[];
    }>;
    getAllServices(): Promise<{
        totalServices: number;
        services: never[];
    }>;
    getAllBookings(): Promise<{
        totalBookings: number;
        bookings: never[];
    }>;
    getDashboardStats(): Promise<{
        summary: {
            totalUsers: number;
            totalProviders: number;
            totalServices: number;
            totalBookings: number;
            totalRevenue: string;
        };
        bookingStats: {
            pending: number;
            confirmed: number;
            cancelled: number;
            completed: number;
        };
        data: {
            users: (import("mongoose").Document<unknown, {}, User, {}, {}> & User & Required<{
                _id: unknown;
            }> & {
                __v: number;
            })[];
            providers: (import("mongoose").Document<unknown, {}, ServiceProvider, {}, {}> & ServiceProvider & Required<{
                _id: unknown;
            }> & {
                __v: number;
            })[];
            services: never[];
            bookings: never[];
        };
    }>;
    getAnalytics(): Promise<{
        userMetrics: {
            totalUsers: number;
        };
        providerMetrics: {
            totalProviders: number;
            servicesPerProvider: {};
        };
        serviceMetrics: {
            totalServices: number;
            averageRating: string;
            bookingsPerService: {};
        };
        bookingMetrics: {
            totalBookings: number;
            averageBookingPrice: string;
            totalRevenue: string;
        };
    }>;
}
