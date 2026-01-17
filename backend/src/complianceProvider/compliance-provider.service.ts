// compliance-provider.service.ts
import { 
  Injectable, 
  Logger, 
  BadRequestException, 
  NotFoundException,
  ForbiddenException 
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { ConfigService } from '@nestjs/config';
import { Model, Types } from 'mongoose';

import { ServiceProvider } from '../providers/provider.entity';
import { Service } from '../service/service.schema';
import { User } from '../auth/user.entity';
import { ComplianceLog } from './entities/compliance-log.entity';
import { NotificationService, CreateNotificationDto } from '../notification/notification.service';
import { RecipientType, NotificationType } from '../notification/notification.schema';
import { SupabaseStorageService } from '../subbase/supabaseStorage.service';

import { 
  UploadDocumentDto, 
  AdminVerificationDto 
} from './dto/upload-document.dto';
import { 
  VerificationResponseDto, 
  ProviderVerificationStatusDto,
  ExtractedDataDto,
  MatchResultDto,
  VerificationStatsDto 
} from './dto/verification-response.dto';
import { 
  VerificationStatus, 
  DocumentType, 
  ProviderType,
  RejectionReason,
  VERIFICATION_CONFIG,
  NOTIFICATION_MESSAGES,
  STORAGE_FOLDERS 
} from './constants/compliance.constants';
import {
  parseDocument,
  matchNames,
  compareIdNumbers,
  isDocumentValid,
  calculateExpiryDate,
  maskIdNumber,
  ParsedDocumentData,
} from './utils/ocr-parser.util';

@Injectable()
export class ComplianceProviderService {
  private readonly logger = new Logger(ComplianceProviderService.name);
  private visionClient: any;

  constructor(
    @InjectModel(ServiceProvider.name) private providerModel: Model<ServiceProvider>,
    @InjectModel(Service.name) private serviceModel: Model<Service>,
    @InjectModel(User.name) private userModel: Model<User>,
    @InjectModel(ComplianceLog.name) private complianceLogModel: Model<ComplianceLog>,
    private notificationService: NotificationService,
    private supabaseStorage: SupabaseStorageService,
    private configService: ConfigService,
  ) {}

  async onModuleInit() {
    try {
      // Initialize Google Cloud Vision
      const { ImageAnnotatorClient } = await import('@google-cloud/vision');
      
      // جلب بيانات الاعتماد من المتغيرات البيئية
      const projectId = this.configService.get<string>('GOOGLE_PROJECT_ID');
      const clientEmail = this.configService.get<string>('GOOGLE_CLIENT_EMAIL');
      const privateKey = this.configService.get<string>('GOOGLE_PRIVATE_KEY');
      
      if (projectId && clientEmail && privateKey) {
        // استخدام المتغيرات البيئية مباشرة
        this.visionClient = new ImageAnnotatorClient({
          credentials: {
            client_email: clientEmail,
            private_key: privateKey.replace(/\\n/g, '\n'), // تحويل \n النصية لسطور جديدة
          },
          projectId: projectId,
        });
        this.logger.log('✅ Google Cloud Vision initialized successfully (from env vars)');
      } else {
        // محاولة استخدام ملف الاعتماد كخيار بديل
        const credentialsPath = this.configService.get<string>('GOOGLE_APPLICATION_CREDENTIALS');
        if (credentialsPath) {
          this.visionClient = new ImageAnnotatorClient({
            keyFilename: credentialsPath,
          });
          this.logger.log('✅ Google Cloud Vision initialized successfully (from file)');
        } else {
          this.logger.warn('⚠️ Google Cloud Vision credentials not configured - OCR will be limited');
        }
      }
    } catch (error) {
      this.logger.error(`❌ Failed to initialize Google Cloud Vision: ${error.message}`);
    }
  }

  /**
   * رفع ومعالجة وثيقة التحقق
   */
  async uploadAndVerifyDocument(
    userId: string,
    file: Express.Multer.File,
    dto: UploadDocumentDto,
  ): Promise<VerificationResponseDto> {
    this.logger.log(`📤 بدء عملية رفع وثيقة للمستخدم: ${userId}`);

    // 1. جلب بيانات المزود
    const provider = await this.providerModel.findOne({ 
      userId: new Types.ObjectId(userId) 
    });

    if (!provider) {
      throw new NotFoundException('لم يتم العثور على ملف المزود');
    }

    const user = await this.userModel.findById(userId);
    if (!user) {
      throw new NotFoundException('لم يتم العثور على المستخدم');
    }

    // حفظ الحالة السابقة
    const previousStatus = provider.verification?.verificationStatus || VerificationStatus.PENDING;

    // 2. رفع الصورة إلى Supabase
    let documentUrl: string;
    try {
      const folder = dto.documentType === DocumentType.NATIONAL_ID 
        ? STORAGE_FOLDERS.NATIONAL_IDS 
        : STORAGE_FOLDERS.BUSINESS_LICENSES;
      
      documentUrl = await this.supabaseStorage.uploadImage(file, folder, false);
      this.logger.log(`✅ تم رفع الوثيقة: ${documentUrl}`);
    } catch (error) {
      this.logger.error(`❌ فشل رفع الوثيقة: ${error.message}`);
      throw new BadRequestException('فشل في رفع الوثيقة. يرجى المحاولة مرة أخرى.');
    }

    // 3. استخراج النص من الصورة باستخدام Google Vision
    let extractedText = '';
    let parsedData: ParsedDocumentData;

    try {
      extractedText = await this.extractTextFromImage(file.buffer);
      this.logger.log(`📝 تم استخراج النص (${extractedText.length} حرف)`);
      
      // تحليل النص المستخرج
      parsedData = parseDocument(
        extractedText, 
        dto.providerType === ProviderType.BUSINESS
      );
    } catch (error) {
      this.logger.error(`❌ فشل استخراج النص: ${error.message}`);
      
      // في حالة فشل OCR، نحول للمراجعة اليدوية
      return await this.handleAdminReview(
        provider,
        user,
        previousStatus,
        documentUrl,
        dto,
        'فشل في استخراج النص من الوثيقة',
      );
    }

    // 4. التحقق من البيانات المستخرجة
    const verificationResult = await this.verifyExtractedData(
      provider,
      user,
      parsedData,
      dto,
    );

    // 5. تحديث بيانات المزود
    const updateData: any = {
      'verification.documentUrl': documentUrl,
      'verification.extractedText': extractedText,
      'verification.providerType': dto.providerType,
      'verification.verificationStatus': verificationResult.status,
    };

    if (parsedData.issueDate) {
      updateData['verification.issueDate'] = parsedData.issueDate;
    }
    if (parsedData.expiryDate) {
      updateData['verification.licenseExpiryDate'] = parsedData.expiryDate;
    }
    if (dto.idNumber) {
      updateData['verification.idNumber'] = this.encryptIdNumber(dto.idNumber);
    } else if (parsedData.idNumber) {
      updateData['verification.idNumber'] = this.encryptIdNumber(parsedData.idNumber);
    }
    if (parsedData.businessName) {
      updateData['verification.businessName'] = parsedData.businessName;
    }
    if (parsedData.commercialRegNumber) {
      updateData['verification.commercialRegNumber'] = parsedData.commercialRegNumber;
    }
    if (verificationResult.status === VerificationStatus.VERIFIED) {
      updateData['verification.verifiedAt'] = new Date();
    }
    if (verificationResult.rejectionReason) {
      updateData['verification.rejectionReason'] = verificationResult.rejectionReason;
    }

    await this.providerModel.updateOne(
      { _id: provider._id },
      { $set: updateData }
    );

    // 6. تسجيل العملية
    await this.logComplianceAction({
      providerId: provider._id as Types.ObjectId,
      userId: new Types.ObjectId(userId),
      documentType: dto.documentType,
      providerType: dto.providerType,
      previousStatus,
      newStatus: verificationResult.status,
      documentUrl,
      extractedText,
      extractedData: {
        idNumber: parsedData.idNumber || undefined,
        issueDate: parsedData.issueDate || undefined,
        expiryDate: parsedData.expiryDate || undefined,
        businessName: parsedData.businessName || undefined,
        confidence: parsedData.confidence,
      },
      matchResult: verificationResult.matchResult,
      action: 'upload',
    });

    // 7. إرسال الإشعار
    await this.sendVerificationNotification(
      new Types.ObjectId(userId),
      user.fcmToken,
      verificationResult.status,
      verificationResult.rejectionReason,
    );

    return verificationResult;
  }

  /**
   * استخراج النص من الصورة باستخدام Google Cloud Vision
   */
  private async extractTextFromImage(imageBuffer: Buffer): Promise<string> {
    if (!this.visionClient) {
      throw new Error('Google Cloud Vision غير متاح');
    }

    try {
      const [result] = await this.visionClient.textDetection({
        image: { content: imageBuffer.toString('base64') },
      });

      const detections = result.textAnnotations;
      
      if (!detections || detections.length === 0) {
        throw new Error('لم يتم العثور على نص في الصورة');
      }

      // أول عنصر يحتوي على النص الكامل
      return detections[0].description || '';
    } catch (error) {
      this.logger.error(`❌ Google Vision Error: ${error.message}`);
      throw error;
    }
  }

  /**
   * التحقق من البيانات المستخرجة
   */
  private async verifyExtractedData(
    provider: ServiceProvider,
    user: User,
    parsedData: ParsedDocumentData,
    dto: UploadDocumentDto,
  ): Promise<VerificationResponseDto> {
    const response: VerificationResponseDto = {
      success: false,
      status: VerificationStatus.PENDING,
      message: '',
      extractedData: {
        idNumber: parsedData.idNumber || undefined,
        issueDate: parsedData.issueDate || undefined,
        expiryDate: parsedData.expiryDate || undefined,
        businessName: parsedData.businessName || undefined,
        commercialRegNumber: parsedData.commercialRegNumber || undefined,
        confidence: parsedData.confidence,
      },
    };

    // التحقق من تاريخ الصلاحية
    if (!parsedData.expiryDate && parsedData.issueDate) {
      parsedData.expiryDate = calculateExpiryDate(parsedData.issueDate);
      if (response.extractedData) {
        response.extractedData.expiryDate = parsedData.expiryDate;
      }
    }

    if (parsedData.expiryDate) {
      const validity = isDocumentValid(parsedData.expiryDate);
      response.expiryDate = parsedData.expiryDate;

      if (!validity.isValid) {
        // الوثيقة منتهية الصلاحية
        response.status = VerificationStatus.REJECTED;
        response.message = 'الوثيقة منتهية الصلاحية';
        response.rejectionReason = RejectionReason.EXPIRED_DOCUMENT;
        return response;
      }

      response.matchResult = {
        ...response.matchResult,
        isValid: true,
        daysUntilExpiry: validity.daysRemaining,
      } as MatchResultDto;
    }

    // للأفراد: التحقق من رقم الهوية والاسم
    if (dto.providerType === ProviderType.INDIVIDUAL) {
      return await this.verifyIndividual(provider, user, parsedData, dto, response);
    }

    // للمؤسسات: التحقق من اسم الشركة
    return await this.verifyBusiness(provider, parsedData, response);
  }

  /**
   * التحقق من بيانات الفرد
   */
  private async verifyIndividual(
    provider: ServiceProvider,
    user: User,
    parsedData: ParsedDocumentData,
    dto: UploadDocumentDto,
    response: VerificationResponseDto,
  ): Promise<VerificationResponseDto> {
    const providedId = dto.idNumber;
    const extractedIds = parsedData.allFoundIdNumbers;

    // التحقق من رقم الهوية
    let idMatched = false;
    if (providedId && extractedIds.length > 0) {
      idMatched = compareIdNumbers(providedId, extractedIds);
    }

    // التحقق من تطابق الاسم
    const nameMatch = await matchNames(user.userName, parsedData.rawText);

    response.matchResult = {
      idMatched,
      nameMatched: nameMatch.isMatch,
      nameSimilarityScore: nameMatch.similarityScore,
      firstNameMatched: nameMatch.firstNameMatch,
      isValid: response.matchResult?.isValid ?? true,
      daysUntilExpiry: response.matchResult?.daysUntilExpiry,
    };

    // منطق القرار
    if (idMatched && (nameMatch.isMatch || nameMatch.firstNameMatch)) {
      // ✅ تم التحقق بنجاح
      response.success = true;
      response.status = VerificationStatus.VERIFIED;
      response.message = 'تم التحقق من هويتك بنجاح';
    } else if (idMatched && !nameMatch.isMatch) {
      // رقم الهوية صحيح لكن الاسم لا يتطابق
      if (nameMatch.firstNameMatch) {
        // الاسم الأول متطابق - نقبل
        response.success = true;
        response.status = VerificationStatus.VERIFIED;
        response.message = 'تم التحقق من هويتك بنجاح';
      } else {
        // تحويل للمراجعة اليدوية
        response.status = VerificationStatus.ADMIN_REVIEW;
        response.message = 'تم تحويل طلبك للمراجعة اليدوية بسبب عدم تطابق الاسم';
      }
    } else if (!idMatched && parsedData.idNumber) {
      // رقم الهوية غير متطابق
      response.status = VerificationStatus.ADMIN_REVIEW;
      response.message = 'تم تحويل طلبك للمراجعة اليدوية للتحقق من رقم الهوية';
    } else {
      // لم يتم العثور على بيانات كافية
      response.status = VerificationStatus.ADMIN_REVIEW;
      response.message = 'تم تحويل طلبك للمراجعة اليدوية لعدم وضوح البيانات';
    }

    return response;
  }

  /**
   * التحقق من بيانات المؤسسة
   */
  private async verifyBusiness(
    provider: ServiceProvider,
    parsedData: ParsedDocumentData,
    response: VerificationResponseDto,
  ): Promise<VerificationResponseDto> {
    // للمؤسسات نتحقق من اسم الشركة والصلاحية
    const companyName = provider.companyName;
    const extractedBusinessName = parsedData.businessName;

    let nameMatched = false;
    let similarityScore = 0;

    if (extractedBusinessName) {
      const nameMatch = await matchNames(companyName, extractedBusinessName);
      nameMatched = nameMatch.isMatch;
      similarityScore = nameMatch.similarityScore;
    }

    response.matchResult = {
      idMatched: !!parsedData.commercialRegNumber,
      nameMatched,
      nameSimilarityScore: similarityScore,
      firstNameMatched: false,
      isValid: response.matchResult?.isValid ?? true,
      daysUntilExpiry: response.matchResult?.daysUntilExpiry,
    };

    // منطق القرار للمؤسسات
    if (response.matchResult.isValid) {
      if (nameMatched || parsedData.commercialRegNumber) {
        response.success = true;
        response.status = VerificationStatus.VERIFIED;
        response.message = 'تم التحقق من بيانات المؤسسة بنجاح';
      } else {
        response.status = VerificationStatus.ADMIN_REVIEW;
        response.message = 'تم تحويل طلبك للمراجعة اليدوية للتحقق من بيانات المؤسسة';
      }
    }

    return response;
  }

  /**
   * معالجة حالة المراجعة اليدوية
   */
  private async handleAdminReview(
    provider: ServiceProvider,
    user: User,
    previousStatus: VerificationStatus,
    documentUrl: string,
    dto: UploadDocumentDto,
    reason: string,
  ): Promise<VerificationResponseDto> {
    await this.providerModel.updateOne(
      { _id: provider._id },
      { 
        $set: {
          'verification.verificationStatus': VerificationStatus.ADMIN_REVIEW,
          'verification.documentUrl': documentUrl,
          'verification.providerType': dto.providerType,
          'verification.adminNotes': reason,
        }
      }
    );

    await this.logComplianceAction({
      providerId: provider._id as Types.ObjectId,
      userId: provider.userId,
      documentType: dto.documentType,
      providerType: dto.providerType,
      previousStatus,
      newStatus: VerificationStatus.ADMIN_REVIEW,
      documentUrl,
      action: 'admin_review',
      metadata: { reason },
    });

    await this.sendVerificationNotification(
      provider.userId,
      user.fcmToken,
      VerificationStatus.ADMIN_REVIEW,
    );

    return {
      success: false,
      status: VerificationStatus.ADMIN_REVIEW,
      message: 'تم تحويل طلبك للمراجعة اليدوية. سيتم إعلامك بالنتيجة قريباً.',
      documentUrl,
    };
  }

  /**
   * المراجعة اليدوية من المشرف
   */
  async adminVerification(
    adminId: string,
    dto: AdminVerificationDto,
  ): Promise<VerificationResponseDto> {
    this.logger.log(`🔍 مراجعة يدوية من المشرف ${adminId} للمزود ${dto.providerId}`);

    const provider = await this.providerModel.findById(dto.providerId);
    if (!provider) {
      throw new NotFoundException('لم يتم العثور على المزود');
    }

    const user = await this.userModel.findById(provider.userId);
    if (!user) {
      throw new NotFoundException('لم يتم العثور على المستخدم');
    }

    const previousStatus = provider.verification?.verificationStatus || VerificationStatus.PENDING;
    let newStatus: VerificationStatus;
    let rejectionReason: RejectionReason | undefined;

    if (dto.approved) {
      newStatus = VerificationStatus.VERIFIED;
    } else {
      newStatus = VerificationStatus.REJECTED;
      rejectionReason = dto.rejectionReason as RejectionReason;
    }

    const updateData: any = {
      'verification.verificationStatus': newStatus,
      'verification.verifiedBy': new Types.ObjectId(adminId),
      'verification.adminNotes': dto.adminNotes,
    };

    if (dto.approved) {
      updateData['verification.verifiedAt'] = new Date();
      // حساب تاريخ الانتهاء إذا لم يكن موجوداً
      if (!provider.verification?.licenseExpiryDate) {
        updateData['verification.licenseExpiryDate'] = calculateExpiryDate(new Date());
        updateData['verification.issueDate'] = new Date();
      }
    } else {
      updateData['verification.rejectionReason'] = rejectionReason;
    }

    await this.providerModel.updateOne(
      { _id: provider._id },
      { $set: updateData }
    );

    await this.logComplianceAction({
      providerId: provider._id as Types.ObjectId,
      userId: provider.userId,
      documentType: DocumentType.NATIONAL_ID,
      providerType: provider.verification?.providerType || ProviderType.INDIVIDUAL,
      previousStatus,
      newStatus,
      rejectionReason,
      adminNotes: dto.adminNotes,
      reviewedBy: new Types.ObjectId(adminId),
      reviewedAt: new Date(),
      action: dto.approved ? 'admin_approve' : 'admin_reject',
    });

    await this.sendVerificationNotification(
      provider.userId,
      user.fcmToken,
      newStatus,
      rejectionReason,
    );

    return {
      success: dto.approved,
      status: newStatus,
      message: dto.approved 
        ? 'تم التحقق من المزود بنجاح' 
        : `تم رفض الوثائق: ${dto.rejectionReason}`,
      rejectionReason,
    };
  }

  /**
   * جلب حالة التحقق للمزود
   */
  async getVerificationStatus(userId: string): Promise<ProviderVerificationStatusDto> {
    const provider = await this.providerModel.findOne({ 
      userId: new Types.ObjectId(userId) 
    });

    if (!provider) {
      throw new NotFoundException('لم يتم العثور على ملف المزود');
    }

    const verification = provider.verification;
    let daysUntilExpiry: number | undefined;

    if (verification?.licenseExpiryDate) {
      const validity = isDocumentValid(verification.licenseExpiryDate);
      daysUntilExpiry = validity.daysRemaining;
    }

    return {
      providerId: (provider._id as Types.ObjectId).toString(),
      verificationStatus: verification?.verificationStatus || VerificationStatus.PENDING,
      providerType: verification?.providerType || ProviderType.INDIVIDUAL,
      maskedIdNumber: verification?.idNumber 
        ? maskIdNumber(this.decryptIdNumber(verification.idNumber))
        : undefined,
      issueDate: verification?.issueDate,
      licenseExpiryDate: verification?.licenseExpiryDate,
      daysUntilExpiry,
      canAddServices: verification?.verificationStatus === VerificationStatus.VERIFIED,
      lastUpdated: verification?.verifiedAt,
      notes: verification?.adminNotes || verification?.rejectionReason,
    };
  }

  /**
   * جلب المزودين حسب حالة التحقق (للمشرف)
   */
  async getProvidersByStatus(
    status?: VerificationStatus,
    page: number = 1,
    limit: number = 20,
  ): Promise<{ providers: any[]; total: number }> {
    const query: any = {};
    
    if (status) {
      query['verification.verificationStatus'] = status;
    }

    const skip = (page - 1) * limit;

    const [providers, total] = await Promise.all([
      this.providerModel
        .find(query)
        .populate('userId', 'userName email phone')
        .skip(skip)
        .limit(limit)
        .sort({ updatedAt: -1 }),
      this.providerModel.countDocuments(query),
    ]);

    return { providers, total };
  }

  /**
   * جلب إحصائيات التحقق (للوحة التحكم)
   */
  async getVerificationStats(): Promise<VerificationStatsDto> {
    const now = new Date();
    const thirtyDaysFromNow = new Date();
    thirtyDaysFromNow.setDate(now.getDate() + 30);

    const [stats] = await this.providerModel.aggregate([
      {
        $group: {
          _id: null,
          total: { $sum: 1 },
          verified: {
            $sum: {
              $cond: [
                { $eq: ['$verification.verificationStatus', VerificationStatus.VERIFIED] },
                1, 0
              ]
            }
          },
          pendingReview: {
            $sum: {
              $cond: [
                { $eq: ['$verification.verificationStatus', VerificationStatus.UNDER_REVIEW] },
                1, 0
              ]
            }
          },
          adminReview: {
            $sum: {
              $cond: [
                { $eq: ['$verification.verificationStatus', VerificationStatus.ADMIN_REVIEW] },
                1, 0
              ]
            }
          },
          expired: {
            $sum: {
              $cond: [
                { $eq: ['$verification.verificationStatus', VerificationStatus.EXPIRED] },
                1, 0
              ]
            }
          },
          rejected: {
            $sum: {
              $cond: [
                { $eq: ['$verification.verificationStatus', VerificationStatus.REJECTED] },
                1, 0
              ]
            }
          },
          deactivated: {
            $sum: {
              $cond: [
                { $eq: ['$verification.verificationStatus', VerificationStatus.DEACTIVATED] },
                1, 0
              ]
            }
          },
        }
      }
    ]);

    // حساب المزودين الذين ستنتهي صلاحيتهم قريباً
    const expiringCount = await this.providerModel.countDocuments({
      'verification.verificationStatus': VerificationStatus.VERIFIED,
      'verification.licenseExpiryDate': {
        $gte: now,
        $lte: thirtyDaysFromNow,
      }
    });

    return {
      total: stats?.total || 0,
      verified: stats?.verified || 0,
      pendingReview: stats?.pendingReview || 0,
      adminReview: stats?.adminReview || 0,
      expired: stats?.expired || 0,
      rejected: stats?.rejected || 0,
      deactivated: stats?.deactivated || 0,
      expiringWithin30Days: expiringCount,
    };
  }

  /**
   * تعطيل خدمات المزود
   */
  async deactivateProviderServices(providerId: Types.ObjectId): Promise<void> {
    this.logger.log(`🔒 تعطيل خدمات المزود: ${providerId}`);

    await this.serviceModel.updateMany(
      { providerId: providerId.toString() },
      { $set: { isActive: false } }
    );

    this.logger.log(`✅ تم تعطيل جميع خدمات المزود`);
  }

  /**
   * إعادة تفعيل خدمات المزود
   */
  async reactivateProviderServices(providerId: Types.ObjectId): Promise<void> {
    this.logger.log(`🔓 إعادة تفعيل خدمات المزود: ${providerId}`);

    await this.serviceModel.updateMany(
      { providerId: providerId.toString() },
      { $set: { isActive: true } }
    );

    this.logger.log(`✅ تم إعادة تفعيل جميع خدمات المزود`);
  }

  /**
   * تحديث حالة المزود إلى منتهي الصلاحية
   */
  async expireProvider(providerId: Types.ObjectId): Promise<void> {
    const provider = await this.providerModel.findById(providerId);
    if (!provider) return;

    const previousStatus = provider.verification?.verificationStatus || VerificationStatus.VERIFIED;

    await this.providerModel.updateOne(
      { _id: providerId },
      { 
        $set: { 
          'verification.verificationStatus': VerificationStatus.EXPIRED,
          'verification.remindersSent': 0,
        } 
      }
    );

    await this.deactivateProviderServices(providerId);

    await this.logComplianceAction({
      providerId,
      userId: provider.userId,
      documentType: DocumentType.BUSINESS_LICENSE,
      providerType: provider.verification?.providerType || ProviderType.INDIVIDUAL,
      previousStatus,
      newStatus: VerificationStatus.EXPIRED,
      action: 'expire',
    });

    const user = await this.userModel.findById(provider.userId);
    if (user) {
      await this.sendExpiryNotification(provider.userId, user.fcmToken, 'expired');
    }
  }

  /**
   * تعطيل حساب المزود
   */
  async deactivateProvider(providerId: Types.ObjectId): Promise<void> {
    const provider = await this.providerModel.findById(providerId);
    if (!provider) return;

    const previousStatus = provider.verification?.verificationStatus || VerificationStatus.EXPIRED;

    await this.providerModel.updateOne(
      { _id: providerId },
      { 
        $set: { 'verification.verificationStatus': VerificationStatus.DEACTIVATED } 
      }
    );

    await this.logComplianceAction({
      providerId,
      userId: provider.userId,
      documentType: DocumentType.BUSINESS_LICENSE,
      providerType: provider.verification?.providerType || ProviderType.INDIVIDUAL,
      previousStatus,
      newStatus: VerificationStatus.DEACTIVATED,
      action: 'deactivate',
    });

    const user = await this.userModel.findById(provider.userId);
    if (user) {
      await this.sendExpiryNotification(provider.userId, user.fcmToken, 'deactivated');
    }
  }

  /**
   * إرسال تذكير بالتجديد
   */
  async sendRenewalReminder(
    providerId: Types.ObjectId, 
    reminderNumber: number
  ): Promise<void> {
    const provider = await this.providerModel.findById(providerId);
    if (!provider) return;

    const user = await this.userModel.findById(provider.userId);
    if (!user) return;

    await this.providerModel.updateOne(
      { _id: providerId },
      { 
        $set: { 
          'verification.remindersSent': reminderNumber,
          'verification.lastReminderDate': new Date(),
        } 
      }
    );

    const remaining = VERIFICATION_CONFIG.MAX_REMINDERS_COUNT - reminderNumber;
    const message = NOTIFICATION_MESSAGES.WEEKLY_REMINDER;

    await this.notificationService.createNotification(
      {
        recipientId: provider.userId,
        recipientType: RecipientType.VENDOR,
        title: message.title,
        body: message.body.replace('{remaining}', remaining.toString()),
        type: NotificationType.GENERAL,
        metadata: { reminderNumber, remaining },
      },
      user.fcmToken || '',
    );
  }

  /**
   * إرسال تنبيه اقتراب انتهاء الصلاحية
   */
  async sendExpiryWarning(
    providerId: Types.ObjectId, 
    daysRemaining: number
  ): Promise<void> {
    const provider = await this.providerModel.findById(providerId);
    if (!provider) return;

    const user = await this.userModel.findById(provider.userId);
    if (!user) return;

    const message = NOTIFICATION_MESSAGES.EXPIRY_WARNING;

    await this.notificationService.createNotification(
      {
        recipientId: provider.userId,
        recipientType: RecipientType.VENDOR,
        title: message.title,
        body: message.body.replace('{days}', daysRemaining.toString()),
        type: NotificationType.GENERAL,
        metadata: { daysRemaining },
      },
      user.fcmToken || '',
    );
  }

  /**
   * جلب سجلات التحقق للمزود
   */
  async getComplianceLogs(
    providerId: string,
    page: number = 1,
    limit: number = 20,
  ): Promise<{ logs: ComplianceLog[]; total: number }> {
    const skip = (page - 1) * limit;

    const [logs, total] = await Promise.all([
      this.complianceLogModel
        .find({ providerId: new Types.ObjectId(providerId) })
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .populate('reviewedBy', 'userName'),
      this.complianceLogModel.countDocuments({ 
        providerId: new Types.ObjectId(providerId) 
      }),
    ]);

    return { logs, total };
  }

  // ==================== Helper Methods ====================

  private async logComplianceAction(data: Partial<ComplianceLog>): Promise<void> {
    try {
      await this.complianceLogModel.create(data);
    } catch (error) {
      this.logger.error(`❌ فشل تسجيل العملية: ${error.message}`);
    }
  }

  private async sendVerificationNotification(
    userId: Types.ObjectId,
    fcmToken: string | undefined,
    status: VerificationStatus,
    rejectionReason?: RejectionReason,
  ): Promise<void> {
    let message: { title: string; body: string };

    switch (status) {
      case VerificationStatus.VERIFIED:
        message = NOTIFICATION_MESSAGES.VERIFIED;
        break;
      case VerificationStatus.ADMIN_REVIEW:
        message = NOTIFICATION_MESSAGES.ADMIN_REVIEW;
        break;
      case VerificationStatus.REJECTED:
        message = {
          title: NOTIFICATION_MESSAGES.REJECTED.title,
          body: NOTIFICATION_MESSAGES.REJECTED.body.replace(
            '{reason}', 
            this.translateRejectionReason(rejectionReason)
          ),
        };
        break;
      default:
        return;
    }

    try {
      await this.notificationService.createNotification(
        {
          recipientId: userId,
          recipientType: RecipientType.VENDOR,
          title: message.title,
          body: message.body,
          type: NotificationType.GENERAL,
          metadata: { verificationStatus: status, rejectionReason },
        },
        fcmToken || '',
      );
    } catch (error) {
      this.logger.error(`❌ فشل إرسال الإشعار: ${error.message}`);
    }
  }

  private async sendExpiryNotification(
    userId: Types.ObjectId,
    fcmToken: string | undefined,
    type: 'expired' | 'deactivated',
  ): Promise<void> {
    const message = type === 'expired' 
      ? NOTIFICATION_MESSAGES.EXPIRED 
      : NOTIFICATION_MESSAGES.DEACTIVATED;

    try {
      await this.notificationService.createNotification(
        {
          recipientId: userId,
          recipientType: RecipientType.VENDOR,
          title: message.title,
          body: message.body,
          type: NotificationType.GENERAL,
        },
        fcmToken || '',
      );
    } catch (error) {
      this.logger.error(`❌ فشل إرسال الإشعار: ${error.message}`);
    }
  }

  private translateRejectionReason(reason?: RejectionReason): string {
    const translations: Record<RejectionReason, string> = {
      [RejectionReason.EXPIRED_DOCUMENT]: 'الوثيقة منتهية الصلاحية',
      [RejectionReason.UNCLEAR_DOCUMENT]: 'الوثيقة غير واضحة',
      [RejectionReason.DATA_MISMATCH]: 'عدم تطابق البيانات',
      [RejectionReason.INVALID_DOCUMENT]: 'وثيقة غير صالحة',
      [RejectionReason.INVALID_ID_NUMBER]: 'رقم الهوية غير صحيح',
    };

    return reason ? translations[reason] : 'سبب غير محدد';
  }

  // تشفير بسيط لرقم الهوية (يمكن استبداله بتشفير أقوى)
  private encryptIdNumber(idNumber: string): string {
    return Buffer.from(idNumber).toString('base64');
  }

  private decryptIdNumber(encrypted: string): string {
    try {
      return Buffer.from(encrypted, 'base64').toString('utf-8');
    } catch {
      return encrypted;
    }
  }
}
