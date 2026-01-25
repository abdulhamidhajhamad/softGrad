// cart.controller.ts
import { Controller, Post, Get, Delete, Body, UseGuards, Request, HttpCode, HttpStatus, Patch, Param } from '@nestjs/common';
import { CartService } from './shoppingCart.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AddToCartDto, RemoveFromCartDto, UpdateCartItemDto } from './shoppingCart.dto';
import { AddPackageToCartDto } from '../Package/package.dto';

@Controller('cart')
@UseGuards(JwtAuthGuard)
export class CartController {
  constructor(private readonly cartService: CartService) {}

  @Post('add')
  @HttpCode(HttpStatus.OK)
  async addToCart(@Request() req, @Body() addToCartDto: AddToCartDto) {
    return this.cartService.addToCart(req.user.userId, addToCartDto);
  }

  @Delete('remove')
  @HttpCode(HttpStatus.OK)
  async removeFromCart(@Request() req, @Body() removeFromCartDto: RemoveFromCartDto) {
    return this.cartService.removeFromCart(req.user.userId, removeFromCartDto);
  }

  @Patch('update')
  @HttpCode(HttpStatus.OK)
  async updateCartItem(@Request() req, @Body() updateCartItemDto: UpdateCartItemDto) {
    return this.cartService.updateCartItem(req.user.userId, updateCartItemDto);
  }

  @Get()
  async getCart(@Request() req) {
    return this.cartService.getCart(req.user.userId);
  }

  @Delete('clear')
  @HttpCode(HttpStatus.NO_CONTENT)
  async clearCart(@Request() req) {
    await this.cartService.clearCart(req.user.userId);
  }

  @Post('add-package')
  async addPackageToCart(@Request() req, @Body() dto: AddPackageToCartDto) {
    return this.cartService.addPackageToCart(req.user.userId, dto);
  }

  // 🆕 Get alternative available slots when booking is not available
  @Post('check-alternatives/:serviceId')
  @HttpCode(HttpStatus.OK)
  async getAlternativeSlots(
    @Param('serviceId') serviceId: string,
    @Body() body: { date: string; startHour?: number; endHour?: number; numberOfPeople?: number }
  ) {
    return this.cartService.getAlternativeAvailability(serviceId, body);
  }
}