import { BookingType, PricingOptions } from './service.schema'; // Import from schema

export type PayType = 'per event' | 'per hour' | 'per person'; 

  export class Service {
  serviceId: number;
  providerId: string;
  serviceName: string;
  images: string[];
  reviews: any[];
  location: any;
  // 🆕 السعر أصبح من نوع PricingOptions
  price: PricingOptions; 
  // 🆕 إضافة نوع الحجز والرابط
  bookingType: BookingType;
  externalLink?: string;
  
  category: string;
  additionalInfo?: any;
  createdAt: Date;
  payType: PayType; // (يمكنك الاستغناء عنه لاحقاً والاعتماد على bookingType)
  updatedAt: Date;
  bookedDates: Date[];
  rating: number; 
  isActive: boolean;

  constructor(data: Partial<Service>) {
    Object.assign(this, data);
    this.bookedDates = data?.bookedDates || [];
    this.isActive = data?.isActive ?? true;
    this.rating = data?.rating || 0;
    this.bookingType = data?.bookingType || BookingType.Hourly; // Default
  }
}