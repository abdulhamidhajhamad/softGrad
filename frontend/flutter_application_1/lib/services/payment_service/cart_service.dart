// lib/services/cart_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/services/auth_service.dart';

/// Model للـ CartItem (متطابق مع Backend)
class CartItemBackend {
  final String serviceId;
  final String serviceName;
  final String providerId;
  final String companyName;
  final String bookingType;
  final BookingDetailsBackend bookingDetails;
  final double price;
  final String? imageUrl;
  final String? packageId;
  final String? packageName;

  CartItemBackend({
    required this.serviceId,
    required this.serviceName,
    required this.providerId,
    required this.companyName,
    required this.bookingType,
    required this.bookingDetails,
    required this.price,
    this.imageUrl,
    this.packageId,
    this.packageName,
  });

  factory CartItemBackend.fromJson(Map<String, dynamic> json) {
    return CartItemBackend(
      serviceId: json['serviceId']?.toString() ?? '',
      serviceName: json['serviceName']?.toString() ?? 'Unknown Service',
      providerId: json['providerId']?.toString() ?? '',
      companyName: json['companyName']?.toString() ?? 'Unknown Provider',
      bookingType: json['bookingType']?.toString() ?? 'Display',
      bookingDetails: BookingDetailsBackend.fromJson(
        json['bookingDetails'] ?? {},
      ),
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
      imageUrl: json['imageUrl']?.toString(),
      packageId: json['packageId']?.toString(),
      packageName: json['packageName']?.toString(),
    );
  }
}

class BookingDetailsBackend {
  final String date;
  final int? startHour;
  final int? endHour;
  final int? numberOfPeople;
  final bool? isFullVenue;

  BookingDetailsBackend({
    required this.date,
    this.startHour,
    this.endHour,
    this.numberOfPeople,
    this.isFullVenue,
  });

  factory BookingDetailsBackend.fromJson(Map<String, dynamic> json) {
    return BookingDetailsBackend(
      date: json['date']?.toString() ?? DateTime.now().toIso8601String(),
      startHour: json['startHour'] as int?,
      endHour: json['endHour'] as int?,
      numberOfPeople: json['numberOfPeople'] as int?,
      isFullVenue: json['isFullVenue'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      if (startHour != null) 'startHour': startHour,
      if (endHour != null) 'endHour': endHour,
      if (numberOfPeople != null) 'numberOfPeople': numberOfPeople,
      if (isFullVenue != null) 'isFullVenue': isFullVenue,
    };
  }
}

/// Response من الـ Backend
class CartResponse {
  final String userId;
  final List<CartItemBackend> items;
  final double totalAmount;

  CartResponse({
    required this.userId,
    required this.items,
    required this.totalAmount,
  });

  factory CartResponse.fromJson(Map<String, dynamic> json) {
    return CartResponse(
      userId: json['userId']?.toString() ?? '',
      items: (json['items'] as List?)
              ?.map((item) => CartItemBackend.fromJson(item))
              .toList() ??
          [],
      totalAmount:
          (json['totalAmount'] is num) ? (json['totalAmount'] as num).toDouble() : 0.0,
    );
  }
}

class CartService {
  static final String baseUrl = AuthService.baseUrl;

  /// 🔹 1. Get Cart
  static Future<CartResponse?> getCart() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        print('❌ No token found');
        throw Exception('Please login first');
      }

      print('📡 Fetching cart...');
      final response = await http.get(
        Uri.parse('$baseUrl/cart'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Cart Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Handle empty cart (backend might return null)
        if (data == null) {
          return CartResponse(userId: '', items: [], totalAmount: 0.0);
        }

        final cart = CartResponse.fromJson(data);
        print('✅ Cart loaded: ${cart.items.length} items, Total: ${cart.totalAmount}');
        return cart;
      } else if (response.statusCode == 404) {
        // Empty cart
        return CartResponse(userId: '', items: [], totalAmount: 0.0);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to load cart');
      }
    } catch (e) {
      print('❌ Error fetching cart: $e');
      rethrow;
    }
  }

  /// 🔹 2. Add to Cart
  static Future<CartResponse> addToCart({
    required String serviceId,
    required BookingDetailsBackend bookingDetails,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Please login first');

      print('📡 Adding to cart: Service $serviceId');

      final response = await http.post(
        Uri.parse('$baseUrl/cart/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'serviceId': serviceId,
          'bookingDetails': bookingDetails.toJson(),
        }),
      );

      print('📥 Add to cart response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Service added to cart');
        return CartResponse.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to add to cart');
      }
    } catch (e) {
      print('❌ Error adding to cart: $e');
      rethrow;
    }
  }

  /// 🔹 3. Remove from Cart
  static Future<CartResponse> removeFromCart(String serviceId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Please login first');

      print('📡 Removing from cart: $serviceId');

      final response = await http.delete(
        Uri.parse('$baseUrl/cart/remove'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'serviceId': serviceId}),
      );

      print('📥 Remove response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Service removed from cart');
        return CartResponse.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to remove from cart');
      }
    } catch (e) {
      print('❌ Error removing from cart: $e');
      rethrow;
    }
  }

  /// 🔹 4. Update Cart Item
  static Future<CartResponse> updateCartItem({
    required String serviceId,
    required BookingDetailsBackend bookingDetails,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Please login first');

      print('📡 Updating cart item: $serviceId');

      final response = await http.patch(
        Uri.parse('$baseUrl/cart/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'serviceId': serviceId,
          'bookingDetails': bookingDetails.toJson(),
        }),
      );

      print('📥 Update response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Cart item updated');
        return CartResponse.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to update cart');
      }
    } catch (e) {
      print('❌ Error updating cart: $e');
      rethrow;
    }
  }

  /// 🔹 5. Clear Cart
  static Future<void> clearCart() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Please login first');

      print('📡 Clearing cart...');

      final response = await http.delete(
        Uri.parse('$baseUrl/cart/clear'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Clear cart response: ${response.statusCode}');

      if (response.statusCode == 204 || response.statusCode == 200) {
        print('✅ Cart cleared successfully');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to clear cart');
      }
    } catch (e) {
      print('❌ Error clearing cart: $e');
      rethrow;
    }
  }
}