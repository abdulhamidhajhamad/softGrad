// lib/services/service_service.dart

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:flutter_application_1/services/auth_service.dart';

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

class ServiceService {
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  // ✅ Localhost logic داخل ServiceService
  static String getBaseUrl() {
    if (_envBaseUrl.trim().isNotEmpty) return _envBaseUrl.trim();

    if (kIsWeb) {
      // Web (Chrome)
      return 'http://localhost:3000';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Android Emulator
      return 'http://localhost:3000';
    } else {
      // iOS / Desktop / غيره
      return 'http://localhost:3000';
    }
  }

  // ✅ baseUrl صار من هون
  static final String baseUrl = getBaseUrl();

  // ====================== 1. GET my services =========================
  static Future<List<dynamic>> fetchMyServices() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Authentication token not found.');

      final res = await http.get(
        Uri.parse('$baseUrl/services/my-services'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = _decodeJsonSafe(res.body);

      if (res.statusCode == 200) {
        if (data is List) return data;
        // أحيانًا الباك إند يرجّع object بدل list
        if (data is Map && data['data'] is List) return data['data'];
        return [];
      }

      throw Exception(_extractMessage(data) ?? 'Failed to fetch services.');
    } catch (e) {
      print('❌ Error in fetchMyServices: $e');
      rethrow;
    }
  }

  // ====================== 2. POST create service (multipart) =========================
  static Future<Map<String, dynamic>> addService({
    required String title,
    required String description,
    required double price,
    required List<Map<String, String>> highlights,
    required List<Map<String, dynamic>> imageFilesData,
    required String category,
    required String priceType,
    double? latitude,
    double? longitude,
    required String address,
    required String city,
    required String companyName,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Authentication token not found.');

      final url = Uri.parse('$baseUrl/services');
      final request = http.MultipartRequest('POST', url);

      request.headers.addAll({'Authorization': 'Bearer $token'});

      final Map<String, dynamic> locationData = {
        'latitude': latitude ?? 0.0,
        'longitude': longitude ?? 0.0,
        'address': address,
        'city': city,
      };

      final createServiceDtoForJson = {
        'serviceName': title,
        'description': description,
        'price': price,
        'category': category,
        'priceType': priceType,
        'location': locationData,
        'highlights': highlights,
        'companyName': companyName,
      };

      request.fields['data'] = jsonEncode(createServiceDtoForJson);

      for (final fileData in imageFilesData) {
        final bytesAny = fileData['bytes'];
        final String fileName = (fileData['name'] as String?) ?? 'image.jpg';

        List<int> fileBytes = [];
        if (bytesAny is Uint8List) fileBytes = bytesAny.toList();
        if (bytesAny is List<int>) fileBytes = bytesAny;

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

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);

      final data = _decodeJsonSafe(res.body);

      if (res.statusCode == 201 || res.statusCode == 200) {
        if (data is Map<String, dynamic>) return data;
        if (data is Map) return Map<String, dynamic>.from(data);
        return {'success': true};
      }

      throw Exception(_extractMessage(data) ?? 'Failed to create service.');
    } catch (e) {
      print('❌ Error in addService with file upload: $e');
      rethrow;
    }
  }

  // ====================== ✅ one method for ALL Add screens =========================
  static Future<Map<String, dynamic>> addServiceFromBookingForm(
      Map<String, dynamic> form) async {
    final String category = (form['category'] ?? '').toString();
    final String title = (form['name'] ?? form['serviceName'] ?? '').toString();
    final String description = (form['description'] ?? '').toString();

    final double price = _pickFirstDouble(
          form['price'],
          form['pricePerUnit'],
          form['finalPrice'],
          form['finalPricePerUnit'],
        ) ??
        0.0;

    String priceType = (form['priceType'] ?? '').toString().trim();
    if (priceType.isEmpty) {
      final String bookingType = (form['bookingType'] ?? '').toString();
      final String pricingModel = (form['pricingModel'] ?? '').toString();

      if (pricingModel == 'per_hour' ||
          bookingType.toLowerCase().contains('hour')) {
        priceType = 'per_hour';
      } else if (pricingModel == 'per_day' ||
          bookingType.toLowerCase().contains('full')) {
        priceType = 'per_day';
      } else if (pricingModel.contains('capacity')) {
        final unit = (form['capacityUnit'] ?? '').toString(); // person|piece
        priceType = unit == 'piece' ? 'per_piece' : 'per_person';
      } else if (pricingModel == 'per_item' ||
          bookingType.toLowerCase().contains('order')) {
        priceType = 'per_item';
      } else {
        priceType = 'per_service';
      }
    }

    final String address = (form['address'] ?? '').toString();
    final String city = (form['city'] ?? '').toString();

    final double? latitude = _toDoubleOrNull(form['latitude']);
    final double? longitude = _toDoubleOrNull(form['longitude']);

    final highlights = _normalizeHighlights(form['highlights']);
    final imageFilesData = _normalizeImages(form['coverImage'], form['images']);

    String companyName = (form['companyName'] ?? '').toString().trim();
    if (companyName.isEmpty) {
      companyName = (await fetchCompanyName()) ?? '';
    }

    if (category.isEmpty) throw Exception('Category is required.');
    if (title.trim().isEmpty) throw Exception('Service name is required.');
    if (description.trim().isEmpty) throw Exception('Description is required.');
    if (address.trim().isEmpty) throw Exception('Address is required.');
    if (city.trim().isEmpty) throw Exception('City is required.');
    if (price <= 0) throw Exception('Price must be > 0.');

    return addService(
      title: title.trim(),
      description: description.trim(),
      price: price,
      highlights: highlights,
      imageFilesData: imageFilesData,
      category: category,
      priceType: priceType,
      latitude: latitude,
      longitude: longitude,
      address: address.trim(),
      city: city.trim(),
      companyName: companyName,
    );
  }

  // ====================== 3. DELETE =========================
  static Future<void> deleteService(String serviceId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Authentication token not found.');

      final res = await http.delete(
        Uri.parse('$baseUrl/services/id/$serviceId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200 || res.statusCode == 204) return;

      final data = _decodeJsonSafe(res.body);
      throw Exception(_extractMessage(data) ?? 'Failed to delete service.');
    } catch (e) {
      print('❌ Error in deleteService: $e');
      rethrow;
    }
  }

  // ====================== 4. PATCH =========================
  static Future<Map<String, dynamic>> updateService(
      String serviceId, Map<String, dynamic> updateData) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Authentication token not found.');

      final res = await http.patch(
        Uri.parse('$baseUrl/services/$serviceId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updateData),
      );

      final data = _decodeJsonSafe(res.body);

      if (res.statusCode == 200) {
        if (data is Map<String, dynamic>) return data;
        if (data is Map) return Map<String, dynamic>.from(data);
        return {'success': true};
      }

      throw Exception(_extractMessage(data) ?? 'Failed to update service.');
    } catch (e) {
      print('❌ Error in updateService: $e');
      rethrow;
    }
  }

  // ====================== Company name =========================
  static Future<String?> fetchCompanyName() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Authentication token not found.');

      final res = await http.get(
        Uri.parse('$baseUrl/providers/my-company-name'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = _decodeJsonSafe(res.body);

      if (res.statusCode == 200 && data is Map) {
        return data['companyName'] as String?;
      } else if (res.statusCode == 404) {
        print('Company name not found (404).');
        return null;
      }

      throw Exception(_extractMessage(data) ?? 'Failed to fetch company name.');
    } catch (e) {
      print('Error fetching company name: $e');
      return null;
    }
  }

  // ====================== 5. GET service by id =========================
  static Future<Map<String, dynamic>> getServiceById(String serviceId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/services/$serviceId'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = _decodeJsonSafe(res.body);

      if (res.statusCode == 200) {
        if (data is Map<String, dynamic>) return data;
        if (data is Map) return Map<String, dynamic>.from(data);
        return {};
      }

      throw Exception(
          _extractMessage(data) ?? 'Failed to fetch service details.');
    } catch (e) {
      print('❌ Error in getServiceById: $e');
      rethrow;
    }
  }

  // ====================== ✅ Upload service image (Web + Mobile) =========================
  static Future<String> uploadServiceImage({
    String? filePath,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Authentication token not found.');

      final url = Uri.parse('$baseUrl/upload/service-image');
      final request = http.MultipartRequest('POST', url);
      request.headers.addAll({'Authorization': 'Bearer $token'});

      if (filePath != null && !kIsWeb) {
        request.files.add(await http.MultipartFile.fromPath('file', filePath));
      } else if (fileBytes != null && fileName != null) {
        request.files.add(
          http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
        );
      } else {
        throw Exception(
            'Image data is missing (requires filePath or fileBytes+fileName).');
      }

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);

      final data = _decodeJsonSafe(res.body);

      if (res.statusCode == 201 || res.statusCode == 200) {
        final urlVal = (data is Map)
            ? (data['url'] ?? data['imageUrl'] ?? data['data'])
            : null;
        if (urlVal is String && urlVal.trim().isNotEmpty) return urlVal.trim();
        throw Exception('Image upload succeeded but URL not returned.');
      }

      throw Exception(_extractMessage(data) ??
          'Failed to upload image. Status: ${res.statusCode}');
    } catch (e) {
      throw Exception('Failed to upload service image: $e');
    }
  }

  // ✅ (اختياري) إذا عندك كود قديم بينادي uploadImageFile
  static Future<String> uploadImageFile(String filePath) async {
    return uploadServiceImage(filePath: filePath);
  }

  // --------------------- helpers ---------------------
  static dynamic _decodeJsonSafe(String body) {
    try {
      final b = body.trim();
      if (b.isEmpty) return null;
      return jsonDecode(b);
    } catch (_) {
      // لو السيرفر رجّع نص مش JSON
      return {'message': body};
    }
  }

  static String? _extractMessage(dynamic data) {
    if (data == null) return null;

    // بعض السيرفرات ترجع message كـ String أو List<String>
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

  static double? _pickFirstDouble(dynamic a, dynamic b, dynamic c, dynamic d) {
    final list = [a, b, c, d];
    for (final x in list) {
      final v = _toDoubleOrNull(x);
      if (v != null) return v;
    }
    return null;
  }

  static List<Map<String, String>> _normalizeHighlights(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      final out = <Map<String, String>>[];
      for (final item in raw) {
        if (item is Map) {
          final k = (item['key'] ?? '').toString();
          final v = (item['value'] ?? '').toString();
          if (k.trim().isNotEmpty && v.trim().isNotEmpty) {
            out.add({'key': k.trim(), 'value': v.trim()});
          }
        }
      }
      return out;
    }
    return [];
  }

  static List<Map<String, dynamic>> _normalizeImages(
      dynamic cover, dynamic images) {
    final out = <Map<String, dynamic>>[];

    void addBytes(Uint8List bytes, {String name = 'cover.jpg'}) {
      if (bytes.isEmpty) return;
      out.add({'bytes': bytes.toList(), 'name': name});
    }

    if (cover is Uint8List) {
      addBytes(cover, name: 'cover.jpg');
    } else if (cover is Map) {
      final b = cover['bytes'];
      final n = (cover['name'] ?? 'cover.jpg').toString();
      if (b is Uint8List) addBytes(b, name: n);
      if (b is List<int>) out.add({'bytes': b, 'name': n});
    }

    if (images is List) {
      int i = 0;
      for (final item in images) {
        i++;
        if (item is Uint8List) {
          addBytes(item, name: 'image_$i.jpg');
        } else if (item is Map) {
          final bytes = item['bytes'];
          final name = (item['name'] ?? 'image_$i.jpg').toString();
          if (bytes is Uint8List) addBytes(bytes, name: name);
          if (bytes is List<int>) out.add({'bytes': bytes, 'name': name});
        }
      }
    }

    return out;
  }
}
