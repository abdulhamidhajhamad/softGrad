// chat.gateway.ts
import {
  WebSocketGateway,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { ChatService } from './chat.service';
import { JoinRoomDto, SendMessageDto } from './chat.dto';

@WebSocketGateway({
  cors: { origin: '*' },
})
export class ChatGateway {
  @WebSocketServer()
  server: Server;

  constructor(private chatService: ChatService) {}

  // Join chat room
  @SubscribeMessage('joinRoom')
  handleJoinRoom(
    @ConnectedSocket() client: Socket,
    @MessageBody() chatId: string,
  ) {
    client.join(chatId);
  }

  // Send message event
  @SubscribeMessage('sendMessage')
  async handleSendMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { chatId: string; senderId: string; content: string },
  ) {
    const msg = await this.chatService.sendMessage(
      data.senderId,
      data.chatId,
      data.content,
    );

    // Broadcast to room
    this.server.to(data.chatId).emit('newMessage', msg);
  }
}
