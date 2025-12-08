// lib/services/service_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/services/auth_service.dart';
import 'dart:io';
import 'dart:typed_data'; // 💡 إضافة لـ Uint8List

class ServiceService {
  static final String baseUrl = AuthService.getBaseUrl();

  // ====================== 1. جلب خدمات المزود (GET /services/my) =========================
  // تستخدم لجلب قائمة الخدمات التي أنشأها المستخدم الموثق (المزود)
  static Future<List<dynamic>> fetchMyServices() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found.');
      }

      final response = await http.get(
        Uri.parse(
            '$baseUrl/services/my-services'), // الـ Endpoint لجلب خدمات المستخدم الموثق
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // ✅ النجاح: فك تشفير الـ JSON وإرجاع قائمة الخدمات
        return jsonDecode(response.body);
      } else {
        // ❌ فشل: التعامل مع رسالة الخطأ
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch services.');
      }
    } catch (e) {
      print('❌ Error in fetchMyServices: $e');
      rethrow;
    }
  }

  // --------------------------------------------------------------------------

  // ====================== 2. إضافة خدمة جديدة مع دعم الصور (POST /services) =========================
  static Future<Map<String, dynamic>> addService({
    required String title,
    required String description,
    required double price,
    required List<Map<String, String>> highlights,
    required List<Map<String, dynamic>> imageFilesData,
    required String category,
    required String priceType,
    double? latitude, // القيمة المتوفرة من شاشة الإدخال
    double? longitude, // القيمة المتوفرة من شاشة الإدخال
    required String address,
    required String city,
    required String companyName,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found.');
      }

      final url = Uri.parse('$baseUrl/services');
      final request = http.MultipartRequest('POST', url);

      // 1. إضافة الـ Headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // 2. إعداد حقول النص وإرسالها كـ JSON في حقل 'data'

      // ✅ تجهيز كائن الموقع (location object) بناءً على Schema الجديد
      final Map<String, dynamic> locationData = {
        'latitude': latitude ?? 0.0,
        'longitude': longitude ?? 0.0,
        'address': address, // يرسل لتحديد الموقع لاحقاً
        'city': city, // يرسل
      };

      final createServiceDtoForJson = {
        'serviceName': title,
        'description': description,
        'price': price,
        'category': category,
        'priceType': priceType,
        'location': locationData, // تمرير كائن الموقع المجهز
        'highlights': highlights,
        "companyName": companyName,
      };
      request.fields['data'] = jsonEncode(createServiceDtoForJson);

      for (var fileData in imageFilesData) {
        final List<int> fileBytes = fileData['bytes'] as List<int>;
        final String fileName = fileData['name'] as String;

        if (fileBytes.isNotEmpty) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'images',
              fileBytes,
              filename: fileName,
            ),
          );
        }
      }

      // 4. إرسال الطلب واستقبال الرد
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return responseBody;
      } else {
        final errorMessage =
            responseBody['message'] ?? 'Failed to create service.';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Error in addService with file upload: $e');
      rethrow;
    }
  }

  // --------------------------------------------------------------------------

  // ====================== 3. حذف خدمة (DELETE /services/:id) =========================
  static Future<void> deleteService(String serviceId) async {
    try {
      final token = await AuthService.getToken(); // 🔑 جلب رمز المصادقة
      if (token == null) {
        throw Exception('Authentication token not found.');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/services/id/$serviceId'), // الـ Endpoint للحذف
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer $token', // ✅ إضافة رمز المصادقة للتحقق من الإذن
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // 200/204: نجاح الحذف
        return;
      } else {
        // ❌ فشل: التعامل مع رسالة الخطأ
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to delete service.');
      }
    } catch (e) {
      print('❌ Error in deleteService: $e');
      rethrow;
    }
  }

  // --------------------------------------------------------------------------

  // ====================== 4. تحديث خدمة جزئياً (PATCH /services/:id) =========================
  // تُستخدم لتحديث أي حقل، وغالباً ما تستخدم لتغيير حالة isActive

  static Future<Map<String, dynamic>> updateService(
      String serviceId, Map<String, dynamic> updateData) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found.');
      }

      // يُفضل استخدام http.patch للتحديث الجزئي
      final response = await http.patch(
        Uri.parse('$baseUrl/services/$serviceId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updateData),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseBody;
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to update service.');
      }
    } catch (e) {
      print('❌ Error in updateService: $e');
      rethrow;
    }
  }

  static Future<String?> fetchCompanyName() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found.');
      }

      final response = await http.get(
        // استخدام نهاية النقطة التي حددتها
        Uri.parse('$baseUrl/providers/my-company-name'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // نفترض أن بنية الرد هي { "companyName": "اسم الشركة" }
        return responseData['companyName'] as String?;
      } else if (response.statusCode == 404) {
        // التعامل مع حالة عدم العثور على اسم الشركة
        print('Company name not found for this provider (404).');
        return null;
      } else {
        // التعامل مع رسائل الخطأ الأخرى
        final errorData = jsonDecode(response.body);
        print('Failed to fetch company name: ${errorData['message']}');
        throw Exception(
            errorData['message'] ?? 'Failed to fetch company name.');
      }
    } catch (e) {
      print('Error fetching company name: $e');
      // لا ترمي خطأ لعدم إيقاف عملية إضافة الخدمة بالكامل، بل أعد القيمة Null
      return null;
    }
  }

  // --------------------------------------------------------------------------

  // ====================== 5. جلب تفاصيل خدمة معينة (GET /services/:id) =========================
  // يستخدمه العميل لعرض شاشة تفاصيل خدمة
  static Future<Map<String, dynamic>> getServiceById(String serviceId) async {
    try {
      // لا نحتاج لـ token لأن هذه نقطة وصول عامة للعملاء
      final response = await http.get(
        Uri.parse('$baseUrl/services/$serviceId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // ✅ النجاح: فك تشفير الـ JSON وإرجاع تفاصيل الخدمة
        return jsonDecode(response.body);
      } else {
        // ❌ فشل: التعامل مع رسالة الخطأ
        final errorData = jsonDecode(response.body);
        throw Exception(
            errorData['message'] ?? 'Failed to fetch service details.');
      }
    } catch (e) {
      print('❌ Error in getServiceById: $e');
      rethrow;
    }
  }

  static Future<String> uploadServiceImage({
    String? filePath,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found.');
      }

      // ⚠️ يجب التأكد من أن هذا هو الـ Endpoint الصحيح لرفع الملفات لديك
      final url = Uri.parse('$baseUrl/upload/service-image');
      final request = http.MultipartRequest('POST', url);
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // 💡 المنطق الجديد: استخدام fromPath للجوال أو fromBytes للويب
      if (filePath != null) {
        // حالة الجوال (Android/iOS)
        request.files.add(
          await http.MultipartFile.fromPath(
            'file', // اسم الحقل في الـ Backend
            filePath,
          ),
        );
      } else if (fileBytes != null && fileName != null) {
        // حالة الويب (Web)
        request.files.add(
          http.MultipartFile.fromBytes(
            'file', // اسم الحقل في الـ Backend
            fileBytes,
            filename: fileName,
          ),
        );
      } else {
        throw Exception(
            'Image data is missing (requires filePath or fileBytes and fileName).');
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final imageUrl = responseData[
            'url']; // يجب التأكد من أن الخادم يعيد الرابط في هذا المفتاح
        if (imageUrl != null) {
          return imageUrl;
        } else {
          throw Exception(
              'Image upload succeeded, but URL not returned by server.');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ??
            'Failed to upload image. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to upload service image: $e');
    }
  }
}
