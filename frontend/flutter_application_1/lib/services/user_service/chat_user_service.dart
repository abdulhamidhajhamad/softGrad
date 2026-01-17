// في chat_user_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_application_1/services/auth_service.dart';

class ChatUserService {
  static final ChatUserService _instance = ChatUserService._internal();
  factory ChatUserService() => _instance;
  ChatUserService._internal();

  // ✅ استخدام AuthService.baseUrl بدلاً من URL ثابت
  String get _baseUrl => AuthService.baseUrl;
  IO.Socket? _socket;
  
  static final ValueNotifier<int> unreadGlobalCount = ValueNotifier<int>(0);
  static final ValueNotifier<Map<String, int>> unreadPerChat = ValueNotifier<Map<String, int>>({});
  
  String? currentUserId;
  String? activeChatId;

  // ✅ استخدم StreamController بدل callbacks
  final _messageStreamController = StreamController<ChatMessageModel>.broadcast();
  Stream<ChatMessageModel> get messageStream => _messageStreamController.stream;
  
  final _statusUpdateController = StreamController<void>.broadcast();
  Stream<void> get statusUpdateStream => _statusUpdateController.stream;

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
    activeChatId = chatId; // ✅ غيرت الاسم هنا كمان
    if (chatId != null && _socket?.connected == true) {
      joinChatRoom(chatId);
    }
  }

  /// Initialize current user ID from stored user data
  Future<void> initializeUserId() async {
  try {
    final userData = await AuthService.getUserData();
    if (userData != null) {
      currentUserId = userData['_id']?.toString() ?? userData['id']?.toString();
      print('✅ User ID initialized: $currentUserId');
      print('🔌 Socket status: ${_socket?.connected}'); // ✅ إضافة
    } else {
      print('⚠️ No user data found in storage');
    }
  } catch (e) {
    print('❌ Error initializing user ID: $e');
  }
  }

  Future<void> initSocket() async {
    final token = await AuthService.getToken();
    
    if (token == null) {
      print('❌ Cannot init socket: No token');
      return;
    }
    
    if (_socket != null && _socket!.connected) {
      print('✅ Socket already connected');
      return;
    }
    
    if (_socket != null && !_socket!.connected) {
      print('🔄 Reconnecting socket...');
      _socket!.dispose();
      _socket = null;
    }

    print('🔌 Initializing chat socket to: $_baseUrl');

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
      if (activeChatId  != null) {
        joinChatRoom(activeChatId !);
      }
      fetchUnreadCount();
      fetchUnreadPerChat();
      
      // ✅ الاستماع لتحديث عدد الرسائل غير المقروءة الموجه لهذا المستخدم (Real-time)
      if (currentUserId != null) {
        _socket?.on('unreadCount_$currentUserId', (data) {
          final count = data['count'] ?? 0;
          unreadGlobalCount.value = count;
          print('📊 Real-time unread count for me: $count');
          fetchUnreadPerChat(); // تحديث تفاصيل كل شات
        });
      }
    });

    _socket!.onDisconnect((_) {
      print('❌ Chat Socket Disconnected');
      Future.delayed(Duration(seconds: 2), () {
        if (_socket?.connected == false) {
          print('🔄 Attempting to reconnect...');
          _socket?.connect();
        }
      });
    });

    _socket!.onConnectError((data) {
      print('⚠️ Chat Connection Error: $data');
    });

    // ✅ الحل: بث الرسائل عبر Stream
    _socket?.on('newMessage', (data) {
      print('📨 New message received via socket: $data');
      
      final messageData = data['message'] ?? data;
      
      if (messageData != null) {
        final senderData = messageData['sender'];
        String senderId = senderData is Map 
            ? _cleanId(senderData['_id'] ?? senderData['id'])
            : _cleanId(senderData);
        
        // ✅ جلب chatId من عدة مصادر محتملة
        final chatID = _cleanId(messageData['chatId'] ?? messageData['chat'] ?? data['chatId']);
        final isMe = senderId == currentUserId;
        
        print('📨 Message chatId: $chatID, activeChatId: $activeChatId, isMe: $isMe');
        
        final newMessage = ChatMessageModel(
          id: messageData['_id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          text: messageData['content']?.toString() ?? '',
          time: DateTime.tryParse(messageData['createdAt']?.toString() ?? '') ?? DateTime.now(),
          fromMe: isMe,
          isRead: isMe || (messageData['isRead'] ?? false),
        );
        
        // ✅ بث الرسالة عبر Stream فقط إذا كانت للشات النشط
        if (activeChatId == chatID) {
          _messageStreamController.add(newMessage);
          
          if (!isMe) {
            markAsRead(chatID);
          }
        }

        // ✅ بث تحديث الحالة
        _statusUpdateController.add(null);
      }
      
      fetchUnreadCount();
      fetchUnreadPerChat();
    });

    _socket?.on('unreadCountUpdated', (data) {
      final count = data['count'] ?? 0;
      unreadGlobalCount.value = count;
      print('📊 Socket: Global unread count updated: $count');
    });
    
    _socket?.on('messagesRead', (data) {
      print('✅ Messages marked as read');
      _statusUpdateController.add(null);
      fetchUnreadPerChat();
    });
  }
  
  void joinChatRoom(String chatId) {
    if (_socket?.connected == true) {
      print('🚪 Joining chat room: $chatId');
      _socket?.emit('joinRoom', {'chatId': chatId, 'userId': currentUserId});
    } else {
      print('❌ Cannot join room: Socket not connected');
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
        print('📊 Unread count fetched: $count');
      }
    } catch (e) {
      print('❌ Error fetching unread count: $e');
    }
  }

  Future<void> fetchUnreadPerChat() async {
    final token = await AuthService.getToken();
    if (token == null) return;
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/unread-per-chat'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        final List<dynamic> data = result['data'] ?? [];
        
        final Map<String, int> unreadMap = {};
        for (var item in data) {
          final chatId = _cleanId(item['chatId']);
          final count = item['unreadCount'] ?? 0;
          unreadMap[chatId] = count;
        }
        
        unreadPerChat.value = unreadMap;
        print('📊 Unread per chat fetched: $unreadMap');
      }
    } catch (e) {
      print('❌ Error fetching unread per chat: $e');
    }
  }

  Future<void> markAsRead(String chatId) async {
    final token = await AuthService.getToken();
    if (token == null) return;
    
    // 1. Via Socket
    if (_socket?.connected == true) {
      print('📖 Sending markAsRead via Socket');
      _socket?.emit('markAsRead', {'chatId': chatId, 'userId': currentUserId});
    }

    // 2. Fallback to HTTP
    try {
      print('📖 Sending markAsRead via HTTP');
      final response = await http.patch(
        Uri.parse('$_baseUrl/chat/mark-read/$chatId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        print('✅ MarkAsRead sent via HTTP successfully');
        fetchUnreadCount();
        fetchUnreadPerChat();
      }
    } catch (e) {
      print('❌ Error marking as read via HTTP: $e');
    }
  }
  
  Future<List<ChatThreadModel>> fetchUserChats() async {
    final token = await AuthService.getToken();
    if (token == null) {
      print('❌ Cannot fetch chats: No token');
      return [];
    }
    
    try {
      print('📥 Fetching user chats...');
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/my-chats'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      
      print('📡 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonChats = json.decode(response.body);
        print('✅ Successfully fetched ${jsonChats.length} chats');
        
        return jsonChats.map((chatJson) {
          final chatId = _cleanId(chatJson['_id']);
          final participants = chatJson['participants'] as List<dynamic>? ?? [];
          
          // Find the other participant (not current user)
          Map<String, dynamic>? otherParticipant;
          for (var p in participants) {
            if (p is Map && _cleanId(p['_id']) != currentUserId) {
              otherParticipant = Map<String, dynamic>.from(p as Map);
              break;
            }
          }
          
          final role = otherParticipant?['role']?.toString() ?? 'user';
          final isSupport = role == 'admin';
          final isVendor = role == 'vendor';
          
          // ✅ تحديد العنوان حسب نوع المستخدم
          String title;
          if (isSupport) {
            title = 'eventPlanner Support';
          } else if (isVendor) {
            // للـ vendor نستخدم companyName
            title = otherParticipant?['companyName']?.toString() ?? 
                    otherParticipant?['userName']?.toString() ?? 
                    'Vendor';
          } else {
            // للمستخدم العادي نستخدم userName
            title = otherParticipant?['userName']?.toString() ?? 'User';
          }
          
          final lastMessage = chatJson['lastMessage']?.toString() ?? '';
          final updatedAt = DateTime.tryParse(chatJson['updatedAt']?.toString() ?? '') ?? DateTime.now();
          
          // Get unread count for this specific chat
          final unreadCount = unreadPerChat.value[chatId] ?? 0;
          
          return ChatThreadModel(
            id: chatId,
            type: isSupport ? ThreadType.support : (isVendor ? ThreadType.vendor : ThreadType.vendor),
            title: title,
            lastMessage: lastMessage,
            lastTime: updatedAt,
            unreadCount: unreadCount,
            online: true, // You can enhance this with real online status
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error fetching user chats: $e');
      return [];
    }
  }
  
  Future<List<ChatMessageModel>> fetchChatMessages(String chatId) async {
    final token = await AuthService.getToken();
    if (token == null) {
      print('❌ Cannot fetch messages: No token');
      return [];
    }
    
    try {
      final url = '$_baseUrl/chat/messages/$chatId';
      print('📥 Fetching messages for chat: $chatId');
      print('📥 URL: $url');
      print('📥 Current User ID: $currentUserId');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      
      print('📡 Messages response status: ${response.statusCode}');
      print('📡 Messages response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonMessages = json.decode(response.body);
        print('✅ Successfully fetched ${jsonMessages.length} messages');
        
        final messages = jsonMessages.map((msgJson) {
          final senderData = msgJson['sender'];
          String senderId = senderData is Map 
            ? _cleanId(senderData['_id'] ?? senderData['id'])
            : _cleanId(senderData);
          
          print('📨 Message: senderId=$senderId, currentUserId=$currentUserId, fromMe=${senderId == currentUserId}');
          
          return ChatMessageModel(
            id: _cleanId(msgJson['_id']),
            text: msgJson['content'] ?? '',
            time: DateTime.tryParse(msgJson['createdAt'] ?? '') ?? DateTime.now(),
            fromMe: senderId == currentUserId,
            isRead: msgJson['isRead'] ?? false,
          );
        }).toList();
        
        return messages;
        
      } else {
        print('⚠️ Failed to fetch messages: ${response.statusCode}');
        throw Exception('Failed to load messages: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching messages: $e');
      rethrow;
    }
  }
  
  Future<void> sendMessage(String chatId, String content) async {
    final token = await AuthService.getToken();
    
    if (token == null) {
      print('❌ Cannot send message: No token');
      return;
    }
    
    try {
      final url = '$_baseUrl/chat/send';
      print('📤 Sending message via HTTP to: $url');
      print('📤 ChatId: $chatId, Content: $content');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'chatId': chatId, 'content': content}),
      );
      
      print('📡 Send message response: ${response.statusCode}');
      print('📡 Response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Message sent via HTTP successfully');
      } else {
        throw Exception('Failed to send message: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error sending message: $e');
      rethrow;
    }
  }

  Future<String?> createChat(String receiverId) async {
    final token = await AuthService.getToken();
    if (token == null) {
      print('❌ Cannot create chat: No token');
      return null;
    }
    
    try {
      final url = '$_baseUrl/chat/create';
      print('📥 Creating chat with receiver: $receiverId');
      print('📥 URL: $url');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'receiverId': receiverId}),
      );
      
      print('📡 Create chat response: ${response.statusCode}');
      print('📡 Response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final chatId = _cleanId(data['_id']);
        print('✅ Chat created/found: $chatId');
        return chatId;
      }
      print('❌ Create chat failed: ${response.statusCode}');
      return null;
    } catch (e) {
      print('❌ Error creating chat: $e');
      return null;
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
        print('✅ Chat deleted successfully');
        fetchUnreadCount();
        fetchUnreadPerChat();
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
    _socket = null;
    print('🔌 Socket disposed');
  }
}

// Models
enum ThreadType { vendor, support }

class ChatThreadModel {
  final String id;
  final ThreadType type;
  final String title;
  final String lastMessage;
  final DateTime lastTime;
  final int unreadCount;
  final bool online;

  ChatThreadModel({
    required this.id,
    required this.type,
    required this.title,
    required this.lastMessage,
    required this.lastTime,
    required this.unreadCount,
    required this.online,
  });

  ChatThreadModel copyWith({
    String? id,
    ThreadType? type,
    String? title,
    String? lastMessage,
    DateTime? lastTime,
    int? unreadCount,
    bool? online,
  }) {
    return ChatThreadModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      lastMessage: lastMessage ?? this.lastMessage,
      lastTime: lastTime ?? this.lastTime,
      unreadCount: unreadCount ?? this.unreadCount,
      online: online ?? this.online,
    );
  }
}

class ChatMessageModel {
  final String id;
  final String text;
  final DateTime time;
  final bool fromMe;
  final bool isRead;

  ChatMessageModel({
    required this.id,
    required this.text,
    required this.time,
    required this.fromMe,
    required this.isRead,
  });
}