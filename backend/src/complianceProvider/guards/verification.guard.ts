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
 * Decorator to verify verification status
 */
export const RequireVerification = () => {
  return (target: any, key?: string, descriptor?: PropertyDescriptor) => {
    Reflect.defineMetadata('requireVerification', true, descriptor?.value || target);
    return descriptor || target;
  };
};

/**
 * Guard to verify that provider is verified before allowing service creation
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
    // Check if the endpoint requires verification
    const requireVerification = this.reflector.get<boolean>(
      'requireVerification',
      context.getHandler(),
    );

    // If not required, allow passage
    if (!requireVerification) {
      return true;
    }

    const request = context.switchToHttp().getRequest();
    const user = request.user;

    if (!user) {
      throw new ForbiddenException('You must be logged in first');
    }

    // Admins can always pass
    if (user.role === 'admin') {
      return true;
    }

    // Check if user is a service provider
    if (user.role !== 'vendor') {
      throw new ForbiddenException('This feature is available for providers only');
    }

    // Get provider data
    const provider = await this.providerModel.findOne({
      userId: new Types.ObjectId(user._id || user.id),
    });

    if (!provider) {
      throw new ForbiddenException(
        'You must complete your provider profile before adding services'
      );
    }

    const verificationStatus = provider.verification?.verificationStatus;

    // Check verification status
    if (verificationStatus !== VerificationStatus.VERIFIED) {
      const message = this.getStatusMessage(verificationStatus);
      this.logger.warn(
        `🚫 Unauthorized access attempt - Provider: ${provider._id}, Status: ${verificationStatus}`
      );
      throw new ForbiddenException(message);
    }

    // Check document validity
    const expiryDate = provider.verification?.licenseExpiryDate;
    if (expiryDate && new Date(expiryDate) < new Date()) {
      this.logger.warn(
        `🚫 Expired document - Provider: ${provider._id}`
      );
      throw new ForbiddenException(
        'Your documents have expired. Please renew them to continue adding services.'
      );
    }

    return true;
  }

  /**
   * Returns appropriate message based on verification status
   */
  private getStatusMessage(status?: VerificationStatus): string {
    switch (status) {
      case VerificationStatus.PENDING:
        return 'You must upload verification documents before adding services. Please upload your ID or business license.';
      
      case VerificationStatus.UNDER_REVIEW:
        return 'Your documents are under review. You will be notified once verification is complete.';
      
      case VerificationStatus.ADMIN_REVIEW:
        return 'Your documents are under manual review by our support team. You will be notified of the result soon.';
      
      case VerificationStatus.REJECTED:
        return 'Your documents were rejected. Please check the rejection reason and upload valid documents.';
      
      case VerificationStatus.EXPIRED:
        return 'Your documents have expired. Please renew them to continue adding services.';
      
      case VerificationStatus.DEACTIVATED:
        return 'Your account has been deactivated. Please contact support to reactivate.';
      
      default:
        return 'You must verify your identity before adding services.';
    }
  }
}

/**
 * Simple guard for quick verification check (without fetching data)
 * Used for endpoints that only need to confirm verified status exists
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

    // Admins can always pass
    if (user.role === 'admin') {
      return true;
    }

    // Check if user is a verified service provider
    if (user.role === 'vendor') {
      const provider = await this.providerModel.findOne({
        userId: new Types.ObjectId(user._id || user.id),
        'verification.verificationStatus': VerificationStatus.VERIFIED,
      });

      if (provider) {
        // Add provider data to request for later use
        request.provider = provider;
        return true;
      }
    }

    throw new ForbiddenException('You are not authorized to perform this action');
  }
}

/**
 * Compound decorator for use with Guards
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
