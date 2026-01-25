import { Document, Schema as MongooseSchema } from 'mongoose';
export declare enum AdminRole {
    SUPER_ADMIN = "super_admin",
    ADMIN = "admin"
}
export declare class Admin extends Document {
    userId: string;
    role: AdminRole;
    createdAt: Date;
}
export declare const AdminSchema: MongooseSchema<Admin, import("mongoose").Model<Admin, any, any, any, Document<unknown, any, Admin, any, {}> & Admin & Required<{
    _id: unknown;
}> & {
    __v: number;
}, any>, {}, {}, {}, {}, import("mongoose").DefaultSchemaOptions, Admin, Document<unknown, {}, import("mongoose").FlatRecord<Admin>, {}, import("mongoose").ResolveSchemaOptions<import("mongoose").DefaultSchemaOptions>> & import("mongoose").FlatRecord<Admin> & Required<{
    _id: unknown;
}> & {
    __v: number;
}>;
