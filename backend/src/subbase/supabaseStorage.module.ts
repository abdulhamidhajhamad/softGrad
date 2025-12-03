import { Module } from '@nestjs/common';
import { SupabaseStorageService } from './supabaseStorage.service';
import { ConfigModule } from '@nestjs/config'; 
@Module({
imports: [ConfigModule.forRoot()], 
  providers: [SupabaseStorageService],
  exports: [SupabaseStorageService],
})
export class SupabaseStorageModule {}