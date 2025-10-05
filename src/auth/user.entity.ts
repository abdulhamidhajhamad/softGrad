import { Entity, Column, PrimaryGeneratedColumn } from 'typeorm';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn({ name: 'user_id' })
  id: number;

  @Column({ name: 'user_name' })
  userName: string;

  @Column({ unique: true })
  email: string;

  @Column({ name: 'password_hash' })
  password: string;

  @Column({ nullable: true })
  phone?: string;

  @Column({ nullable: true })
  city?: string;

  @Column()
  role: 'client' | 'vendor' | 'admin';
}
