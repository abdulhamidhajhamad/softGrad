// expiry-check.cron.ts
import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';

import { ServiceProvider } from '../../providers/provider.entity';
import { ComplianceProviderService } from '../compliance-provider.service';
import { 
  VerificationStatus, 
  VERIFICATION_CONFIG 
} from '../constants/compliance.constants';
import { isDocumentValid } from '../utils/ocr-parser.util';

// Helper type for provider with _id
type ProviderWithId = ServiceProvider & { _id: Types.ObjectId };

/**
 * Cron Jobs لفحص انتهاء صلاحية الوثائق وإرسال الإشعارات
 */
@Injectable()
export class ExpiryCheckCronService {
  private readonly logger = new Logger(ExpiryCheckCronService.name);

  constructor(
    @InjectModel(ServiceProvider.name) 
    private providerModel: Model<ServiceProvider>,
    private complianceService: ComplianceProviderService,
  ) {}

  /**
   * فحص يومي للوثائق المقتربة من الانتهاء والمنتهية
   * يعمل كل يوم الساعة 8 صباحاً
   */
  @Cron(CronExpression.EVERY_DAY_AT_8AM)
  async handleDailyExpiryCheck(): Promise<void> {
    this.logger.log('🔍 بدء الفحص اليومي لصلاحية الوثائق...');

    try {
      const now = new Date();
      now.setHours(0, 0, 0, 0);

      // 1. إرسال تنبيهات للوثائق التي ستنتهي خلال 30 يوم
      await this.sendExpiryWarnings();

      // 2. تحديث حالة الوثائق المنتهية
      await this.processExpiredDocuments();

      // 3. تعطيل الحسابات التي مر عليها أكثر من شهر
      await this.processDeactivations();

      this.logger.log('✅ انتهى الفحص اليومي بنجاح');
    } catch (error) {
      this.logger.error(`❌ خطأ في الفحص اليومي: ${error.message}`);
    }
  }

  /**
   * إرسال تذكيرات أسبوعية للمزودين منتهيي الصلاحية
   * يعمل كل يوم أحد الساعة 10 صباحاً
   */
  @Cron(CronExpression.EVERY_WEEK)
  async handleWeeklyReminders(): Promise<void> {
    this.logger.log('📬 بدء إرسال التذكيرات الأسبوعية...');

    try {
      // جلب المزودين منتهيي الصلاحية الذين لم يتجاوزوا 4 تذكيرات
      const expiredProviders = await this.providerModel.find({
        'verification.verificationStatus': VerificationStatus.EXPIRED,
        'verification.remindersSent': { 
          $lt: VERIFICATION_CONFIG.MAX_REMINDERS_COUNT 
        },
      });

      this.logger.log(`📊 عدد المزودين المحتاجين تذكير: ${expiredProviders.length}`);

      for (const provider of expiredProviders) {
        const reminderNumber = (provider.verification?.remindersSent || 0) + 1;
        
        // التحقق من مرور أسبوع منذ آخر تذكير
        const lastReminder = provider.verification?.lastReminderDate;
        if (lastReminder) {
          const daysSinceLastReminder = Math.floor(
            (Date.now() - new Date(lastReminder).getTime()) / (1000 * 60 * 60 * 24)
          );
          
          if (daysSinceLastReminder < VERIFICATION_CONFIG.WEEKLY_REMINDER_INTERVAL) {
            continue; // لم يمر أسبوع بعد
          }
        }

        await this.complianceService.sendRenewalReminder(
          (provider as ProviderWithId)._id,
          reminderNumber,
        );

        this.logger.log(
          `📧 تم إرسال التذكير رقم ${reminderNumber} للمزود: ${(provider as ProviderWithId)._id}`
        );
      }

      this.logger.log('✅ انتهى إرسال التذكيرات الأسبوعية');
    } catch (error) {
      this.logger.error(`❌ خطأ في إرسال التذكيرات: ${error.message}`);
    }
  }

  /**
   * إرسال تنبيهات للوثائق المقتربة من الانتهاء (30 يوم)
   */
  private async sendExpiryWarnings(): Promise<void> {
    const now = new Date();
    const warningDate = new Date();
    warningDate.setDate(now.getDate() + VERIFICATION_CONFIG.EXPIRY_WARNING_DAYS);

    // جلب المزودين الموثقين الذين ستنتهي صلاحيتهم خلال 30 يوم
    const providersToWarn = await this.providerModel.find({
      'verification.verificationStatus': VerificationStatus.VERIFIED,
      'verification.licenseExpiryDate': {
        $gte: now,
        $lte: warningDate,
      },
    });

    this.logger.log(`⚠️ عدد المزودين المقتربين من الانتهاء: ${providersToWarn.length}`);

    for (const provider of providersToWarn) {
      const expiryDate = provider.verification?.licenseExpiryDate;
      if (!expiryDate) continue;

      const validity = isDocumentValid(expiryDate);
      
      // إرسال تنبيه فقط إذا كانت الأيام المتبقية = 30 أو 15 أو 7 أو 3 أو 1
      const warningDays = [30, 15, 7, 3, 1];
      if (warningDays.includes(validity.daysRemaining)) {
        await this.complianceService.sendExpiryWarning(
          (provider as ProviderWithId)._id,
          validity.daysRemaining,
        );
        
        this.logger.log(
          `📢 تم إرسال تنبيه للمزود ${(provider as ProviderWithId)._id} - متبقي ${validity.daysRemaining} يوم`
        );
      }
    }
  }

  /**
   * معالجة الوثائق المنتهية الصلاحية
   */
  private async processExpiredDocuments(): Promise<void> {
    const now = new Date();
    now.setHours(0, 0, 0, 0);

    // جلب المزودين الموثقين الذين انتهت صلاحيتهم
    const expiredProviders = await this.providerModel.find({
      'verification.verificationStatus': VerificationStatus.VERIFIED,
      'verification.licenseExpiryDate': { $lt: now },
    });

    this.logger.log(`🔴 عدد المزودين منتهيي الصلاحية: ${expiredProviders.length}`);

    for (const provider of expiredProviders) {
      await this.complianceService.expireProvider((provider as ProviderWithId)._id);
      
      this.logger.log(`❌ تم تحويل المزود ${(provider as ProviderWithId)._id} إلى حالة منتهي الصلاحية`);
    }
  }

  /**
   * تعطيل الحسابات التي مر عليها أكثر من شهر بعد الانتهاء
   */
  private async processDeactivations(): Promise<void> {
    const now = new Date();
    const deactivationThreshold = new Date();
    deactivationThreshold.setDate(
      now.getDate() - VERIFICATION_CONFIG.DEACTIVATION_GRACE_PERIOD_DAYS
    );

    // جلب المزودين المنتهيين الذين مر عليهم أكثر من شهر
    // وأرسلنا لهم 4 تذكيرات
    const providersToDeactivate = await this.providerModel.find({
      'verification.verificationStatus': VerificationStatus.EXPIRED,
      'verification.licenseExpiryDate': { $lt: deactivationThreshold },
      'verification.remindersSent': { 
        $gte: VERIFICATION_CONFIG.MAX_REMINDERS_COUNT 
      },
    });

    this.logger.log(`🔒 عدد المزودين للتعطيل: ${providersToDeactivate.length}`);

    for (const provider of providersToDeactivate) {
      await this.complianceService.deactivateProvider((provider as ProviderWithId)._id);
      
      this.logger.log(`🚫 تم تعطيل حساب المزود: ${(provider as ProviderWithId)._id}`);
    }
  }

  /**
   * فحص يدوي (يمكن استدعاؤه من الـ Controller)
   */
  async manualExpiryCheck(): Promise<{
    warned: number;
    expired: number;
    deactivated: number;
  }> {
    this.logger.log('🔧 بدء الفحص اليدوي...');

    const now = new Date();
    now.setHours(0, 0, 0, 0);
    const warningDate = new Date();
    warningDate.setDate(now.getDate() + VERIFICATION_CONFIG.EXPIRY_WARNING_DAYS);
    const deactivationThreshold = new Date();
    deactivationThreshold.setDate(
      now.getDate() - VERIFICATION_CONFIG.DEACTIVATION_GRACE_PERIOD_DAYS
    );

    // إحصائيات
    const [warnCount, expireCount, deactivateCount] = await Promise.all([
      this.providerModel.countDocuments({
        'verification.verificationStatus': VerificationStatus.VERIFIED,
        'verification.licenseExpiryDate': { $gte: now, $lte: warningDate },
      }),
      this.providerModel.countDocuments({
        'verification.verificationStatus': VerificationStatus.VERIFIED,
        'verification.licenseExpiryDate': { $lt: now },
      }),
      this.providerModel.countDocuments({
        'verification.verificationStatus': VerificationStatus.EXPIRED,
        'verification.licenseExpiryDate': { $lt: deactivationThreshold },
        'verification.remindersSent': { $gte: VERIFICATION_CONFIG.MAX_REMINDERS_COUNT },
      }),
    ]);

    // تنفيذ الفحوصات
    await this.handleDailyExpiryCheck();

    return {
      warned: warnCount,
      expired: expireCount,
      deactivated: deactivateCount,
    };
  }

  /**
   * جلب ملخص حالة الصلاحيات
   */
  async getExpiryStatusSummary(): Promise<{
    expiringIn7Days: number;
    expiringIn30Days: number;
    expiredButActive: number;
    pendingDeactivation: number;
  }> {
    const now = new Date();
    now.setHours(0, 0, 0, 0);

    const in7Days = new Date();
    in7Days.setDate(now.getDate() + 7);

    const in30Days = new Date();
    in30Days.setDate(now.getDate() + 30);

    const deactivationThreshold = new Date();
    deactivationThreshold.setDate(
      now.getDate() - VERIFICATION_CONFIG.DEACTIVATION_GRACE_PERIOD_DAYS
    );

    const [expiringIn7Days, expiringIn30Days, expiredButActive, pendingDeactivation] = 
      await Promise.all([
        this.providerModel.countDocuments({
          'verification.verificationStatus': VerificationStatus.VERIFIED,
          'verification.licenseExpiryDate': { $gte: now, $lte: in7Days },
        }),
        this.providerModel.countDocuments({
          'verification.verificationStatus': VerificationStatus.VERIFIED,
          'verification.licenseExpiryDate': { $gte: now, $lte: in30Days },
        }),
        this.providerModel.countDocuments({
          'verification.verificationStatus': VerificationStatus.VERIFIED,
          'verification.licenseExpiryDate': { $lt: now },
        }),
        this.providerModel.countDocuments({
          'verification.verificationStatus': VerificationStatus.EXPIRED,
          'verification.remindersSent': { $gte: VERIFICATION_CONFIG.MAX_REMINDERS_COUNT },
        }),
      ]);

    return {
      expiringIn7Days,
      expiringIn30Days,
      expiredButActive,
      pendingDeactivation,
    };
  }
}
