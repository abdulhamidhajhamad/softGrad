// lib/services/package_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/services/auth_service.dart'; 

class PackageService {
  // استخدام الـ BaseUrl الخاص بك
  // ⚠️ ملاحظة: يفضل استخدام AuthService.baseUrl لتجنب مشاكل IP الداخلي
  static const String _baseUrl = 'http://192.168.110.16:3000';

  // 1. ✅ دالة جلب الخدمات المتاحة للمزود (لإنشاء الباقة وحساب السعر الأساسي)
  // 🎯 EndPoint: /services/vendor-services-details
  static Future<List<Map<String, dynamic>>> fetchProviderServicesForCreation() async {
    const String servicesEndpoint = '$_baseUrl/services/vendor-services-details'; 

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found. Please log in.');
      }
      
      final response = await http.get(
        Uri.parse(servicesEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        // يتم التأكد من أن الكائنات في القائمة تحتوي على ID، Name، و Price
        return jsonList.cast<Map<String, dynamic>>();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch services for package creation.');
      }
    } catch (e) {
      print('❌ Error in fetchProviderServicesForCreation: $e');
      rethrow;
    }
  }


  // 2. ✅ دالة جلب الباقات الموجودة للمزود (GET /packages)
  static Future<List<Map<String, dynamic>>> fetchProviderPackages() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found. Please log in.');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/packages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.cast<Map<String, dynamic>>();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch packages.');
      }
    } catch (e) {
      print('❌ Error in fetchProviderPackages: $e');
      rethrow;
    }
  }

  // 3. ✅ دالة إنشاء باقة جديدة (POST /packages)
  static Future<Map<String, dynamic>> createPackage({
    required String packageName,
    required List<String> serviceIds,
    required double newPrice,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found. Please log in.');
      }

      final body = {
        "packageName": packageName,
        "serviceIds": serviceIds,
        "newPrice": newPrice,
        // تحويل التواريخ إلى صيغة ISO 8601 المطلوبة
        if (startDate != null) "startDate": startDate.toIso8601String(),
        if (endDate != null) "endDate": endDate.toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/packages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return responseBody;
      } else {
        throw Exception(
            responseBody['message'] ?? 'Failed to create package.');
      }
    } catch (e) {
      print('❌ Error in createPackage: $e');
      rethrow;
    }
  }

  // 4. ✅ دالة حذف باقة (DELETE /packages/:id)
  static Future<void> deletePackage(String packageId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found.');
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/packages/$packageId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to delete package.');
      }
    } catch (e) {
      print('❌ Error in deletePackage: $e');
      rethrow;
    }
  }
}