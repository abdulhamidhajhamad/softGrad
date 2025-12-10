// src/notification/notification.gateway.ts
import { WebSocketGateway, WebSocketServer, OnGatewayConnection, OnGatewayDisconnect } from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger } from '@nestjs/common';
import { Types } from 'mongoose';

// Note: Configure CORS for your WebSocket server
@WebSocketGateway({
  cors: {
    origin: '*', // Adjust this to your frontend URL
  },
})
export class NotificationsGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer() server: Server;
  private readonly logger = new Logger(NotificationsGateway.name);
  private connectedClients: Map<string, Socket> = new Map();

  handleConnection(client: Socket) {
    // IMPORTANT: Client must send authentication data (e.g., recipientId) upon connection
    // For this example, we assume recipientId is sent as a query parameter or token payload
    const recipientId = client.handshake.query.recipientId as string;
    
    if (recipientId) {
      this.connectedClients.set(recipientId, client);
      this.logger.log(`Client connected: ${client.id}. Recipient ID: ${recipientId}`);
    } else {
      this.logger.warn(`Client connected without Recipient ID: ${client.id}`);
      client.disconnect();
    }
  }

  handleDisconnect(client: Socket) {
    // Remove client from the map when disconnected
    for (const [recipientId, socket] of this.connectedClients.entries()) {
      if (socket.id === client.id) {
        this.connectedClients.delete(recipientId);
        this.logger.log(`Client disconnected: ${client.id}. Recipient ID removed.`);
        break;
      }
    }
  }

  /**
   * Sends an immediate update to a specific recipient.
   * @param recipientId The MongoDB ObjectId of the user/vendor.
   * @param event The event name (e.g., 'newNotification', 'unreadCountUpdated').
   * @param payload The data to send.
   */
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