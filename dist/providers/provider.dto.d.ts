declare class CoordinatesDto {
    latitude?: number;
    longitude?: number;
}
declare class LocationDto {
    city?: string;
    country?: string;
    coordinates?: CoordinatesDto;
}
export declare class CreateServiceProviderDto {
    companyName: string;
    description?: string;
    location?: LocationDto;
    details?: Record<string, any>;
    venueType?: string;
    hasGoogleMapLocation?: boolean;
    targetCustomerType?: 'regular' | 'mid' | 'high';
}
export declare class UpdateServiceProviderDto {
    description?: string;
    location?: LocationDto;
    details?: Record<string, any>;
    venueType?: string;
    hasGoogleMapLocation?: boolean;
    targetCustomerType?: 'regular' | 'mid' | 'high';
}
export {};
