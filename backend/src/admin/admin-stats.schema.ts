
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true })
export class AdminStats extends Document {
  @Prop({ required: true, default: 0 })
  totalUsers: number;

  @Prop({ required: true, default: 0 })
  totalVendors: number;

  @Prop({ required: true, default: 0 })
  totalSales: number;

  @Prop({ default: Date.now })
  lastUpdated: Date;
}

export const AdminStatsSchema = SchemaFactory.createForClass(AdminStats);
