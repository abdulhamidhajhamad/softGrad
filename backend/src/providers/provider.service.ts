// provider.service.ts
import { Injectable, NotFoundException, ForbiddenException, Logger, ConflictException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { ServiceProvider } from './provider.entity';
import { CreateServiceProviderDto, UpdateServiceProviderDto } from './provider.dto';
import { DeleteResult } from 'mongodb';
import { User } from '../auth/user.entity'; 
// 🆕 استيراد خدمة المصادقة
import { AuthService } from '../auth/auth.service';
@Injectable()
export class ProviderService {
  private readonly logger = new Logger(ProviderService.name);
  
constructor(
    @InjectModel(ServiceProvider.name) private providerModel: Model<ServiceProvider>,
    // ✅ التصحيح: استخدام Model<User> بدلاً من Model<UserDocument>
    @InjectModel(User.name) private readonly userModel: Model<User>, 
    private readonly authService: AuthService, 
  ) {}

  // إنشاء مزود خدمة
// provider.service.ts
async create(userId: string, dto: CreateServiceProviderDto): Promise<{ provider: ServiceProvider, token: string }> {
    try {
      this.logger.debug(`Creating company for user: ${userId}`);
      
      if (!Types.ObjectId.isValid(userId)) {
        throw new ForbiddenException(`Invalid user ID: ${userId}`);
      }
      
      const userObjectId = new Types.ObjectId(userId);
      
      const existingCompany = await this.providerModel.findOne({ 
        userId: userObjectId,
        companyName: dto.companyName 
      });
      
      if (existingCompany) {
        throw new ConflictException('You already have a company with this name');
      }
      
      const company = new this.providerModel({ ...dto, userId: userObjectId });
      const savedCompany = await company.save();
      this.logger.debug(`Company created successfully: ${savedCompany.companyName}`);

      // 1. تحديث دور المستخدم في قاعدة البيانات
      const updatedUser = await this.userModel.findByIdAndUpdate(
        userId, 
        { role: 'vendor' }, 
        { new: true, lean: true } 
      );
      
      if (!updatedUser) {
           throw new NotFoundException('User not found after provider creation.');
      }
      
      // 2. توليد JWT جديد بالدور المحدث
      const newToken = await this.authService.generateToken(updatedUser); 
      
      return { provider: savedCompany, token: newToken };
      
    } catch (error) {
      this.logger.error(`Error creating company: ${error.message}`);
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
  
  // 1. العثور على الشركة الحالية
  const company = await this.providerModel.findOne({ 
    userId: userObjectId,
    companyName 
  });
  
  if (!company) throw new NotFoundException('Company not found or you do not own this company');
  
  // 2. تجهيز كائن التحديث
  const updatePayload: any = { ...dto }; // نبدأ بالـ DTO المرسل
  
  // 3. دمج حقل details لضمان التحديث الجزئي
  if (dto.details) {
    // ندمج الـ details القديمة مع الجديدة المرسلة لتجنب مسح الحقول الأخرى
    updatePayload.details = {
      ...company.details, // البيانات القديمة في details
      ...dto.details,     // البيانات الجديدة المرسلة (مثل phone أو email)
    };
  }

  // 4. تنفيذ التحديث
  const updatedCompany = await this.providerModel.findOneAndUpdate(
    { userId: userObjectId, companyName }, 
    updatePayload, // استخدام كائن التحديث المعدل
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
async findCompanyNameByUserId(userId: string): Promise<string> {
  const userObjectId = new Types.ObjectId(userId);
  // البحث عن أول شركة تابعة لهذا المستخدم واختيار حقل companyName فقط
  const company = await this.providerModel.findOne(
    { userId: userObjectId },
    { companyName: 1 } // اختيار حقل companyName فقط
  ).exec();
  
  if (!company) {
    throw new NotFoundException('No company found for this user.');
  }
  
  return company.companyName;
}
async findProviderDetails(userId: string): Promise<any> {
  const userObjectId = new Types.ObjectId(userId);

  // 1. جلب بيانات الشركة
  const company = await this.providerModel.findOne({ userId: userObjectId }).exec();

  if (!company) {
    throw new NotFoundException('No company found for this user.');
  }

  // 2. استخراج البيانات المطلوبة: companyName, description, city, phone, email, image
  return {
    companyName: company.companyName, // من حقول الشركة الأساسية
    description: company.description, // من حقول الشركة الأساسية
    city: company.location?.city, // من حقل location
    
    // استخراج من حقل details (حسب طلبك الأخير)
    phone: company.details?.phone, 
    email: company.details?.email, 
    
    // حقل image: بما أنه غير موجود في الـ entity الحالية، سنرجعه كـ null
    image: company.details?.image || null, // يمكنك استخدام حقل آخر إذا تمت إضافته لاحقًا بشكل مستقل.
  };
}

async updateByUserId(userId: string, dto: UpdateServiceProviderDto): Promise<ServiceProvider> {
  // 1. استخدام userId (string) مباشرة في البحث
  // ملاحظة: بما أن حقل userId في الـ entity هو Types.ObjectId، التحويل هو الأفضل.
  // سنقوم بالتحويل لكن سنُجرب استخدام findByIdAndUpdate
  
  const userObjectId = new Types.ObjectId(userId);
  
  // 1. العثور على الشركة الحالية بواسطة userId فقط 
  const company = await this.providerModel.findOne({ userId: userObjectId }); 
  if (!company) {
    // 💡 قم بتغيير رسالة الخطأ لتكون فريدة للـ PATCH /my-details
    throw new NotFoundException('Cannot find company details for the logged-in user.'); 
  }

   if (!company) {
    throw new NotFoundException('Cannot find company details for the logged-in user.'); 
  }

  // ✅ 2. تجهيز كائن التحديث
  const updatePayload: any = { ...dto };

  // ✅ 3. معالجة companyName
  if (dto.companyName) {
    updatePayload.companyName = dto.companyName;
  }
  
  // ✅ 4. دمج حقل details
  if (dto.details) {
    updatePayload.details = {
      ...company.details,
      ...dto.details,
    };
  }

  // ✅ 5. تنفيذ التحديث
  const updatedCompany = await this.providerModel.findOneAndUpdate(
    { userId: userObjectId },
    updatePayload, 
    { new: true }
  );
  
  if (!updatedCompany) throw new NotFoundException('Update failed after finding the company.'); 
  return updatedCompany;
}

}