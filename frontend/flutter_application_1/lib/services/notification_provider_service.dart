import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/screens/notifications_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:jwt_decode/jwt_decode.dart'; // Add this package to pubspec.yaml

class NotificationProviderService {
  static const String baseUrl = 'http://192.168.110.16:3000';

  // ✅ ValueNotifier for red dot indicator
  static final ValueNotifier<bool> hasUnreadNotifier = ValueNotifier<bool>(false);

  static IO.Socket? _socket;

  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ===============================================
  // 🚀 REAL-TIME NOTIFICATIONS (WebSocket)
  // ===============================================

  /// Initialize WebSocket connection with proper recipientId
  static Future<void> initRealtimeNotifications() async {
    final token = await AuthService.getToken();
    if (token == null) {
      debugPrint('❌ Realtime connection failed: No auth token found.');
      return;
    }

    // 🔥 Extract userId from JWT token
    String? userId;
    try {
      Map<String, dynamic> decodedToken = Jwt.parseJwt(token);
      userId = decodedToken['userId'] ?? decodedToken['id'];
      debugPrint('👤 Extracted userId from token: $userId');
    } catch (e) {
      debugPrint('❌ Failed to decode JWT token: $e');
      return;
    }

    if (userId == null) {
      debugPrint('❌ Could not extract userId from token');
      return;
    }

    // If already connected, just update count and return
    if (_socket != null && _socket!.connected) {
      debugPrint('ℹ️ Socket already connected, updating count...');
      updateUnreadCountOnConnect();
      return;
    }

    try {
      debugPrint('🔌 Connecting to WebSocket with userId: $userId');
      
      _socket = IO.io(
        baseUrl, 
        IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableForceNewConnection()
          .setQuery({'recipientId': userId}) // 🔥 CRITICAL: Pass recipientId as query param
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .build(),
      );

      _socket!.onConnect((_) {
        debugPrint('✅ Socket connected successfully!');
        debugPrint('📡 Connected with recipientId: $userId');
        // Update count when first connected
        updateUnreadCountOnConnect();
      });

      // 👂 Listen for real-time unread count updates
      _socket!.on('unreadCountUpdated', (data) {
        final int count = data is int 
            ? data 
            : (data is Map && data.containsKey('count') ? data['count'] : 0);
        
        debugPrint('🔔 Realtime unread count updated: $count');
        hasUnreadNotifier.value = count > 0;
      });

      // 👂 Listen for new notifications
      _socket!.on('newNotification', (data) {
        debugPrint('📬 New notification received: $data');
        // Automatically set red dot when new notification arrives
        hasUnreadNotifier.value = true;
      });

      _socket!.onDisconnect((_) {
        debugPrint('❌ Socket disconnected');
      });

      _socket!.onError((error) {
        debugPrint('❌ Socket error: $error');
      });

      _socket!.onConnectError((error) {
        debugPrint('❌ Socket connection error: $error');
      });

    } catch (e) {
      debugPrint('❌ Failed to establish socket connection: $e');
    }
  }

  /// Close WebSocket connection
  static void closeRealtimeConnection() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    debugPrint('🔌 Socket connection closed.');
  }

  /// Manually update unread count (called when connecting or returning to app)
  static Future<void> updateUnreadCountOnConnect() async {
    try {
      final count = await getUnreadCount();
      hasUnreadNotifier.value = count > 0;
      debugPrint('🔄 Manual count update: $count (hasUnread: ${count > 0})');
    } catch(e) {
      debugPrint('❌ Error manual update count: $e');
    }
  }

  // ===============================================
  // 📌 HTTP API METHODS
  // ===============================================

  /// Fetch all notifications
  static Future<List<ProviderNotification>> fetchNotifications() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: headers,
      );

      debugPrint('📥 Fetch notifications response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        return data.map((json) {
          return ProviderNotification(
            id: json['_id'],
            title: json['title'] ?? 'No Title',
            body: json['body'] ?? '',
            createdAt: DateTime.parse(json['createdAt']),
            isRead: json['isRead'] ?? false,
            type: _mapBackendTypeToUiType(json['type']),
          );
        }).toList();
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      debugPrint('❌ Error fetching notifications: $e');
      throw e;
    }
  }

  /// Get unread notification count
  static Future<int> getUnreadCount() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/unread/count'),
        headers: headers,
      );

      debugPrint('📊 Unread count response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final count = data['count'] ?? 0;
        debugPrint('📊 Unread count from API: $count');
        return count;
      }
      return 0;
    } catch (e) {
      debugPrint('❌ Error fetching unread count: $e');
      return 0;
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllAsRead() async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/notifications/mark-all-read'),
        headers: headers,
      );
      
      debugPrint('✅ Mark all as read response: ${response.statusCode}');
      
      // Update local state
      hasUnreadNotifier.value = false;
    } catch (e) {
      debugPrint('❌ Error marking all as read: $e');
    }
  }

  /// Delete a notification
  static Future<void> deleteNotification(String id) async {
    try {
      final headers = await _getHeaders();
      await http.delete(
        Uri.parse('$baseUrl/notifications/$id'),
        headers: headers,
      );
      debugPrint('🗑️ Notification deleted: $id');
    } catch (e) {
      debugPrint('❌ Error deleting notification: $e');
      throw e;
    }
  }

  /// Map backend notification types to UI types
  static NotificationType _mapBackendTypeToUiType(String? backendType) {
    switch (backendType) {
      case 'NEW_MESSAGE':
      case 'USER_MESSAGE':
        return NotificationType.message;
      case 'BOOKING_CONFIRMED':
      case 'BOOKING_CANCELLED':
        return NotificationType.booking;
      case 'SERVICE_FAVOURITED':
        return NotificationType.favorite;
      case 'REVIEW_ADDED':
        return NotificationType.review;
      case 'PAYOUT_SENT':
      case 'PROMO_CODE':
      default:
        return NotificationType.system;
    }
  }
}