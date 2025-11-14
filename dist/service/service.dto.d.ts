export declare class LocationDto {
    latitude: number;
    longitude: number;
    address?: string;
    city?: string;
    country?: string;
}
export declare class CreateServiceDto {
    serviceName: string;
    images?: string[];
    location: LocationDto;
    price: number;
    additionalInfo?: any;
    companyName?: string;
}
export declare class UpdateServiceDto {
    serviceName?: string;
    images?: string[];
    location?: LocationDto;
    price?: number;
    additionalInfo?: any;
    companyName?: string;
}
export declare class ServiceResponseDto {
    _id: string;
    providerId: string;
    serviceName: string;
    images: string[];
    reviews: any[];
    location: any;
    price: number;
    additionalInfo?: any;
    createdAt: Date;
    updatedAt: Date;
    companyName?: string;
}
