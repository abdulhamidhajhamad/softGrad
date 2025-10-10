// src/booking/booking.entity.ts

import { Entity, Column, PrimaryGeneratedColumn, ManyToOne, JoinColumn } from 'typeorm';
import { User } from '../auth/user.entity'; // <-- Import User entity
import { Service } from '../service/service.entity'; // <-- Import Service entity

export enum BookingStatus {
  PENDING = 'pending',
  CONFIRMED = 'confirmed',
  CANCELLED = 'cancelled',
  COMPLETED = 'completed',
}

@Entity('bookings')
export class Booking {
  @PrimaryGeneratedColumn({ name: 'booking_id' })
  bookingId: number;
  
  // Define relationships
  @ManyToOne(() => User, { eager: true }) // eager: true automatically loads the user
  @JoinColumn({ name: 'user_id' })
  user: User;

  @ManyToOne(() => Service, { eager: true }) // eager: true automatically loads the service
  @JoinColumn({ name: 'service_id' })
  service: Service;

  // You can keep the ID columns if you need direct access, 
  // but they are implicitly handled by the @JoinColumn.
  @Column({ name: 'user_id' })
  userId: number;

  @Column({ name: 'service_id' })
  serviceId: number;

  @Column({ name: 'booking_date', type: 'date', nullable: false })
  bookingDate: Date;

  @Column({
    type: 'enum',
    enum: BookingStatus,
    default: BookingStatus.PENDING,
  })
  status: BookingStatus;

  @Column({ name: 'total_price', type: 'decimal', precision: 10, scale: 2, nullable: false })
  totalPrice: number;
}