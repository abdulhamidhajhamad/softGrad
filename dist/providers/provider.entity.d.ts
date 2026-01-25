import { Document, Types } from 'mongoose';
export declare class ServiceProvider extends Document {
    userId: Types.ObjectId;
    companyName: string;
    description?: string;
    location?: {
        city?: string;
        country?: string;
        coordinates?: {
            latitude?: number;
            longitude?: number;
        };
    };
    details?: Record<string, any>;
    venueType?: string;
    hasGoogleMapLocation?: boolean;
    targetCustomerType?: 'regular' | 'mid' | 'high';
}
export declare const ServiceProviderSchema: import("mongoose").Schema<ServiceProvider, import("mongoose").Model<ServiceProvider, any, any, any, Document<unknown, any, ServiceProvider, any, {}> & ServiceProvider & Required<{
    _id: unknown;
}> & {
    __v: number;
}, any>, {}, {}, {}, {}, import("mongoose").DefaultSchemaOptions, ServiceProvider, Document<unknown, {}, import("mongoose").FlatRecord<ServiceProvider>, {}, import("mongoose").ResolveSchemaOptions<import("mongoose").DefaultSchemaOptions>> & import("mongoose").FlatRecord<ServiceProvider> & Required<{
    _id: unknown;
}> & {
    __v: number;
}>;
