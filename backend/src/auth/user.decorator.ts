// src/auth/user.decorator.ts
import { createParamDecorator, ExecutionContext } from '@nestjs/common';

/**
 * Custom decorator to retrieve the authenticated user data (or a specific field from it)
 * stored in the request object (usually added by an AuthGuard).
 * * Usage: @User() user: UserEntity
 * Usage: @User('id') userId: string
 */
export const User = createParamDecorator(
  (data: unknown, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    // Assuming the AuthGuard attaches the user object to request.user
    const user = request.user; 
    
    if (!user) {
      // Should not happen if an AuthGuard is used correctly
      return null;
    }

    if (data) {
      // If a specific field is requested (e.g., @User('id'))
      return user[data as string];
    }
    
    // Return the whole user object
    return user;
  },
);