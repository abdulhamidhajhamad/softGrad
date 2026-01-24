//handel Api calls related to admin functionalities 
//admin_service/admin_service.dart --path of the file
// lib/services/admin_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth_service.dart';
import '../socket_service.dart';

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

  /// Get financial growth (with period option)
  static Future<Map<String, dynamic>> getFinancialGrowth({String period = '6months'}) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/stats/financial-growth?period=$period'),
        headers: headers,
      );

      print('📈 Financial Growth Response: ${response.statusCode}');
      print('📈 Financial Growth Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'period': data['period'] ?? 'Last 6 Months',
          'data': List<Map<String, dynamic>>.from(data['data'] ?? []),
        };
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
        Uri.parse('$baseUrl/admin/stats/top-providers?limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
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
        Uri.parse('$baseUrl/admin/reviews?filter=$filter'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Debug: Print first review structure
        if (data['reviews'] != null && (data['reviews'] as List).isNotEmpty) {
          print('📝 First review structure: ${json.encode(data['reviews'][0])}');
        }
        
        return data;
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
      print('🔑 Headers: $headers');
      print('🌐 URL: $baseUrl/promotion/admin/codes');
      
      final response = await http.get(
        Uri.parse('$baseUrl/promotion/admin/codes'),
        headers: headers,
      );

      print('📦 Promo codes status: ${response.statusCode}');
      print('📦 Promo codes response: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        } else if (decoded is Map && decoded['data'] != null) {
          return List<Map<String, dynamic>>.from(decoded['data']);
        } else if (decoded is Map && decoded['codes'] != null) {
          return List<Map<String, dynamic>>.from(decoded['codes']);
        }
        return [];
      } else {
        print('❌ Failed with status: ${response.statusCode}');
        throw Exception('Failed to fetch promo codes: ${response.statusCode}');
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
      print('📝 Marking all notifications as read...');
      final headers = await _getAuthHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/notifications/mark-all-read'),
        headers: headers,
      );
      print('✅ Mark all read response: ${response.statusCode}');
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

      print('📨 Get chats response: ${response.statusCode}');
      print('📨 Get chats body: ${response.body}');

      if (response.statusCode == 200) {
        final chats = List<Map<String, dynamic>>.from(json.decode(response.body));
        print('📨 Found ${chats.length} chats');
        return chats;
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
      // Get chats and count unread ones locally
      final chats = await getChats();
      int unreadCount = 0;
      for (final chat in chats) {
        if (chat['hasUnread'] == true || chat['unread'] == true) {
          unreadCount++;
        }
      }
      return unreadCount;
    } catch (e) {
      print('❌ Error fetching unread messages count: $e');
      return 0;
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

  /// Start or get existing chat with a user
  static Future<Map<String, dynamic>> startChatWithUser(String userId, String initialMessage) async {
    try {
      final headers = await _getAuthHeaders();
      
      print('🔄 Starting chat with user: $userId');
      
      // First, try to create or get existing chat using /chat/create endpoint
      final chatResponse = await http.post(
        Uri.parse('$baseUrl/chat/create'),
        headers: headers,
        body: json.encode({
          'receiverId': userId,
        }),
      );

      print('📦 Chat create response: ${chatResponse.statusCode} - ${chatResponse.body}');

      if (chatResponse.statusCode == 200 || chatResponse.statusCode == 201) {
        final chatData = json.decode(chatResponse.body);
        final chatId = chatData['_id'] ?? chatData['id'];
        
        print('✅ Chat created/found: $chatId');
        
        // Send the initial message using /chat/send endpoint
        if (initialMessage.isNotEmpty && chatId != null) {
          final msgResponse = await http.post(
            Uri.parse('$baseUrl/chat/send'),
            headers: headers,
            body: json.encode({
              'chatId': chatId,
              'content': initialMessage,
            }),
          );
          print('📨 Message send response: ${msgResponse.statusCode}');
          
          // Trigger chat list refresh for real-time update
          SocketService.triggerChatRefresh({'chatId': chatId, 'type': 'new-message'});
        }
        
        return chatData;
      } else {
        print('❌ Chat create failed: ${chatResponse.body}');
        throw Exception('Failed to start chat: ${chatResponse.statusCode}');
      }
    } catch (e) {
      print('❌ Error starting chat: $e');
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