export type PayType = 'per event' | 'per hour' | 'per person'; // 🆕 تعريف النوع

export class Service {
  serviceId: number;
  providerId: string;
  serviceName: string;
  images: string[];
  reviews: Review[];
  location: Location;
  price: number;
  category: string;
  additionalInfo?: any;
  createdAt: Date;
  payType: PayType;
  updatedAt: Date;
  bookedDates: Date[];
  rating: number; 
isActive: boolean;
  constructor(data: Partial<Service>) {
    Object.assign(this, data);
    this.bookedDates = data?.bookedDates || [];
    this.isActive = data?.isActive ?? true;
    this.rating = data?.rating || 0; // ✅ تعيين قيمة افتراضية
    this.payType = data?.payType || 'per event'; // 🆕 تعيين قيمة افتراضية
  }
  
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