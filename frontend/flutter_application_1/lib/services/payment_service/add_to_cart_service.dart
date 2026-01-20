// lib/services/payment_service/add_to_cart_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth_service.dart';

class AddToCartService {
  static final String baseUrl = AuthService.baseUrl;

  /// Add item to cart with booking details
  /// Returns success response or throws exception with error message
  static Future<Map<String, dynamic>> addToCart({
    required String serviceId,
    required Map<String, dynamic> bookingDetails,
  }) async {
    try {
      // Get authentication token
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Please login to add items to cart');
      }

      print('🛒 Adding to cart - Service: $serviceId');
      print('📅 Booking details: $bookingDetails');

      // Prepare request body
      final body = {
        'serviceId': serviceId,
        'bookingDetails': bookingDetails,
      };

      // Make API request
      final response = await http.post(
        Uri.parse('$baseUrl/cart/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      // Parse response
      final responseData = json.decode(response.body);

      // Handle success (200 OK)
      if (response.statusCode == 200) {
        print('✅ Item added to cart successfully');
        return {
          'success': true,
          'message': 'Added to cart successfully',
          'cart': responseData,
        };
      }

      // Handle errors (400, 404, 409, etc.)
      if (response.statusCode == 400) {
        throw Exception(responseData['message'] ?? 'Invalid booking details');
      } else if (response.statusCode == 404) {
        throw Exception('Service not found');
      } else if (response.statusCode == 409) {
        throw Exception(responseData['message'] ?? 'Service is not available for the selected date/time');
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again');
      } else {
        throw Exception(responseData['message'] ?? 'Failed to add to cart');
      }

    } catch (e) {
      print('❌ Error adding to cart: $e');
      rethrow;
    }
  }

  /// 🆕 Get alternative available slots when booking conflicts
  static Future<Map<String, dynamic>> getAlternativeSlots({
    required String serviceId,
    required String date,
    int? startHour,
    int? endHour,
    int? numberOfPeople,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Please login');
      }

      final body = <String, dynamic>{
        'date': date,
      };
      if (startHour != null) body['startHour'] = startHour;
      if (endHour != null) body['endHour'] = endHour;
      if (numberOfPeople != null) body['numberOfPeople'] = numberOfPeople;

      final response = await http.post(
        Uri.parse('$baseUrl/cart/check-alternatives/$serviceId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      print('📡 Alternative slots response: ${response.statusCode}');
      print('📡 Body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get alternatives');
      }
    } catch (e) {
      print('❌ Error getting alternatives: $e');
      rethrow;
    }
  }

  /// Get current cart
  static Future<Map<String, dynamic>> getCart() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Please login to view cart');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/cart'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'cart': data,
        };
      } else {
        throw Exception('Failed to load cart');
      }
    } catch (e) {
      print('❌ Error getting cart: $e');
      rethrow;
    }
  }

  /// Remove item from cart
  static Future<Map<String, dynamic>> removeFromCart(String serviceId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Please login');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/cart/remove'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'serviceId': serviceId}),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Item removed from cart',
        };
      } else {
        throw Exception('Failed to remove item');
      }
    } catch (e) {
      print('❌ Error removing from cart: $e');
      rethrow;
    }
  }
}