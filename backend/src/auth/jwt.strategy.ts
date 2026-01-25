import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { User } from './user.entity';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    @InjectModel(User.name)
    private userModel: Model<User>,
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

    const user = await this.userModel.findById(payload.userId).exec();

    console.log('👤 Found User:', user);

    if (!user) {
      console.log('❌ User not found!');
      throw new UnauthorizedException('User not found');
    }

    // ✅ UPDATED: Include username in the returned object
    return {
      id: (user._id as Types.ObjectId).toString(),
      userId: (user._id as Types.ObjectId).toString(),
      email: user.email,
      role: user.role,
      username: user.userName,
    };
  }
}