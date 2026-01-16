// lib/services/package_service.dart

import 'dart:convert';
import 'dart:typed_data';
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
    required List<Map<String, dynamic>> services,
    required double totalPrice,
    DateTime? startDate,
    DateTime? endDate,
    String? imageUrl,
    Uint8List? coverImageBytes, // ✅ صورة الغلاف (اختيارية)
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Authentication token not found.');

      // ✅ التعديل هنا: تحويل البيانات لتناسب DTO الباك إند بدقة
      // الباك إند يتوقع: services: [{ serviceId: "...", newPrice: number }]
      final List<Map<String, dynamic>> formattedServices = services.map((s) {
        return {
          "serviceId": s['id'], // يجب أن يطابق الاسم في DTO (serviceId)
          "newPrice": s['customPrice'], // السعر الجديد
          // قمنا بإزالة maxHours و maxCapacity لأنك لم تعد تدخلهم
        };
      }).toList();

      final packageData = {
        'packageName': packageName,
        'services': formattedServices,
        'newPrice': totalPrice,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'packageImageUrl': imageUrl,
      };

      // ✅ إذا كانت هناك صورة، نستخدم MultipartRequest
      if (coverImageBytes != null && coverImageBytes.isNotEmpty) {
        final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/packages'));
        request.headers.addAll({'Authorization': 'Bearer $token'});
        request.fields['data'] = jsonEncode(packageData);
        request.files.add(
          http.MultipartFile.fromBytes(
            'coverImage',
            coverImageBytes,
            filename: 'cover.jpg',
          ),
        );

        final streamed = await request.send();
        final res = await http.Response.fromStream(streamed);

        if (res.statusCode == 201 || res.statusCode == 200) {
          return;
        }

        final data = _decodeJsonSafe(res.body);
        throw Exception(_extractMessage(data) ?? 'Failed to create package.');
      } else {
        // ✅ بدون صورة - نستخدم JSON عادي مع form-data
        final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/packages'));
        request.headers.addAll({'Authorization': 'Bearer $token'});
        request.fields['data'] = jsonEncode(packageData);

        final streamed = await request.send();
        final res = await http.Response.fromStream(streamed);

        if (res.statusCode == 201 || res.statusCode == 200) {
          return;
        }

        final data = _decodeJsonSafe(res.body);
        throw Exception(_extractMessage(data) ?? 'Failed to create package.');
      }
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
// -------------------- 1. تحديث بيانات الباقة --------------------
  static Future<void> updatePackage({
  required String packageId,
  required String newPackageName,
  required List<Map<String, dynamic>> services, // ✅ تم التغيير: الآن نستقبل map كامل مع الأسعار
  required double newPrice,
  DateTime? startDate,
  DateTime? endDate,
  Uint8List? newCoverImageBytes, // ✅ صورة غلاف جديدة (اختيارية)
  String? existingImageUrl, // ✅ URL الصورة الحالية (للحفاظ عليها)
}) async {
  try {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Authentication token not found.');

    // تحضير البيانات
    final List<Map<String, dynamic>> formattedServices = services.map((s) {
      return {
        'serviceId': s['serviceId'] ?? s['id'],
        'newPrice': s['newPrice'] ?? s['customPrice'] ?? 0.0,
      };
    }).toList();

    final packageData = {
      'packageName': newPackageName,
      'services': formattedServices,
      'newPrice': newPrice,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };

    // ✅ استخدام MultipartRequest للتحديث (مع أو بدون صورة)
    final request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/packages/$packageId'));
    request.headers.addAll({'Authorization': 'Bearer $token'});
    request.fields['data'] = jsonEncode(packageData);

    // ✅ إذا كانت هناك صورة جديدة
    if (newCoverImageBytes != null && newCoverImageBytes.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'coverImage',
          newCoverImageBytes,
          filename: 'cover.jpg',
        ),
      );
    }

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode == 200) return;

    final data = _decodeJsonSafe(res.body);
    throw Exception(_extractMessage(data) ?? 'Failed to update package.');
  } catch (e) {
    print('❌ Error in updatePackage: $e');
    rethrow;
  }
}
// -------------------- 2. تحديث حالة الباقة (تفعيل/إلغاء تفعيل) --------------------
static Future<void> updatePackageStatus({
  required String packageId,
  required bool isActive,
}) async {
  try {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Authentication token not found.');

    final body = jsonEncode({'isActive': isActive});

    // نستخدم PATCH لتحديث خاصية واحدة فقط
    final res = await http.patch(
      Uri.parse('$baseUrl/packages/$packageId'), // افترضت وجود endpoint لتحديث الحالة
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    if (res.statusCode == 200) return;

    final data = _decodeJsonSafe(res.body);
    throw Exception(_extractMessage(data) ?? 'Failed to update package status.');
  } catch (e) {
    print('❌ Error in updatePackageStatus: $e');
    rethrow;
  }
}
}