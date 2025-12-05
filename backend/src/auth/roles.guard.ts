// src/auth/roles.guard.ts
import { Injectable, CanActivate, ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { ROLES_KEY } from './roles.decorator';

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    // 1. Get required roles from the @Roles() decorator
    const requiredRoles = this.reflector.getAllAndOverride<string[]>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (!requiredRoles) {
      return true; // No roles required, access granted
    }

    // 2. Get user information from the request object (set by JwtStrategy)
    const { user } = context.switchToHttp().getRequest();
    
    // Check if the user's role is included in the required roles
    // The user object must contain the 'role' property (added in JwtStrategy)
    const hasRole = requiredRoles.some((role) => user.role === role);
    
    console.log(`🛡️ RolesGuard: User Role: ${user.role}, Required Roles: ${requiredRoles}, Access Granted: ${hasRole}`);
    
    return hasRole;
  }
}