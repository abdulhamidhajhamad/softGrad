export declare class SignUpDto {
    userName: string;
    email: string;
    password: string;
    phone?: string;
    city?: string;
    role: 'client' | 'vendor' | 'admin';
    imageUrl?: string;
}
export declare class LoginDto {
    email: string;
    password: string;
}
export declare class ForgotPasswordDto {
    email: string;
}
export declare class ResetPasswordDto {
    token: string;
    newPassword: string;
}
export declare class VerifyEmailDto {
    email: string;
    verificationCode: string;
}
export declare class ResendVerificationDto {
    email: string;
}
