import { Document } from 'mongoose';
export declare class User extends Document {
    userName: string;
    email: string;
    password: string;
    phone?: string;
    city?: string;
    role: 'client' | 'vendor' | 'admin';
    imageUrl?: string;
    isVerified: boolean;
    verificationCode?: string;
    verificationCodeExpires?: Date;
    companyName?: string;
}
export declare const UserSchema: import("mongoose").Schema<User, import("mongoose").Model<User, any, any, any, Document<unknown, any, User, any, {}> & User & Required<{
    _id: unknown;
}> & {
    __v: number;
}, any>, {}, {}, {}, {}, import("mongoose").DefaultSchemaOptions, User, Document<unknown, {}, import("mongoose").FlatRecord<User>, {}, import("mongoose").ResolveSchemaOptions<import("mongoose").DefaultSchemaOptions>> & import("mongoose").FlatRecord<User> & Required<{
    _id: unknown;
}> & {
    __v: number;
}>;
