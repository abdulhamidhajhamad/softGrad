//handel Api calls related to admin functionalities 
//admin_service/admin_service.dart --path of the file
// lib/services/admin_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth_service.dart';

class AdminService {
  static String get baseUrl => AuthService.baseUrl;

  // ====================== HEADERS =========================
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await AuthService. getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ====================== DASHBOARD =========================
  
  /// Get complete dashboard summary
  static Future<Map<String, dynamic>> getDashboardSummary() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/dashboard/summary'),
        headers: headers,
      );

      if (response. statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch dashboard:  ${response.body}');
      }
    } catch (e) {
      print('❌ Error fetching dashboard: $e');
      rethrow;
    }
  }

  /// Get total revenue
  static Future<double> getTotalRevenue() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/stats/revenue'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['totalRevenue'] ?? 0).toDouble();
      } else {
        throw Exception('Failed to fetch revenue');
      }
    } catch (e) {
      print('❌ Error fetching revenue: $e');
      rethrow;
    }
  }

  /// Get financial growth (last 7 months)
  static Future<List<Map<String, dynamic>>> getFinancialGrowth() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/stats/financial-growth'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Failed to fetch financial growth');
      }
    } catch (e) {
      print('❌ Error fetching financial growth: $e');
      rethrow;
    }
  }

  /// Get booking stats
  static Future<Map<String, dynamic>> getBookingStats() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/stats/bookings'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch booking stats');
      }
    } catch (e) {
      print('❌ Error fetching booking stats: $e');
      rethrow;
    }
  }

  /// Get top providers sales
  static Future<Map<String, dynamic>> getTopProviderSales({int limit = 10}) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/stats/top-providers? limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response. body);
      } else {
        throw Exception('Failed to fetch top providers');
      }
    } catch (e) {
      print('❌ Error fetching top providers: $e');
      rethrow;
    }
  }

  // ====================== SERVICES & PACKAGES =========================

  /// Get service sales
  static Future<List<Map<String, dynamic>>> getServiceSales() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/stats/service-sales'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else {
        throw Exception('Failed to fetch service sales');
      }
    } catch (e) {
      print('❌ Error fetching service sales: $e');
      rethrow;
    }
  }

  /// Get package sales
  static Future<List<Map<String, dynamic>>> getPackageSales() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/stats/package-sales'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response. body));
      } else {
        throw Exception('Failed to fetch package sales');
      }
    } catch (e) {
      print('❌ Error fetching package sales: $e');
      rethrow;
    }
  }

  // ====================== USERS & PROVIDERS =========================

  /// Get all users
  static Future<Map<String, dynamic>> getAllUsers() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/users'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response. body);
      } else {
        throw Exception('Failed to fetch users');
      }
    } catch (e) {
      print('❌ Error fetching users:  $e');
      rethrow;
    }
  }

  /// Get all providers
  static Future<Map<String, dynamic>> getAllProviders() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri. parse('$baseUrl/admin/providers'),
        headers: headers,
      );

      if (response. statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch providers');
      }
    } catch (e) {
      print('❌ Error fetching providers: $e');
      rethrow;
    }
  }

  /// Get users count
  static Future<int> getUsersCount() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/stats/users'),
        headers: headers,
      );

      if (response. statusCode == 200) {
        final data = json.decode(response.body);
        return data['regularUsersCount'] ??  0;
      } else {
        throw Exception('Failed to fetch users count');
      }
    } catch (e) {
      print('❌ Error fetching users count: $e');
      rethrow;
    }
  }

  /// Get providers count
  static Future<int> getProvidersCount() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/stats/providers'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['providersCount'] ?? 0;
      } else {
        throw Exception('Failed to fetch providers count');
      }
    } catch (e) {
      print('❌ Error fetching providers count: $e');
      rethrow;
    }
  }

  // ====================== REVIEWS =========================

  /// Get all reviews
  static Future<Map<String, dynamic>> getAllReviews({String filter = 'all'}) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/reviews? filter=$filter'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response. body);
      } else {
        throw Exception('Failed to fetch reviews');
      }
    } catch (e) {
      print('❌ Error fetching reviews: $e');
      rethrow;
    }
  }

  // ====================== PROMO CODES =========================

  /// Get all promo codes
  static Future<List<Map<String, dynamic>>> getPromoCodes() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri. parse('$baseUrl/promotion/admin/codes'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>. from(json.decode(response.body));
      } else {
        throw Exception('Failed to fetch promo codes');
      }
    } catch (e) {
      print('❌ Error fetching promo codes: $e');
      rethrow;
    }
  }

  /// Create promo code
  static Future<Map<String, dynamic>> createPromoCode({
    required String code,
    required String description,
    required int discountValue,
    required String expiryDate,
    String? startDate,
    String type = 'percentage',
    int? minPurchaseAmount,
    int? maxDiscountAmount,
    int? usageLimit,
    bool sendNotification = true,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      
      final body = {
        'code':  code. toUpperCase(),
        'description': description,
        'type': type,
        'discountValue':  discountValue,
        'expiryDate': expiryDate,
        'sendNotification': sendNotification,
      };

      if (startDate != null) body['startDate'] = startDate;
      if (minPurchaseAmount != null) body['minPurchaseAmount'] = minPurchaseAmount;
      if (maxDiscountAmount != null) body['maxDiscountAmount'] = maxDiscountAmount;
      if (usageLimit != null) body['usageLimit'] = usageLimit;

      final response = await http.post(
        Uri.parse('$baseUrl/promotion/admin/create-code'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        return json.decode(response. body);
      } else {
        throw Exception('Failed to create promo code:  ${response.body}');
      }
    } catch (e) {
      print('❌ Error creating promo code: $e');
      rethrow;
    }
  }

  /// Delete promo code
  static Future<void> deletePromoCode(String id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/promotion/admin/codes/$id'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete promo code');
      }
    } catch (e) {
      print('❌ Error deleting promo code:  $e');
      rethrow;
    }
  }

  // ====================== NOTIFICATIONS =========================

  /// Get admin notifications
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>. from(json.decode(response.body));
      } else {
        throw Exception('Failed to fetch notifications');
      }
    } catch (e) {
      print('❌ Error fetching notifications: $e');
      rethrow;
    }
  }

  /// Get unread notifications count
  static Future<int> getUnreadNotificationsCount() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/unread/count'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response. body);
        return data['count'] ??  0;
      } else {
        throw Exception('Failed to fetch unread count');
      }
    } catch (e) {
      print('❌ Error fetching unread count: $e');
      rethrow;
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllNotificationsAsRead() async {
    try {
      final headers = await _getAuthHeaders();
      await http.patch(
        Uri. parse('$baseUrl/notifications/mark-all-read'),
        headers: headers,
      );
    } catch (e) {
      print('❌ Error marking notifications as read: $e');
      rethrow;
    }
  }

  /// Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      final headers = await _getAuthHeaders();
      await http.delete(
        Uri.parse('$baseUrl/notifications/$notificationId'),
        headers: headers,
      );
    } catch (e) {
      print('❌ Error deleting notification: $e');
      rethrow;
    }
  }

  // ====================== CHAT/MESSAGES =========================

  /// Get admin chats
  static Future<List<Map<String, dynamic>>> getChats() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/chat/my-chats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else {
        throw Exception('Failed to fetch chats');
      }
    } catch (e) {
      print('❌ Error fetching chats: $e');
      rethrow;
    }
  }

  /// Get unread messages count
  static Future<int> getUnreadMessagesCount() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/chat/unread-count'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'] ?? 0;
      } else {
        throw Exception('Failed to fetch unread messages count');
      }
    } catch (e) {
      print('❌ Error fetching unread messages count: $e');
      rethrow;
    }
  }

  /// Get messages for a chat
  static Future<List<Map<String, dynamic>>> getMessages(String chatId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/chat/messages/$chatId'),
        headers: headers,
      );

      if (response. statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else {
        throw Exception('Failed to fetch messages');
      }
    } catch (e) {
      print('❌ Error fetching messages: $e');
      rethrow;
    }
  }

  /// Send message
  static Future<Map<String, dynamic>> sendMessage(String chatId, String content) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/chat/send'),
        headers: headers,
        body: json.encode({
          'chatId': chatId,
          'content': content,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json. decode(response.body);
      } else {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      print('❌ Error sending message: $e');
      rethrow;
    }
  }

  // ====================== DELETE OPERATIONS =========================

  /// Delete user by email
  static Future<void> deleteUserByEmail(String email) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/users/by-email/$email'),
        headers: headers,
      );

      if (response. statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ??  'Failed to delete user');
      }
    } catch (e) {
      print('❌ Error deleting user:  $e');
      rethrow;
    }
  }

  /// Delete provider by email
  static Future<void> deleteProviderByEmail(String email) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/providers/by-email/$email'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to delete provider');
      }
    } catch (e) {
      print('❌ Error deleting provider: $e');
      rethrow;
    }
  }

  /// Delete service by name
  static Future<void> deleteServiceByName(String name) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/services/by-name/$name'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to delete service');
      }
    } catch (e) {
      print('❌ Error deleting service: $e');
      rethrow;
    }
  }

  /// Delete package by name
  static Future<void> deletePackageByName(String name) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/packages/by-name/$name'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        final error = json.decode(response. body);
        throw Exception(error['message'] ?? 'Failed to delete package');
      }
    } catch (e) {
      print('❌ Error deleting package: $e');
      rethrow;
    }
  }
}