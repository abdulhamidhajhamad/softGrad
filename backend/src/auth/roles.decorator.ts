// src/auth/roles.decorator.ts
import { SetMetadata } from '@nestjs/common';

export const ROLES_KEY = 'roles';
export const Roles = (...roles: ('user' | 'vendor' | 'admin')[]) => SetMetadata(ROLES_KEY, roles);