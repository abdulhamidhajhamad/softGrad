import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Enable CORS
  app.enableCors({
    origin: true, // Allow all origins during development
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
    credentials: true,
  });

  // Global validation pipe
  app.useGlobalPipes(new ValidationPipe({
    transform: true,  // ← هذا يحول النصوص إلى أرقام تلقائياً
    whitelist: true,  // ← يسمح فقط بالحقول المحددة في DTO
    forbidNonWhitelisted: true,  // ← يرفض الحقول الإضافية
  }));
  // Listen on all network interfaces with explicit configuration
  const port = 3000;
  const host = '0.0.0.0'; // Listen on all network interfaces
  
  await app.listen(port, host);
  console.log(`🚀 Application is running on: http://localhost:${port}`);
  console.log(`🚀 Application is running on: http://192.168.110.14:${port}`);
  
  // Test if we can get the actual IP (fixed variable names)
  const os = require('os');
  const networkInterfaces = os.networkInterfaces();
  Object.keys(networkInterfaces).forEach(interfaceName => {
    networkInterfaces[interfaceName].forEach((netInterface: any) => {  // Changed to netInterface
      if (netInterface.family === 'IPv4' && !netInterface.internal) {  // Fixed variable name here
        console.log(`🚀 Application is running on: http://${netInterface.address}:${port}`);
      }
    });
  });
}
bootstrap();