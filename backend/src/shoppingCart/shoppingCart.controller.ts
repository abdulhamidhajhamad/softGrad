import { 
  Controller, Get, Post, Delete, Body, Query,
  UseGuards, Request, HttpException, HttpStatus 
} from '@nestjs/common';
import { ShoppingCartService } from './shoppingCart.service';
import { AddToCartDto, RemoveFromCartDto } from './shoppingCart.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('shoppingCart') 
@UseGuards(JwtAuthGuard)
export class ShoppingCartController {
  constructor(private readonly shoppingCartService: ShoppingCartService) {}

  @Post()
  async addToCart(@Body() addToCartDto: AddToCartDto, @Request() req: any) {
    try {
      const userId = req.user.userId;
      const userRole = req.user.role;

      // تصحيح: استخدام 'user' بدلاً من 'client'
      if (userRole !== 'user' && userRole !== 'client') {
        throw new HttpException(
          'Only clients can add services to cart',
          HttpStatus.FORBIDDEN
        );
      }

      return await this.shoppingCartService.addToCart(userId, addToCartDto);
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to add to cart',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  @Delete()
  async removeFromCart(@Body() removeFromCartDto: RemoveFromCartDto, @Request() req: any) {
    try {
      const userId = req.user.userId;
      const userRole = req.user.role;

      if (userRole !== 'user' && userRole !== 'client') {
        throw new HttpException(
          'Only clients can remove services from cart',
          HttpStatus.FORBIDDEN
        );
      }

      return await this.shoppingCartService.removeFromCart(userId, removeFromCartDto);
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to remove from cart',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  @Delete('clear')
  async clearCart(@Request() req: any) {
    try {
      const userId = req.user.userId;
      const userRole = req.user.role;

      if (userRole !== 'user' && userRole !== 'client') {
        throw new HttpException(
          'Only clients can clear cart',
          HttpStatus.FORBIDDEN
        );
      }

      return await this.shoppingCartService.clearCart(userId);
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to clear cart',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  @Get()
  async getCart(@Request() req: any) {
    try {
      const userId = req.user.userId;
      return await this.shoppingCartService.getCartByUserId(userId);
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to get cart',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  /**
   * 🆕 فحص التوافر الشامل
   */
  @Post('check-availability')
  async checkAvailability(
    @Body('serviceId') serviceId: string,
    @Body('bookingDate') bookingDate: Date,
    @Body('startHour') startHour?: number,
    @Body('endHour') endHour?: number,
    @Body('numberOfPeople') numberOfPeople?: number,
    @Body('isFullVenueBooking') isFullVenueBooking?: boolean
  ) {
    try {
      return await this.shoppingCartService.checkAvailability(
        serviceId,
        bookingDate,
        startHour,
        endHour,
        numberOfPeople,
        isFullVenueBooking
      );
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to check availability',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  /**
   * للتوافق مع الكود القديم
   */
  @Post('check-date')
  async checkDateAvailability(
    @Body('serviceId') serviceId: string,
    @Body('bookingDate') bookingDate: Date
  ) {
    try {
      return await this.shoppingCartService.checkDateAvailability(serviceId, bookingDate);
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to check date availability',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }
}