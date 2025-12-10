// chat.module.ts
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ChatController } from './chat.controller';
import { ChatService } from './chat.service';
import { Chat, ChatSchema } from './chat.schema';
import { Message, MessageSchema } from './message.schema';
import { ChatGateway } from './chat.gateway';
// 👇 1. استيراد المودولز والكيانات الجديدة
import { NotificationModule } from '../notification/notification.module';
import { User, UserSchema } from '../auth/user.entity'; // تأكد من المسار الصحيح لـ User
import { ProviderModule } from '../providers/provider.module'; // 💡 تأكد من مسار الملف الصحيح!
@Module({
  imports: [
    // 👇 2. إضافة NotificationModule
    NotificationModule,
    ProviderModule, 
    MongooseModule.forFeature([
      { name: Chat.name, schema: ChatSchema },
      { name: Message.name, schema: MessageSchema },
      { name: User.name, schema: UserSchema }, // 👇 3. نحتاج User للوصول للتوكن
    ]),
  ],
  controllers: [ChatController],
  providers: [ChatService, ChatGateway],
})
export class ChatModule {}