// lib/services/socket_service.dart
// Handle real-time socket connection for admin dashboard

import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'auth_service.dart';
import 'dart:async';

class SocketService {
  static IO.Socket? _socket;
  static bool _isConnected = false;
  
  // Stream controllers for real-time updates
  static final StreamController<Map<String, dynamic>> _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  static final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  static final StreamController<Map<String, dynamic>> _reviewController =
      StreamController<Map<String, dynamic>>.broadcast();
  static final StreamController<Map<String, dynamic>> _dashboardController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Getters for streams
  static Stream<Map<String, dynamic>> get notificationStream =>
      _notificationController.stream;
  static Stream<Map<String, dynamic>> get messageStream =>
      _messageController.stream;
  static Stream<Map<String, dynamic>> get reviewStream =>
      _reviewController.stream;
  static Stream<Map<String, dynamic>> get dashboardStream =>
      _dashboardController.stream;

  static bool get isConnected => _isConnected;

  /// Initialize and connect socket
  static Future<void> connect() async {
    if (_socket != null && _isConnected) {
      print('✅ Socket already connected');
      return;
    }

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        print('❌ No token found, cannot connect socket');
        return;
      }

      print('🔌 Connecting to socket: ${AuthService.baseUrl}');

      _socket = IO.io(
        AuthService.baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setAuth({'token': token})
            .setExtraHeaders({'Authorization': 'Bearer $token'})
            .build(),
      );

      _socket!.connect();

      // Connection events
      _socket!.onConnect((_) {
        _isConnected = true;
        print('✅ Socket connected successfully');
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        print('⚠️ Socket disconnected');
      });

      _socket!.onConnectError((error) {
        print('❌ Socket connection error: $error');
      });

      _socket!.onError((error) {
        print('❌ Socket error: $error');
      });

      // Listen to admin-specific events
      _setupAdminListeners();
    } catch (e) {
      print('❌ Error initializing socket: $e');
    }
  }

  /// Setup listeners for admin events
  static void _setupAdminListeners() {
    if (_socket == null) return;

    // New notification
    _socket!.on('new-notification', (data) {
      print('🔔 New notification received: $data');
      _notificationController.add(data as Map<String, dynamic>);
    });

    // New message
    _socket!.on('new-message', (data) {
      print('💬 New message received: $data');
      _messageController.add(data as Map<String, dynamic>);
    });

    // New chat created
    _socket!.on('new-chat', (data) {
      print('💬 New chat created: $data');
      _messageController.add(data as Map<String, dynamic>);
    });

    // Chat created event
    _socket!.on('chat-created', (data) {
      print('💬 Chat created: $data');
      _messageController.add(data as Map<String, dynamic>);
    });

    // Message sent confirmation
    _socket!.on('message-sent', (data) {
      print('✉️ Message sent confirmation: $data');
      _messageController.add(data as Map<String, dynamic>);
    });

    // New review
    _socket!.on('new-review', (data) {
      print('⭐ New review received: $data');
      _reviewController.add(data as Map<String, dynamic>);
    });

    // Dashboard update
    _socket!.on('dashboard-update', (data) {
      print('📊 Dashboard update received: $data');
      _dashboardController.add(data as Map<String, dynamic>);
    });

    // Booking update
    _socket!.on('booking-update', (data) {
      print('📅 Booking update: $data');
      _dashboardController.add({'type': 'booking', 'data': data});
    });

    // Payment update
    _socket!.on('payment-received', (data) {
      print('💰 Payment received: $data');
      _dashboardController.add({'type': 'payment', 'data': data});
    });
  }

  /// Join admin room
  static void joinAdminRoom() {
    if (_socket != null && _isConnected) {
      _socket!.emit('join-admin-room');
      print('🏠 Joined admin room');
    }
  }

  /// Leave admin room
  static void leaveAdminRoom() {
    if (_socket != null && _isConnected) {
      _socket!.emit('leave-admin-room');
      print('👋 Left admin room');
    }
  }

  /// Send message
  static void sendMessage(String chatId, String content) {
    if (_socket != null && _isConnected) {
      _socket!.emit('send-message', {
        'chatId': chatId,
        'content': content,
      });
    }
  }

  /// Mark notification as read
  static void markNotificationRead(String notificationId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('mark-notification-read', {'notificationId': notificationId});
    }
  }

  /// Trigger chat list refresh (for local updates when we know a chat was created)
  static void triggerChatRefresh([Map<String, dynamic>? data]) {
    _messageController.add(data ?? {'type': 'refresh'});
  }

  /// Disconnect socket
  static void disconnect() {
    if (_socket != null) {
      leaveAdminRoom();
      _socket!.disconnect();
      _socket = null;
      _isConnected = false;
      print('🔌 Socket disconnected');
    }
  }

  /// Dispose all stream controllers
  static void dispose() {
    disconnect();
    _notificationController.close();
    _messageController.close();
    _reviewController.close();
    _dashboardController.close();
    print('🗑️ Socket service disposed');
  }
}