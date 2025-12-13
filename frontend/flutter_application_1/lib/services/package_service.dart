// lib/services/package_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/service_service.dart';

class PackageService {
  static final String baseUrl = ServiceService.baseUrl;

  /// جلب خدمات الـ Provider لإنشاء الباقات (مع تفاصيل السعر)
  static Future<List<Map<String, dynamic>>> fetchProviderServicesForCreation() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Authentication token not found.');

      final res = await http.get(
        Uri.parse('$baseUrl/services/vendor-services-details'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = _decodeJsonSafe(res.body);

      if (res.statusCode == 200) {
        if (data is List) {
          // ✅ نورمالايز البيانات لتشمل معلومات السعر
          return data.map((service) {
            return _normalizeServiceForPackage(service);
          }).toList();
        }
        return [];
      }

      throw Exception(_extractMessage(data) ?? 'Failed to fetch services.');
    } catch (e) {
      print('❌ Error in fetchProviderServicesForCreation: $e');
      rethrow;
    }
  }

  /// ✅ نورمالايز Service لتحديد نوع السعر
  static Map<String, dynamic> _normalizeServiceForPackage(dynamic service) {
    if (service is! Map) return {};

    final Map<String, dynamic> normalized = {};

    normalized['_id'] = (service['_id'] ?? '').toString();
    normalized['name'] = (service['name'] ?? '').toString();
    normalized['bookingType'] = (service['bookingType'] ?? '').toString();

    // ✅ معالجة price (قد يكون object أو number)
    final priceData = service['price'];
    
    // تحديد نوع السعر
    String priceType = 'fixed'; // fixed | hourly | capacity
    double? basePrice;
    double? perHour;
    double? perPerson;

    if (priceData is num) {
      // سعر ثابت
      basePrice = priceData.toDouble();
      priceType = 'fixed';
    } else if (priceData is Map) {
      // PricingOptions object
      basePrice = _toDoubleOrNull(priceData['basePrice']);
      perHour = _toDoubleOrNull(priceData['perHour']);
      perPerson = _toDoubleOrNull(priceData['perPerson']);

      // تحديد النوع بناءً على القيم الموجودة
      if (perHour != null && perHour > 0) {
        priceType = 'hourly';
      } else if (perPerson != null && perPerson > 0) {
        priceType = 'capacity';
      } else if (basePrice != null && basePrice > 0) {
        priceType = 'fixed';
      }
    }

    normalized['priceType'] = priceType;
    normalized['basePrice'] = basePrice ?? 0.0;
    normalized['perHour'] = perHour ?? 0.0;
    normalized['perPerson'] = perPerson ?? 0.0;

    // للعرض في UI
    if (priceType == 'hourly') {
      normalized['displayPrice'] = perHour;
      normalized['priceLabel'] = 'Per Hour';
    } else if (priceType == 'capacity') {
      normalized['displayPrice'] = perPerson;
      normalized['priceLabel'] = 'Per Person';
    } else {
      normalized['displayPrice'] = basePrice;
      normalized['priceLabel'] = 'Fixed Price';
    }

    return normalized;
  }

  /// جلب باقات الـ Provider
  static Future<List<dynamic>> fetchProviderPackages() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Authentication token not found.');

      final res = await http.get(
        Uri.parse('$baseUrl/packages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = _decodeJsonSafe(res.body);

      if (res.statusCode == 200) {
        if (data is List) return data;
        if (data is Map && data['data'] is List) return data['data'];
        return [];
      }

      throw Exception(_extractMessage(data) ?? 'Failed to fetch packages.');
    } catch (e) {
      print('❌ Error in fetchProviderPackages: $e');
      rethrow;
    }
  }

  /// إنشاء باقة جديدة
  static Future<void> createPackage({
    required String packageName,
    required List<String> serviceIds,
    required double newPrice,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Authentication token not found.');

      final now = DateTime.now();
      final start = startDate ?? now;
      final end = endDate ?? DateTime(now.year + 1, now.month, now.day);

      final body = jsonEncode({
        'packageName': packageName,
        'serviceIds': serviceIds,
        'newPrice': newPrice,
        'startDate': start.toIso8601String(),
        'endDate': end.toIso8601String(),
      });

      final res = await http.post(
        Uri.parse('$baseUrl/packages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (res.statusCode == 201 || res.statusCode == 200) return;

      final data = _decodeJsonSafe(res.body);
      throw Exception(_extractMessage(data) ?? 'Failed to create package.');
    } catch (e) {
      print('❌ Error in createPackage: $e');
      rethrow;
    }
  }

  /// حذف باقة
  static Future<void> deletePackage(String packageId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Authentication token not found.');

      final res = await http.delete(
        Uri.parse('$baseUrl/packages/$packageId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200 || res.statusCode == 204) return;

      final data = _decodeJsonSafe(res.body);
      throw Exception(_extractMessage(data) ?? 'Failed to delete package.');
    } catch (e) {
      print('❌ Error in deletePackage: $e');
      rethrow;
    }
  }

  // --------------------- helpers ---------------------
  static dynamic _decodeJsonSafe(String body) {
    try {
      final b = body.trim();
      if (b.isEmpty) return null;
      return jsonDecode(b);
    } catch (_) {
      return {'message': body};
    }
  }

  static String? _extractMessage(dynamic data) {
    if (data == null) return null;
    if (data is Map) {
      final m = data['message'] ?? data['error'] ?? data['msg'];
      if (m is String) return m;
      if (m is List) return m.join(', ');
    }
    if (data is String) return data;
    return null;
  }

  static double? _toDoubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }
}