// chat.service.ts
import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Chat } from './chat.schema';
import { Message } from './message.schema';
import { Model, Types } from 'mongoose';

@Injectable()
export class ChatService {
  constructor(
    @InjectModel(Chat.name) private chatModel: Model<Chat>,
    @InjectModel(Message.name) private messageModel: Model<Message>,
  ) {}

  // Create or get existing chat between two participants
  async createChat(userId: string, receiverId: string) {
    let chat = await this.chatModel.findOne({
      participants: { $all: [userId, receiverId] },
    });

    if (!chat) {
      chat = await this.chatModel.create({
        participants: [userId, receiverId],
      });
    }

    return chat;
  }

  // Send a message inside a chat room
  async sendMessage(senderId: string, chatId: string, content: string) {
    const chat = await this.chatModel.findById(chatId);

    if (!chat) {
      throw new NotFoundException('Chat not found');
    }

    const message = await this.messageModel.create({
      sender: senderId,
      chatId,
      content,
    });

    // Save last message for better UI experience
    chat.lastMessage = content;
    await chat.save();

    return message;
  }

  // Get all messages of a chat
  async getMessages(chatId: string) {
    return this.messageModel
      .find({ chatId })
      .populate('sender', 'userName imageUrl role')
      .sort({ createdAt: 1 });
  }

  // Get all chats of a user
  async getUserChats(userId: string) {
    return this.chatModel
      .find({ participants: userId })
      .populate('participants', 'userName imageUrl role')
      .sort({ updatedAt: -1 });
  }
}