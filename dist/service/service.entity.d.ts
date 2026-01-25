export declare class Service {
    serviceId: number;
    providerId: string;
    serviceName: string;
    images: string[];
    reviews: Review[];
    location: Location;
    price: number;
    additionalInfo?: any;
    createdAt: Date;
    updatedAt: Date;
    constructor(data: Partial<Service>);
}
export interface Review {
    userId: string;
    userName: string;
    rating: number;
    comment: string;
    createdAt: Date;
}
export interface Location {
    latitude: number;
    longitude: number;
    address?: string;
    city?: string;
    country?: string;
}
