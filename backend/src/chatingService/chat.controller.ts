import { Controller, Post, Body, Get, Param, Req, UseGuards, Delete, Patch } from '@nestjs/common'; // ✨ استيراد Delete و Patch
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

  @Delete(':chatId')
  async deleteChat(@Req() req, @Param('chatId') chatId: string) {
    return this.chatService.deleteChat(req.user.id, chatId);
  }

  // ==========================================================
  // ✨ إضافة مسار تمييز الرسائل كمقروءة (2)
  // PATCH /chat/mark-read/:chatId
  // ==========================================================
  @Patch('mark-read/:chatId')
  async markRead(@Req() req, @Param('chatId') chatId: string) {
    const count = await this.chatService.markMessagesAsRead(req.user.id, chatId);
    return { messagesMarkedAsRead: count };
  }

  // ==========================================================
  // ✨ إضافة مسار الحصول على عدد المحادثات غير المقروءة (3)
  // GET /chat/unread-count
  // ==========================================================
  @Get('unread-count')
  async getUnreadCount(@Req() req) {
    const count = await this.chatService.getUnreadChatsCount(req.user.id);
    return { count };
  }
}