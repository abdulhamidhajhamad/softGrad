import { Strategy } from 'passport-jwt';
import { Model } from 'mongoose';
import { User } from './user.entity';
declare const JwtStrategy_base: new (...args: any[]) => Strategy;
export declare class JwtStrategy extends JwtStrategy_base {
    private userModel;
    constructor(userModel: Model<User>);
    validate(payload: any): Promise<{
        id: string;
        userId: string;
        email: string;
        role: "client" | "vendor" | "admin";
    }>;
}
export {};
