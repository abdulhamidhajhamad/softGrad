export declare class MailService {
    private transporter;
    constructor();
    private verifyTransporter;
    sendVerificationEmail(email: string, verificationCode: string): Promise<void>;
    sendPasswordResetEmail(email: string, resetUrl: string): Promise<void>;
}
