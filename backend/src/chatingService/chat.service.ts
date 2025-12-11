// chat.service.ts
import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Chat, LastReadStatus } from './chat.schema';
import { Message } from './message.schema';
import { Model, Types } from 'mongoose';
import { User } from '../auth/user.entity'; 
import { NotificationService } from '../notification/notification.service';
import { NotificationType, RecipientType } from '../notification/notification.schema';
import { ProviderService } from '../providers/provider.service'; 

@Injectable()
export class ChatService {
  constructor(
    @InjectModel(Chat.name) private chatModel: Model<Chat>,
    @InjectModel(Message.name) private messageModel: Model<Message>,
    @InjectModel(User.name) private userModel: Model<User>, 
    private notificationService: NotificationService,
    private providerService: ProviderService,
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
    const chat = await this.chatModel.findById(chatId);
    if (!chat) throw new NotFoundException('Chat not found');

    const message = await this.messageModel.create({ sender: senderId, chatId, content });
    chat.lastMessage = content;
    
    const participantObject = chat.participants.find(
      (p) => p.toString() !== senderId.toString()
    );
    const recipientId: string | null = participantObject ? participantObject.toString() : null; 

    chat.lastRead = chat.lastRead.map(status => {
      if (status.userId.toString() === senderId) {
        status.lastReadAt = new Date();
      } else if (recipientId && status.userId.toString() === recipientId) {
        status.lastReadAt = null;
      }
      return status;
    });

    await chat.save();
    
    const sender = await this.userModel.findById(senderId).exec();
    if (!sender) {
      throw new NotFoundException('Sender user not found'); 
    }
    
    let notificationTitle: string;
    const senderRole = sender['role'] as string; 
    
    if (senderRole === 'vendor') {
      try {
        const companyName = await this.providerService.findCompanyNameByUserId(senderId);
        notificationTitle = `New message from ${companyName}`; 
      } catch (e) {
        console.error('Could not find company name for vendor:', senderId, e.message);
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
      newUnreadCount = await this.getUnreadChatsCount(recipientId);

      const recipient = await this.userModel.findById(recipientId);
      if (recipient) {
        const fcmToken = recipient['fcmToken'] as string | undefined;
        if (fcmToken) { 
          const targetType = recipient['role'] === 'vendor' ? RecipientType.VENDOR : RecipientType.USER;
          
          const notifDto = {
            recipientId: recipient._id as Types.ObjectId, 
            recipientType: targetType,
            title: notificationTitle, 
            body: content.substring(0, 50) + (content.length > 50 ? '...' : ''),
            type: NotificationType.NEW_MESSAGE,
            metadata: { chatId: chatId, messageId: message._id as Types.ObjectId }
          };
          
          await this.notificationService.createNotification(notifDto, fcmToken);
        }
      }
    }
    
    return { message, recipientId, newUnreadCount };
  }

  async getMessages(chatId: string) {
    // ✅ Use string because chatId is stored as string in database
    return this.messageModel
      .find({ chatId: chatId })  // Use string, not ObjectId
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

    // ✅ Use string for deletion too
    await this.messageModel.deleteMany({ chatId: chatId });
    const result = await this.chatModel.deleteOne({ _id: chatId });

    return { deleted: result.deletedCount > 0, chatId };
  }

  /**
   * ✅ FIXED: Robust mark as read with multiple fallback strategies
   */
 // chat.service.ts

// ... (بقية الدالة)

async markMessagesAsRead(userId: string, chatId: string): Promise<{ messagesMarkedReadCount: number, newUnreadCount: number }> {
    console.log(`\n🔵 ===== MARK AS READ DEBUG START (Bulk Update) =====`);
    
    // Validate and convert IDs
    let userIdObj: Types.ObjectId;
    
    try {
      userIdObj = new Types.ObjectId(userId);
    } catch (error) {
      throw new Error('Invalid User ID format');
    }

    // 1. Find the chat
    // استخدمنا chatIdObj في findById للحصول على الوثيقة (Chat) بشكل سليم
    const chat = await this.chatModel.findById(chatId); 

    // ✅ تصحيح الخطأ الأول: التحقق من وجود 'chat' قبل استخدامها
    if (!chat) {
        throw new NotFoundException('Chat not found');
    }

    // Verify participation
    const isParticipant = chat.participants.some(p => p.toString() === userId);
    if (!isParticipant) {
        throw new NotFoundException('User is not a participant in this chat');
    }
    
    // 🎯 FIX: Perform BULK UPDATE (Solution for messagesMarkedAsRead: 0)
    // نستخدم الـ chatId كـ string هنا لضمان التطابق مع قاعدة البيانات
    const updateResult = await this.messageModel.updateMany(
      {
        chatId: chatId, // <<< هنا نستخدم الـ string ID
        isRead: false,
        sender: { $ne: userIdObj } 
      },
      { $set: { isRead: true } }
    );
    
    const messagesMarkedReadCount = updateResult.modifiedCount;
    
    console.log(`✅ Bulk Update executed. Messages marked as read: ${messagesMarkedReadCount}`);

    // 2. Update lastRead in Chat document
    console.log(`📝 Updating lastRead in Chat document...`);
    
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

    // ✅ تصحيح الخطأ الثاني: Initializing lastRead array (Type Safety)
    if (chat.lastRead.length === 0 && chat.participants.length > 0) {
        const otherParticipantId = chat.participants.find(p => p.toString() !== userId);
        
        const initialStatuses: LastReadStatus[] = [
            { userId: userIdObj, lastReadAt: new Date() }
        ];

        // نضيف المشارك الآخر فقط إذا وجدناه (نستخدم Types.ObjectId مباشرة)
        if (otherParticipantId) {
             initialStatuses.push({ 
                userId: new Types.ObjectId(otherParticipantId), 
                lastReadAt: null 
             });
        }
        
        chat.lastRead = initialStatuses;
        console.log(`✅ Initialized lastRead array`);
    }
    
    // 🛑 الآن بات آمناً: chat مؤكد أنه ليس null
    await chat.save(); 
    console.log(`✅ Chat document saved`);

    // Calculate new unread count
    const newUnreadCount = await this.getUnreadChatsCount(userId);
    
    console.log(`📊 New unread count for user: ${newUnreadCount}`);
    console.log(`🔵 ===== MARK AS READ DEBUG END (Bulk Update) =====\n`);

    return { messagesMarkedReadCount, newUnreadCount };
}

  async getUnreadChatsCount(userId: string): Promise<number> {
    // ✅ Match both string and ObjectId formats for sender
    const unreadChats = await this.messageModel.aggregate([
      {
        $match: {
          $expr: {
            $and: [
              { $ne: [{ $toString: "$sender" }, userId] },  // Compare as strings
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