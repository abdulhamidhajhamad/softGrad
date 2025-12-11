// lib/services/fcm_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Request notification permissions (iOS)
  static Future<void> requestPermission() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ User granted notification permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('⚠️ User granted provisional permission');
      } else {
        print('❌ User declined notification permission');
      }
    } catch (e) {
      print('❌ Error requesting permission: $e');
    }
  }

  /// Get FCM Token
  static Future<String?> getToken() async {
    try {
      // Request permission first (important for iOS)
      await requestPermission();
      
      final token = await _messaging.getToken();
      
      if (token != null) {
        print('🔑 FCM Token: $token');
        return token;
      } else {
        print('⚠️ FCM Token is null');
        return null;
      }
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Listen to token refresh
  static void onTokenRefresh(Function(String) onNewToken) {
    _messaging.onTokenRefresh.listen((newToken) {
      print('🔄 FCM Token refreshed: $newToken');
      onNewToken(newToken);
    });
  }

  /// Initialize FCM (call this in main.dart after Firebase.initializeApp)
  static Future<void> initialize() async {
    try {
      // Request permission
      await requestPermission();

      // Get initial token
      final token = await getToken();
      if (token != null) {
        print('📱 FCM initialized with token: ${token.substring(0, 20)}...');
      }

      // Listen for token refresh
      onTokenRefresh((newToken) {
        // You can update the token in your backend here if needed
        print('🔄 Token refreshed, update backend if user is logged in');
      });

      // Handle foreground messages (optional)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📬 Foreground message received');
        print('Title: ${message.notification?.title}');
        print('Body: ${message.notification?.body}');
      });

    } catch (e) {
      print('❌ Error initializing FCM: $e');
    }
  }
}