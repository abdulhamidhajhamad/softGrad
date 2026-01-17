import { Injectable } from '@nestjs/common';
import * as nodemailer from 'nodemailer';

@Injectable()
export class MailService {
  private transporter;

  constructor() {
    const isDevelopment = process.env.NODE_ENV === 'development';
    
    const transporterConfig: any = {
      host: process.env.MAIL_HOST || 'smtp.gmail.com',
      port: parseInt(process.env.MAIL_PORT!) || 587,
      secure: process.env.MAIL_PORT === '465',
      auth: {
        user: process.env.MAIL_USER!,
        pass: process.env.MAIL_PASSWORD!,
      },
    };

    if (isDevelopment) {
      transporterConfig.tls = {
        rejectUnauthorized: false,
      };
      console.log('🔐 Development mode: SSL certificate verification disabled');
    }

    this.transporter = nodemailer.createTransport(transporterConfig);
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
  // 🎨 MODERN EMAIL TEMPLATE BASE
  // =============================================================
  private getEmailTemplate(title: string, content: string): string {
    return `
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>${title}</title>
        <style>
          * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
          }
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            background-color: #f5f5f5;
            padding: 20px;
            line-height: 1.6;
          }
          .email-container {
            max-width: 600px;
            margin: 0 auto;
            background-color: #ffffff;
            border-radius: 16px;
            overflow: hidden;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
          }
          .header {
            background: linear-gradient(135deg, rgba(20, 20, 215, 0.95) 0%, rgba(43, 123, 233, 0.95) 100%);
            padding: 40px 30px;
            text-align: center;
            color: white;
          }
          .header-icon {
            width: 80px;
            height: 80px;
            background: rgba(255, 255, 255, 0.2);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 20px;
            backdrop-filter: blur(10px);
          }
          .header h1 {
            font-size: 28px;
            font-weight: 700;
            margin: 0;
            letter-spacing: -0.5px;
          }
          .content {
            padding: 40px 30px;
          }
          .greeting {
            font-size: 18px;
            color: #1A1A2E;
            margin-bottom: 20px;
            font-weight: 600;
          }
          .message {
            font-size: 15px;
            color: #666;
            margin-bottom: 30px;
            line-height: 1.8;
          }
          .code-container {
            background: linear-gradient(135deg, #f0f8ff 0%, #e6f3ff 100%);
            border: 2px dashed rgba(20, 20, 215, 0.3);
            border-radius: 12px;
            padding: 30px;
            text-align: center;
            margin: 30px 0;
          }
          .code-label {
            font-size: 13px;
            color: #666;
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-bottom: 15px;
            font-weight: 600;
          }
          .code {
            font-size: 36px;
            font-weight: 700;
            color: rgba(20, 20, 215, 1);
            letter-spacing: 8px;
            font-family: 'Courier New', monospace;
          }
          .button-container {
            text-align: center;
            margin: 30px 0;
          }
          .button {
            display: inline-block;
            padding: 16px 40px;
            background: linear-gradient(135deg, rgba(20, 20, 215, 1) 0%, rgba(43, 123, 233, 1) 100%);
            color: white;
            text-decoration: none;
            border-radius: 12px;
            font-weight: 600;
            font-size: 16px;
            transition: all 0.3s ease;
            box-shadow: 0 4px 15px rgba(20, 20, 215, 0.3);
          }
          .info-box {
            background: #fff9e6;
            border-left: 4px solid #ffc107;
            border-radius: 8px;
            padding: 20px;
            margin: 25px 0;
            display: flex;
            align-items: start;
          }
          .info-icon {
            font-size: 24px;
            margin-right: 15px;
            color: #f57c00;
          }
          .info-text {
            font-size: 14px;
            color: #666;
            line-height: 1.6;
          }
          .footer {
            background: #f8f9fa;
            padding: 30px;
            text-align: center;
            border-top: 1px solid #e9ecef;
          }
          .footer-text {
            font-size: 13px;
            color: #999;
            margin-bottom: 15px;
          }
          .footer-links {
            font-size: 13px;
            color: rgba(20, 20, 215, 1);
            text-decoration: none;
            margin: 0 10px;
          }
          .divider {
            height: 1px;
            background: linear-gradient(to right, transparent, #e0e0e0, transparent);
            margin: 30px 0;
          }
          .security-badge {
            display: inline-flex;
            align-items: center;
            background: #e8f5e9;
            color: #2e7d32;
            padding: 8px 16px;
            border-radius: 20px;
            font-size: 13px;
            font-weight: 600;
            margin-top: 20px;
          }
          .security-icon {
            margin-right: 8px;
            font-size: 16px;
          }
          @media only screen and (max-width: 600px) {
            body {
              padding: 10px;
            }
            .header {
              padding: 30px 20px;
            }
            .header h1 {
              font-size: 24px;
            }
            .content {
              padding: 30px 20px;
            }
            .code {
              font-size: 28px;
              letter-spacing: 4px;
            }
            .button {
              padding: 14px 30px;
              font-size: 15px;
            }
          }
        </style>
      </head>
      <body>
        <div class="email-container">
          ${content}
        </div>
      </body>
      </html>
    `;
  }

  // =============================================================
  // 📧 VERIFICATION EMAIL (Modern Design)
  // =============================================================
  async sendVerificationEmail(email: string, code: string): Promise<void> {
    const content = `
      <div class="header">
        <div class="header-icon">
          <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2">
            <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
            <polyline points="22 4 12 14.01 9 11.01"></polyline>
          </svg>
        </div>
        <h1>Verify Your Email</h1>
      </div>
      
      <div class="content">
        <div class="greeting">Welcome to PlanMyWedding! 🎉</div>
        
        <div class="message">
          Thank you for signing up! We're excited to have you on board. 
          To get started, please verify your email address by entering the code below:
        </div>
        
        <div class="code-container">
          <div class="code-label">Your Verification Code</div>
          <div class="code">${code}</div>
        </div>
        
        <div class="info-box">
          <div class="info-icon">⏱️</div>
          <div class="info-text">
            <strong>Important:</strong> This verification code will expire in 15 minutes for security reasons.
            Please verify your account as soon as possible.
          </div>
        </div>
        
        <div class="divider"></div>
        
        <div class="message" style="font-size: 14px; color: #999;">
          If you didn't create an account with us, you can safely ignore this email.
          No further action is required.
        </div>
        
        <div style="text-align: center;">
          <div class="security-badge">
            <span class="security-icon">🔒</span>
            Secure & Encrypted
          </div>
        </div>
      </div>
      
      <div class="footer">
        <div class="footer-text">
          This email was sent by PlanMyWedding<br>
          © ${new Date().getFullYear()} PlanMyWedding. All rights reserved.
        </div>
      </div>
    `;

    const mailOptions = {
      from: `"Event Planner Support" <${process.env.MAIL_FROM || 'noreply@example.com'}>`,
      to: email,
      subject: '✨ Verify Your Email Address - PlanMyWedding',
      html: this.getEmailTemplate('Email Verification', content),
    };

    try {
      await this.transporter.sendMail(mailOptions);
      console.log('✅ Verification email sent to:', email);
    } catch (error) {
      console.error('❌ Error sending verification email:', error);
      throw new Error('Failed to send verification email');
    }
  }

  // =============================================================
  // 🔐 PASSWORD RESET EMAIL (Modern Design)
  // =============================================================
  async sendPasswordResetEmail(email: string, resetUrl: string): Promise<void> {
    const content = `
      <div class="header">
        <div class="header-icon">
          <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2">
            <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
            <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
          </svg>
        </div>
        <h1>Reset Your Password</h1>
      </div>
      
      <div class="content">
        <div class="greeting">Password Reset Request</div>
        
        <div class="message">
          We received a request to reset your password for your PlanMyWedding account.
          If you made this request, click the button below to create a new password:
        </div>
        
        <div class="button-container">
          <a href="${resetUrl}" class="button">Reset My Password</a>
        </div>
        
        <div class="info-box">
          <div class="info-icon">⏱️</div>
          <div class="info-text">
            <strong>Security Notice:</strong> This password reset link will expire in 15 minutes.
            If you need more time, you can request a new link from the app.
          </div>
        </div>
        
        <div class="divider"></div>
        
        <div class="message" style="font-size: 14px; color: #999;">
          <strong>Didn't request this?</strong><br>
          If you didn't request a password reset, you can safely ignore this email.
          Your password will remain unchanged and your account is secure.
        </div>
        
        <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin-top: 25px;">
          <div style="font-size: 12px; color: #999; margin-bottom: 8px; font-weight: 600;">
            If the button doesn't work, copy and paste this link:
          </div>
          <div style="font-size: 12px; color: rgba(20, 20, 215, 1); word-break: break-all; font-family: monospace;">
            ${resetUrl}
          </div>
        </div>
        
        <div style="text-align: center; margin-top: 25px;">
          <div class="security-badge">
            <span class="security-icon">🔒</span>
            Secure Password Reset
          </div>
        </div>
      </div>
      
      <div class="footer">
        <div class="footer-text">
          This email was sent by PlanMyWedding<br>
          © ${new Date().getFullYear()} PlanMyWedding. All rights reserved.
        </div>
        <div style="margin-top: 15px;">
          <a href="#" class="footer-links">Privacy Policy</a>
          <span style="color: #ddd;">|</span>
          <a href="#" class="footer-links">Contact Support</a>
        </div>
      </div>
    `;

    const mailOptions = {
      from: `"Event Planner Support" <${process.env.MAIL_FROM || 'noreply@example.com'}>`,
      to: email,
      subject: '🔐 Password Reset Request - PlanMyWedding',
      html: this.getEmailTemplate('Password Reset', content),
    };

    try {
      await this.transporter.sendMail(mailOptions);
      console.log('✅ Password reset email sent to:', email);
    } catch (error) {
      console.error('❌ Error sending password reset email:', error);
      throw new Error('Failed to send password reset email');
    }
  }

  // =============================================================
  // 🌟 GENERAL HTML EMAIL (Modern Design)
  // =============================================================
  async sendHtmlEmail(to: string, subject: string, htmlContent: string): Promise<void> {
    const content = `
      <div class="content" style="padding: 40px 30px;">
        ${htmlContent}
      </div>
      
      <div class="footer">
        <div class="footer-text">
          This email was sent by PlanMyWedding<br>
          © ${new Date().getFullYear()} PlanMyWedding. All rights reserved.
        </div>
      </div>
    `;

    const mailOptions = {
      from: `"Event Planner Support" <${process.env.MAIL_FROM || 'noreply@example.com'}>`,
      to: to,
      subject: subject,
      html: this.getEmailTemplate(subject, content),
    };
    
    try {
      await this.transporter.sendMail(mailOptions);
      console.log(`✅ HTML email sent to: ${to}`);
    } catch (error) {
      console.error(`❌ Failed to send HTML email to ${to}:`, error);
      throw new Error(`Failed to send HTML email: ${error.message}`);
    }
  }
}