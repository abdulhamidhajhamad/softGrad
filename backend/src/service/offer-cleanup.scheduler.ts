import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { ServiceService } from './service.service';

/**
 * ✅ Scheduled job to automatically cleanup expired offers
 * Runs every day at midnight (00:00)
 */
@Injectable()
export class OfferCleanupScheduler {
  private readonly logger = new Logger(OfferCleanupScheduler.name);

  constructor(private readonly serviceService: ServiceService) {}

  /**
   * Run every day at midnight to cleanup expired offers
   */
  @Cron(CronExpression.EVERY_DAY_AT_MIDNIGHT)
  async handleExpiredOffersCleanup() {
    this.logger.log('🔄 Starting scheduled cleanup of expired offers...');
    
    try {
      const cleanedCount = await this.serviceService.cleanupExpiredOffers();
      
      if (cleanedCount > 0) {
        this.logger.log(`✅ Successfully cleaned up ${cleanedCount} expired offers`);
      } else {
        this.logger.log('✅ No expired offers to cleanup');
      }
    } catch (error) {
      this.logger.error('❌ Failed to cleanup expired offers:', error.message);
    }
  }

  /**
   * Also run every hour to catch recently expired offers
   * (Optional - for more frequent cleanup)
   */
  @Cron(CronExpression.EVERY_HOUR)
  async handleHourlyCheck() {
    this.logger.debug('🔍 Hourly check for expired offers...');
    
    try {
      const cleanedCount = await this.serviceService.cleanupExpiredOffers();
      
      if (cleanedCount > 0) {
        this.logger.log(`⏰ Hourly cleanup: removed ${cleanedCount} expired offers`);
      }
    } catch (error) {
      this.logger.error('❌ Hourly cleanup failed:', error.message);
    }
  }
}
