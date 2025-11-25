// chat.dto.ts

import { IsNotEmpty, IsString, IsOptional } from 'class-validator';

// ===========================
// Create Conversation DTO
// ===========================
export class CreateConversationDto {
  @IsNotEmpty()
  @IsString()
  receiverId: string;
}

// ===========================
// Send Message DTO
// ===========================
export class SendMessageDto {
  @IsNotEmpty()
  @IsString()
  chatId: string;

  @IsNotEmpty()
  @IsString()
  content: string;
}

// ===========================
// Join Room DTO (WebSocket)
// ===========================
export class JoinRoomDto {
  @IsNotEmpty()
  @IsString()
  chatId: string;
}

// ===========================
// Mark Messages As Read DTO
// ===========================
export class MarkReadDto {
  @IsNotEmpty()
  @IsString()
  chatId: string;
}

// ===========================
// Get Messages (Pagination)
// OPTIONAL
// ===========================
export class GetMessagesDto {
  @IsNotEmpty()
  @IsString()
  chatId: string;

  @IsOptional()
  @IsString()
  page?: string;

  @IsOptional()
  @IsString()
  limit?: string;
}
