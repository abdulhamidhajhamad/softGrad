// provider.service.ts
import { Injectable, NotFoundException, ForbiddenException, Logger, ConflictException, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { ServiceProvider } from './provider.entity';
import { CreateServiceProviderDto, UpdateServiceProviderDto } from './provider.dto';
import { DeleteResult } from 'mongodb';
import { User } from '../auth/user.entity'; 
// 🆕 استيراد خدمة المصادقة و Supabase Storage
import { AuthService } from '../auth/auth.service';
import { SupabaseStorageService } from '../subbase/supabaseStorage.service';

@Injectable()
export class ProviderService {
  private readonly logger = new Logger(ProviderService.name);
  
  // الشعار الافتراضي
  private readonly DEFAULT_LOGO_URL = 'https://hquymxmztgxpvsascxux.supabase.co/storage/v1/object/public/images/logos/default-company-logo.png';
  
constructor(
    @InjectModel(ServiceProvider.name) private providerModel: Model<ServiceProvider>,
    // ✅ التصحيح: استخدام Model<User> بدلاً من Model<UserDocument>
    @InjectModel(User.name) private readonly userModel: Model<User>, 
    private readonly authService: AuthService,
    private readonly supabaseStorage: SupabaseStorageService, // 🆕 إضافة Supabase Storage
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
    companyName: company.companyName,
    description: company.description,
    city: company.location?.city,
    phone: company.details?.phone, 
    email: company.details?.email, 
    image: company.logoUrl || company.details?.image || null,
    logoUrl: company.logoUrl || null,
    // ✅ أيضاً نرجع البيانات بالـ structure القديم للتوافق
    location: company.location,
    details: company.details,
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

// 🆕 رفع شعار الشركة
async uploadLogo(userId: string, file: Express.Multer.File): Promise<string> {
  try {
    const userObjectId = new Types.ObjectId(userId);
    
    // 1. التحقق من وجود شركة للمستخدم
    const company = await this.providerModel.findOne({ userId: userObjectId });
    if (!company) {
      throw new NotFoundException('No company found for this user');
    }

    // 2. رفع الشعار إلى Supabase
    this.logger.debug(`📤 Uploading logo for company: ${company.companyName}`);
    const logoUrl = await this.supabaseStorage.uploadImage(file, 'logos', true);
    
    // 3. تحديث الشركة بالشعار الجديد
    await this.providerModel.findOneAndUpdate(
      { userId: userObjectId },
      { logoUrl },
      { new: true }
    );

    this.logger.debug(`✅ Logo uploaded successfully: ${logoUrl}`);
    return logoUrl;
  } catch (error) {
    this.logger.error(`❌ Error uploading logo: ${error.message}`);
    throw error;
  }
}

// 🆕 الحصول على الشعار الافتراضي
getDefaultLogoUrl(): string {
  return this.DEFAULT_LOGO_URL;
}

}