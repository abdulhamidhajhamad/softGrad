// src/health/health.module.ts
import { Module } from '@nestjs/common';
import { HealthController } from './health.controller';
import { KeepAliveService } from './keep-alive.service';

/**
 * Health Module
 * Provides health check endpoint and keep-alive cron job
 */
@Module({
  controllers: [HealthController],
  providers: [KeepAliveService],
  exports: [KeepAliveService],
})
export class HealthModule {}
