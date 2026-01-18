import { Controller, Post, Body, Get, Param, Req, UseGuards, Delete, Patch } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
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
  
  // ✅ FIXED: Send message - ensure it returns 200/201 status
  @Post('send')
  async sendMessage(@Req() req, @Body() dto: SendMessageDto) {
    const message = await this.chatService.sendMessage(req.user.id, dto.chatId, dto.content);
    
    // ✅ Return the message with 200 status (success)
    return {
      success: true,
      message: message,
    };
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

 // ✅ Mark messages as read
  @Patch('mark-read/:chatId')
  async markRead(@Req() req, @Param('chatId') chatId: string) {
    // 💡 التعديل: استخلاص العدد messagesMarkedReadCount من الكائن المرجع
    const { messagesMarkedReadCount } = await this.chatService.markMessagesAsRead(req.user.id, chatId);
    return { 
      success: true,
      messagesMarkedAsRead: messagesMarkedReadCount // إرجاع العدد فقط
    };
  }

  // ✅ Get unread count
  @Get('unread-count')
  async getUnreadCount(@Req() req) {
    const count = await this.chatService.getUnreadChatsCount(req.user.id);
    return { count };
  }

  // ✅ New Endpoint: Get unread messages count for EACH chat
// ✅ Endpoint جديد يرجع تفصيل الرسائل غير المقروءة لكل شات
@Get('unread-per-chat')
async getUnreadPerChat(@Req() req) {
  const result = await this.chatService.getUnreadCountsPerChat(req.user.id);
  
  return {
    success: true,
    data: result, // ستحتوي على مصفوفة بكل الشاتات التي بها رسائل غير مقروءة
  };
}

}