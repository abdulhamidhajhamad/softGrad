// chat.controller.ts
import { Controller, Post, Body, Get, Param, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard'; // ← عدل المسار حسب مشروعك
import { ChatService } from './chat.service';
import { CreateConversationDto, SendMessageDto } from './chat.dto';

@Controller('chat')
@UseGuards(JwtAuthGuard) 
export class ChatController {
  constructor(private chatService: ChatService) {}

  @Post('create')
  createChat(@Req() req, @Body() dto: CreateConversationDto) {
    return this.chatService.createChat(req.user.id, dto.receiverId);
  }
  
  // Send message
  @Post('send')
  sendMessage(@Req() req, @Body() dto: SendMessageDto) {
    return this.chatService.sendMessage(req.user.id, dto.chatId, dto.content);
  }

  // Get all messages in a chat
  @Get('messages/:chatId')
  getMessages(@Param('chatId') chatId: string) {
    return this.chatService.getMessages(chatId);
  }

  // Get all chats for logged-in user
  @Get('my-chats')
  getUserChats(@Req() req) {
    return this.chatService.getUserChats(req.user.id);
  }
}