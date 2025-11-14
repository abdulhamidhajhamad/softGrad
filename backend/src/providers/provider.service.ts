// provider.service.ts
import { Injectable, NotFoundException, ForbiddenException, Logger, ConflictException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { ServiceProvider } from './provider.entity';
import { CreateServiceProviderDto, UpdateServiceProviderDto } from './provider.dto';
import { DeleteResult } from 'mongodb';

@Injectable()
export class ProviderService {
  private readonly logger = new Logger(ProviderService.name);

  constructor(@InjectModel(ServiceProvider.name) private providerModel: Model<ServiceProvider>) {}

  // إنشاء مزود خدمة
// provider.service.ts
async create(userId: string, dto: CreateServiceProviderDto): Promise<ServiceProvider> {
  try {
    this.logger.debug(`Creating company for user: ${userId}`);
    
    // تحقق من صحة الـ userId
    if (!Types.ObjectId.isValid(userId)) {
      throw new Error(`Invalid user ID: ${userId}`);
    }
    
    const userObjectId = new Types.ObjectId(userId);
    
    // تحقق من عدم وجود شركة بنفس الاسم لنفس المستخدم
    const existingCompany = await this.providerModel.findOne({ 
      userId: userObjectId,
      companyName: dto.companyName 
    });
    
    if (existingCompany) {
      throw new ConflictException('You already have a company with this name');
    }
    
    // أنشئ السجل الجديد
    const company = new this.providerModel({ 
      ...dto, 
      userId: userObjectId
    });
    
    const savedCompany = await company.save();
    this.logger.debug(`Company created successfully: ${savedCompany.companyName}`);
    return savedCompany;
  } catch (error) {
    this.logger.error(`Error creating company: ${error.message}`);
    this.logger.error(`Stack: ${error.stack}`);
    throw error;
  }
}

// أضف دالة لجلب جميع شركات المستخدم
async findAllByUser(userId: string): Promise<ServiceProvider[]> {
  const userObjectId = new Types.ObjectId(userId);
  return this.providerModel.find({ userId: userObjectId }).exec();
}

// تحديث الدوال الأخرى لتتحقق من ملكية الشركة وليس المستخدم ككل
async update(userId: string, companyName: string, dto: UpdateServiceProviderDto): Promise<ServiceProvider> {
  const userObjectId = new Types.ObjectId(userId);
  
  const company = await this.providerModel.findOne({ 
    userId: userObjectId,
    companyName 
  });
  
  if (!company) throw new NotFoundException('Company not found or you do not own this company');
  
  const updatedCompany = await this.providerModel.findOneAndUpdate(
    { userId: userObjectId, companyName }, 
    dto, 
    { new: true }
  );
  
  if (!updatedCompany) throw new NotFoundException('Company not found after update');
  return updatedCompany;
}

async remove(userId: string, companyName: string, isAdmin = false): Promise<DeleteResult> {
  const userObjectId = new Types.ObjectId(userId);
  
  const company = await this.providerModel.findOne({ 
    userId: userObjectId,
    companyName 
  });
  
  if (!company) throw new NotFoundException('Company not found or you do not own this company');
  
  if (!isAdmin && company.userId.toString() !== userId) {
    throw new ForbiddenException('You cannot delete this company');
  }
  
  return this.providerModel.deleteOne({ userId: userObjectId, companyName });
}

async findByName(userId: string, companyName: string): Promise<ServiceProvider> {
  const userObjectId = new Types.ObjectId(userId);
  
  const company = await this.providerModel.findOne({ 
    userId: userObjectId,
    companyName 
  });
  
  if (!company) throw new NotFoundException('Company not found or you do not have access');
  
  return company;
}
}