// src/health/health.controller.ts
import { Controller, Get } from '@nestjs/common';

/**
 * Health Controller
 * Provides a simple health check endpoint for monitoring and keep-alive pings
 */
@Controller('health')
export class HealthController {
  
  @Get()
  check() {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      service: 'Eventry API',
    };
  }
}
