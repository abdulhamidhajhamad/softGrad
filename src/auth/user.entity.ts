import { Entity, Column, PrimaryGeneratedColumn } from 'typeorm';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn({ name: 'user_id' })
  id: number;

  @Column({ name: 'user_name', type: 'varchar' })
  userName: string;

  @Column({ unique: true, type: 'varchar' })
  email: string;

  @Column({ name: 'password_hash', type: 'varchar' })
  password: string;

  @Column({ nullable: true, type: 'varchar' })
  phone?: string | null;

  @Column({ nullable: true, type: 'varchar' })
  city: string | null;

  @Column({ type: 'varchar' })
  role: 'client' | 'vendor' | 'admin';

  @Column({ name: 'image_url', nullable: true, type: 'varchar', default: null })
  imageUrl: string | null;

  @Column({ name: 'is_verified', type: 'boolean', default: false })
  isVerified: boolean;

  @Column({ name: 'verification_code', nullable: true, type: 'varchar', length: 6 })
  verificationCode: string | null;

  @Column({ name: 'verification_code_expires', nullable: true, type: 'timestamp' })
  verificationCodeExpires: Date | null;
}
