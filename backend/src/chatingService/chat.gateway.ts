// chat.gateway.ts
import {
  WebSocketGateway,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  WebSocketServer,
  OnGatewayInit,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { ChatService } from './chat.service';
import { JoinRoomDto, SendMessageDto } from './chat.dto';

@WebSocketGateway({
  cors: { origin: '*' },
})
export class ChatGateway implements OnGatewayInit {
  @WebSocketServer()
  server: Server;

  // ✅ ChatService حقنها هنا الآن لا يسبب الاعتماد الدائري
  constructor(private chatService: ChatService) {} 

  afterInit(server: Server) {
    console.log('✅ Chat Gateway Initialized');
  }

  // دالة مساعدة: إرسال تحديث لعدد المحادثات غير المقروءة
  emitUnreadCount(userId: string, count: number): void {
    // نرسل إلى الغرفة الشخصية التي تحمل ID المستخدم
    this.server.to(userId).emit('unreadCountUpdated', { count });
  }

  // Join chat room
  @SubscribeMessage('joinRoom')
  async handleJoinRoom(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { chatId: string, userId: string }, 
  ) {
    const { chatId, userId } = data;
    
    client.join(chatId);
    client.join(userId);

    // 1. استدعاء الدالة من الـ Service، والتي ترجع العدد الجديد
    const { messagesMarkedReadCount, newUnreadCount } = await this.chatService.markMessagesAsRead(userId, chatId);
    
    if (messagesMarkedReadCount > 0) {
        // 2. استخدام البيانات المرجعة لتحديث العدد في الوقت الفعلي
        this.emitUnreadCount(userId, newUnreadCount);
    }
    
    // 3. إرسال حدث للغرفة لتحديث واجهة المستخدم (مثل إزالة الدائرة الحمراء على الشات)
    this.server.to(chatId).emit('messagesRead', { chatId: chatId, readerId: userId });
  }

  // Send message event
  @SubscribeMessage('sendMessage')
  async handleSendMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { chatId: string; senderId: string; content: string },
  ) {
    // 1. استدعاء الدالة من الـ Service، والتي ترجع الرسالة و ID المستلم والعدد الجديد
    const { message, recipientId, newUnreadCount } = await this.chatService.sendMessage(
      data.senderId,
      data.chatId,
      data.content,
    );

    // 2. Broadcast للرسالة الجديدة
    this.server.to(data.chatId).emit('newMessage', message);
    
    // 3. استخدام البيانات المرجعة لتحديث العدد غير المقروء للمستلم
    if (recipientId) {
        this.emitUnreadCount(recipientId, newUnreadCount);
    }
  }
}