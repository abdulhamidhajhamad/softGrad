import { BookingType } from './service.schema';

// ✅ تعديل PayType
export type PayType = 'per hour' | 'per person' | 'per day' | 'display';

export class Service {
  serviceId: number;
  providerId: string;
  serviceName: string;
  images: string[];
  reviews: any[];
  location: any;
  
  // ✅ السعر أصبح number بسيط (اختياري)
  price?: number;
  
  bookingType: BookingType;
  externalLink?: string;
  
  category: string;
  additionalInfo?: any;
  createdAt: Date;
  payType: PayType;
  updatedAt: Date;
  rating: number; 
  isActive: boolean;
  description?: string;

  // ✅ الحقول الاختيارية
  maxCapacity?: number;
  minBookingHours?: number;
  maxBookingHours?: number;
  availableHours?: number[];
  cleanupTimeMinutes?: number;
  workingDays?: string[];

  constructor(data: Partial<Service>) {
    Object.assign(this, data);
    this.isActive = data?.isActive ?? true;
    this.rating = data?.rating || 0;
    this.bookingType = data?.bookingType || BookingType.Daily;
  }
}