// compliance-provider.service.ts
import { 
  Injectable, 
  Logger, 
  BadRequestException, 
  NotFoundException,
  ForbiddenException,
  OnModuleInit,
  OnModuleDestroy,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { ConfigService } from '@nestjs/config';
import { Model, Types } from 'mongoose';
import Tesseract from 'tesseract.js';

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
export class ComplianceProviderService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(ComplianceProviderService.name);
  private tesseractWorker: Tesseract.Worker | null = null;

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
      // Initialize Tesseract.js for Arabic + English OCR
      this.logger.log('🔄 Initializing Tesseract OCR...');
      
      this.tesseractWorker = await Tesseract.createWorker(['ara', 'eng'], 1, {
        logger: (m) => {
          if (m.status === 'recognizing text') {
            this.logger.log(`📝 OCR Progress: ${Math.round(m.progress * 100)}%`);
          }
        },
      });
      
      this.logger.log('✅ Tesseract OCR initialized successfully (Arabic + English)');
    } catch (error) {
      this.logger.error(`❌ Failed to initialize Tesseract OCR: ${error.message}`);
    }
  }

  async onModuleDestroy() {
    // Cleanup Tesseract worker on shutdown
    if (this.tesseractWorker) {
      await this.tesseractWorker.terminate();
      this.logger.log('🔄 Tesseract worker terminated');
    }
  }

  /**
   * Upload and process verification document
   */
  async uploadAndVerifyDocument(
    userId: string,
    file: Express.Multer.File,
    dto: UploadDocumentDto,
  ): Promise<VerificationResponseDto> {
    this.logger.log(`📤 Starting document upload for user: ${userId}`);

    // 1. Get provider data
    this.logger.log(`🔍 Searching for provider with userId: ${userId}`);
    
    // Try to find by userId first
    let provider = await this.providerModel.findOne({ 
      userId: new Types.ObjectId(userId) 
    });

    // If not found, try to find by provider _id (in case userId IS the provider id)
    if (!provider) {
      this.logger.log(`🔍 Provider not found by userId, trying by _id...`);
      try {
        provider = await this.providerModel.findById(userId);
      } catch (e) {
        this.logger.log(`🔍 Not a valid ObjectId for provider _id`);
      }
    }

    // If still not found, log all providers for debugging
    if (!provider) {
      const allProviders = await this.providerModel.find({}).select('_id userId companyName').limit(5);
      this.logger.log(`🔍 Sample providers in DB: ${JSON.stringify(allProviders)}`);
      throw new NotFoundException('Provider profile not found. Please complete your provider registration first.');
    }

    this.logger.log(`✅ Found provider: ${provider._id}, companyName: ${provider.companyName}`);

    const user = await this.userModel.findById(userId);
    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Save previous status
    const previousStatus = provider.verification?.verificationStatus || VerificationStatus.PENDING;

    // 2. Upload image to Supabase
    let documentUrl: string;
    try {
      const folder = dto.documentType === DocumentType.NATIONAL_ID 
        ? STORAGE_FOLDERS.NATIONAL_IDS 
        : STORAGE_FOLDERS.BUSINESS_LICENSES;
      
      documentUrl = await this.supabaseStorage.uploadImage(file, folder, false);
      this.logger.log(`✅ Document uploaded: ${documentUrl}`);
    } catch (error) {
      this.logger.error(`❌ Document upload failed: ${error.message}`);
      throw new BadRequestException('Failed to upload document. Please try again.');
    }

    // 3. Extract text from image using Google Vision
    let extractedText = '';
    let parsedData: ParsedDocumentData;

    try {
      extractedText = await this.extractTextFromImage(file.buffer);
      this.logger.log(`📝 Text extracted (${extractedText.length} characters)`);
      
      // Parse the extracted text
      parsedData = parseDocument(
        extractedText, 
        dto.providerType === ProviderType.BUSINESS
      );
    } catch (error) {
      this.logger.error(`❌ Text extraction failed: ${error.message}`);
      
      // If OCR fails, forward for manual review
      return await this.handleAdminReview(
        provider,
        user,
        previousStatus,
        documentUrl,
        dto,
        'Failed to extract text from document',
      );
    }

    // 4. Verify extracted data
    const verificationResult = await this.verifyExtractedData(
      provider,
      user,
      parsedData,
      dto,
    );

    // 5. Update provider data
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

    // 6. Log the operation
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

    // 7. Send notification
    await this.sendVerificationNotification(
      new Types.ObjectId(userId),
      user.fcmToken,
      verificationResult.status,
      verificationResult.rejectionReason,
    );

    return verificationResult;
  }

  /**
   * Extract text from image using Tesseract.js OCR
   */
  private async extractTextFromImage(imageBuffer: Buffer): Promise<string> {
    if (!this.tesseractWorker) {
      // Try to reinitialize if worker is not available
      this.logger.warn('⚠️ Tesseract worker not available, reinitializing...');
      await this.onModuleInit();
      
      if (!this.tesseractWorker) {
        throw new Error('Tesseract OCR is not available');
      }
    }

    try {
      this.logger.log('🔍 Starting OCR text extraction with Tesseract...');
      
      // Recognize text from the image buffer
      const { data } = await this.tesseractWorker.recognize(imageBuffer);
      
      const extractedText = data.text || '';
      
      this.logger.log(`✅ Tesseract OCR completed - Confidence: ${Math.round(data.confidence)}%`);
      this.logger.log(`📝 Extracted text preview: ${extractedText.substring(0, 200)}...`);
      
      if (!extractedText || extractedText.trim().length === 0) {
        throw new Error('No text found in the image');
      }

      return extractedText;
    } catch (error) {
      this.logger.error(`❌ Tesseract OCR Error: ${error.message}`);
      throw error;
    }
  }

  /**
   * Verify extracted data
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

    // Verify validity date
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
        // Document expired
        response.status = VerificationStatus.REJECTED;
        response.message = 'Document has expired';
        response.rejectionReason = RejectionReason.EXPIRED_DOCUMENT;
        return response;
      }

      response.matchResult = {
        ...response.matchResult,
        isValid: true,
        daysUntilExpiry: validity.daysRemaining,
      } as MatchResultDto;
    }

    // For individuals: verify ID number and name
    if (dto.providerType === ProviderType.INDIVIDUAL) {
      return await this.verifyIndividual(provider, user, parsedData, dto, response);
    }

    // For businesses: verify company name
    return await this.verifyBusiness(provider, parsedData, response);
  }

  /**
   * Verify individual data
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

    // Verify ID number
    let idMatched = false;
    if (providedId && extractedIds.length > 0) {
      idMatched = compareIdNumbers(providedId, extractedIds);
    }

    // Verify name match
    const nameMatch = await matchNames(user.userName, parsedData.rawText);

    response.matchResult = {
      idMatched,
      nameMatched: nameMatch.isMatch,
      nameSimilarityScore: nameMatch.similarityScore,
      firstNameMatched: nameMatch.firstNameMatch,
      isValid: response.matchResult?.isValid ?? true,
      daysUntilExpiry: response.matchResult?.daysUntilExpiry,
    };

    // Decision logic - ID number is the primary identifier
    if (idMatched) {
      // ✅ ID number matched - VERIFY (name matching is optional for Arabic OCR limitations)
      response.success = true;
      response.status = VerificationStatus.VERIFIED;
      response.message = 'Your identity has been verified successfully';
    } else if (!idMatched && extractedIds.length > 0 && providedId) {
      // ID number clearly extracted but doesn't match what user provided - REJECT
      response.success = false;
      response.status = VerificationStatus.REJECTED;
      response.message = 'The ID number you entered does not match the ID number in the document. Please check and try again.';
      response.rejectionReason = RejectionReason.INVALID_ID_NUMBER;
    } else if (!parsedData.idNumber && !extractedIds.length) {
      // No ID number found in document - send for manual review
      response.status = VerificationStatus.ADMIN_REVIEW;
      response.message = 'Your request has been forwarded for manual review due to unclear document';
    } else {
      // Other cases - send for manual review
      response.status = VerificationStatus.ADMIN_REVIEW;
      response.message = 'Your request has been forwarded for manual review';
    }

    return response;
  }

  /**
   * Verify business data
   */
  private async verifyBusiness(
    provider: ServiceProvider,
    parsedData: ParsedDocumentData,
    response: VerificationResponseDto,
  ): Promise<VerificationResponseDto> {
    // For businesses, verify company name and validity
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

    // Decision logic for businesses
    // If we have a valid date (not expired) - verify
    if (parsedData.expiryDate && response.matchResult.isValid) {
      // Document has valid date - approve
      response.success = true;
      response.status = VerificationStatus.VERIFIED;
      response.message = 'Business document has been verified successfully. License is valid.';
      this.logger.log(`✅ Business verified: Valid license until ${parsedData.expiryDate}`);
    } else if (parsedData.issueDate && !parsedData.expiryDate) {
      // Found issue date but couldn't calculate expiry - still verify
      response.success = true;
      response.status = VerificationStatus.VERIFIED;
      response.message = 'Business document has been verified successfully.';
      this.logger.log(`✅ Business verified: Issue date found ${parsedData.issueDate}`);
    } else if (nameMatched || parsedData.commercialRegNumber) {
      // Found company name match or commercial reg number
      response.success = true;
      response.status = VerificationStatus.VERIFIED;
      response.message = 'Business data has been verified successfully';
      this.logger.log(`✅ Business verified: Name/Reg matched`);
    } else {
      // Could not extract enough data - forward to admin
      response.status = VerificationStatus.ADMIN_REVIEW;
      response.message = 'Your request has been forwarded for manual review to verify business data';
      this.logger.log(`⚠️ Business sent to admin review: Insufficient data extracted`);
    }

    return response;
  }

  /**
   * Handle manual review case
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
      message: 'Your request has been forwarded for manual review. You will be notified of the result soon.',
      documentUrl,
    };
  }

  /**
   * Manual review by admin
   */
  async adminVerification(
    adminId: string,
    dto: AdminVerificationDto,
  ): Promise<VerificationResponseDto> {
    this.logger.log(`🔍 Manual review by admin ${adminId} for provider ${dto.providerId}`);

    const provider = await this.providerModel.findById(dto.providerId);
    if (!provider) {
      throw new NotFoundException('Provider not found');
    }

    const user = await this.userModel.findById(provider.userId);
    if (!user) {
      throw new NotFoundException('User not found');
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
      // Calculate expiry date if not present
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
        ? 'Provider has been verified successfully' 
        : `Documents rejected: ${dto.rejectionReason}`,
      rejectionReason,
    };
  }

  /**
   * Get verification status for provider
   */
  async getVerificationStatus(userId: string): Promise<ProviderVerificationStatusDto> {
    const provider = await this.providerModel.findOne({ 
      userId: new Types.ObjectId(userId) 
    });

    if (!provider) {
      throw new NotFoundException('Provider profile not found. Please complete your provider registration first.');
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
   * Get providers by verification status (for admin)
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
   * Get verification statistics (for dashboard)
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

    // Count providers expiring soon
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
   * Deactivate provider services
   */
  async deactivateProviderServices(providerId: Types.ObjectId): Promise<void> {
    this.logger.log(`🔒 Deactivating provider services: ${providerId}`);

    await this.serviceModel.updateMany(
      { providerId: providerId.toString() },
      { $set: { isActive: false } }
    );

    this.logger.log(`✅ All provider services deactivated`);
  }

  /**
   * Reactivate provider services
   */
  async reactivateProviderServices(providerId: Types.ObjectId): Promise<void> {
    this.logger.log(`🔓 Reactivating provider services: ${providerId}`);

    await this.serviceModel.updateMany(
      { providerId: providerId.toString() },
      { $set: { isActive: true } }
    );

    this.logger.log(`✅ All provider services reactivated`);
  }

  /**
   * Update provider status to expired
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
   * Deactivate provider account
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
   * Send renewal reminder
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
   * Send expiry warning notification
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
   * Get verification logs for provider
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
      this.logger.error(`❌ Failed to log operation: ${error.message}`);
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
      this.logger.error(`❌ Failed to send notification: ${error.message}`);
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
      this.logger.error(`❌ Failed to send notification: ${error.message}`);
    }
  }

  private translateRejectionReason(reason?: RejectionReason): string {
    const translations: Record<RejectionReason, string> = {
      [RejectionReason.EXPIRED_DOCUMENT]: 'Document has expired',
      [RejectionReason.UNCLEAR_DOCUMENT]: 'Document is unclear',
      [RejectionReason.DATA_MISMATCH]: 'Data mismatch',
      [RejectionReason.INVALID_DOCUMENT]: 'Invalid document',
      [RejectionReason.INVALID_ID_NUMBER]: 'Invalid ID number',
    };

    return reason ? translations[reason] : 'Unspecified reason';
  }

  // Simple encryption for ID number (can be replaced with stronger encryption)
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
