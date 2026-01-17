// lib/services/offer_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/service_service.dart';

/// ✅ Offer Service - Handles all offer-related API calls
class OfferService {
  static String get baseUrl => ServiceService.baseUrl;

  /// Get provider's services with offer status (Active Offers + Available Services)
  static Future<Map<String, dynamic>> getMyServicesWithOffers() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Authentication token not found.');

      final res = await http.get(
        Uri.parse('$baseUrl/services/offers/my-services'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return {
          'success': true,
          'activeOffers': data['activeOffers'] ?? [],
          'availableServices': data['availableServices'] ?? [],
        };
      } else {
        final error = json.decode(res.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to fetch services with offers',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Create an offer for a service
  static Future<Map<String, dynamic>> createOffer({
    required String serviceId,
    required double discountedPrice,
    double? discountPercentage,
    required DateTime startDate,
    required DateTime endDate,
    String? description,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Authentication token not found.');

      final body = {
        'discountedPrice': discountedPrice,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        if (discountPercentage != null) 'discountPercentage': discountPercentage,
        if (description != null && description.isNotEmpty) 'description': description,
      };

      final res = await http.post(
        Uri.parse('$baseUrl/services/offers/$serviceId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      final data = json.decode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Offer created successfully',
          'service': data['service'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create offer',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Remove an offer from a service
  static Future<Map<String, dynamic>> removeOffer(String serviceId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Authentication token not found.');

      final res = await http.delete(
        Uri.parse('$baseUrl/services/offers/$serviceId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(res.body);

      if (res.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Offer removed successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to remove offer',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Calculate discount percentage from original and discounted price
  static double calculateDiscountPercentage(double originalPrice, double discountedPrice) {
    if (originalPrice <= 0) return 0;
    return ((originalPrice - discountedPrice) / originalPrice) * 100;
  }

  /// Format remaining time for offer
  static String formatRemainingTime(DateTime endDate) {
    final now = DateTime.now();
    final difference = endDate.difference(now);

    if (difference.isNegative) {
      return 'Expired';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days left';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours left';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes left';
    } else {
      return 'Ending soon';
    }
  }

  /// Check if offer is still active
  static bool isOfferActive(DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) return false;
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }
}
