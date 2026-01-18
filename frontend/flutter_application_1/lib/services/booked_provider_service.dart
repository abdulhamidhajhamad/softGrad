// lib/services/booked_provider_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/services/auth_service.dart';

/// 🔔 Service for handling vendor bookings with real-time updates
class BookedProviderService {
  static String get baseUrl => AuthService.baseUrl; // ✅ Dynamic URL
  // static const String baseUrl = 'http://localhost:3000'; // للـ iOS Simulator
  // static const String baseUrl = 'http://YOUR_IP:3000'; // للـ Real Device

  // ✅ ValueNotifier للإشعار بوجود حجوزات غير مُشاهدة
  static final ValueNotifier<int> unseenCountNotifier = ValueNotifier<int>(0);

  /// 📥 جلب جميع حجوزات الـ Vendor مع معلومات العميل
  static Future<List<Map<String, dynamic>>> fetchVendorBookings() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/bookings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📦 Fetch bookings response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> bookingsData = json.decode(response.body);
        debugPrint('✅ Fetched ${bookingsData.length} bookings');
        
        // ✅ Backend يُرسل clientName مباشرة - لا حاجة لمعالجة إضافية
        List<Map<String, dynamic>> processedBookings = bookingsData
            .map((booking) => Map<String, dynamic>.from(booking))
            .toList();
        
        return processedBookings;
      } else {
        debugPrint('❌ Failed to fetch bookings: ${response.body}');
        throw Exception('Failed to load bookings: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching bookings: $e');
      rethrow;
    }
  }

  /// 👤 جلب اسم المستخدم من الـ userId
  static Future<String> _fetchUserName(String userId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        return userData['name'] ?? 'Unknown Client';
      } else {
        debugPrint('⚠️ Failed to fetch user name for $userId');
        return 'Unknown Client';
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching user name: $e');
      return 'Unknown Client';
    }
  }

  /// 🔢 جلب عدد الحجوزات غير المُشاهدة
  static Future<int> fetchUnseenCount() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/bookings/vendor/unseen-count'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📊 Unseen count response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final count = data['count'] ?? 0;
        debugPrint('✅ Unseen bookings count: $count');
        
        // تحديث الـ Notifier
        unseenCountNotifier.value = count;
        
        return count;
      } else {
        debugPrint('❌ Failed to fetch unseen count: ${response.body}');
        return 0;
      }
    } catch (e) {
      debugPrint('❌ Error fetching unseen count: $e');
      return 0;
    }
  }

  /// 👁️ تعليم جميع الحجوزات كـ "تمت مشاهدتها" (يتم استدعاؤها عند فتح صفحة Bookings)
  static Future<bool> markAllBookingsAsSeen() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/bookings/mark-all-seen'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('👁️ Mark all as seen response: ${response.statusCode}');

      if (response.statusCode == 204 || response.statusCode == 200) {
        debugPrint('✅ All bookings marked as seen');
        
        // تحديث العداد إلى 0
        unseenCountNotifier.value = 0;
        
        return true;
      } else {
        debugPrint('❌ Failed to mark all as seen: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error marking all bookings as seen: $e');
      return false;
    }
  }

  /// ❌ إلغاء الحجز من قبل الـ Vendor
  static Future<bool> cancelBooking({
    required String bookingId,
    String? reason,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final body = reason != null && reason.isNotEmpty
          ? json.encode({'reason': reason})
          : json.encode({});

      final response = await http.patch(
        Uri.parse('$baseUrl/bookings/$bookingId/cancel'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      debugPrint('❌ Cancel booking response: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ Booking $bookingId cancelled successfully');
        return true;
      } else {
        debugPrint('❌ Failed to cancel booking: ${response.body}');
        throw Exception('Failed to cancel booking: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error cancelling booking: $e');
      rethrow;
    }
  }

  /// 🔄 تحديث عداد الحجوزات غير المُشاهدة (للاستدعاء الدوري)
  static Future<void> updateUnseenCount() async {
    await fetchUnseenCount();
  }

  /// 🧹 تنظيف الـ Notifier
  static void dispose() {
    unseenCountNotifier.dispose();
  }
}