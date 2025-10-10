import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn } from 'typeorm';
import { User } from '../auth/user.entity';

export enum CustomerType {
  REGULAR = 'regular',
  MID = 'mid',
  HIGH = 'high'
}

@Entity('service_providers')
export class ServiceProvider {
  @PrimaryGeneratedColumn({ name: 'provider_id' })
  providerId: number;

  @Column({ name: 'user_id', type: 'int' })
  userId: number;

  @ManyToOne(() => User, { onDelete: 'CASCADE', onUpdate: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ name: 'company_name', type: 'varchar', length: 100 })
  companyName: string;

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ type: 'varchar', length: 100, nullable: true })
  location: string;

  @Column({ type: 'jsonb', nullable: true, default: null })
  imageUrls: string[];

  @Column({ 
    name: 'customer_type', 
    type: 'varchar', 
    length: 20, 
    default: 'regular' 
  })
  customerType: CustomerType;
}