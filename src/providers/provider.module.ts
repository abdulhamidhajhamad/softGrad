import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ProviderController } from './provider.controller';
import { ProviderService } from './provider.service';
import { ServiceProvider } from './provider.entity';
import { AuthModule } from '../auth/auth.module'; // ← Import AuthModule

@Module({
  imports: [
    TypeOrmModule.forFeature([ServiceProvider]),
    AuthModule, // ← Add this to share JWT authentication
  ],
  controllers: [ProviderController],
  providers: [ProviderService],
  exports: [ProviderService],
})
export class ProviderModule {}