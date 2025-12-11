// chat.gateway.ts
import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { ChatService } from './chat.service';
import { Injectable, UseGuards, forwardRef, Inject } from '@nestjs/common'; // ✨ تم استيراد Injectable
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Message } from './message.schema'; // ✨ تم استيراد Message Schema
@Injectable() // ✨ إضافة @Injectable
@WebSocketGateway({
  cors: {
    origin: true,
    credentials: true,
  },
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  constructor(@Inject(forwardRef(() => ChatService))
    private chatService: ChatService) {}

  handleConnection(client: Socket) {
    console.log(`✅ Client connected: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    console.log(`❌ Client disconnected: ${client.id}`);
  }

  @SubscribeMessage('joinRoom')
  async handleJoinRoom(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { chatId: string; userId: string },
  ) {
    console.log(`🚪 User ${data.userId} joining room ${data.chatId}`);
    client.join(data.chatId);
    console.log(`✅ User joined room successfully`);
  }

  @SubscribeMessage('leaveChat')
  async handleLeaveChat(
    @ConnectedSocket() client: Socket,
    @MessageBody() chatId: string,
  ) {
    console.log(`🚪 Client ${client.id} leaving room ${chatId}`);
    client.leave(chatId);
  }

  @SubscribeMessage('sendMessage')
  async handleSendMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { chatId: string; senderId: string; content: string },
  ) {
    console.log(`📤 Sending message in chat ${data.chatId}`);
    
    try {
      const result = await this.chatService.sendMessage(
        data.senderId,
        data.chatId,
        data.content,
      );

      // Emit message to everyone in the room
      this.server.to(data.chatId).emit('newMessage', {
        message: result.message,
        chatId: data.chatId,
      });

      // Emit unread count update to recipient
      if (result.recipientId) {
        this.server.emit(`unreadCount_${result.recipientId}`, {
          count: result.newUnreadCount,
        });
      }

      console.log(`✅ Message sent successfully`);
    } catch (error) {
      console.error(`❌ Error sending message:`, error);
      client.emit('error', { message: 'Failed to send message' });
    }
  }

  @SubscribeMessage('markAsRead')
  async handleMarkAsRead(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { chatId: string; userId: string },
  ) {
    console.log(`\n📖 Socket: markAsRead event received`);
    console.log(`Chat ID: ${data.chatId}`);
    console.log(`User ID: ${data.userId}`);
    
    try {
      const result = await this.chatService.markMessagesAsRead(
        data.userId,
        data.chatId,
      );

      console.log(`✅ Socket: Marked ${result.messagesMarkedReadCount} messages as read`);

      // Notify all clients in the room about the read status
      this.server.to(data.chatId).emit('messagesRead', {
        chatId: data.chatId,
        userId: data.userId,
        count: result.messagesMarkedReadCount,
      });

      // Update unread count for the user
      client.emit('unreadCountUpdated', {
        count: result.newUnreadCount,
      });

      console.log(`📊 Socket: Emitted unread count: ${result.newUnreadCount}\n`);
    } catch (error) {
      console.error(`❌ Socket: Error marking as read:`, error);
      client.emit('error', { message: 'Failed to mark messages as read' });
    }
  }

  @SubscribeMessage('typing')
  handleTyping(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { chatId: string; userId: string; isTyping: boolean },
  ) {
    client.to(data.chatId).emit('userTyping', {
      userId: data.userId,
      isTyping: data.isTyping,
    });
  }


  // ✨ الدالة الجديدة: لإرسال الرسالة عبر السوكيت من الـ Service
 async sendNewMessageToRoom(chatId: string, message: Message) {
    console.log(`📡 Gateway: Emitting 'newMessage' to room ${chatId}`);

    // ✅ الحل: تحويل Mongoose Document إلى JavaScript Object باستخدام toJSON(). 
    // هذا يضمن تحويل ObjectId إلى string وتجنب أخطاء .toString()
    const messageObject = message.toJSON(); 
    
    // يطلق حدث 'newMessage' لجميع العملاء في الغرفة
    this.server.to(chatId).emit('newMessage', {
      message: messageObject, 
    });
  }

}