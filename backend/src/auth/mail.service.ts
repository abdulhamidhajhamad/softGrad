import { Injectable } from '@nestjs/common';
import * as nodemailer from 'nodemailer';

@Injectable()
export class MailService {
  private transporter;

  constructor() {
    const isDevelopment = process.env.NODE_ENV === 'development';
    
    const transporterConfig: any = {
      host: process.env.MAIL_HOST || 'smtp.gmail.com',
      // ✅ FIX: استخدام علامة (!) لضمان أن القيمة string عند قراءتها
      port: parseInt(process.env.MAIL_PORT!) || 587,
      secure: process.env.MAIL_PORT === '465', // true for 465, false for other ports
      auth: {
        user: process.env.MAIL_USER!, // 👈 Fix: Non-Null assertion
        pass: process.env.MAIL_PASSWORD!, // 👈 Fix: Non-Null assertion
      },
    };

    // Only disable certificate verification in development
    if (isDevelopment) {
      transporterConfig.tls = {
        rejectUnauthorized: false,
      };
      console.log('🔐 Development mode: SSL certificate verification disabled');
    }
    // In production, let it use default SSL verification (secure)

    this.transporter = nodemailer.createTransport(transporterConfig);
    
    // Verify transporter configuration
    this.verifyTransporter();
  }

  private async verifyTransporter(): Promise<void> {
    try {
      await this.transporter.verify();
      console.log('✅ Mail transporter is ready');
    } catch (error) {
      console.error('❌ Mail transporter verification failed:', error);
    }
  }

  // =============================================================
  // 🌟 NEW: وظيفة إرسال بريد إلكتروني بمحتوى HTML عام
  // =============================================================
  async sendHtmlEmail(to: string, subject: string, htmlContent: string): Promise<void> {
    const mailOptions = {
      from: process.env.MAIL_FROM || 'noreply@example.com',
      to: to,
      subject: subject,
      html: htmlContent,
    };
    
    try {
      await this.transporter.sendMail(mailOptions);
    } catch (error) {
      console.error(`❌ Failed to send HTML email to ${to}:`, error);
      // إعادة إطلاق الخطأ لـ Bull ليتمكن من معالجة الفشل
      throw new Error(`Failed to send HTML email: ${error.message}`);
    }
  }


  async sendVerificationEmail(email: string, code: string): Promise<void> {
    const mailOptions = {
      from: process.env.MAIL_FROM || 'noreply@example.com',
      to: email,
      subject: 'Verify your email address',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #333;">Email Verification</h2>
          <p>Thank you for signing up! Please use the following code to verify your email address:</p>
          <div style="background-color: #f0f8ff; padding: 15px; text-align: center; border-radius: 5px; margin: 20px 0;">
            <strong style="font-size: 24px; color: #007bff;">${code}</strong>
          </div>
          <p>This code will expire shortly.</p>
          <p>If you didn't create an account, please ignore this email.</p>
        </div>
      `,
    };

    try {
      await this.transporter.sendMail(mailOptions);
      console.log('✅ Verification email sent to:', email);
    } catch (error) {
      console.error('❌ Error sending verification email:', error);
      throw new Error('Failed to send verification email');
    }
  }

  async sendPasswordResetEmail(email: string, resetUrl: string): Promise<void> {
    const mailOptions = {
      from: process.env.MAIL_FROM || 'noreply@example.com',
      to: email,
      subject: 'Password Reset Request',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #333;">Password Reset Request</h2>
          <p>You requested to reset your password. Click the link below to reset your password:</p>
          <a href="${resetUrl}" style="display: inline-block; padding: 10px 20px; margin: 20px 0; background-color: #007bff; color: white; text-decoration: none; border-radius: 5px;">Reset Password</a>
          <p>If you didn't request this, please ignore this email.</p>
          <p>This link will expire in 1 hour.</p>
          <hr style="border: 1px solid #eee; margin: 20px 0;">
          <p style="color: #666; font-size: 12px;">If the button doesn't work, copy and paste this URL into your browser:</p>
          <p style="color: #666; font-size: 12px;">${resetUrl}</p>
        </div>
      `,
    };

    try {
      await this.transporter.sendMail(mailOptions);
      console.log('✅ Password reset email sent to:', email);
    } catch (error) {
      console.error('❌ Error sending password reset email:', error);
      throw new Error('Failed to send password reset email');
    }
  }
}