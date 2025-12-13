// chat.service.ts
import { Injectable, NotFoundException , forwardRef, Inject, Logger} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Chat, LastReadStatus } from './chat.schema';
import { Message } from './message.schema';
import { Model, Types } from 'mongoose';
import { User } from '../auth/user.entity'; 
import { NotificationService } from '../notification/notification.service';
import { NotificationType, RecipientType } from '../notification/notification.schema';
import { ProviderService } from '../providers/provider.service'; 
import { ChatGateway } from './chat.gateway';

@Injectable()
export class ChatService {
  private readonly logger = new Logger(ChatService.name);

  constructor(
    @InjectModel(Chat.name) private chatModel: Model<Chat>,
    @InjectModel(Message.name) private messageModel: Model<Message>,
    @InjectModel(User.name) private userModel: Model<User>, 
    private notificationService: NotificationService,
    private providerService: ProviderService,
    @Inject(forwardRef(() => ChatGateway))
    private chatGateway: ChatGateway,
  ) {}

  async createChat(userId: string, receiverId: string) {
    let chat = await this.chatModel.findOne({
      participants: { $all: [userId, receiverId] },
   
    });

    if (!chat) {
      chat = await this.chatModel.create({
        participants: [userId, receiverId],
        lastRead: [
          { userId: new Types.ObjectId(userId), lastReadAt: new Date() },
          { userId: new Types.ObjectId(receiverId), lastReadAt: null },
        ]
      });
    }

    if (chat && (!chat.lastRead || chat.lastRead.length === 0)) {
      chat.lastRead = [
        { userId: new Types.ObjectId(userId), lastReadAt: new Date() },
        { userId: new Types.ObjectId(receiverId), lastReadAt: null }, 
      ];
      await chat.save();
    }

    return chat;
  }

  async sendMessage(senderId: string, chatId: string, content: string): Promise<{ message: Message, recipientId: string | null, newUnreadCount: number }> {
    this.logger.log(`\n🔵 ===== SEND MESSAGE START =====`);
    this.logger.log(`Sender: ${senderId}, Chat: ${chatId}`);
    
    const chat = await this.chatModel.findById(chatId);
    if (!chat) {
      this.logger.error(`❌ Chat not found: ${chatId}`);
      throw new NotFoundException('Chat not found');
    }

    // Create message
    const message = await this.messageModel.create({ sender: senderId, chatId, content });
    this.logger.log(`✅ Message created with ID: ${message._id}`);
    
    chat.lastMessage = content;
    
    // Find recipient
    const participantObject = chat.participants.find(
      (p) => p.toString() !== senderId.toString()
    );
    const recipientId: string | null = participantObject ? participantObject.toString() : null;
    this.logger.log(`📤 Recipient ID: ${recipientId}`);

    // Update lastRead status
    chat.lastRead = chat.lastRead.map(status => {
      if (status.userId.toString() === senderId) {
        status.lastReadAt = new Date();
      } else if (recipientId && status.userId.toString() === recipientId) {
        status.lastReadAt = null;
      }
      return status;
    });

    await chat.save();
    this.logger.log(`✅ Chat updated`);
    
    // Send via WebSocket
    try {
      this.chatGateway.sendNewMessageToRoom(chatId, message);
      this.logger.log(`✅ Message sent to WebSocket room`);
    } catch (wsError) {
      this.logger.error(`❌ WebSocket error: ${wsError.message}`);
    }
    
    // Get sender info
    const sender = await this.userModel.findById(senderId).exec();
    if (!sender) {
      this.logger.error(`❌ Sender not found: ${senderId}`);
      throw new NotFoundException('Sender user not found'); 
    }
    
    let notificationTitle: string;
    const senderRole = sender['role'] as string;
    this.logger.log(`📋 Sender role: ${senderRole}`);
    
    if (senderRole === 'vendor') {
      try {
        const companyName = await this.providerService.findCompanyNameByUserId(senderId);
        notificationTitle = `New message from ${companyName}`; 
      } catch (e) {
        this.logger.error(`Could not find company name for vendor: ${senderId}`, e.message);
        notificationTitle = `New message from Vendor`;
      }
    } else if (senderRole === 'admin') {
      notificationTitle = `New message from Admin`; 
    } else {
      const userName = sender['userName'] || 'User';
      notificationTitle = `New message from ${userName}`; 
    }

    let newUnreadCount = 0;
    
    if (recipientId) {
      this.logger.log(`\n📬 Processing notification for recipient: ${recipientId}`);
      
      newUnreadCount = await this.getUnreadChatsCount(recipientId);
      this.logger.log(`📊 Unread count: ${newUnreadCount}`);

      const recipient = await this.userModel.findById(recipientId);
      if (!recipient) {
        this.logger.warn(`⚠️ Recipient not found: ${recipientId}`);
      } else {
        this.logger.log(`✅ Recipient found: ${recipient['userName']}`);
        
        const fcmToken = recipient['fcmToken'] as string | undefined;
        const recipientRole = recipient['role'] as string;
        
        this.logger.log(`📱 FCM Token: ${fcmToken ? 'EXISTS' : 'MISSING'}`);
        this.logger.log(`👤 Recipient role: ${recipientRole}`);
        
        const targetType = recipientRole === 'vendor' ? RecipientType.VENDOR : RecipientType.USER;
        
        this.logger.log(`🎯 Target type: ${targetType}`);
        
        const notifDto = {
          recipientId: recipient._id as Types.ObjectId, 
          recipientType: targetType,
          title: notificationTitle, 
          body: content.substring(0, 50) + (content.length > 50 ? '...' : ''),
          type: NotificationType.NEW_MESSAGE,
          metadata: { chatId: chatId, messageId: message._id as Types.ObjectId }
        };
        
        this.logger.log(`📝 Notification DTO: ${JSON.stringify({
          recipientId: notifDto.recipientId.toString(),
          recipientType: notifDto.recipientType,
          title: notifDto.title,
          type: notifDto.type
        })}`);
        
        try {
          this.logger.log(`🚀 Calling createNotification...`);
          // ✅ FIX: إرسال الإشعار حتى لو لم يكن هناك FCM token
          // نمرر empty string إذا لم يكن هناك token
          const createdNotification = await this.notificationService.createNotification(notifDto, fcmToken || '');
          this.logger.log(`✅ Notification created successfully with ID: ${createdNotification._id}`);
        } catch (notifError) {
          this.logger.error(`❌ Error creating notification: ${notifError.message}`);
          this.logger.error(`Stack: ${notifError.stack}`);
        }
      }
    } else {
      this.logger.warn(`⚠️ No recipient found in chat`);
    }
    
    this.logger.log(`🔵 ===== SEND MESSAGE END =====\n`);
    return { message, recipientId, newUnreadCount };
  }

  async getMessages(chatId: string) {
    return this.messageModel
      .find({ chatId: chatId })
      .populate('sender', 'userName imageUrl role')
      .sort({ createdAt: 1 });
  }

  async getUserChats(userId: string) {
    return this.chatModel
      .find({ participants: userId })
      .populate('participants', 'userName imageUrl role')
      .sort({ updatedAt: -1 });
  }

  async deleteChat(userId: string, chatId: string): Promise<any> {
    const chat = await this.chatModel.findById(chatId);

    if (!chat) {
      throw new NotFoundException('Chat not found');
    }

    if (!chat.participants.map(p => p.toString()).includes(userId)) {
      throw new NotFoundException('Chat not found or access denied');
    }

    await this.messageModel.deleteMany({ chatId: chatId });
    const result = await this.chatModel.deleteOne({ _id: chatId });

    return { deleted: result.deletedCount > 0, chatId };
  }

  async markMessagesAsRead(userId: string, chatId: string): Promise<{ messagesMarkedReadCount: number, newUnreadCount: number }> {
    console.log(`\n🔵 ===== MARK AS READ DEBUG START (Bulk Update) =====`);
    
    let userIdObj: Types.ObjectId;
    
    try {
      userIdObj = new Types.ObjectId(userId);
    } catch (error) {
      throw new Error('Invalid User ID format');
    }

    const chat = await this.chatModel.findById(chatId); 

    if (!chat) {
        throw new NotFoundException('Chat not found');
    }

    const isParticipant = chat.participants.some(p => p.toString() === userId);
    if (!isParticipant) {
        throw new NotFoundException('User is not a participant in this chat');
    }
    
    const updateResult = await this.messageModel.updateMany(
      {
        chatId: chatId,
        isRead: false,
        sender: { $ne: userIdObj } 
      },
      { $set: { isRead: true } }
    );
    
    const messagesMarkedReadCount = updateResult.modifiedCount;
    
    console.log(`✅ Bulk Update executed. Messages marked as read: ${messagesMarkedReadCount}`);

    console.log(`📖 Updating lastRead in Chat document...`);
    
    let lastReadUpdated = false;
    for (const status of chat.lastRead) {
        if (status.userId.equals(userIdObj)) {
            status.lastReadAt = new Date();
            lastReadUpdated = true;
            break;
        }
    }

    if (!lastReadUpdated) {
        chat.lastRead.push({
            userId: userIdObj,
            lastReadAt: new Date(),
        });
        lastReadUpdated = true;
    }

    if (chat.lastRead.length === 0 && chat.participants.length > 0) {
        const otherParticipantId = chat.participants.find(p => p.toString() !== userId);
        
        const initialStatuses: LastReadStatus[] = [
            { userId: userIdObj, lastReadAt: new Date() }
        ];

        if (otherParticipantId) {
             initialStatuses.push({ 
                userId: new Types.ObjectId(otherParticipantId), 
                lastReadAt: null 
             });
        }
        
        chat.lastRead = initialStatuses;
        console.log(`✅ Initialized lastRead array`);
    }
    
    await chat.save(); 
    console.log(`✅ Chat document saved`);

    const newUnreadCount = await this.getUnreadChatsCount(userId);
    
    console.log(`📊 New unread count for user: ${newUnreadCount}`);
    console.log(`🔵 ===== MARK AS READ DEBUG END (Bulk Update) =====\n`);

    return { messagesMarkedReadCount, newUnreadCount };
  }

  async getUnreadChatsCount(userId: string): Promise<number> {
    const unreadChats = await this.messageModel.aggregate([
      {
        $match: {
          $expr: {
            $and: [
              { $ne: [{ $toString: "$sender" }, userId] },
              { $eq: ["$isRead", false] }
            ]
          }
        },
      },
      {
        $group: {
          _id: '$chatId',
        },
      },
    ]);
    
    return unreadChats.length;
  }
}