import { AuthService } from './auth.service';
import { SignUpDto, LoginDto, VerifyEmailDto, ResendVerificationDto } from './auth.dto';
export declare class AuthController {
    private authService;
    constructor(authService: AuthService);
    signUp(signUpDto: SignUpDto): Promise<{
        message: string;
        email: string;
    }>;
    verifyEmail(verifyEmailDto: VerifyEmailDto): Promise<{
        token: string;
        user: any;
    }>;
    resendVerification(resendVerificationDto: ResendVerificationDto): Promise<{
        message: string;
    }>;
    login(loginDto: LoginDto): Promise<{
        token: string;
        user: any;
    }>;
}
