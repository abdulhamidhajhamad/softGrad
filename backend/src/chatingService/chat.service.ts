// chat.service.ts - FIXED VERSION (No DB notification for messages)
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
import { NotificationsGateway } from '../notification/notification.gateway';

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
    private notificationsGateway: NotificationsGateway,
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
    this.logger.log(`Sender: ${senderId}, Chat: ${chatId}, Content: ${content}`);
    
    const chat = await this.chatModel.findById(chatId);
    if (!chat) {
      this.logger.error(`❌ Chat not found: ${chatId}`);
      throw new NotFoundException('Chat not found');
    }
    this.logger.log(`✅ Chat found with participants: ${chat.participants}`);

    // Create message (isRead defaults to false in schema)
    // ✅ حفظ chatId و sender كـ ObjectId وليس String
    this.logger.log(`📝 Creating message...`);
    const chatIdObj = new Types.ObjectId(chatId);
    const senderIdObj = new Types.ObjectId(senderId);
    const message = await this.messageModel.create({ 
      sender: senderIdObj,  // ✅ ObjectId بدلاً من String
      chatId: chatIdObj,    // ✅ ObjectId بدلاً من String
      content 
    });
    this.logger.log(`✅ Message created with ID: ${message._id}, isRead: ${message.isRead}`);
    
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
    
    // ✅ حساب عدد الرسائل غير المقروءة للمستلم قبل إرسال الـ WebSocket
    let newUnreadCount = 0;
    if (recipientId) {
      newUnreadCount = await this.getUnreadChatsCount(recipientId);
      this.logger.log(`📊 Unread count for recipient: ${newUnreadCount}`);
    }
    
    // Send via WebSocket (مع إرسال تحديث الـ unread count)
    try {
      this.chatGateway.sendNewMessageToRoom(chatId, message, recipientId ?? undefined, newUnreadCount);
      this.logger.log(`✅ Message sent to WebSocket room with unread count`);
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

    // newUnreadCount تم حسابه مسبقاً قبل إرسال الـ WebSocket
    
    if (recipientId) {
      this.logger.log(`\n📬 Processing notification for recipient: ${recipientId}`);
      this.logger.log(`📊 Unread count (already calculated): ${newUnreadCount}`);

      const recipient = await this.userModel.findById(recipientId);
      if (!recipient) {
        this.logger.warn(`⚠️ Recipient not found: ${recipientId}`);
      } else {
        this.logger.log(`✅ Recipient found: ${recipient['userName']}`);
        
        const fcmToken = recipient['fcmToken'] as string | undefined;
        const recipientRole = recipient['role'] as string;
        
        this.logger.log(`📱 FCM Token: ${fcmToken ? 'EXISTS' : 'MISSING'}`);
        this.logger.log(`👤 Recipient role: ${recipientRole}`);
        
        // ✅ التحقق من حالة اتصال المستخدم
        const isRecipientOnline = this.notificationsGateway.isUserConnected(recipientId);
        this.logger.log(`🔌 Recipient online status: ${isRecipientOnline}`);
        
        // ✅ إرسال FCM فقط إذا كان المستخدم offline و عنده token
        const shouldSendFCM = !isRecipientOnline && fcmToken && fcmToken.trim() !== '';
        
        if (shouldSendFCM) {
          this.logger.log(`🚀 Recipient is OFFLINE - Sending FCM notification ONLY`);
          
          try {
            // ✅ إرسال FCM مباشرة بدون حفظ في قاعدة البيانات
            await this.notificationService.sendNotification(
              fcmToken!,
              notificationTitle,
              content.substring(0, 100) + (content.length > 100 ? '...' : '')
            );
            
            this.logger.log(`✅ FCM notification sent successfully (no DB save)`);
          } catch (fcmError) {
            this.logger.error(`❌ Error sending FCM notification: ${fcmError.message}`);
          }
        } else if (isRecipientOnline) {
          this.logger.log(`✅ Recipient is ONLINE - Message delivered via WebSocket (no FCM needed)`);
        } else if (!fcmToken) {
          this.logger.log(`⚠️ No FCM token - Cannot send push notification`);
        }
      }
    } else {
      this.logger.warn(`⚠️ No recipient found in chat`);
    }
    
    this.logger.log(`🔵 ===== SEND MESSAGE END =====\n`);
    return { message, recipientId, newUnreadCount };
  }

  async getMessages(chatId: string) {
    // ✅ البحث بكلا النوعين: ObjectId و String
    this.logger.log(`📨 getMessages called with chatId: ${chatId}`);
    const chatIdObj = new Types.ObjectId(chatId);
    
    const messages = await this.messageModel
      .find({ 
        $or: [
          { chatId: chatIdObj },
          { chatId: chatId }
        ]
      })
      .populate('sender', 'userName imageUrl role')
      .sort({ createdAt: 1 });
    
    this.logger.log(`📨 Found ${messages.length} messages for chatId: ${chatId}`);
    return messages;
  }

  async getUserChats(userId: string) {
    const chats = await this.chatModel
      .find({ participants: userId })
      .populate('participants', 'userName imageUrl role')
      .sort({ updatedAt: -1 })
      .lean();
    
    for (const chat of chats) {
      for (const participant of chat.participants as any[]) {
        if (participant && participant.role === 'vendor') {
          try {
            const companyName = await this.providerService.findCompanyNameByUserId(participant._id.toString());
            participant.companyName = companyName;
          } catch (e) {
            participant.companyName = participant.userName;
          }
        }
      }
    }
    
    return chats;
  }

  async deleteChat(userId: string, chatId: string): Promise<any> {
    const chat = await this.chatModel.findById(chatId);

    if (!chat) {
      throw new NotFoundException('Chat not found');
    }

    if (!chat.participants.map(p => p.toString()).includes(userId)) {
      throw new NotFoundException('Chat not found or access denied');
    }

    // ✅ حذف بكلا النوعين: ObjectId و String
    const chatIdObj = new Types.ObjectId(chatId);
    await this.messageModel.deleteMany({ 
      $or: [
        { chatId: chatIdObj },
        { chatId: chatId }
      ]
    });
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
    
    console.log(`📖 markMessagesAsRead called by userId: ${userId} for chatId: ${chatId}`);
    
    // ✅ دعم الـ chatId كـ ObjectId و String
    const chatIdObj = new Types.ObjectId(chatId);
    
    const updateResult = await this.messageModel.updateMany(
      {
        $or: [
          { chatId: chatId },        // كـ String
          { chatId: chatIdObj },     // كـ ObjectId
        ],
        isRead: false,
        sender: { $ne: userIdObj } 
      },
      { $set: { isRead: true } }
    );
    
    const messagesMarkedReadCount = updateResult.modifiedCount;
    
    console.log(`✅ Bulk Update executed. Messages marked as read: ${messagesMarkedReadCount} (marking messages NOT from ${userId})`);

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
    // ✅ أولاً: جلب جميع الشاتات التي يشارك فيها المستخدم
    const userChats = await this.chatModel.find({ participants: userId }).select('_id').lean();
    
    if (userChats.length === 0) {
      return 0;
    }
    
    // ✅ تحويل الـ chatIds لـ ObjectId و String للمطابقة مع كلا النوعين
    const userChatIdsAsObjectId = userChats.map(chat => chat._id);
    const userChatIdsAsString = userChats.map(chat => chat._id.toString());
    
    // ✅ ثانياً: حساب عدد الشاتات التي فيها رسائل غير مقروءة
    const unreadChats = await this.messageModel.aggregate([
      {
        $match: {
          $or: [
            // مطابقة الـ chatId كـ ObjectId
            { chatId: { $in: userChatIdsAsObjectId } },
            // مطابقة الـ chatId كـ String
            { chatId: { $in: userChatIdsAsString } },
          ],
          // رسائل ليست من المستخدم نفسه (دعم ObjectId و String)
          sender: { $nin: [new Types.ObjectId(userId), userId] },
          // رسائل غير مقروءة
          isRead: false,
        },
      },
      {
        $group: {
          _id: '$chatId',
        },
      },
    ]);
    
    this.logger.log(`📊 getUnreadChatsCount for ${userId}: ${unreadChats.length} chats with unread messages`);
    return unreadChats.length;
  }

async getUnreadCountsPerChat(userId: string) {
  // ✅ أولاً: جلب جميع الشاتات التي يشارك فيها المستخدم
  const userChats = await this.chatModel.find({ participants: userId }).select('_id').lean();
  
  if (userChats.length === 0) {
    return [];
  }
  
  // ✅ تحويل الـ chatIds لـ ObjectId و String للمطابقة مع كلا النوعين
  const userChatIdsAsObjectId = userChats.map(chat => chat._id);
  const userChatIdsAsString = userChats.map(chat => chat._id.toString());
  
  const unreadCounts = await this.messageModel.aggregate([
    {
      $match: {
        $or: [
          // مطابقة الـ chatId كـ ObjectId
          { chatId: { $in: userChatIdsAsObjectId } },
          // مطابقة الـ chatId كـ String
          { chatId: { $in: userChatIdsAsString } },
        ],
        // 1. استبعاد الرسائل التي أرسلها المستخدم نفسه (دعم ObjectId و String)
        sender: { $nin: [new Types.ObjectId(userId), userId] },
        // 2. جلب الرسائل غير المقروءة فقط
        isRead: false,
      },
    },
    {
      $group: {
        // 3. تجميع النتائج حسب معرف الشات
        _id: '$chatId',
        // 4. حساب عدد الرسائل في كل مجموعة
        count: { $sum: 1 },
      },
    },
  ]);

  // تنسيق النتيجة لتكون أسهل في القراءة للفرونت إند
  return unreadCounts.map((item) => ({
    chatId: item._id,
    unreadCount: item.count,
  }));
}
  
}