// lib/services/notification_provider_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/screens/notifications_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class NotificationProviderService {
  static const String baseUrl = 'http://192.168.110.16:3000';
  static const String wsUrl = 'http://192.168.110.16:3000'; // استخدم HTTP/WS نفس العنوان 

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
      updateUnreadCountOnConnect();
      return;
    }

    try {
      debugPrint('🔌 Connecting to WebSocket using Token (Verification in Gateway)...');
      
      _socket = IO.io(
        wsUrl, 
        IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableForceNewConnection()
          // ✅ CRITICAL: نرسل التوكن كـ Query Parameter باسم 'token'
          .setQuery({'token': token}) 
          // إرسال التوكن في الـ Headers أيضاً
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .build(),
      );

      _socket!.onConnect((_) {
        debugPrint('✅ Socket connected successfully!');
        updateUnreadCountOnConnect();
      });

      _socket!.on('unreadCountUpdated', (data) {
        final int count = data is int 
            ? data 
            : (data is Map && data.containsKey('count') ? data['count'] : 0);
        
        debugPrint('🔔 Realtime unread count updated: $count');
        hasUnreadNotifier.value = count > 0;
      });
      
      _socket!.onDisconnect((_) => debugPrint('❌ Socket disconnected'));
      _socket!.onError((error) => debugPrint('❌ Socket error: $error'));
      _socket!.onConnectError((error) => debugPrint('❌ Socket connection error: $error'));

    } catch (e) {
      debugPrint('❌ Failed to establish socket connection: $e');
    }
  }

  // ... (بقية الدوال تبقى كما هي)
  
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
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: headers,
      );

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
      print('❌ Error fetching notifications: $e');
      throw e;
    }
  }

  // 2. جلب عدد الإشعارات غير المقروءة
  static Future<int> getUnreadCount() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/unread/count'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['count'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('❌ Error fetching unread count: $e');
      return 0;
    }
  }

  // 3. تعليم الكل كمقروء
  static Future<void> markAllAsRead() async {
    try {
      final headers = await _getHeaders();
      await http.patch(
        Uri.parse('$baseUrl/notifications/mark-all-read'),
        headers: headers,
      );
      hasUnreadNotifier.value = false;
    } catch (e) {
      print('❌ Error marking all as read: $e');
    }
  }

  // 4. حذف إشعار
  static Future<void> deleteNotification(String id) async {
    try {
      final headers = await _getHeaders();
      await http.delete(
        Uri.parse('$baseUrl/notifications/$id'),
        headers: headers,
      );
    } catch (e) {
      print('❌ Error deleting notification: $e');
      throw e;
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