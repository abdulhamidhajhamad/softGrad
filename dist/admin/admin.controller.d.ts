import { AdminService } from './admin.service';
export declare class AdminController {
    private readonly adminService;
    constructor(adminService: AdminService);
    getAllUsers(): Promise<{
        totalUsers: number;
        users: (import("mongoose").Document<unknown, {}, import("../auth/user.entity").User, {}, {}> & import("../auth/user.entity").User & Required<{
            _id: unknown;
        }> & {
            __v: number;
        })[];
    }>;
    getAllProviders(): Promise<{
        totalProviders: number;
        providers: (import("mongoose").Document<unknown, {}, import("../providers/provider.entity").ServiceProvider, {}, {}> & import("../providers/provider.entity").ServiceProvider & Required<{
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
    getDashboard(): Promise<{
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
            users: (import("mongoose").Document<unknown, {}, import("../auth/user.entity").User, {}, {}> & import("../auth/user.entity").User & Required<{
                _id: unknown;
            }> & {
                __v: number;
            })[];
            providers: (import("mongoose").Document<unknown, {}, import("../providers/provider.entity").ServiceProvider, {}, {}> & import("../providers/provider.entity").ServiceProvider & Required<{
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
