// verification.guard.ts
import { 
  Injectable, 
  CanActivate, 
  ExecutionContext, 
  ForbiddenException,
  Logger,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';

import { ServiceProvider } from '../../providers/provider.entity';
import { VerificationStatus } from '../constants/compliance.constants';

/**
 * Decorator للتحقق من حالة التوثيق
 */
export const RequireVerification = () => {
  return (target: any, key?: string, descriptor?: PropertyDescriptor) => {
    Reflect.defineMetadata('requireVerification', true, descriptor?.value || target);
    return descriptor || target;
  };
};

/**
 * Guard للتحقق من أن المزود موثق قبل السماح بإضافة الخدمات
 */
@Injectable()
export class VerificationGuard implements CanActivate {
  private readonly logger = new Logger(VerificationGuard.name);

  constructor(
    private reflector: Reflector,
    @InjectModel(ServiceProvider.name) 
    private providerModel: Model<ServiceProvider>,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    // التحقق مما إذا كان الـ endpoint يتطلب توثيق
    const requireVerification = this.reflector.get<boolean>(
      'requireVerification',
      context.getHandler(),
    );

    // إذا لم يكن مطلوباً، نسمح بالمرور
    if (!requireVerification) {
      return true;
    }

    const request = context.switchToHttp().getRequest();
    const user = request.user;

    if (!user) {
      throw new ForbiddenException('يجب تسجيل الدخول أولاً');
    }

    // المشرفين يمكنهم المرور دائماً
    if (user.role === 'admin') {
      return true;
    }

    // التحقق من أن المستخدم هو مزود خدمة
    if (user.role !== 'vendor') {
      throw new ForbiddenException('هذه الخدمة متاحة للمزودين فقط');
    }

    // جلب بيانات المزود
    const provider = await this.providerModel.findOne({
      userId: new Types.ObjectId(user._id || user.id),
    });

    if (!provider) {
      throw new ForbiddenException(
        'يجب إكمال ملف المزود أولاً قبل إضافة الخدمات'
      );
    }

    const verificationStatus = provider.verification?.verificationStatus;

    // التحقق من حالة التوثيق
    if (verificationStatus !== VerificationStatus.VERIFIED) {
      const message = this.getStatusMessage(verificationStatus);
      this.logger.warn(
        `🚫 محاولة وصول غير مصرح - المزود: ${provider._id}, الحالة: ${verificationStatus}`
      );
      throw new ForbiddenException(message);
    }

    // التحقق من صلاحية الوثيقة
    const expiryDate = provider.verification?.licenseExpiryDate;
    if (expiryDate && new Date(expiryDate) < new Date()) {
      this.logger.warn(
        `🚫 وثيقة منتهية الصلاحية - المزود: ${provider._id}`
      );
      throw new ForbiddenException(
        'انتهت صلاحية وثائقك. يرجى تجديدها لاستعادة إمكانية إضافة الخدمات.'
      );
    }

    return true;
  }

  /**
   * إرجاع رسالة مناسبة حسب حالة التوثيق
   */
  private getStatusMessage(status?: VerificationStatus): string {
    switch (status) {
      case VerificationStatus.PENDING:
        return 'يجب رفع وثائق التحقق أولاً قبل إضافة الخدمات. يرجى رفع الهوية أو السجل التجاري للتوثيق.';
      
      case VerificationStatus.UNDER_REVIEW:
        return 'وثائقك قيد المراجعة. سيتم إعلامك فور الانتهاء من التحقق.';
      
      case VerificationStatus.ADMIN_REVIEW:
        return 'وثائقك قيد المراجعة اليدوية من قبل فريق الدعم. سيتم إعلامك بالنتيجة قريباً.';
      
      case VerificationStatus.REJECTED:
        return 'تم رفض وثائقك. يرجى مراجعة سبب الرفض ورفع وثائق صحيحة.';
      
      case VerificationStatus.EXPIRED:
        return 'انتهت صلاحية وثائقك. يرجى تجديدها لاستعادة إمكانية إضافة الخدمات.';
      
      case VerificationStatus.DEACTIVATED:
        return 'تم تعطيل حسابك. يرجى التواصل مع الدعم الفني لإعادة التفعيل.';
      
      default:
        return 'يجب التحقق من هويتك قبل إضافة الخدمات.';
    }
  }
}

/**
 * Guard بسيط للتحقق السريع (بدون جلب البيانات)
 * يستخدم للـ endpoints التي تحتاج فقط للتأكد من وجود حالة موثقة
 */
@Injectable()
export class SimpleVerificationGuard implements CanActivate {
  private readonly logger = new Logger(SimpleVerificationGuard.name);

  constructor(
    @InjectModel(ServiceProvider.name) 
    private providerModel: Model<ServiceProvider>,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const user = request.user;

    if (!user) {
      return false;
    }

    // المشرفين يمكنهم المرور دائماً
    if (user.role === 'admin') {
      return true;
    }

    // التحقق من أن المستخدم مزود خدمة موثق
    if (user.role === 'vendor') {
      const provider = await this.providerModel.findOne({
        userId: new Types.ObjectId(user._id || user.id),
        'verification.verificationStatus': VerificationStatus.VERIFIED,
      });

      if (provider) {
        // إضافة بيانات المزود للطلب للاستخدام لاحقاً
        request.provider = provider;
        return true;
      }
    }

    throw new ForbiddenException('غير مصرح لك بهذا الإجراء');
  }
}

/**
 * Decorator مركب للاستخدام مع الـ Guards
 */
export function VerifiedVendorOnly() {
  return function (
    target: any,
    propertyKey: string,
    descriptor: PropertyDescriptor,
  ) {
    RequireVerification()(target, propertyKey, descriptor);
    return descriptor;
  };
}
