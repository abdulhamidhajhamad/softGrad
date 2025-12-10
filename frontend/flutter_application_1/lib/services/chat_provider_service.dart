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

  // Base URL - update this to match your network
  static const String _baseUrl = 'http://192.168.110.16:3000';
  
  // Socket
  IO.Socket? _socket;
  
  // Global unread count notifier
  static final ValueNotifier<int> unreadGlobalCount = ValueNotifier<int>(0);

  // Current user ID
  String? currentUserId;

  // Callbacks
  void Function(ChatMessage)? onNewMessage;
  void Function()? onMessageStatusUpdate;

  // Helper function to clean IDs
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

  /// Initialize socket connection
  Future<void> initSocket() async {
    final token = await AuthService.getToken();
    final userMap = await AuthService.getUserData();
    
    // Get and clean user ID
    currentUserId = _cleanId(userMap?['_id'] ?? userMap?['id']);
    
    print('🔐 Initialized with User ID: $currentUserId'); // Debug log

    if (token == null || currentUserId == null || currentUserId!.isEmpty) {
      print('❌ Cannot initialize socket: token or userId is null');
      return;
    }

    // Fetch initial unread count
    fetchUnreadCount();

    // Initialize socket if not already connected
    if (_socket?.connected == true) {
      print('✅ Socket already connected');
      return;
    }

    _socket = IO.io(
      _baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableForceNewConnection()
          .disableAutoConnect()
          .build(),
    );

    _socket?.connect();

    // Socket event listeners
    _socket?.onConnect((_) {
      print('✅ Socket Connected: ${_socket?.id}');
    });
    
    _socket?.onDisconnect((_) {
      print('❌ Socket Disconnected');
    });
    
    _socket?.onError((error) {
      print('❌ Socket Error: $error');
    });

    // Listen for new messages
    _socket?.on('newMessage', (data) {
      print('📨 New message received: $data'); // Debug log
      
      final messageData = data['message'] ?? data;
      
      if (messageData != null) {
        final senderData = messageData['sender'];
        String senderId = '';
        
        if (senderData is Map) {
          senderId = _cleanId(senderData['_id'] ?? senderData['id']);
        } else {
          senderId = _cleanId(senderData);
        }
        
        // Determine if message is from current user
        final isMe = senderId == currentUserId;
        
        print('📝 Processing message: senderId=$senderId, currentUserId=$currentUserId, isMe=$isMe');
        
        final newMessage = ChatMessage(
          id: messageData['_id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          text: messageData['content']?.toString() ?? '',
          createdAt: DateTime.tryParse(messageData['createdAt']?.toString() ?? '') ?? DateTime.now(),
          isMe: isMe,
          isRead: messageData['isRead'] ?? false,
        );

        // Send to ChatScreen
        onNewMessage?.call(newMessage);
      }
      
      // Update unread count
      fetchUnreadCount();
      onMessageStatusUpdate?.call();
    });

    // Listen for unread count updates
    _socket?.on('unreadCountUpdated', (data) {
      print('🔔 Unread count updated: $data');
      if (data != null && data['count'] != null) {
        unreadGlobalCount.value = data['count'];
      } else {
        fetchUnreadCount();
      }
    });

    // Listen for message read status updates
    _socket?.on('messagesRead', (data) {
      print('✅ Messages marked as read');
      fetchUnreadCount();
      onMessageStatusUpdate?.call();
    });
    
    _socket?.on('messageStatusUpdate', (data) {
      print('🔄 Message status updated');
      fetchUnreadCount();
      onMessageStatusUpdate?.call();
    });
  }

  // --------------------------------------------------------------------------
  // Socket Room Management
  // --------------------------------------------------------------------------

  void joinChatRoom(String chatId) {
    if (_socket?.connected == true && currentUserId != null) {
      _socket?.emit('joinRoom', {
        'chatId': chatId, 
        'userId': currentUserId
      });
      print('🚪 Joined chat room: $chatId');
    } else {
      print('❌ Cannot join room: socket not connected or userId null');
    }
  }

  void leaveChatRoom(String chatId) {
    if (_socket?.connected == true) {
      _socket?.emit('leaveChat', chatId);
      print('🚪 Left chat room: $chatId');
    }
  }

  // --------------------------------------------------------------------------
  // HTTP API Calls
  // --------------------------------------------------------------------------

  /// Fetch global unread count
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
        final count = data['count'] as int? ?? 0;
        unreadGlobalCount.value = count;
        print('🔔 Unread count: $count');
      }
    } catch (e) {
      print('❌ Error fetching unread count: $e');
    }
  }

  /// Fetch all user chats
  Future<List<Map<String, dynamic>>> fetchUserChats() async {
    final token = await AuthService.getToken();
    if (token == null) return [];
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/my-chats'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else {
        print('❌ Failed to fetch chats: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching chats: $e');
      return [];
    }
  }

  /// Fetch messages for a specific chat
  Future<List<Map<String, dynamic>>> fetchMessages(String chatId) async {
    final token = await AuthService.getToken();
    if (token == null) return [];
    
    try {
      print('📡 Fetching messages for chat: $chatId');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/messages/$chatId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ Fetched ${data.length} messages');
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else {
        print('❌ Failed to fetch messages: ${response.statusCode}');
        print('Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching messages: $e');
      return [];
    }
  }

  /// Send a message
  Future<void> sendMessage(String chatId, String content) async {
    final token = await AuthService.getToken();
    if (token == null) return;
    
    // Use Socket for real-time sending
    if (_socket?.connected == true && currentUserId != null) {
      _socket?.emit('sendMessage', {
        'chatId': chatId, 
        'senderId': currentUserId, 
        'content': content
      });
      print('📤 Message sent via socket');
    } else {
      // Fallback to HTTP
      print('📤 Sending message via HTTP (socket not connected)');
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/chat/send'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'chatId': chatId,
            'content': content,
          }),
        );
        
        if (response.statusCode != 200) {
          print('❌ Failed to send message: ${response.statusCode}');
          throw Exception('Failed to send message');
        }
      } catch (e) {
        print('❌ Error sending message: $e');
        rethrow;
      }
    }
  }

  /// Mark chat as read
  Future<void> markAsRead(String chatId) async {
    final token = await AuthService.getToken();
    if (token == null) return;
    
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/chat/mark-read/$chatId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        print('✅ Chat marked as read');
        fetchUnreadCount();
        onMessageStatusUpdate?.call();
      }
    } catch (e) {
      print('❌ Error marking as read: $e');
    }
  }

  /// Delete a chat
  Future<bool> deleteChat(String chatId) async {
    final token = await AuthService.getToken();
    if (token == null) return false;
    
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/chat/$chatId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        print('✅ Chat deleted');
        fetchUnreadCount();
        onMessageStatusUpdate?.call();
        return true;
      } else {
        print('❌ Failed to delete chat: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error deleting chat: $e');
      return false;
    }
  }
  
  /// Dispose socket connection
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    print('🔌 Socket disposed');
  }
}