// src/booking/booking.service.ts

import { Injectable, NotFoundException, BadRequestException, ForbiddenException, Request } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types, Document } from 'mongoose';
import { Booking, BookingDocument, PaymentStatus } from './booking.entity';
import { Service } from '../service/service.entity'; 
import { ShoppingCart } from '../shoppingCart/shoppingCart.schema'; 
import { User } from '../auth/user.entity'; 

import { NotificationService, CreateNotificationDto } from '../notification/notification.service';
import { NotificationType, RecipientType } from '../notification/notification.schema'; 

// =============================================================
// Helper Interfaces (for better Type Safety)
// =============================================================

interface PreparedService {
    serviceId: string;
    bookingDate: Date;
}

interface ServiceDocument extends Document {
    _id: Types.ObjectId;
    providerId: Types.ObjectId; 
    serviceName: string; // Changed from 'name' to 'serviceName'
}

interface UserDocument extends Document {
    _id: Types.ObjectId;
    fcmToken?: string;
    username: string; 
}

@Injectable()
export class BookingService {

    constructor(
        @InjectModel(Booking.name)
        private readonly bookingModel: Model<BookingDocument>,

        @InjectModel(ShoppingCart.name)
        private readonly shoppingCartModel: Model<ShoppingCart & Document>,
        @InjectModel(User.name)
        private readonly userModel: Model<UserDocument>,
        @InjectModel(Service.name)
        private readonly serviceModel: Model<ServiceDocument>,
        private readonly notificationService: NotificationService,
    ) {}

    // =============================================================
    // Helper function to extract service ID
    // =============================================================

    private extractServiceId(serviceId: any): string {
        if (!serviceId) {
            throw new BadRequestException('Invalid service ID');
        }
        if (typeof serviceId === 'string') {
            if (serviceId.includes('bookedDates') || serviceId.includes('_id: new ObjectId')) {
                try {
                    const cleanedString = serviceId
                        .replace(/new ObjectId\(['"]([^'"]+)['"]\)/g, '"$1"')
                        .replace(/(\w+):/g, '"$1":') 
                        .replace(/=/g, ':');
                    const parsed = JSON.parse(`{${cleanedString}}`);
                    return parsed._id || parsed.serviceId;
                } catch (e) {
                    // Fallback to original string if parsing fails
                }
            }
            return serviceId;
        }
        if (serviceId instanceof Types.ObjectId) {
            return serviceId.toString();
        }
        if (serviceId.serviceId) return serviceId.serviceId;
        if (serviceId._id) return serviceId._id.toString();
        
        throw new BadRequestException('Could not parse service ID from input.');
    }

    // =============================================================
    // 🌟 UPDATED: Send notifications to vendors (English version)
    // Groups services by vendor and sends one notification per vendor
    // =============================================================
  
    private async notifyVendors(
        booking: BookingDocument,
        notificationType: NotificationType,
        userFullName: string 
    ): Promise<void> {
        
        // 1. Extract service IDs
        const serviceIds = booking.services.map(s => this.extractServiceId(s.serviceId));

        // 2. Fetch service data (providerId, serviceName) for all services
        const servicesData = await this.serviceModel.find(
            { _id: { $in: serviceIds } },
            { providerId: 1, serviceName: 1 } // Changed from 'name' to 'serviceName'
        ).exec();
        
        if (servicesData.length === 0) return;

        // 3. Group services by vendor (providerId)
        const servicesByVendor = new Map<string, Array<{ name: string; date: Date }>>();
        
        for (const bookingService of booking.services) {
            const serviceId = this.extractServiceId(bookingService.serviceId);
            const serviceData = servicesData.find(s => (s._id as Types.ObjectId).toString() === serviceId);
            
            if (serviceData) {
                const vendorId = serviceData.providerId.toString();
                
                if (!servicesByVendor.has(vendorId)) {
                    servicesByVendor.set(vendorId, []);
                }
                
                servicesByVendor.get(vendorId)!.push({
                    name: serviceData.serviceName, // Changed from serviceData.name
                    date: bookingService.bookingDate
                });
            }
        }

        // 4. Get unique vendor IDs
        const uniqueVendorIds = Array.from(servicesByVendor.keys()).map(id => new Types.ObjectId(id));
        
        // 5. Fetch vendor data (fcmToken and username)
        const vendors = await this.userModel.find(
            { _id: { $in: uniqueVendorIds } },
            { fcmToken: 1, username: 1 }
        ).exec();

        // 6. Send notification to each vendor
        const isConfirmed = notificationType === NotificationType.BOOKING_CONFIRMED;
        
        for (const vendor of vendors) {
            const vendorId = (vendor._id as Types.ObjectId).toString();
            const vendorServices = servicesByVendor.get(vendorId);
            
            if (!vendorServices || vendorServices.length === 0) continue;

            // Format service details (name and date)
            const serviceDetails = vendorServices.map(service => {
                const formattedDate = service.date.toLocaleDateString('en-US', {
                    year: 'numeric',
                    month: 'short',
                    day: 'numeric',
                });
                return `${service.name} (${formattedDate})`;
            }).join(', ');
            
            const title = isConfirmed 
                ? 'New Booking Confirmed! ✅' 
                : 'Booking Cancelled! ❌';
            
            const body = isConfirmed
                ? `${userFullName} has booked the following services: ${serviceDetails}.`
                : `${userFullName} has cancelled the booking for: ${serviceDetails}.`;

            const notificationDto: CreateNotificationDto = {
                recipientId: vendor._id as Types.ObjectId,
                recipientType: RecipientType.VENDOR,
                title: title,
                body: body, 
                type: notificationType,
                metadata: { 
                    bookingId: (booking._id as Types.ObjectId).toString(), 
                    userId: booking.userId 
                }, 
            };
            
            await this.notificationService.createNotification(
                notificationDto, 
                vendor.fcmToken || ''
            );
        }
    }

    // =============================================================
    // Get user bookings
    // =============================================================
    async findByUser(userId: string): Promise<BookingDocument[]> {
        return this.bookingModel.find({ userId }).exec();
    }

    // =============================================================
    // 1. Create PENDING booking from shopping cart 
    // =============================================================
    async createPendingBookingFromCart(userId: string): Promise<any> {
        const shoppingCart = await this.shoppingCartModel
            .findOne({ userId: new Types.ObjectId(userId) })
            .exec();

        if (!shoppingCart || shoppingCart.services.length === 0) {
            throw new BadRequestException('Shopping cart is empty');
        }

        const preparedServices: PreparedService[] = [];
        for (const cartService of shoppingCart.services) {
            const serviceId = this.extractServiceId(cartService.serviceId);
            const service = await this.serviceModel.findById(serviceId).exec();
            if (!service) {
                throw new NotFoundException(`Service with ID '${serviceId}' not found`);
            }

            preparedServices.push({
                serviceId: serviceId,
                bookingDate: cartService.bookingDate,
            });
        }

        let totalAmount = shoppingCart.totalPrice; 
        
        const newBooking = new this.bookingModel({
            userId,
            services: preparedServices,
            totalAmount,
            paymentStatus: PaymentStatus.PENDING, 
        });

        try {
            const savedBooking = await newBooking.save();
            await this.shoppingCartModel.deleteOne({ userId }).exec(); 
            
            return this.formatBookingResponse(savedBooking);
        } catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Failed to create pending booking';
            throw new BadRequestException(errorMessage);
        }
    }
    
    // =============================================================
    // 2. UPDATED: Confirm payment and finalize booking (with notifications)
    // Username now comes from JWT token
    // =============================================================
    async confirmBookingPayment(
        bookingId: string, 
        userId: string,
        userName: string
    ): Promise<any> {
        
        // 1. Find the booking
        const booking = await this.bookingModel.findById(bookingId).exec();

        if (!booking) {
            throw new NotFoundException(`Booking with ID '${bookingId}' not found`);
        }

        // 2. Security check: ensure the user owns this booking
        if (booking.userId.toString() !== userId) {
            throw new ForbiddenException('You are not authorized to confirm this booking.');
        }

        // 3. Check if already confirmed
        if (booking.paymentStatus === PaymentStatus.SUCCESSFUL) {
            return this.formatBookingResponse(booking); 
        }

        // 4. Update payment status to SUCCESSFUL
        booking.paymentStatus = PaymentStatus.SUCCESSFUL;
        const savedBooking = await booking.save();

        // 5. Update all related services (add booked dates)
        for (const service of booking.services) {
            const serviceId = this.extractServiceId(service.serviceId); 
            
            await this.serviceModel.findByIdAndUpdate(
                serviceId,
                { 
                    $push: { 
                        bookedDates: service.bookingDate 
                    } 
                }
            ).exec();
        }

        // 6. Clear shopping cart
        await this.shoppingCartModel.findOneAndUpdate(
            { userId: new Types.ObjectId(booking.userId) },
            { 
                $set: { 
                    services: [],
                    totalPrice: 0 
                } 
            }
        ).exec();

        // 7. 🔥 Send notifications to vendors (ENGLISH version with grouped services)
        await this.notifyVendors(
            savedBooking, 
            NotificationType.BOOKING_CONFIRMED, 
            userName // Using username from JWT
        );

        // 8. Return formatted response
        return this.formatBookingResponse(savedBooking);
    }

    // =============================================================
    // Cancel booking - Username comes from JWT token
    // =============================================================

    async cancelBooking(bookingId: string, userId: string, userFullName: string): Promise<BookingDocument> {
        const booking = await this.bookingModel.findOne({ _id: bookingId, userId }).exec();

        if (!booking) {
            throw new NotFoundException(`Booking with ID ${bookingId} not found or access denied.`);
        }
        
        if (booking.paymentStatus === PaymentStatus.CANCELLED) {
            throw new BadRequestException('Booking is already cancelled.');
        }
        
        booking.paymentStatus = PaymentStatus.CANCELLED;
        const cancelledBooking = await booking.save();

        // Send cancellation notification to vendors
        await this.notifyVendors(
            cancelledBooking, 
            NotificationType.BOOKING_CANCELLED, 
            userFullName
        );
        
        return cancelledBooking;
    }
    
    // =============================================================
    // Remaining methods (unchanged)
    // =============================================================
    
    async findAll(): Promise<any[]> {
        const bookings = await this.bookingModel.find().exec();
        return bookings.map(booking => this.formatBookingResponse(booking));
    }

    private formatBookingResponse(booking: any): any {
        const formattedBooking = booking.toObject ? booking.toObject() : { ...booking };
        
        if (formattedBooking.services && Array.isArray(formattedBooking.services)) {
            formattedBooking.services = formattedBooking.services.map(service => ({
                serviceId: this.extractServiceId(service.serviceId),
                bookingDate: service.bookingDate
            }));
        }

        delete formattedBooking.__v;
        
        return formattedBooking;
    }
    
    async getTotalSales(): Promise<{ totalSales: number }> {
        const successfulBookings = await this.bookingModel.find({ 
            paymentStatus: PaymentStatus.SUCCESSFUL 
        }).exec();

        const totalSales = successfulBookings.reduce(
            (sum, booking) => sum + booking.totalAmount,
            0,
        );

        return { totalSales };
    }

    async getTotalBookingsAndServices(): Promise<{ totalBookings: number, bookedServices: { serviceId: string, bookingDate: Date }[] }> {
        const bookings = await this.bookingModel.find().exec();
        const totalBookings = bookings.length;
        
        let bookedServices: { serviceId: string, bookingDate: Date }[] = [];

        bookings.forEach(booking => {
            if (Array.isArray(booking.services)) {
                booking.services.forEach(serviceItem => {
                    const formattedItem = this.formatBookingResponse({ services: [serviceItem] }).services[0];
                    
                    bookedServices.push({
                        serviceId: formattedItem.serviceId,
                        bookingDate: formattedItem.bookingDate,
                    });
                });
            }
        });

        return { 
            totalBookings, 
            bookedServices 
        };
    }

    async getVendorSalesAndBookings(vendorId: string): Promise<{ totalSales: number; totalBookings: number }> {
        const vendorServices = await this.serviceModel.find({ providerId: vendorId }, { _id: 1 }).exec();
        const serviceIds = vendorServices.map(service => service._id);

        if (serviceIds.length === 0) {
            return { totalSales: 0, totalBookings: 0 }; 
        }

        const bookings = await this.bookingModel.find({
            'services.serviceId': { $in: serviceIds },
            paymentStatus: PaymentStatus.SUCCESSFUL,
        }).select('totalAmount') 
          .exec();

        let totalSales = 0;
        const totalBookings = bookings.length; 
        
        bookings.forEach(booking => {
            totalSales += booking.totalAmount;
        });

        return { 
            totalSales, 
            totalBookings, 
        };
    }
}