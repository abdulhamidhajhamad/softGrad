import { Injectable, CanActivate, ExecutionContext, ForbiddenException, UnauthorizedException } from '@nestjs/common';

@Injectable()
export class AdminGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const user = request.user;

    if (!user) {
      throw new UnauthorizedException('User not authenticated. Please login first.');
    }

    // Debug: Log the user role
    console.log('Admin Guard - User Role:', user.role, 'Type:', typeof user.role);

    // Check if user has admin role (handle both string and potential variations)
    const userRole = String(user.role).toLowerCase().trim();
    if (userRole !== 'admin') {
      throw new ForbiddenException(`You do not have permission to access admin features. Your role is: ${user.role}`);
    }

    return true;
  }
}