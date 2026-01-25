// lib/services/notification_provider_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/booked_provider_service.dart';
import 'package:flutter_application_1/screens/notifications_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class NotificationProviderService {
  // ✅ استخدام AuthService.baseUrl بدلاً من URL ثابت
  static String get baseUrl => AuthService.baseUrl;
  static String get wsUrl => AuthService.baseUrl;

  static final ValueNotifier<bool> hasUnreadNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<List<ProviderNotification>> notificationsNotifier = 
      ValueNotifier<List<ProviderNotification>>([]);
  
  /// ✅ NEW: Unread count notifier (for badge display: ≤9 shows number, >9 shows "9+")
  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);
  
  static IO.Socket? _socket;
  static bool _isConnecting = false;

  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// دالة لإنشاء اتصال الـ Socket.IO مع معالجة أفضل للأخطاء
  static Future<void> initRealtimeNotifications() async {
    if (_isConnecting) {
      debugPrint('⏳ Connection already in progress, skipping...');
      return;
    }

    if (_socket != null && _socket!.connected) {
      debugPrint('✅ Socket already connected');
      return;
    }

    _isConnecting = true;

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        debugPrint('❌ Realtime connection failed: No auth token found.');
        _isConnecting = false;
        return;
      }

      // ✅ إغلاق أي اتصال سابق
      if (_socket != null) {
        _socket!.disconnect();
        _socket!.dispose();
        _socket = null;
      }

      debugPrint('🔌 Connecting to WebSocket: $wsUrl with token: ${token.substring(0, 20)}...');
      
      _socket = IO.io(
        wsUrl, 
        IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableForceNewConnection()
          .setQuery({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .setReconnectionDelay(2000)
          .setReconnectionDelayMax(5000)
          .setReconnectionAttempts(10)
          .build(),
      );

      // ✅ معالجة الاتصال الناجح
      _socket!.onConnect((_) {
        debugPrint('✅✅✅ Notification Socket CONNECTED successfully!');
        _isConnecting = false;
        updateUnreadCountOnConnect();
      });

      // ✅ معالجة تأكيد الاتصال من السيرفر
      _socket!.on('connected', (data) {
        debugPrint('✅ Server confirmed connection: $data');
      });

      // 🔥 استقبال إشعار جديد في الوقت الفعلي
      _socket!.on('newNotification', (data) {
        debugPrint('\n🔔🔔🔔 NEW NOTIFICATION RECEIVED 🔔🔔🔔');
        debugPrint('📦 Data type: ${data.runtimeType}');
        debugPrint('📦 Data content: $data');
        
        try {
          final newNotification = ProviderNotification(
            id: data['_id'] ?? '',
            title: data['title'] ?? 'No Title',
            body: data['body'] ?? '',
            createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
            isRead: data['isRead'] ?? false,
            type: _mapBackendTypeToUiType(data['type']),
          );
          
          debugPrint('✅ Notification object created: ${newNotification.title}');
          
          // إضافة في البداية
          final currentList = List<ProviderNotification>.from(notificationsNotifier.value);
          currentList.insert(0, newNotification);
          notificationsNotifier.value = currentList;
          
          debugPrint('✅ Added to list. Total notifications: ${currentList.length}');
          
          // ✅ تحديث العداد فوراً
          hasUnreadNotifier.value = true;
          unreadCountNotifier.value = unreadCountNotifier.value + 1;  // ✅ Increment count
          debugPrint('✅ Updated hasUnread badge to TRUE\n');
          
          // ✅ إذا كان الإشعار من نوع booking، قم بتحديث عداد الحجوزات أيضاً
          final notificationType = data['type']?.toString().toLowerCase() ?? '';
          if (notificationType.contains('booking') || 
              notificationType.contains('confirmed') ||
              newNotification.title.toLowerCase().contains('booking')) {
            debugPrint('📅 Booking notification detected - updating booking count');
            // استيراد وتحديث BookedProviderService
            _updateBookingCount();
          }
          
        } catch (e, stackTrace) {
          debugPrint('❌ Error processing new notification: $e');
          debugPrint('Stack trace: $stackTrace');
        }
      });

      // 🔥 تحديث عداد غير المقروءة
      _socket!.on('unreadCountUpdated', (data) {
        debugPrint('🔔 UNREAD COUNT UPDATE EVENT: $data');
        
        try {
          final int count = data is int 
              ? data 
              : (data is Map && data.containsKey('count') ? data['count'] : 0);
          
          debugPrint('📊 Setting hasUnread to: ${count > 0} (count: $count)');
          hasUnreadNotifier.value = count > 0;
          unreadCountNotifier.value = count;  // ✅ Update count notifier
        } catch (e) {
          debugPrint('❌ Error processing unread count: $e');
        }
      });
      
      // ✅ معالجة قطع الاتصال
      _socket!.onDisconnect((reason) {
        debugPrint('❌ Notification Socket disconnected. Reason: $reason');
        _isConnecting = false;
      });

      // ✅ معالجة الأخطاء
      _socket!.onError((error) {
        debugPrint('❌ Socket error: $error');
        _isConnecting = false;
      });

      _socket!.onConnectError((error) {
        debugPrint('❌ Socket connection error: $error');
        _isConnecting = false;
      });

      // ✅ معالجة إعادة الاتصال
      _socket!.onReconnect((attempt) {
        debugPrint('🔄 Reconnected after $attempt attempts');
        updateUnreadCountOnConnect();
      });

      _socket!.onReconnectAttempt((attempt) {
        debugPrint('🔄 Reconnection attempt $attempt...');
      });

      _socket!.onReconnectError((error) {
        debugPrint('❌ Reconnection error: $error');
      });

      _socket!.onReconnectFailed((_) {
        debugPrint('❌ Reconnection failed after all attempts');
        _isConnecting = false;
      });

      // ✅ بدء الاتصال
      _socket!.connect();
      debugPrint('📡 Socket connection initiated...\n');

    } catch (e, stackTrace) {
      debugPrint('❌ Failed to establish socket connection: $e');
      debugPrint('Stack trace: $stackTrace');
      _isConnecting = false;
    }
  }

  /// دالة مساعدة لتحديث عدد الحجوزات غير المقروءة
  static void _updateBookingCount() {
    BookedProviderService.fetchUnseenCount();
    debugPrint('📦 Booking count updated from notification');
  }
  
  /// دالة لإغلاق اتصال الـ Socket عند مغادرة الصفحة
  static void closeRealtimeConnection() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnecting = false;
      debugPrint('🔌 Socket connection closed.');
    }
  }

  /// دالة للتحقق من حالة الاتصال
  static bool isConnected() {
    return _socket != null && _socket!.connected;
  }

  /// دالة لإعادة الاتصال يدوياً
  static Future<void> reconnect() async {
    debugPrint('🔄 Manual reconnection requested...');
    closeRealtimeConnection();
    await Future.delayed(const Duration(milliseconds: 500));
    await initRealtimeNotifications();
  }

  /// دالة لجلب العدد يدوياً وتحديث الـ Notifier
  static Future<void> updateUnreadCountOnConnect() async {
    try {
      final count = await getUnreadCount();
      hasUnreadNotifier.value = count > 0;
      unreadCountNotifier.value = count;  // ✅ Update count notifier
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

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('✅ Successfully fetched ${data.length} notifications');
        
        final notifications = data.map((json) {
          return ProviderNotification(
            id: json['_id'],
            title: json['title'] ?? 'No Title',
            body: json['body'] ?? '',
            createdAt: DateTime.parse(json['createdAt']),
            isRead: json['isRead'] ?? false,
            type: _mapBackendTypeToUiType(json['type']),
          );
        }).toList();
        
        // تحديث القائمة العامة
        notificationsNotifier.value = notifications;
        
        return notifications;
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
        debugPrint('📊 Unread count from API: $count');
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
      debugPrint('📖 Starting markAllAsRead...');
      
      // ✅ تحديث محلي أولاً
      hasUnreadNotifier.value = false;
      unreadCountNotifier.value = 0;  // ✅ Reset count
      debugPrint('✅ Updated hasUnreadNotifier to false');
      
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/notifications/mark-all-read'),
        headers: headers,
      );
      
      debugPrint('📡 Response status: ${response.statusCode}');
      
      if (response.statusCode == 204 || response.statusCode == 200) {
        debugPrint('✅ Server confirmed: All notifications marked as read');
        
        // تحديث القائمة المحلية
        final updatedList = List<ProviderNotification>.from(notificationsNotifier.value);
        for (var n in updatedList) {
          n.isRead = true;
        }
        notificationsNotifier.value = updatedList;
        debugPrint('✅ Updated local notification list - all marked as read');
      } else {
        debugPrint('⚠️ Mark as read returned unexpected status: ${response.statusCode}');
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
        
        // حذف من القائمة المحلية
        final updatedList = notificationsNotifier.value
            .where((n) => n.id != id)
            .toList();
        notificationsNotifier.value = updatedList;
        
        // تحديث العداد
        await updateUnreadCountOnConnect();
      }
    } catch (e) {
      debugPrint('❌ Error deleting notification: $e');
      rethrow;
    }
  }

  /// دالة مساعدة لربط أنواع الباك إند مع أنواع الواجهة الأمامية
  static NotificationType _mapBackendTypeToUiType(String? backendType) {
    switch (backendType) {
      case 'new_message':
      case 'NEW_MESSAGE':
      case 'USER_MESSAGE':
        return NotificationType.message;
      case 'booking_confirmed':
      case 'BOOKING_CONFIRMED':
      case 'booking_cancelled':
      case 'BOOKING_CANCELLED':
        return NotificationType.booking;
      case 'SERVICE_FAVOURITED':
        return NotificationType.favorite;
      case 'REVIEW_ADDED':
        return NotificationType.review;
      case 'PAYOUT_SENT':
      case 'promo_code':
      case 'PROMO_CODE':
      default:
        return NotificationType.system;
    }
  }
}