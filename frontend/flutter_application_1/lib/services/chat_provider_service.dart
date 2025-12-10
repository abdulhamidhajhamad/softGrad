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

  // 🚨 عنوان الخادم (يجب تعديله ليتطابق مع إعداداتك)
  static const String _baseUrl = 'http://192.168.110.16:3000';
  
  // Socket
  IO.Socket? _socket;
  
  // Notifier للإشارة الحمراء في الصفحة الرئيسية (Global Unread Count)
  static final ValueNotifier<int> unreadGlobalCount = ValueNotifier<int>(0);

  // تخزين الـ userId الحالي لمعرفة (isMe)
  String? currentUserId;

  // ✅ Callback for new messages in ChatScreen
  void Function(ChatMessage)? onNewMessage;
  
  // ✅ Callback for message read status updates (to refresh messages list)
  void Function()? onMessageStatusUpdate;

  /// تهيئة الاتصال بالسوكت وجلب العدد الأولي
  Future<void> initSocket() async {
    final token = await AuthService.getToken();
    final userMap = await AuthService.getUserData(); 
    currentUserId = userMap?['id'] ?? userMap?['_id']; 

    if (token == null || currentUserId == null) return;

    // 1. جلب العدد الحالي من الرسائل غير المقروءة عبر API
    fetchUnreadCount(); 

    // 2. تهيئة السوكت والاتصال به
    if (_socket?.connected == true) return;

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

    // 3. الاستماع لأحداث السوكت
    _socket?.onConnect((_) => print('Socket Connected: ${_socket?.id}'));
    _socket?.onDisconnect((_) => print('Socket Disconnected'));
    _socket?.onError((error) => print('Socket Error: $error'));

    // 4. الاستماع لحدث الرسائل الجديدة
    _socket?.on('newMessage', (data) {
      if (data != null && data['message'] != null) {
        final messageData = data['message'];
        final senderId = messageData['sender'] is Map 
            ? messageData['sender']['_id'] ?? messageData['sender']['id']
            : messageData['sender'];
        final isMe = senderId == currentUserId;
        
        final newMessage = ChatMessage(
          id: messageData['_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          text: messageData['content'],
          createdAt: DateTime.parse(messageData['createdAt']),
          isMe: isMe,
          isRead: messageData['isRead'] ?? false,
        );

        // إرسال الرسالة الجديدة إلى الـ ChatScreen الحالية
        onNewMessage?.call(newMessage);
      }
      
      // تحديث العدد الإجمالي للرسائل غير المقروءة
      fetchUnreadCount();
      
      // تحديث قائمة المحادثات
      onMessageStatusUpdate?.call();
    });

    // 5. الاستماع لحدث تحديث حالة القراءة
    _socket?.on('messageStatusUpdate', (data) {
       fetchUnreadCount();
       onMessageStatusUpdate?.call();
    });
  }

  // --------------------------------------------------------------------------
  // 🚪 Socket Helpers for Chat Screen (Join/Leave Room)
  // --------------------------------------------------------------------------

  /// طلب الانضمام إلى غرفة محادثة معينة
  void joinChatRoom(String chatId) {
    if (_socket?.connected == true) {
      _socket?.emit('joinChat', chatId);
      print('Socket: Joined chat room $chatId');
    }
  }

  /// طلب مغادرة غرفة محادثة معينة
  void leaveChatRoom(String chatId) {
    if (_socket?.connected == true) {
      _socket?.emit('leaveChat', chatId);
      print('Socket: Left chat room $chatId');
    }
  }

  // --------------------------------------------------------------------------
  // 📡 API Calls (HTTP)
  // --------------------------------------------------------------------------

  /// API: جلب العدد الإجمالي للرسائل غير المقروءة
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
      } else {
        print('Failed to fetch unread count: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching unread count: $e');
    }
  }

  /// API: جلب جميع المحادثات للمستخدم الحالي
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
        print('Failed to fetch chats: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching chats: $e');
      return [];
    }
  }

  /// API: جلب رسائل محادثة معينة
  Future<List<Map<String, dynamic>>> fetchMessages(String chatId) async {
    final token = await AuthService.getToken();
    if (token == null) return [];
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/messages/$chatId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else {
        print('Failed to fetch messages: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching messages: $e');
      return [];
    }
  }

  /// API: إرسال رسالة
  Future<void> sendMessage(String chatId, String content) async {
    final token = await AuthService.getToken();
    if (token == null) return;
    try {
      await http.post(
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
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  /// API: تعليم المحادثة كمقروءة
  Future<void> markAsRead(String chatId) async {
    final token = await AuthService.getToken();
    if (token == null) return;
    try {
      await http.patch(
        Uri.parse('$_baseUrl/chat/mark-read/$chatId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      fetchUnreadCount();
      onMessageStatusUpdate?.call();
      
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  /// API: حذف محادثة
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
        onMessageStatusUpdate?.call();
        return true;
      } else {
        print('Failed to delete chat: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error deleting chat: $e');
      return false;
    }
  }
  
  /// إغلاق الاتصال
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
  }
}