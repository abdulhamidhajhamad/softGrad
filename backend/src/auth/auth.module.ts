import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { MongooseModule } from '@nestjs/mongoose';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { User, UserSchema } from './user.entity';
import { JwtStrategy } from './jwt.strategy';
import { MailService } from './mail.service';
import { SupabaseStorageModule } from '../subbase/supabaseStorage.module';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: User.name, schema: UserSchema }]),
    PassportModule.register({ defaultStrategy: 'jwt' }),
    JwtModule.register({
      secret: 'your-secret-key-change-in-production',
      signOptions: { expiresIn: '24h' },
    }),
    SupabaseStorageModule, 
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtStrategy, MailService],
  exports: [
    JwtStrategy, 
    PassportModule, 
    JwtModule,
    MongooseModule,
  ],
})
export class AuthModule {}