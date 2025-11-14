import { Module } from '@nestjs/common';
import { FirebaseController } from './firebase.controller';
import { FirebaseService } from './firebase.service';
import { FirebaseConfig } from './firebase.config';

@Module({
  controllers: [FirebaseController],
  providers: [FirebaseService, FirebaseConfig],
  exports: [FirebaseService],
})
export class FirebaseModule {}