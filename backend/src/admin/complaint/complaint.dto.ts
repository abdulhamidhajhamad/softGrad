import { 
  IsString, IsEnum, IsOptional, IsArray, IsEmail, 
  IsNotEmpty, IsNumber, Min, Max, IsBoolean, IsDate, MinLength, MaxLength 
} from 'class-validator';
import { Type } from 'class-transformer';
import { 
  ComplaintType, ComplaintPriority, ComplaintStatus 
} from './complaint.schema';

export class CreateComplaintDto {
  @IsEnum(ComplaintType)
  @IsNotEmpty()
  type: ComplaintType;

  @IsString()
  @IsNotEmpty()
  @MinLength(5)
  @MaxLength(100)
  title: string;

  @IsString()
  @IsNotEmpty()
  @MinLength(20)
  description: string;

  @IsEnum(ComplaintPriority)
  @IsOptional()
  priority?: ComplaintPriority;

  @IsString()
  @IsOptional()
  targetId?: string;

  @IsString()
  @IsOptional()
  targetType?: string;

  @IsArray()
  @IsOptional()
  attachments?: string[];
}

export class UpdateComplaintStatusDto {
  @IsEnum(ComplaintStatus)
  @IsNotEmpty()
  status: ComplaintStatus;

  @IsString()
  @IsOptional()
  @MinLength(10)
  resolution?: string;
}

export class AddComplaintNoteDto {
  @IsString()
  @IsNotEmpty()
  @MinLength(5)
  note: string;
}

export class AssignComplaintDto {
  @IsString()
  @IsNotEmpty()
  adminId: string;
}

export class ComplaintFilterDto {
  @IsEnum(ComplaintStatus)
  @IsOptional()
  status?: ComplaintStatus;

  @IsEnum(ComplaintType)
  @IsOptional()
  type?: ComplaintType;

  @IsEnum(ComplaintPriority)
  @IsOptional()
  priority?: ComplaintPriority;

  @IsString()
  @IsOptional()
  assignedTo?: string;

  @IsDate()
  @IsOptional()
  @Type(() => Date)
  fromDate?: Date;

  @IsDate()
  @IsOptional()
  @Type(() => Date)
  toDate?: Date;

  @IsString()
  @IsOptional()
  search?: string;

  @IsBoolean()
  @IsOptional()
  isArchived?: boolean;
}

export class ComplaintResponseDto {
  _id: string;
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
  notes: any[];
  activityLog: any[];
  assignedTo?: string;
  resolvedBy?: string;
  resolution?: string;
  isArchived: boolean;
  createdAt: Date;
  updatedAt: Date;
  resolvedAt?: Date;
  responseTimeHours?: number;
}

export class ComplaintStatsDto {
  total: number;
  pending: number;
  urgent: number;
  resolved: number;
  avgResponseTime: number;
  byType: { _id: string; count: number }[];
  byStatus: { _id: string; count: number }[];
  byPriority: { _id: string; count: number }[];
}
