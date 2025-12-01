import { 
  Injectable, 
  ConflictException, 
  UnauthorizedException, 
  NotFoundException, 
  BadRequestException,  
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { User } from './user.entity';
import { 
  SignUpDto, 
  LoginDto, 
  VerifyEmailDto,
  ResendVerificationDto 
} from './auth.dto';
import { MailService } from './mail.service';
import { SupabaseStorageService } from '../subbase/supabaseStorage.service';
import * as crypto from 'crypto';
import { PasswordResetToken } from './password-reset-token.schema'; 
@Injectable()
export class AuthService {
  private verificationCodes = new Map<string, { code: string; expires: Date }>();
  constructor(
    @InjectModel(User.name)
    private userModel: Model<User>,
    @InjectModel(PasswordResetToken.name)
    private passwordResetTokenModel: Model<PasswordResetToken>,

    private jwtService: JwtService,
    private mailService: MailService,
    private supabaseStorage: SupabaseStorageService,
  ) {}
  private generateVerificationCode(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }

  private generateDefaultAvatar(userName: string): string {
    const initials = this.getUserInitials(userName);
    return `https://ui-avatars.com/api/?name=${encodeURIComponent(initials)}&background=0D8ABC&color=fff&size=128`;
  }

  private getUserInitials(userName: string): string {
    if (!userName) return 'U';
    const names = userName.trim().split(/\s+/);
    if (names.length === 1) {
      return userName.substring(0, 2).toUpperCase();
    } else {
      return (names[0].charAt(0) + names[names.length - 1].charAt(0)).toUpperCase();
    }
  }

  async signUp(
    signUpDto: SignUpDto, 
    file?: Express.Multer.File
  ): Promise<{ message: string; email: string; imageUrl?: string }> {
    const { userName, email, password, phone, city, role  } = signUpDto;
    
    const existingUser = await this.userModel.findOne({ email }).exec();
    if (existingUser) {
      throw new ConflictException('Email already exists');
    }
    
    const hashedPassword = await bcrypt.hash(password, 10);
    
    const verificationCode = this.generateVerificationCode();
    const verificationCodeExpires = new Date(Date.now() + 15 * 60 * 1000);
    
    let imageUrl: string;

    if (file) {
      try {
        console.log('📤 Uploading image to Supabase...');
        imageUrl = await this.supabaseStorage.uploadImage(file, 'users', true);
        console.log('✅ Image uploaded successfully:', imageUrl);
      } catch (error) {
        console.error('❌ Supabase upload failed, using default avatar:', error);
        imageUrl = this.generateDefaultAvatar(userName);
      }
    } else {
      imageUrl = this.generateDefaultAvatar(userName);
      console.log('🖼️ Using default avatar');
    }

    // Store verification code in memory
    this.verificationCodes.set(email, {
      code: verificationCode,
      expires: verificationCodeExpires
    });

    const user = new this.userModel({
      userName,
      email,
      password: hashedPassword,
      phone,
      city,
      role,
      imageUrl,
      isVerified: false,
      // ❌ REMOVED: verificationCode and verificationCodeExpires from user document
    });

    await user.save();
    console.log('👤 User created with image:', imageUrl);

    // إرسال email التحقق
    try {
      await this.mailService.sendVerificationEmail(email, verificationCode);
    } catch (error) {
      console.error('Failed to send verification email:', error);
    }

    return {
      message: 'User registered successfully. Please check your email for verification code.',
      email: user.email,
      imageUrl: imageUrl,
    };
  }

  // ✅ Verify email with code (using in-memory storage)
  async verifyEmail(verifyEmailDto: VerifyEmailDto): Promise<{ token: string; user: any }> {
    const { email, verificationCode } = verifyEmailDto;

    // Find user by email
    const user = await this.userModel.findOne({ email }).exec();
    
    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Check if already verified
    if (user.isVerified) {
      throw new BadRequestException('Email is already verified');
    }

    // Check if verification code exists in memory
    const storedCode = this.verificationCodes.get(email);
    if (!storedCode) {
      throw new BadRequestException('No verification code found. Please request a new one.');
    }

    // Check if code has expired
    if (new Date() > storedCode.expires) {
      this.verificationCodes.delete(email); // Clean up expired code
      throw new BadRequestException('Verification code has expired. Please request a new one.');
    }

    // Verify code matches
    if (storedCode.code !== verificationCode) {
      throw new BadRequestException('Invalid verification code');
    }

    // Mark user as verified
    user.isVerified = true;
    await user.save();

    // Remove used verification code
    this.verificationCodes.delete(email);

    // Generate JWT token
    const token = this.jwtService.sign({ 
      userId: (user._id as Types.ObjectId).toString(), 
      email: user.email 
    });
    
    // Return user without sensitive data
    const userObject = user.toObject();
    const { password, ...userWithoutPassword } = userObject;
    
    return {
      token,
      user: userWithoutPassword,
    };
  }

  // ✅ Resend verification code
  async resendVerificationCode(resendVerificationDto: ResendVerificationDto): Promise<{ message: string }> {
    const { email } = resendVerificationDto;

    // Find user by email
    const user = await this.userModel.findOne({ email }).exec();
    
    if (!user) {
      // Don't reveal if email exists or not for security
      return { message: 'If the email exists and is not verified, a new code has been sent.' };
    }

    // Check if already verified
    if (user.isVerified) {
      throw new BadRequestException('Email is already verified');
    }

    // Generate new verification code and expiration
    const verificationCode = this.generateVerificationCode();
    const verificationCodeExpires = new Date(Date.now() + 15 * 60 * 1000); // 15 minutes

    // Store new code in memory
    this.verificationCodes.set(email, {
      code: verificationCode,
      expires: verificationCodeExpires
    });

    // Send verification email
    try {
      await this.mailService.sendVerificationEmail(email, verificationCode);
    } catch (error) {
      console.error('Failed to send verification email:', error);
      throw new BadRequestException('Failed to send verification email. Please try again.');
    }

    return {
      message: 'A new verification code has been sent to your email.',
    };
  }

  async login(loginDto: LoginDto): Promise<{ token: string; user: any }> {
    const { email, password } = loginDto;
    
    const user = await this.userModel.findOne({ email }).exec();
    if (!user) {
      throw new UnauthorizedException('Invalid Email/Pass');
    }

    // ✅ Check if email is verified
    if (!user.isVerified) {
      throw new UnauthorizedException('Please verify your email before logging in');
    }
    
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid Email/Pass');
    }
    
    const token = this.jwtService.sign({ 
      userId: (user._id as Types.ObjectId).toString(), 
      email: user.email 
    });
    
    const userObject = user.toObject();
    const { password: _, ...userWithoutPassword } = userObject;
    return {
      token,
      user: userWithoutPassword,
    };
  }

  // ✅ Update user profile with image handling
  async updateProfile(
    userId: string,
    updateData: Partial<{
      userName: string;
      phone: string;
      city: string;
    }>,
    file?: Express.Multer.File
  ): Promise<{ message: string; user: any }> {
    const user = await this.userModel.findById(userId).exec();
    
    if (!user) {
      throw new NotFoundException('User not found');
    }

    let imageUrl = user.imageUrl;

    if (file) {
      try {
        console.log('📤 Uploading new image to Supabase...');
        
        if (user.imageUrl && !user.imageUrl.includes('ui-avatars.com')) {
          console.log('🗑️ Deleting old image:', user.imageUrl);
          await this.supabaseStorage.deleteImage(user.imageUrl);
        }
        
        imageUrl = await this.supabaseStorage.uploadImage(file, 'users', true);
        console.log('✅ New image uploaded successfully:', imageUrl);
      } catch (error) {
        console.error('❌ Supabase upload failed:', error);
        throw new BadRequestException('Failed to upload image');
      }
    }

    if (updateData.userName) user.userName = updateData.userName;
    if (updateData.phone) user.phone = updateData.phone;
    if (updateData.city) user.city = updateData.city;
    user.imageUrl = imageUrl;

    await user.save();

    const userObject = user.toObject();
    const { password, ...userWithoutPassword } = userObject;

    return {
      message: 'Profile updated successfully',
      user: userWithoutPassword,
    };
  }

  // Clean up expired verification codes (call this periodically)
  cleanupExpiredVerificationCodes(): void {
    const now = new Date();
    for (const [email, data] of this.verificationCodes.entries()) {
      if (now > data.expires) {
        this.verificationCodes.delete(email);
      }
    }
  }


async forgotPassword(email: string) {
  const user = await this.userModel.findOne({ email });
  if (!user) {
    console.log('❌ User not found for email:', email);
    return { message: 'If this email exists, a reset link has been sent.' };
  }

  console.log('✅ User found:', user.email);

  // إنشاء التوكن
  const token = crypto.randomBytes(32).toString('hex');
  console.log('🔑 Original token:', token);

  // حساب الـ hash بشكل صحيح
  const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
  console.log('🔑 Token hash:', tokenHash);

  // التأكد من عدم وجود مسافات أو أخطاء
  if (tokenHash.includes(' ')) {
    console.error('❌ ERROR: Token hash contains spaces!');
  }

  const expiresAt = new Date(Date.now() + 15 * 60 * 1000);

  // حفظ في قاعدة البيانات
  await this.passwordResetTokenModel.create({
    email,
    tokenHash,
    expiresAt
  });

  console.log('💾 Token saved to database successfully');

  // لأغراض الت testing - إرجاع التوكن في ال response
  return { 
    message: 'If this email exists, a reset link has been sent.',
    debug_token: token // ✅ إرجاع التوكن للتجربة
  };
}

async verifyResetToken(token: string, email: string) {
  console.log('🔍 Verifying token for email:', email);
  console.log('🔑 Original token received:', token);
  
  // تنظيف التوكن من أي مسافات
  const cleanToken = token.trim().replace(/\s+/g, '');
  console.log('🔑 Cleaned token:', cleanToken);

  const tokenHash = crypto.createHash('sha256').update(cleanToken).digest('hex');
  console.log('🔑 Calculated hash:', tokenHash);

  // فحص جميع التوكنات لهذا البريد (للتشخيص)
  const allTokens = await this.passwordResetTokenModel.find({ email });
  console.log('📋 All tokens in DB for this email:', allTokens);

  const record = await this.passwordResetTokenModel.findOne({
    email,
    tokenHash,
    expiresAt: { $gt: new Date() }
  });

  if (!record) {
    console.log('❌ No matching token found');
    console.log('⏰ Current time:', new Date());
    const expiredRecord = await this.passwordResetTokenModel.findOne({
      email,
      tokenHash
    });
    if (expiredRecord) {
      console.log('⏰ Found expired token:', expiredRecord.expiresAt);
    }
    
    throw new BadRequestException('Invalid or expired token');
  }

  console.log('✅ Token is valid');
  return { valid: true };
}



  async resetPassword(email: string, token: string, newPassword: string) {
  const tokenHash = crypto.createHash('sha256').update(token).digest('hex');

  const record = await this.passwordResetTokenModel.findOne({
    email,
    tokenHash,
    expiresAt: { $gt: new Date() }
  });

  if (!record)
    throw new BadRequestException('Invalid or expired token');

  // hash new password
  const hashedPassword = await bcrypt.hash(newPassword, 12);

  // update user password
  await this.userModel.updateOne(
    { email },
    { $set: { password: hashedPassword } }
  );

  // حذف التوكن
  await this.passwordResetTokenModel.deleteMany({ email });

  return { message: 'Password has been reset successfully.' };
}

async getUserProfile(userId: string): Promise<{
  userName: string;
  email: string;
  phone?: string;
  city?: string;
  imageUrl?: string;
}> {
  const user = await this.userModel.findById(userId).exec();
  
  if (!user) {
    throw new NotFoundException('User not found');
  }

  return {
    userName: user.userName,
    email: user.email,
    phone: user.phone,
    city: user.city,
    imageUrl: user.imageUrl
  };
}

}