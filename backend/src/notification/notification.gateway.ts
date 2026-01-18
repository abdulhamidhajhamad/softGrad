// src/notification/notification.gateway.ts

import { WebSocketGateway, WebSocketServer, OnGatewayConnection, OnGatewayDisconnect, SubscribeMessage, MessageBody, ConnectedSocket } from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger } from '@nestjs/common';
import { Types } from 'mongoose';
import { JwtService } from '@nestjs/jwt';

@WebSocketGateway({
  cors: {
    origin: '*',
  },
})
export class NotificationsGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer() server: Server;
  private readonly logger = new Logger(NotificationsGateway.name);
  private connectedClients: Map<string, Socket> = new Map();

  constructor(private readonly jwtService: JwtService) {}

  handleConnection(client: Socket) {
    this.logger.log(`\n🔌 New connection attempt: ${client.id}`);
    
    const token = client.handshake.query.token as string;
    let recipientId: string | undefined;

    if (!token) {
      this.logger.warn(`❌ No token provided. Client: ${client.id}`);
      client.disconnect();
      return;
    }

    try {
      const payload = this.jwtService.verify(token);
      recipientId = payload.userId?.toString() || payload.id?.toString();
      this.logger.log(`🔑 Token verified. Recipient ID: ${recipientId}`);
    } catch (e) {
      this.logger.warn(`❌ Invalid or expired token. Client disconnected: ${client.id}. Error: ${e.message}`);
      client.disconnect();
      return;
    }

    if (recipientId) {
      // Check if already connected
      const existingClient = this.connectedClients.get(recipientId);
      if (existingClient) {
        this.logger.log(`⚠️ User ${recipientId} already connected. Replacing connection.`);
        existingClient.disconnect();
      }
      
      this.connectedClients.set(recipientId, client);
      this.logger.log(`✅ Client connected and authenticated: ${client.id}. Recipient ID: ${recipientId}`);
      this.logger.log(`📊 Total connected clients: ${this.connectedClients.size}`);
      
      // ✅ إرسال تأكيد الاتصال للعميل
      client.emit('connected', { recipientId, message: 'Successfully connected to notifications' });
      
      // ✅ join room خاص بالمستخدم
      client.join(`user_${recipientId}`);
      this.logger.log(`📍 Client joined room: user_${recipientId}\n`);
    } else {
      this.logger.warn(`❌ Connection rejected. No valid Recipient ID found in token: ${client.id}`);
      client.disconnect();
    }
  }

  handleDisconnect(client: Socket) {
    for (const [recipientId, socket] of this.connectedClients.entries()) {
      if (socket.id === client.id) {
        this.connectedClients.delete(recipientId);
        this.logger.log(`❌ Client disconnected: ${client.id}. Recipient ID: ${recipientId} removed.`);
        break;
      }
    }
  }

  // ✅ دالة محسّنة لإرسال الإشعارات
  emitToRecipient(recipientId: Types.ObjectId | string, event: string, payload: any) {
    const recipientIdStr = recipientId.toString();
    
    this.logger.log(`\n📡 Attempting to emit '${event}' to recipient: ${recipientIdStr}`);
    this.logger.log(`📦 Payload type: ${typeof payload}, Keys: ${payload ? Object.keys(payload).join(', ') : 'null'}`);
    
    // طريقة 1: إرسال مباشر للعميل المخزن
    const client = this.connectedClients.get(recipientIdStr);
    if (client && client.connected) {
      this.logger.log(`✅ Found client in map. Socket ID: ${client.id}, Connected: ${client.connected}`);
      try {
        client.emit(event, payload);
        this.logger.log(`✅ Successfully emitted '${event}' to recipient: ${recipientIdStr} (direct)\n`);
        return true;
      } catch (emitError) {
        this.logger.error(`❌ Error emitting to client: ${emitError.message}`);
      }
    } else {
      this.logger.log(`⚠️ Client not found in map or disconnected. Client exists: ${!!client}, Connected: ${client?.connected}`);
    }
    
    // طريقة 2: إرسال للـ room (fallback)
    const room = `user_${recipientIdStr}`;
    const socketsInRoom = this.server.sockets.adapter.rooms.get(room);
    
    if (socketsInRoom && socketsInRoom.size > 0) {
      this.logger.log(`✅ Found ${socketsInRoom.size} clients in room: ${room}`);
      try {
        this.server.to(room).emit(event, payload);
        this.logger.log(`✅ Successfully emitted '${event}' to room: ${room}\n`);
        return true;
      } catch (roomError) {
        this.logger.error(`❌ Error emitting to room: ${roomError.message}`);
      }
    } else {
      this.logger.log(`⚠️ No clients in room: ${room}`);
    }
    
    this.logger.warn(`❌ Recipient ${recipientIdStr} not currently connected for real-time push.`);
    this.logger.log(`📊 Total connected clients: ${this.connectedClients.size}`);
    this.logger.log(`📋 Connected IDs: ${Array.from(this.connectedClients.keys()).join(', ')}\n`);
    
    return false;
  }

  // ✅ دالة إضافية: broadcast لجميع المتصلين (للاستخدام المستقبلي)
  broadcastToAll(event: string, payload: any) {
    this.logger.log(`📢 Broadcasting '${event}' to all connected clients`);
    this.server.emit(event, payload);
  }

  // ✅ دالة للتحقق من اتصال مستخدم معين
  isUserConnected(recipientId: string): boolean {
    return this.connectedClients.has(recipientId);
  }

  // ✅ دالة للحصول على عدد المتصلين
  getConnectedCount(): number {
    return this.connectedClients.size;
  }
}