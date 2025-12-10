// src/notification/notification.gateway.ts

import { WebSocketGateway, WebSocketServer, OnGatewayConnection, OnGatewayDisconnect } from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger } from '@nestjs/common';
import { Types } from 'mongoose';
import { JwtService } from '@nestjs/jwt'; // ✅ استيراد JwtService

@WebSocketGateway({
  cors: {
    origin: '*',
  },
})
export class NotificationsGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer() server: Server;
  private readonly logger = new Logger(NotificationsGateway.name);
  private connectedClients: Map<string, Socket> = new Map();

  // ✅ CRITICAL: حقن JwtService
  constructor(private readonly jwtService: JwtService) {}

  handleConnection(client: Socket) {
    // 1. محاولة استخلاص التوكن من الـ Query Parameter
    const token = client.handshake.query.token as string;
    let recipientId: string | undefined;

    if (token) {
      try {
        // 2. التحقق من التوقيع (Signature) ومدة الصلاحية (Expiration)
        const payload = this.jwtService.verify(token); 
        
        // 3. استخراج الـ ID
        recipientId = payload.userId?.toString() || payload.id?.toString(); 
        
      } catch (e) {
        this.logger.warn(`❌ Invalid or expired token provided. Client disconnected: ${client.id}. Error: ${e.message}`);
        client.disconnect();
        return;
      }
    }

    // 4. حفظ الاتصال إذا تم التحقق من الهوية بنجاح
    if (recipientId) {
      this.connectedClients.set(recipientId, client);
      this.logger.log(`✅ Client connected and authenticated: ${client.id}. Recipient ID: ${recipientId}`);
    } else {
      this.logger.warn(`❌ Connection rejected. No valid Recipient ID found in token: ${client.id}`);
      client.disconnect();
    }
  }

  handleDisconnect(client: Socket) {
    for (const [recipientId, socket] of this.connectedClients.entries()) {
      if (socket.id === client.id) {
        this.connectedClients.delete(recipientId);
        this.logger.log(`Client disconnected: ${client.id}. Recipient ID removed.`);
        break;
      }
    }
  }

  emitToRecipient(recipientId: Types.ObjectId | string, event: string, payload: any) {
    const client = this.connectedClients.get(recipientId.toString());
    if (client) {
      this.logger.debug(`Emitting '${event}' to recipient: ${recipientId}`);
      client.emit(event, payload);
      return true;
    }
    this.logger.warn(`Recipient ${recipientId} not currently connected for real-time push.`);
    return false;
  }
}