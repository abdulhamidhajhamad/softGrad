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
  ResendVerificationDto, 
  ResetPasswordDto
} from './auth.dto';
import { MailService } from './mail.service';
import { SupabaseStorageService } from '../subbase/supabaseStorage.service';
import * as crypto from 'crypto';
import { PasswordResetToken } from './password-reset-token.schema'; 
import { UpdateFCMTokenDto } from './auth.dto'; // Need to create this DTO
import { AdminStats } from '../admin/admin-stats.schema';

@Injectable()
export class AuthService {
  private verificationCodes = new Map<string, { code: string; expires: Date }>();
  constructor(
    @InjectModel(User.name)
    private userModel: Model<User>,
    @InjectModel(PasswordResetToken.name)
    private passwordResetTokenModel: Model<PasswordResetToken>,
    @InjectModel(AdminStats.name) 
    private adminStatsModel: Model<AdminStats>,
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
    await this.incrementStats(signUpDto.role || 'user');

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

  private async incrementStats(userRole: string): Promise<void> {
    try {
      // البحث عن الإحصائيات أو إنشاء جديدة
      let stats = await this.adminStatsModel.findOne();
      
      if (!stats) {
        stats = new this.adminStatsModel({
          totalUsers: 0,
          totalVendors: 0,
          totalSales: 0
        });
      }

      // زيادة العداد المناسب
      if (userRole === 'user' || userRole === 'USER') {
        stats.totalUsers += 1;
      } else if (userRole === 'vendor' || userRole === 'VENDOR') {
        stats.totalVendors += 1;
      }

      stats.lastUpdated = new Date();
      await stats.save();
      
      console.log(`📊 Stats updated - Users: ${stats.totalUsers}, Vendors: ${stats.totalVendors}`);
    } catch (error) {
      console.error('❌ Failed to update stats:', error);
    }
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
      email: user.email ,
      username: user.userName // ADD THIS LINE

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
    const { email, password, fcmToken } = loginDto; // 👈 تم إضافة fcmToken
    
    const user = await this.userModel.findOne({ email }).exec();
    if (!user) {
      throw new UnauthorizedException('Invalid Email/Pass');
    }

    // Check if email is verified
    if (!user.isVerified) {
      throw new UnauthorizedException('Please verify your email before logging in');
    }
    
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid Email/Pass');
    }

   if (fcmToken) {
      // الخطوة 1: حذف الرمز من أي مستخدم آخر يحمله لضمان فرادته (unique)
      await this.userModel.updateOne(
        { fcmToken },
        { $unset: { fcmToken: 1 } }
      ).exec();

      // الخطوة 2: تحديث رمز المستخدم الحالي
      user.fcmToken = fcmToken;
      await user.save();
      console.log(`FCM Token updated upon login for user: ${user.email}`);
    }
    
    const token = this.jwtService.sign({ 
      userId: (user._id as Types.ObjectId).toString(), 
      email: user.email,
          username: user.userName 
 
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
      // 🆕 الحقول الجديدة لكلمة المرور
      currentPassword?: string; 
      newPassword?: string;
      confirmNewPassword?: string;
    }>,
    file?: Express.Multer.File
  ): Promise<{ message: string; user: any; newToken?: string }> {
    const user = await this.userModel.findById(userId).exec();
    
    if (!user) {
      throw new NotFoundException('User not found');
    }
    
    // ----------------------------------------------------------------
    // 🛑 منطق التحقق من كلمة المرور الجديدة
    // ----------------------------------------------------------------
    // فصل حقول كلمة المرور عن باقي بيانات الملف الشخصي (profileData)
    const { currentPassword, newPassword, confirmNewPassword, ...profileData } = updateData; 

    if (newPassword || currentPassword || confirmNewPassword) {
      // 1. يجب أن تكون جميع الحقول موجودة لتغيير كلمة المرور
      if (!currentPassword || !newPassword || !confirmNewPassword) {
        throw new BadRequestException('Current password, new password, and confirmation are all required to change password.');
      }

      // 2. التحقق من تطابق كلمة المرور الجديدة وتأكيدها
      if (newPassword !== confirmNewPassword) {
        throw new BadRequestException('New password and confirmation do not match.');
      }
      
      // 3. التحقق من صحة كلمة المرور الحالية
      const isPasswordValid = await bcrypt.compare(currentPassword, user.password);
      if (!isPasswordValid) {
        throw new UnauthorizedException('Current password is not correct.');
      }
      
      // 4. تشفير وتحديث كلمة المرور
      const hashedPassword = await bcrypt.hash(newPassword, 10);
      user.password = hashedPassword;
      console.log(`Password updated for user: ${user.email}`);
    } // 👈 القوس الناقص الذي كان يسبب خطأ التجميع
    // ----------------------------------------------------------------
    
    // منطق تحديث الصورة والحقول الأخرى
    let imageUrl = user.imageUrl; 

    if (file) {
      try {
        console.log('📤 Uploading new image to Supabase...');
        
        // حذف الصورة القديمة إذا لم تكن الصورة الافتراضية
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

    // 🛑 استخدام profileData لتحديث باقي الحقول (لأن حقول كلمة المرور تم فصلها في الأعلى)
    if (profileData.userName) user.userName = profileData.userName;
    if (profileData.phone) user.phone = profileData.phone;
    if (profileData.city) user.city = profileData.city;
    user.imageUrl = imageUrl;

    await user.save();

    const userObject = user.toObject();
    const { password: _, ...userWithoutPassword } = userObject;

    return {
      message: 'Profile updated successfully',
      user: userWithoutPassword,
    };
  }


async forgotPassword(email: string) {
 const user = await this.userModel.findOne({ email });
  if (!user) {
    return { message: 'If this email exists, a reset link has been sent.' };
  }
  await this.passwordResetTokenModel.deleteMany({ email });
  const token = crypto.randomBytes(32).toString('hex');
  const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
  const expiresAt = new Date(Date.now() + 15 * 60 * 1000); 
  await this.passwordResetTokenModel.create({
    email,
    tokenHash,
    expiresAt
  });

  const frontendBaseUrl = process.env.FRONTEND_URL || 'http://localhost:3001'; 
  const resetUrl = `${frontendBaseUrl}/reset-password?token=${token}&email=${email}`;

  try {
    await this.mailService.sendPasswordResetEmail(email, resetUrl);
    console.log(`✅ Password reset email sent to: ${email}`);
  } catch (error) {
    console.error('❌ Error sending reset email:', error);
    throw new BadRequestException('Failed to send reset email, please try again later.');
  }

  return { 
    message: 'If this email exists, a reset link has been sent.' 
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



async resetPassword(resetData: ResetPasswordDto) {
  const { email, token, newPassword, confirmPassword } = resetData;

  // 1. 🔥 التحقق من تطابق كلمتي السر في الباك إند
  if (newPassword !== confirmPassword) {
    throw new BadRequestException('Passwords do not match');
  }

  // 2. التحقق من صحة التوكن (Hash comparison)
  const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
  const storedToken = await this.passwordResetTokenModel.findOne({
    email,
    tokenHash,
    expiresAt: { $gt: new Date() }, // تأكد أنه لم ينتهِ
  });

  if (!storedToken) {
    throw new BadRequestException('Invalid or expired reset token');
  }

  // 3. تحديث كلمة السر للمستخدم
  const hashedPassword = await bcrypt.hash(newPassword, 10);
  const user = await this.userModel.findOneAndUpdate(
    { email },
    { password: hashedPassword },
    { new: true }
  );

  if (!user) {
    throw new NotFoundException('User not found');
  }

  // 4. 🔥 مسح التوكن بعد الاستخدام الناجح (أفضل ممارسة)
  await this.passwordResetTokenModel.deleteMany({ email });

  return { message: 'Password has been reset successfully' };
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

// ✅ NEW METHOD: Update user's FCM Token
  async updateFCMToken(userId: string, token: string): Promise<void> {
    // Find the user by ID
    const user = await this.userModel.findById(userId).exec();
    if (!user) {
      throw new NotFoundException('User not found');
    }
    
    // Set or update the token
    user.fcmToken = token;
    await user.save();
    console.log(`FCM Token updated for user ${userId}`);
  }

async generateToken(user: any): Promise<string> {
    const payload = { 
        email: user.email, 
        userId: user._id, 
        role: user.role,
        username: user.userName // ADD THIS LINE

    };
    return this.jwtService.sign(payload);
  }


  async toggleFavoriteService(userId: string, serviceId: string): Promise<Types.ObjectId[]> {
  const user = await this.userModel.findById(userId);
  if (!user) throw new NotFoundException('User not found');

  const sId = new Types.ObjectId(serviceId);
  const index = user.favoriteServices.indexOf(sId);

  if (index > -1) {
    // إذا كان موجوداً، نقوم بحذفه
    user.favoriteServices.splice(index, 1);
  } else {
    // إذا لم يكن موجوداً، نقوم بإضافته
    user.favoriteServices.push(sId);
  }

  await user.save();
  return user.favoriteServices;
}

async toggleFavoritePackage(userId: string, packageId: string): Promise<Types.ObjectId[]> {
  const user = await this.userModel.findById(userId);
  if (!user) throw new NotFoundException('User not found');

  const pId = new Types.ObjectId(packageId);
  const index = user.favoritePackages.indexOf(pId);

  if (index > -1) {
    user.favoritePackages.splice(index, 1);
  } else {
    user.favoritePackages.push(pId);
  }

  await user.save();
  return user.favoritePackages;
}

async getUserFavorites(userId: string): Promise<{ favoriteServices: any[]; favoritePackages: any[] }> {
  const user = await this.userModel.findById(userId)
    .select('favoriteServices favoritePackages -_id')
    .exec();

  if (!user) {
    throw new NotFoundException('User not found'); //
  }

  return {
    favoriteServices: user.favoriteServices || [],
    favoritePackages: user.favoritePackages || []
  };
}
}