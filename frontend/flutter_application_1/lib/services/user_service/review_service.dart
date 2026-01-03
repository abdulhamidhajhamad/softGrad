//handel api calls related to reviews
// lib/services/review_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/models/review_model.dart';

class ReviewService {
  static final String baseUrl = AuthService.baseUrl;

  /// ✅ Create Review
  static Future<Review> createReview({
    required String bookingId,
    required String serviceId,
    required int rating,
    String? comment,
    List<String>? tags,
    List<String>? images,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.post(
        Uri.parse('$baseUrl/reviews'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'bookingId': bookingId,
          'serviceId': serviceId,
          'rating': rating,
          'comment': comment,
          'images': images ?? [],
        }),
      );

      print('📤 Create Review Response: ${response.statusCode}');
      print('📤 Response Body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Review.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to create review');
      }
    } catch (e) {
      print('❌ Error creating review: $e');
      rethrow;
    }
  }

  /// ✅ Get Pending Reviews
  static Future<List<PendingReview>> getPendingReviews() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$baseUrl/reviews/pending'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Pending Reviews Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => PendingReview.fromJson(item)).toList();
      } else {
        throw Exception('Failed to fetch pending reviews');
      }
    } catch (e) {
      print('❌ Error fetching pending reviews: $e');
      rethrow;
    }
  }

  /// ✅ Get Service Reviews (with pagination)
  static Future<Map<String, dynamic>> getServiceReviews({
    required String serviceId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reviews/service/$serviceId?page=$page&limit=$limit'),
      );

      print('📥 Service Reviews Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'reviews': (data['reviews'] as List).map((item) => Review.fromJson(item)).toList(),
          'totalCount': data['totalCount'] ?? 0,
          'page': data['page'] ?? 1,
          'totalPages': data['totalPages'] ?? 1,
          'averageRating': (data['averageRating'] ?? 0).toDouble(),
          'totalReviews': data['totalReviews'] ?? 0,
        };
      } else {
        throw Exception('Failed to fetch service reviews');
      }
    } catch (e) {
      print('❌ Error fetching service reviews: $e');
      rethrow;
    }
  }

  /// ✅ Can Review (Check eligibility)
  static Future<Map<String, dynamic>> canReview(String bookingId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$baseUrl/reviews/can-review/$bookingId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Can Review Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to check review eligibility');
      }
    } catch (e) {
      print('❌ Error checking review eligibility: $e');
      rethrow;
    }
  }

  /// ✅ Get My Reviews
  static Future<Map<String, dynamic>> getMyReviews({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$baseUrl/reviews/my-reviews?page=$page&limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 My Reviews Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'reviews': (data['reviews'] as List).map((item) => Review.fromJson(item)).toList(),
          'totalCount': data['totalCount'] ?? 0,
          'page': data['page'] ?? 1,
          'totalPages': data['totalPages'] ?? 1,
        };
      } else {
        throw Exception('Failed to fetch my reviews');
      }
    } catch (e) {
      print('❌ Error fetching my reviews: $e');
      rethrow;
    }
  }

  /// ✅ Get User Bookings (All)
static Future<List<dynamic>> getUserBookings() async {
  try {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No authentication token found');

    final response = await http.get(
      Uri.parse('${AuthService.baseUrl}/bookings'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    print('📥 Get Bookings Response: ${response.statusCode}');
    print('📥 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Failed to fetch bookings');
    }
  } catch (e) {
    print('❌ Error fetching bookings: $e');
    rethrow;
  }
}
}