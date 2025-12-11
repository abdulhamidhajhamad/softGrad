// lib/services/chat_provider_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/screens/chat_screen.dart';

class ChatProviderService {
  // Singleton
  static final ChatProviderService _instance = ChatProviderService._internal();
  factory ChatProviderService() => _instance;
  ChatProviderService._internal();

  static const String _baseUrl = 'http://localhost:3000';  
  
  IO.Socket? _socket;
  static final ValueNotifier<int> unreadGlobalCount = ValueNotifier<int>(0);
  String? currentUserId;

  String? _activeChatId;

  void Function(ChatMessage)? onNewMessage;
  void Function()? onMessageStatusUpdate;

  String _cleanId(dynamic id) {
    if (id == null) return '';
    return id.toString()
        .replaceAll('ObjectId', '')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .trim();
  }

  Future<void> initSocket() async {
    final token = await AuthService.getToken();
    
    if (_socket != null && _socket!.connected) {
      print('Socket already connected');
      return;
    }

    _socket = IO.io(
      _baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect() 
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .enableForceNewConnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000)
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      print('✅ Socket Connected ID: ${_socket!.id}');
      if (_activeChatId != null) {
        joinChatRoom(_activeChatId!);
      }
    });

    _socket!.onDisconnect((_) {
      print('❌ Socket Disconnected');
    });

    _socket!.onConnectError((data) {
      print('⚠️ Connection Error: $data');
    });

    _socket?.on('newMessage', (data) {
      final messageData = data['message'] ?? data;
      
      if (messageData != null) {
        final senderData = messageData['sender'];
        String senderId = senderData is Map 
            ? _cleanId(senderData['_id'] ?? senderData['id'])
            : _cleanId(senderData);
            
        final chatID = _cleanId(messageData['chat'] ?? data['chatId']);
        final isMe = senderId == currentUserId;
        
        if (!isMe && _activeChatId == chatID) {
           markAsRead(chatID); 
        }

        final newMessage = ChatMessage(
          id: messageData['_id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          text: messageData['content']?.toString() ?? '',
          createdAt: DateTime.tryParse(messageData['createdAt']?.toString() ?? '') ?? DateTime.now(),
          isMe: isMe,
          isRead: isMe || (_activeChatId == chatID) || (messageData['isRead'] ?? false),
        );

        onNewMessage?.call(newMessage);
      }
      
      if (_activeChatId == null) {
        fetchUnreadCount();
      }
    });

    _socket?.on('unreadCountUpdated', (data) {
      if (data != null && data['count'] != null) {
        unreadGlobalCount.value = data['count'];
      } else {
        fetchUnreadCount();
      }
    });
  }

  void joinChatRoom(String chatId) {
    _activeChatId = chatId;
    
    if (currentUserId != null) {
      print('🚪 Joining room: $chatId with user: $currentUserId');
      _socket?.emit('joinRoom', { 'chatId': chatId, 'userId': currentUserId });
      
      // Mark as read after joining room with slight delay
      Future.delayed(const Duration(milliseconds: 200), () {
        markAsRead(chatId);
      });
    }
  }

  void leaveChatRoom(String chatId) {
    if (_activeChatId == chatId) {
      _activeChatId = null;
    }
    _socket?.emit('leaveChat', chatId);
    fetchUnreadCount();
  }

  Future<void> markAsRead(String chatId) async {
    print('📖 Marking chat as read: $chatId');
    
    // Method 1: Socket emission (real-time)
    if (_socket != null && _socket!.connected && currentUserId != null) {
      print('📡 Emitting markAsRead via socket');
      _socket?.emit('markAsRead', {
        'chatId': chatId,
        'userId': currentUserId,
      });
    } else {
      print('⚠️ Socket not connected or userId null');
    }

    // Method 2: HTTP request (fallback and guarantee)
    final token = await AuthService.getToken();
    if (token != null) {
      try {
        print('🌐 Sending HTTP PATCH request to mark as read');
        final response = await http.patch(
          Uri.parse('$_baseUrl/chat/mark-read/$chatId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        
        if (response.statusCode == 200) {
          print('✅ HTTP MarkRead successful');
          // Trigger unread count update
          fetchUnreadCount();
        } else {
          print('⚠️ HTTP MarkRead failed: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        print('❌ HTTP MarkRead Error: $e');
      }
    } else {
      print('⚠️ No auth token available');
    }
  }

  Future<void> fetchUnreadCount() async {
    final token = await AuthService.getToken();
    if (token == null) return;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/unread-count'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        unreadGlobalCount.value = data['count'] ?? 0;
        print('📊 Unread count updated: ${unreadGlobalCount.value}');
      }
    } catch (e) {
      print('❌ Error fetching unread count: $e');
    }
  }

  Future<List<dynamic>> fetchMessages(String chatId) async {
    final token = await AuthService.getToken();
    if (token == null) return [];
    final response = await http.get(
      Uri.parse('$_baseUrl/chat/messages/$chatId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load messages');
  }
  
  Future<List<dynamic>> fetchUserChats() async {
    final token = await AuthService.getToken();
    if (token == null) return [];
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/my-chats'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200 ? json.decode(response.body) : [];
    } catch (e) { return []; }
  }

  Future<void> sendMessage(String chatId, String content) async {
    final token = await AuthService.getToken();
    
    if (_socket?.connected == true && currentUserId != null) {
      _socket?.emit('sendMessage', {
        'chatId': chatId,
        'senderId': currentUserId,
        'content': content
      });
    } else {
      if (token != null) {
        await http.post(
          Uri.parse('$_baseUrl/chat/send'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({'chatId': chatId, 'content': content}),
        );
      }
    }
  }

  Future<bool> deleteChat(String chatId) async {
    final token = await AuthService.getToken();
    if (token == null) return false;
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/chat/$chatId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        fetchUnreadCount();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    print('🔌 Socket disposed');
  }
}   