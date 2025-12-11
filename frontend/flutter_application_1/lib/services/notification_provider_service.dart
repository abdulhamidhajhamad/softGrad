// lib/services/notification_provider_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/screens/notifications_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class NotificationProviderService {
  // ✅ تأكد من استخدام نفس الـ IP في كل مكان
  static const String baseUrl = 'http://10.0.2.2:3000';
static const String wsUrl = 'http://10.0.2.2:3000';

  static final ValueNotifier<bool> hasUnreadNotifier = ValueNotifier<bool>(false);
  static IO.Socket? _socket;

  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// دالة لإنشاء اتصال الـ Socket.IO
  static Future<void> initRealtimeNotifications() async {
    final token = await AuthService.getToken();
    if (token == null) {
      debugPrint('❌ Realtime connection failed: No auth token found.');
      return;
    }

    if (_socket != null && _socket!.connected) {
      debugPrint('✅ Socket already connected');
      updateUnreadCountOnConnect();
      return;
    }

    try {
      debugPrint('🔌 Connecting to WebSocket: $wsUrl');
      
      _socket = IO.io(
        wsUrl, 
        IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableForceNewConnection()
          .setQuery({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .setReconnectionDelay(1000)
          .setReconnectionAttempts(5)
          .build(),
      );

      _socket!.onConnect((_) {
        debugPrint('✅ Notification Socket connected successfully!');
        updateUnreadCountOnConnect();
      });

      _socket!.on('newNotification', (data) {
        debugPrint('🔔 New notification received: $data');
        updateUnreadCountOnConnect();
      });

      _socket!.on('unreadCountUpdated', (data) {
        final int count = data is int 
            ? data 
            : (data is Map && data.containsKey('count') ? data['count'] : 0);
        
        debugPrint('🔔 Realtime unread count updated: $count');
        hasUnreadNotifier.value = count > 0;
      });
      
      _socket!.onDisconnect((_) => debugPrint('❌ Notification Socket disconnected'));
      _socket!.onError((error) => debugPrint('❌ Socket error: $error'));
      _socket!.onConnectError((error) => debugPrint('❌ Socket connection error: $error'));

    } catch (e) {
      debugPrint('❌ Failed to establish socket connection: $e');
    }
  }
  
  /// دالة لإغلاق اتصال الـ Socket عند مغادرة الصفحة
  static void closeRealtimeConnection() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    debugPrint('🔌 Socket connection closed.');
  }

  /// دالة لجلب العدد يدوياً وتحديث الـ Notifier
  static Future<void> updateUnreadCountOnConnect() async {
     try {
        final count = await getUnreadCount();
        hasUnreadNotifier.value = count > 0;
        debugPrint('🔄 Manual count update: $count (hasUnread: ${count > 0})');
      } catch(e) {
        debugPrint('❌ Error manual update count: $e');
      }
  }
  
  // 1. جلب جميع الإشعارات
  static Future<List<ProviderNotification>> fetchNotifications() async {
    try {
      debugPrint('📥 Fetching notifications from: $baseUrl/notifications');
      final headers = await _getHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      debugPrint('📡 Response status: ${response.statusCode}');
      debugPrint('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('✅ Successfully fetched ${data.length} notifications');
        
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
        debugPrint('❌ Failed to load notifications: ${response.statusCode}');
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching notifications: $e');
      rethrow;
    }
  }

  // 2. جلب عدد الإشعارات غير المقروءة
  static Future<int> getUnreadCount() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/unread/count'),
        headers: headers,
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final count = data['count'] ?? 0;
        debugPrint('📊 Unread count: $count');
        return count;
      }
      return 0;
    } catch (e) {
      debugPrint('❌ Error fetching unread count: $e');
      return 0;
    }
  }

  // 3. تعليم الكل كمقروء
  static Future<void> markAllAsRead() async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/notifications/mark-all-read'),
        headers: headers,
      );
      
      if (response.statusCode == 204 || response.statusCode == 200) {
        debugPrint('✅ All notifications marked as read');
        hasUnreadNotifier.value = false;
      }
    } catch (e) {
      debugPrint('❌ Error marking all as read: $e');
    }
  }

  // 4. حذف إشعار
  static Future<void> deleteNotification(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/notifications/$id'),
        headers: headers,
      );
      
      if (response.statusCode == 204 || response.statusCode == 200) {
        debugPrint('✅ Notification deleted: $id');
      }
    } catch (e) {
      debugPrint('❌ Error deleting notification: $e');
      rethrow;
    }
  }

  /// دالة مساعدة لربط أنواع الباك إند مع أنواع الواجهة الأمامية
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