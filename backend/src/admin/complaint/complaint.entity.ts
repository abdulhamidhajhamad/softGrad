export class Complaint {
  _id: string;
  userId: string;
  userName: string;
  userEmail: string;
  type: string;
  title: string;
  description: string;
  priority: string;
  status: string;
  targetId?: string;
  targetType?: string;
  attachments: string[];
  notes: ComplaintNote[];
  activityLog: ComplaintActivity[];
  assignedTo?: string;
  resolvedBy?: string;
  resolution?: string;
  isArchived: boolean;
  createdAt: Date;
  updatedAt: Date;
  resolvedAt?: Date;
  responseTimeHours?: number;

  constructor(data: Partial<Complaint>) {
    Object.assign(this, data);
    this.attachments = data?.attachments || [];
    this.notes = data?.notes || [];
    this.activityLog = data?.activityLog || [];
    this.isArchived = data?.isArchived || false;
  }
}

export interface ComplaintNote {
  adminId: string;
  adminName: string;
  note: string;
  timestamp: Date;
}

export interface ComplaintActivity {
  action: string;
  adminId?: string;
  details: string;
  timestamp: Date;
}
