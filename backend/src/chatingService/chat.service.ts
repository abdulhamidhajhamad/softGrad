// chat.service.ts
import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Chat } from './chat.schema';
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
  ) 
  {}

  /**
   * @description تنشئ أو تجلب محادثة موجودة بين مشاركين.
   * عند الإنشاء، يتم تهيئة حالة القراءة (lastRead) حيث يُعتبر المرسِل (المُنشِئ) قد قرأ المحادثة، ويُعتبر المستلِم لم يقرأها (lastReadAt: null).
   */
  async createChat(userId: string, receiverId: string) {
    let chat = await this.chatModel.findOne({
      participants: { $all: [userId, receiverId] },
    });

    if (!chat) {
      chat = await this.chatModel.create({
        participants: [userId, receiverId],
        // ✨ NEW: تهيئة حالة القراءة للطرفين
        lastRead: [
          { userId: new Types.ObjectId(userId), lastReadAt: new Date() }, // المرسِل: مقروء
          { userId: new Types.ObjectId(receiverId), lastReadAt: null }, // المستلِم: غير مقروء
        ]
      });
    }

    // إذا كانت المحادثة موجودة، يجب التأكد من وجود حقل lastRead
    if (chat && (!chat.lastRead || chat.lastRead.length === 0)) {
        // إذا كان الموديل قديماً، قم بتهيئته بالقيم الافتراضية
         chat.lastRead = [
            { userId: new Types.ObjectId(userId), lastReadAt: new Date() },
            { userId: new Types.ObjectId(receiverId), lastReadAt: null }, 
        ];
        await chat.save();
    }


    return chat;
  }

  /**
   * @description يرسل رسالة ويحدث حالة القراءة في وثيقة المحادثة (Chat Document).
   * يتم تعيين lastReadAt للمرسِل إلى الوقت الحالي، وللمستلِم إلى null (غير مقروء).
   */
 async sendMessage(senderId: string, chatId: string, content: string): Promise<{ message: Message, recipientId: string | null, newUnreadCount: number }> {
    const chat = await this.chatModel.findById(chatId);
    if (!chat) throw new NotFoundException('Chat not found');

    const message = await this.messageModel.create({ sender: senderId, chatId, content });
    chat.lastMessage = content;
    
    // 1. تحديد هوية المستلم (الطرف الآخر في المحادثة)
    // ✅ تم تعريفه هنا لمرة واحدة فقط
    const participantObject = chat.participants.find(
      (p) => p.toString() !== senderId.toString()
    );
    const recipientId: string | null = participantObject ? participantObject.toString() : null; 

    // 2. ✨ NEW: تحديث حالة القراءة في وثيقة Chat
    // يتم تعيين lastReadAt للمستلِم إلى null (غير مقروء)
    // ويتم تحديث آخر وقت للمرسل
    chat.lastRead = chat.lastRead.map(status => {
        if (status.userId.toString() === senderId) {
            // المرسِل: مقروء حالياً
            status.lastReadAt = new Date();
        } else if (recipientId && status.userId.toString() === recipientId) {
            // المستلِم: رسالة جديدة، وضع "غير مقروء"
            status.lastReadAt = null;
        }
        return status;
    });

    await chat.save();
    
    // 3. جلب بيانات المرسل (Sender)
    const sender = await this.userModel.findById(senderId).exec();
    if (!sender) {
        throw new NotFoundException('Sender user not found'); 
    }
    
    let notificationTitle: string;
    const senderRole = sender['role'] as string; 
    
    // 4. ✨ تحديد عنوان الإشعار بناءً على دور المرسل
    if (senderRole === 'vendor') {
        // الحالة 1: المرسل مزود خدمة (Vendor)
        try {
            const companyName = await this.providerService.findCompanyNameByUserId(senderId);
            notificationTitle = `New message from ${companyName}`; 
        } catch (e) {
            console.error('Could not find company name for vendor:', senderId, e.message);
            notificationTitle = `New message from Vendor`;
        }
    } else if (senderRole === 'admin') {
        // الحالة 2: المرسل أدمن (Admin)
        notificationTitle = `New message from Admin`; 
    } else {
        // الحالة 3: المرسل مستخدم عادي (User) أو دور آخر
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
          
          // 5. استخدام العنوان الديناميكي الجديد
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

  /**
   * @description جلب جميع رسائل محادثة معينة.
   */
  async getMessages(chatId: string) {
    return this.messageModel
      .find({ chatId })
      .populate('sender', 'userName imageUrl role')
      .sort({ createdAt: 1 });
  }

  /**
   * @description جلب جميع محادثات مستخدم معين.
   * يتم تمرير بيانات حالة القراءة (lastRead) في وثيقة المحادثة ليتمكن الـ Frontend من تحديد ما إذا كانت المحادثة غير مقروءة للمستخدم الحالي.
   */
  async getUserChats(userId: string) {
    return this.chatModel
      .find({ participants: userId })
      .populate('participants', 'userName imageUrl role')
      .sort({ updatedAt: -1 });
  }

  /**
   * @description حذف محادثة ورسائلها المرتبطة. يتطلب أن يكون المستخدم مشاركاً في المحادثة.
   */
  async deleteChat(userId: string, chatId: string): Promise<any> {
    const chat = await this.chatModel.findById(chatId);

    if (!chat) {
      throw new NotFoundException('Chat not found');
    }

    // تحقق أمني: فقط المشاركون يمكنهم الحذف
    if (!chat.participants.map(p => p.toString()).includes(userId)) {
        throw new NotFoundException('Chat not found or access denied');
    }

    // حذف جميع الرسائل المرتبطة بالمحادثة أولاً
    await this.messageModel.deleteMany({ chatId });
    
    // ثم حذف المحادثة نفسها
    const result = await this.chatModel.deleteOne({ _id: chatId });

    return { deleted: result.deletedCount > 0, chatId };
  }

  /**
   * @description تمييز رسائل محادثة معينة كـ "مقروءة" (isRead: true) في وثائق الرسائل (Message).
   * كما يقوم بتحديث حقل lastReadAt في وثيقة المحادثة (Chat Document) للمستخدم الحالي إلى الوقت الحالي.
   * @returns {messagesMarkedReadCount: number, newUnreadCount: number}
   */
  async markMessagesAsRead(userId: string, chatId: string): Promise<{ messagesMarkedReadCount: number, newUnreadCount: number }> {
    const userIdObj = new Types.ObjectId(userId);
    const chatIdObj = new Types.ObjectId(chatId);

    // العثور على المحادثة لتحديث حالة القراءة
    const chat = await this.chatModel.findById(chatIdObj);
    if (!chat) throw new NotFoundException('Chat not found');

    // 1. تحديث الرسائل الفردية كمقروءة (المنطق القديم)
    const updateResult = await this.messageModel.updateMany(
      {
        chatId: chatIdObj,
        sender: { $ne: userIdObj }, 
        isRead: false,
      },
      {
        $set: { isRead: true },
      },
    );

    const messagesMarkedReadCount = updateResult.modifiedCount;

    // 2. ✨ NEW: تحديث حالة القراءة في وثيقة Chat (Mark as read للمستخدم الحالي)
    // يتم تحديث lastReadAt إلى الوقت الحالي
    chat.lastRead = chat.lastRead.map(status => {
        if (status.userId.equals(userIdObj)) {
            // المستخدم يقرأ المحادثة، تحديث وقت القراءة
            status.lastReadAt = new Date();
        }
        return status;
    });
    // ✅ التعامل مع الحالة التي لم يكن فيها حقل lastRead موجوداً مسبقاً
     if (chat.lastRead.length === 0) {
        const otherParticipantId = chat.participants.find(p => p.toString() !== userId);
        chat.lastRead = [
            { userId: userIdObj, lastReadAt: new Date() },
            { userId: new Types.ObjectId(otherParticipantId), lastReadAt: null }, 
        ];
    }
    
    await chat.save();


    let newUnreadCount = 0;

    if (messagesMarkedReadCount > 0) {
      newUnreadCount = await this.getUnreadChatsCount(userId);
    }

    // ✅ إرجاع البيانات
    return { messagesMarkedReadCount, newUnreadCount };
  }

  /**
   * @description جلب عدد المحادثات التي تحتوي على رسائل غير مقروءة للمستخدم الحالي.
   * *ملحوظة*: هذه الدالة ما زالت تعتمد على حقل `isRead` في وثيقة `Message`، 
   * ولكن المنطق الآن مدعوم بحقل `lastRead` في `Chat` لتحديد حالة "غير مقروءة" في القائمة الرئيسية.
   */
  async getUnreadChatsCount(userId: string): Promise<number> {
    const userIdObj = new Types.ObjectId(userId);

    // نستخدم الـ Aggregate للعثور على عدد المحادثات الفريدة التي تحتوي على رسائل غير مقروءة
    const unreadChats = await this.messageModel.aggregate([
      {
        $match: {
          sender: { $ne: userIdObj }, // الرسائل المرسلة من الطرف الآخر
          isRead: false, // الرسائل غير المقروءة
        },
      },
      {
        $group: {
          _id: '$chatId', // التجميع حسب الـ Chat ID
        },
      },
    ]);
    
    // عدد المحادثات غير المقروءة هو طول مصفوفة الـ chat IDs الفريدة
    return unreadChats.length;
  }
}