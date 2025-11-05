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
  updatedAt: Date;
  bookedDates: Date[];

  constructor(data: Partial<Service>) {
    Object.assign(this, data);
    this.bookedDates = data?.bookedDates || [];
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