import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './user.entity';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: 'your-secret-key-change-in-production',
    });
    console.log('✅ JwtStrategy initialized');
  }

  async validate(payload: any) {
    console.log('🔍 JWT Payload:', payload);

    const user = await this.userRepository.findOne({
      where: { id: payload.userId },
    });

    console.log('👤 Found User:', user);

    if (!user) {
      console.log('❌ User not found!');
      throw new UnauthorizedException('User not found');
    }

    // ✅ IMPORTANT: Include role in the returned object
    return {
      id: user.id,
      userId: user.id,
      email: user.email,
      role: user.role, // <-- Add this
    };
  }
}