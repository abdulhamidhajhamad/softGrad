import { Document } from 'mongoose';
export declare class Service extends Document {
    providerId: string;
    serviceName: string;
    images: string[];
    location: {
        latitude: number;
        longitude: number;
        address?: string;
        city?: string;
        country?: string;
    };
    price: number;
    additionalInfo: any;
    reviews: any[];
    companyName: string;
}
export declare const ServiceSchema: import("mongoose").Schema<Service, import("mongoose").Model<Service, any, any, any, Document<unknown, any, Service, any, {}> & Service & Required<{
    _id: unknown;
}> & {
    __v: number;
}, any>, {}, {}, {}, {}, import("mongoose").DefaultSchemaOptions, Service, Document<unknown, {}, import("mongoose").FlatRecord<Service>, {}, import("mongoose").ResolveSchemaOptions<import("mongoose").DefaultSchemaOptions>> & import("mongoose").FlatRecord<Service> & Required<{
    _id: unknown;
}> & {
    __v: number;
}>;
