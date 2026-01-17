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

  // ✅ استخدام AuthService.baseUrl بدلاً من URL ثابت
  String get _baseUrl => AuthService.baseUrl;
  static String get _staticBaseUrl => AuthService.baseUrl; // ✅ للـ static methods
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

  void setActiveChat(String? chatId) {
    _activeChatId = chatId;
    if (chatId != null && _socket?.connected == true) {
      joinChatRoom(chatId);
    }
  }
  
  /// ✅ تسجيل الاستماع لتحديث عدد الرسائل غير المقروءة
  void _registerUnreadCountListener() {
    if (currentUserId != null && _socket != null) {
      final eventName = 'unreadCount_$currentUserId';
      print('📡 Registering listener for: $eventName');
      
      _socket?.on(eventName, (data) {
        final count = data['count'] ?? 0;
        unreadGlobalCount.value = count;
        print('📊 Real-time unread count received: $count');
      });
    } else {
      print('⚠️ Cannot register unread listener: userId=$currentUserId, socket=${_socket != null}');
    }
  }

  Future<void> initSocket() async {
    final token = await AuthService.getToken();
    
    if (token == null) {
      print('âŒ Cannot init socket: No token');
      return;
    }
    
    if (_socket != null && _socket!.connected) {
      print('âœ… Socket already connected');
      return;
    }

    print('ðŸ”Œ Initializing chat socket to: $_baseUrl');

    _socket = IO.io(
      _baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect() 
          .setQuery({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .enableForceNewConnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000)
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      print('✅ Chat Socket Connected ID: ${_socket!.id}');
      if (_activeChatId != null) {
        joinChatRoom(_activeChatId!);
      }
      fetchUnreadCount();
      
      // ✅ تسجيل الاستماع لتحديث عدد الرسائل غير المقروءة
      _registerUnreadCountListener();
    });

    _socket!.onDisconnect((_) {
      print('âŒ Chat Socket Disconnected');
    });

    _socket!.onConnectError((data) {
      print('âš ï¸ Chat Connection Error: $data');
    });

    _socket?.on('newMessage', (data) {
      print('ðŸ“¨ New message received via socket: $data');
      
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
        
        if (_activeChatId == chatID) {
          print('âœ… Socket: New message for active chat. Calling onNewMessage.');
          onNewMessage?.call(newMessage);
          
          if (!isMe) {
             markAsRead(chatID); 
          }
        } else {
          print('â„¹ï¸ Socket: New message for inactive chat: $chatID');
        }

        onMessageStatusUpdate?.call();
      }
      
      fetchUnreadCount();
    });

    _socket?.on('unreadCountUpdated', (data) {
      final count = data['count'] ?? 0;
      unreadGlobalCount.value = count;
      print('ðŸ“Š Socket: Global unread count updated: $count');
    });
    
    _socket?.on('messagesRead', (data) {
      print('âœ… Messages marked as read');
      onMessageStatusUpdate?.call();
    });
  }
  
  void joinChatRoom(String chatId) {
    if (_socket?.connected == true) {
      print('ðŸšª Joining chat room: $chatId');
      _socket?.emit('joinRoom', {'chatId': chatId, 'userId': currentUserId});
    } else {
      print('âŒ Cannot join room: Socket not connected');
    }
  }

  Future<void> fetchUnreadCount() async {
    final token = await AuthService.getToken();
    if (token == null) return;
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/unread-count'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final count = data['count'] ?? 0;
        unreadGlobalCount.value = count;
        print('ðŸ“Š Unread count fetched: $count');
      }
    } catch (e) {
      print('âŒ Error fetching unread count: $e');
    }
  }

  /// ✅ جلب عدد الرسائل غير المقروءة لكل chat
  Future<Map<String, int>> fetchUnreadCountsPerChat() async {
    final token = await AuthService.getToken();
    if (token == null) return {};
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/unread-per-chat'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> counts = data['data'] ?? [];
        
        Map<String, int> result = {};
        for (var item in counts) {
          final chatId = item['chatId']?.toString() ?? '';
          final count = item['unreadCount'] ?? 0;
          if (chatId.isNotEmpty) {
            result[chatId] = count;
          }
        }
        print('Unread counts per chat: $result');
        return result;
      }
    } catch (e) {
      print('Error fetching unread counts per chat: $e');
    }
    return {};
  }

  Future<void> markAsRead(String chatId) async {
    final token = await AuthService.getToken();
    if (token == null) return;
    
    // 1. Ø¥Ø·Ù„Ø§Ù‚ Ø§Ù„Ø­Ø¯Ø« Ø¹Ø¨Ø± Ø§Ù„Ø³ÙˆÙƒÙŠØª
    if (_socket?.connected == true) {
      print('ðŸ“– Sending markAsRead via Socket');
      _socket?.emit('markAsRead', {'chatId': chatId, 'userId': currentUserId});
    }

    // 2. Fallback to HTTP
    try {
      print('ðŸ“– Sending markAsRead via HTTP');
      final response = await http.patch(
        Uri.parse('$_baseUrl/chat/mark-read/$chatId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        print('âœ… MarkAsRead sent via HTTP successfully');
        onMessageStatusUpdate?.call();
        fetchUnreadCount();
      }
    } catch (e) {
      print('âŒ Error marking as read via HTTP: $e');
    }
  }
  
  Future<List<Map<String, dynamic>>> fetchUserChats() async {
    final token = await AuthService.getToken();
    if (token == null) {
      print('âŒ Cannot fetch chats: No token');
      return [];
    }
    
    try {
      print('ðŸ“¥ Fetching user chats...');
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/my-chats'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      
      print('ðŸ“¡ Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonChats = json.decode(response.body);
        print('âœ… Successfully fetched ${jsonChats.length} chats');
        return jsonChats.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('âŒ Error fetching user chats: $e');
      return [];
    }
  }
  
  Future<List<ChatMessage>> fetchChatMessages(String chatId) async {
    final token = await AuthService.getToken();
    if (token == null) {
      print('âŒ Cannot fetch messages: No token');
      return [];
    }
    
    try {
      print('ðŸ“¥ Fetching messages for chat: $chatId');
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/messages/$chatId'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      
      print('ðŸ“¡ Messages response status: ${response.statusCode}');
      print('ðŸ“¡ Messages response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonMessages = json.decode(response.body);
        print('âœ… Successfully fetched ${jsonMessages.length} messages');
        
        final messages = jsonMessages.map((msgJson) {
          final senderData = msgJson['sender'];
          String senderId = senderData is Map 
            ? _cleanId(senderData['_id'] ?? senderData['id'])
            : _cleanId(senderData);
          
          final isReadFromServer = msgJson['isRead'];
          print('📩 Message: ${msgJson['content']}, isRead from server: $isReadFromServer, senderId: $senderId, currentUserId: $currentUserId');
          
          return ChatMessage(
            id: _cleanId(msgJson['_id']),
            text: msgJson['content'] ?? '',
            createdAt: DateTime.tryParse(msgJson['createdAt'] ?? '') ?? DateTime.now(),
            isMe: senderId == currentUserId,
            isRead: msgJson['isRead'] ?? false, 
          );
        }).toList();
        
        return messages;
        
      } else {
        print('âš ï¸ Failed to fetch messages: ${response.statusCode}');
        throw Exception('Failed to load messages: ${response.statusCode}');
      }
    } catch (e) {
      print('âŒ Error fetching messages: $e');
      rethrow;
    }
  }
  
  Future<void> sendMessage(String chatId, String content) async {
    final token = await AuthService.getToken();
    
    if (token == null) {
      print('âŒ Cannot send message: No token');
      return;
    }
    
    try {
      print('ðŸ“¤ Sending message via HTTP');
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/send'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'chatId': chatId, 'content': content}),
      );
      
      print('ðŸ“¡ Send message response: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('âœ… Message sent via HTTP successfully');
        onMessageStatusUpdate?.call();
      } else {
         throw Exception('Failed to send message: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('âŒ Error sending message: $e');
      rethrow;
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
        print('âœ… Chat deleted successfully');
        fetchUnreadCount();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting chat: $e');
      return false;
    }
  }

  /// Start or get existing chat with a user (without sending initial message)
  static Future<Map<String, dynamic>> startChatWithUser(String userId, String initialMessage) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');
      
      print('Starting chat with user: $userId');
      
      // First, create or get existing chat
      final chatResponse = await http.post(
        Uri.parse('$_staticBaseUrl/chat/create'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'receiverId': userId,
        }),
      );

      print('Chat create response: ${chatResponse.statusCode} - ${chatResponse.body}');

      if (chatResponse.statusCode == 200 || chatResponse.statusCode == 201) {
        final chatData = json.decode(chatResponse.body);
        final chatId = chatData['_id'] ?? chatData['id'];
        
        print('Chat created/found: $chatId');
        
        // Only send message if initialMessage is not empty
        if (initialMessage.isNotEmpty && chatId != null) {
          final msgResponse = await http.post(
            Uri.parse('$_staticBaseUrl/chat/send'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'chatId': chatId,
              'content': initialMessage,
            }),
          );
          print('Message send response: ${msgResponse.statusCode}');
        }
        
        return {
          'success': true,
          'chatId': chatId,
          'data': chatData,
        };
      } else {
        print('Chat create failed: ${chatResponse.body}');
        return {
          'success': false,
          'message': 'Failed to start chat: ${chatResponse.statusCode}',
        };
      }
    } catch (e) {
      print('Error starting chat: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    print('Socket disposed');
  }
}