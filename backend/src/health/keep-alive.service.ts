// src/health/keep-alive.service.ts
import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';

/**
 * Keep-Alive Service
 * Prevents Render free tier from sleeping by pinging the health endpoint every 14 minutes
 * Only runs in production mode to avoid errors during local development
 */
@Injectable()
export class KeepAliveService implements OnModuleInit {
  private readonly logger = new Logger(KeepAliveService.name);
  private readonly serverUrl: string;
  private readonly isProduction: boolean;

  constructor(private readonly configService: ConfigService) {
    this.serverUrl = this.configService.get<string>('SERVER_URL') || '';
    this.isProduction = this.configService.get<string>('NODE_ENV') === 'production';
  }

  onModuleInit() {
    if (this.isProduction) {
      this.logger.log('🚀 Keep-Alive Service initialized for PRODUCTION');
      this.logger.log(`📍 Target URL: ${this.serverUrl}/health`);
    } else {
      this.logger.log('⏸️ Keep-Alive Service DISABLED (development mode)');
    }
  }

  /**
   * Cron job that runs every 14 minutes
   * Render free tier sleeps after 15 minutes of inactivity
   */
  @Cron('0 */14 * * * *') // Every 14 minutes
  async pingServer() {
    // Skip in development mode
    if (!this.isProduction) {
      return;
    }

    // Skip if no server URL configured
    if (!this.serverUrl) {
      this.logger.warn('⚠️ SERVER_URL not configured, skipping ping');
      return;
    }

    const healthUrl = `${this.serverUrl}/health`;
    
    try {
      this.logger.log(`🏓 Sending keep-alive ping to ${healthUrl}...`);
      
      const startTime = Date.now();
      const response = await axios.get(healthUrl, {
        timeout: 10000, // 10 second timeout
        headers: {
          'User-Agent': 'Eventry-KeepAlive/1.0',
        },
      });
      const duration = Date.now() - startTime;

      if (response.status === 200) {
        this.logger.log(`✅ Keep-alive ping SUCCESS (${duration}ms) - Status: ${response.data?.status || 'ok'}`);
      } else {
        this.logger.warn(`⚠️ Keep-alive ping returned unexpected status: ${response.status}`);
      }
    } catch (error) {
      this.logger.error(`❌ Keep-alive ping FAILED: ${error.message}`);
      
      // Log more details for debugging
      if (error.response) {
        this.logger.error(`   Response status: ${error.response.status}`);
      } else if (error.code) {
        this.logger.error(`   Error code: ${error.code}`);
      }
    }
  }

  /**
   * Manual ping method (can be called from other services if needed)
   */
  async manualPing(): Promise<boolean> {
    if (!this.serverUrl) {
      return false;
    }

    try {
      const response = await axios.get(`${this.serverUrl}/health`, { timeout: 10000 });
      return response.status === 200;
    } catch {
      return false;
    }
  }
}
