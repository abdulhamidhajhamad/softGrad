import { Document } from 'mongoose';
import { ComplaintStatus, ComplaintType, ComplaintPriority } from './complaint.schema';

export interface IComplaint extends Document {
  _id: any;
  userId: string;
  userName: string;
  userEmail: string;
  type: ComplaintType;
  title: string;
  description: string;
  priority: ComplaintPriority;
  status: ComplaintStatus;
  targetId?: string;
  targetType?: string;
  attachments: string[];
  notes: {
    adminId: string;
    adminName: string;
    note: string;
    timestamp: Date;
  }[];
  activityLog: {
    action: string;
    adminId?: string;
    details: string;
    timestamp: Date;
  }[];
  assignedTo?: string;
  resolvedBy?: string;
  resolution?: string;
  responseTimeHours?: number;
  isArchived: boolean;
  createdAt: Date;
  updatedAt: Date;
  resolvedAt?: Date;
  __v: number;
}
