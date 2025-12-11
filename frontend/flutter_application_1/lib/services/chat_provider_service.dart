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

  // لتعيين الدردشة النشطة/المفتوحة
  void setActiveChat(String? chatId) {
    _activeChatId = chatId;
    if (chatId != null && _socket?.connected == true) {
      joinChatRoom(chatId);
    }
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
        
        final newMessage = ChatMessage(
          id: messageData['_id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          text: messageData['content']?.toString() ?? '',
          createdAt: DateTime.tryParse(messageData['createdAt']?.toString() ?? '') ?? DateTime.now(),
          isMe: isMe,
          isRead: isMe || (messageData['isRead'] ?? false), 
        );
        
        // 1. تحديث واجهة المستخدم فورياً إذا كانت هذه الدردشة هي النشطة
        if (_activeChatId == chatID) {
          print('✅ Socket: New message received for active chat. Calling onNewMessage.');
          onNewMessage?.call(newMessage);
          
          // 2. إذا لم تكن الرسالة مرسلة مني، يتم وضع علامة "مقروءة"
          if (!isMe) {
             markAsRead(chatID); 
          }
        } else {
          print('ℹ️ Socket: New message for inactive chat: $chatID. Only updating counts.');
        }

        // 3. تحديث حالة الرسائل الأخرى (لإظهار علامة "مقروءة" للرسائل المرسلة مني)
        onMessageStatusUpdate?.call();
      }
      
      // 4. تحديث عدد الرسائل غير المقروءة (Global count)
      fetchUnreadCount();
    });

    _socket?.on('unreadCountUpdated', (data) {
      final count = data['count'] ?? 0;
      unreadGlobalCount.value = count;
      print('📊 Socket: Global unread count updated: $count');
    });
    
    _socket?.on('messagesRead', (data) {
      // يستخدم لتحديث علامات "مقروءة" لرسائلي المرسلة
      onMessageStatusUpdate?.call();
    });

  }
  
  void joinChatRoom(String chatId) {
    if (_socket?.connected == true) {
      print('Joining chat room: $chatId');
      _socket?.emit('joinRoom', {'chatId': chatId, 'userId': currentUserId});
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
        final count = data['count'] ?? 0;
        unreadGlobalCount.value = count;
      }
    } catch (e) {
      print('❌ Error fetching unread count: $e');
    }
  }

  Future<void> markAsRead(String chatId) async {
    final token = await AuthService.getToken();
    if (token == null) return;
    
    // 1. إطلاق الحدث عبر السوكيت (الأفضل والأسرع)
    if (_socket?.connected == true) {
      print('📖 Sending markAsRead via Socket');
      _socket?.emit('markAsRead', {'chatId': chatId, 'userId': currentUserId});
      // لا نستخدم return هنا ونكمل إلى HTTP كـ fallback
    }

    // 2. Fallback to HTTP if socket not connected or as guarantee
    try {
      print('📖 Sending markAsRead via HTTP (Guarantee)');
      final response = await http.patch(
        Uri.parse('$_baseUrl/chat/mark-read/$chatId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        print('✅ MarkAsRead sent via HTTP successfully');
        // تحديث إضافي للحالة بعد التأكيد عبر HTTP
        onMessageStatusUpdate?.call();
        fetchUnreadCount();
      }
    } catch (e) {
      print('❌ Error marking as read via HTTP: $e');
    }
  }
  
  // دالة لجلب قائمة المحادثات (Threads)
  Future<List<Map<String, dynamic>>> fetchUserChats() async {
    final token = await AuthService.getToken();
    if (token == null) return [];
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/my-chats'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonChats = json.decode(response.body);
        return jsonChats.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('❌ Error fetching user chats: $e');
      return [];
    }
  }
  
  // ✅ الدالة الصحيحة لجلب الرسائل، والتي يجب استدعاؤها في messages_provider.dart باسم fetchChatMessages
  Future<List<ChatMessage>> fetchChatMessages(String chatId) async {
    final token = await AuthService.getToken();
    if (token == null) return [];
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/messages/$chatId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonMessages = json.decode(response.body);
        
        return jsonMessages.map((msgJson) {
          final senderData = msgJson['sender'];
          String senderId = senderData is Map 
            ? _cleanId(senderData['_id'] ?? senderData['id'])
            : _cleanId(senderData);
          
          return ChatMessage(
            id: _cleanId(msgJson['_id']),
            text: msgJson['content'] ?? '',
            createdAt: DateTime.tryParse(msgJson['createdAt'] ?? '') ?? DateTime.now(),
            isMe: senderId == currentUserId,
            isRead: msgJson['isRead'] ?? false, 
          );
        }).toList(); 
        
      } else {
        print('⚠️ Failed to fetch messages: ${response.statusCode}');
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      print('❌ Error fetching messages: $e');
      throw Exception('Failed to load messages');
    }
  }
  
  // دالة إرسال الرسالة
  Future<void> sendMessage(String chatId, String content) async {
    final token = await AuthService.getToken();
    
    if (token != null) {
      try {
        print('📤 Sending message via HTTP (Triggers Socket Push on Server)');
        final response = await http.post(
          Uri.parse('$_baseUrl/chat/send'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({'chatId': chatId, 'content': content}),
        );
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          print('✅ Message sent via HTTP successfully');
          onMessageStatusUpdate?.call();
        } else {
           throw Exception('Failed to send message via HTTP: ${response.body}');
        }
      } catch (e) {
        print('❌ Error sending message via HTTP: $e');
        rethrow;
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
      print('❌ Error deleting chat: $e');
      return false;
    }
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    print('🔌 Socket disposed');
  }
}