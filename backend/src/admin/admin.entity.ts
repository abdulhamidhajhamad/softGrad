import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Schema as MongooseSchema } from 'mongoose';

export enum AdminRole {
  SUPER_ADMIN = 'super_admin',
  ADMIN = 'admin',
}

@Schema({ collection: 'admins', timestamps: true })
export class Admin extends Document {
  @Prop({ required: true, type: MongooseSchema.Types.ObjectId, ref: 'User', unique: true })
  userId: string;

  @Prop({
    type: String,
    enum: Object.values(AdminRole),
    default: AdminRole.ADMIN,
  })
  role: AdminRole;

  @Prop({ type: Date, default: Date.now })
  createdAt: Date;
}

export const AdminSchema = SchemaFactory.createForClass(Admin);

// Create indexes
AdminSchema.index({ userId: 1 }, { unique: true });