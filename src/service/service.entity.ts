import { Entity, Column, PrimaryGeneratedColumn, ManyToOne, JoinColumn } from 'typeorm';

@Entity('services')
export class Service {
  @PrimaryGeneratedColumn({ name: 'service_id' })
  serviceId: number;

  @Column({ name: 'provider_id', type: 'int', nullable: false })
  providerId: number;

  @Column({ type: 'varchar', length: 100, nullable: false })
  name: string;

  @Column({
    type: 'varchar',
    length: 50,
    nullable: true,
  })
  category: 'venue' | 'buffet' | 'photography';

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: false })
  price: number;

  @Column({
    type: 'decimal',
    precision: 2,
    scale: 1,
    default: 0.0,
    nullable: true,
  })
  rating: number;
  
  @Column({ type: 'jsonb', nullable: true, default: null })
  imageUrls: string[];
}