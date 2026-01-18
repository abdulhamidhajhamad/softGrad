// lib/services/payment_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/services/auth_service.dart';

/// Checkout Response
class CheckoutResponse {
  final String clientSecret;
  final double originalAmount;
  final double? discount;
  final double finalAmount;
  final String? promoCodeApplied;

  CheckoutResponse({
    required this.clientSecret,
    required this.originalAmount,
    this.discount,
    required this.finalAmount,
    this.promoCodeApplied,
  });

  factory CheckoutResponse.fromJson(Map<String, dynamic> json) {
    return CheckoutResponse(
      clientSecret: json['clientSecret']?.toString() ?? '',
      originalAmount: (json['originalAmount'] is num)
          ? (json['originalAmount'] as num).toDouble()
          : 0.0,
      discount: (json['discount'] is num) ? (json['discount'] as num).toDouble() : null,
      finalAmount:
          (json['finalAmount'] is num) ? (json['finalAmount'] as num).toDouble() : 0.0,
      promoCodeApplied: json['promoCodeApplied']?.toString(),
    );
  }
}

/// Confirm Payment Response
class ConfirmPaymentResponse {
  final bool success;
  final String message;
  final List<dynamic> bookings;
  final PaymentIntentInfo paymentIntent;

  ConfirmPaymentResponse({
    required this.success,
    required this.message,
    required this.bookings,
    required this.paymentIntent,
  });

  factory ConfirmPaymentResponse.fromJson(Map<String, dynamic> json) {
    return ConfirmPaymentResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      bookings: json['bookings'] as List? ?? [],
      paymentIntent: PaymentIntentInfo.fromJson(json['paymentIntent'] ?? {}),
    );
  }
}

class PaymentIntentInfo {
  final String id;
  final double amount;
  final double originalAmount;
  final double discount;
  final String? promoCode;
  final String status;

  PaymentIntentInfo({
    required this.id,
    required this.amount,
    required this.originalAmount,
    required this.discount,
    this.promoCode,
    required this.status,
  });

  factory PaymentIntentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentIntentInfo(
      id: json['id']?.toString() ?? '',
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0.0,
      originalAmount: (json['originalAmount'] is num)
          ? (json['originalAmount'] as num).toDouble()
          : 0.0,
      discount: (json['discount'] is num) ? (json['discount'] as num).toDouble() : 0.0,
      promoCode: json['promoCode']?.toString(),
      status: json['status']?.toString() ?? '',
    );
  }
}

class PaymentService {
  static final String baseUrl = AuthService.baseUrl;

  /// 🔹 1. Create Payment Intent (Checkout)
  static Future<CheckoutResponse> checkout({
    String currency = 'usd',
    String? promoCode,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Please login first');

      print('📡 Creating payment intent...');
      if (promoCode != null && promoCode.isNotEmpty) {
        print('🎟️ Promo code: $promoCode');
      }

      final Map<String, dynamic> body = {'currency': currency};
      if (promoCode != null && promoCode.trim().isNotEmpty) {
        body['promoCode'] = promoCode.trim().toUpperCase();
      }

      final response = await http.post(
        Uri.parse('$baseUrl/payment/checkout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );
      print('📥 Checkout response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final checkout = CheckoutResponse.fromJson(data);
        
        print('✅ Payment intent created');
        print('💰 Original: \$${checkout.originalAmount}');
        if (checkout.discount != null && checkout.discount! > 0) {
          print('🎉 Discount: -\$${checkout.discount}');
          print('🏷️ Promo: ${checkout.promoCodeApplied}');
        }
        print('💵 Final: \$${checkout.finalAmount}');
        
        return checkout;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to create payment intent');
      }
    } catch (e) {
      print('❌ Error in checkout: $e');
      rethrow;
    }
  }

  /// 🔹 2. Confirm Payment and Create Bookings
  static Future<ConfirmPaymentResponse> confirmPayment(String paymentIntentId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Please login first');

      print('📡 Confirming payment: $paymentIntentId');

      final response = await http.post(
        Uri.parse('$baseUrl/payment/confirm'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'paymentIntentId': paymentIntentId}),
      );

      print('📥 Confirm response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = ConfirmPaymentResponse.fromJson(data);
        
        print('✅ Payment confirmed!');
        print('📦 Bookings created: ${result.bookings.length}');
        print('💳 Transaction ID: ${result.paymentIntent.id}');
        
        return result;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to confirm payment');
      }
    } catch (e) {
      print('❌ Error confirming payment: $e');
      rethrow;
    }
  }

  /// 🔹 3. Original Payment Intent (for backward compatibility)
  static Future<String> createPaymentIntent({
    required double amount,
    String currency = 'usd',
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Please login first');

      print('📡 Creating simple payment intent: \$${amount}');

      final response = await http.post(
        Uri.parse('$baseUrl/payment/create-payment-intent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'amount': amount,
          'currency': currency,
        }),
      );

      print('📥 Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final clientSecret = data['clientSecret']?.toString() ?? '';
        print('✅ Client secret received');
        return clientSecret;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to create payment intent');
      }
    } catch (e) {
      print('❌ Error: $e');
      rethrow;
    }
  }
}