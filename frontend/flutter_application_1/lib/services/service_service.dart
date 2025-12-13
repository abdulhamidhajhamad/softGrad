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
      // ✅ Android Emulator يستخدم 10.0.2.2 للوصول لـ localhost على الجهاز
      return 'http://10.0.2.2:3000';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS Simulator يستخدم localhost عادي
      return 'http://localhost:3000';
    } else {
      // Desktop / Other
      return 'http://localhost:3000';
    }
  }

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
        if (data is List) {
          // ✅ نورمالايز البيانات لتتوافق مع UI
          return data.map((service) => _normalizeServiceFromBackend(service)).toList();
        }
        if (data is Map && data['data'] is List) {
          return (data['data'] as List)
              .map((service) => _normalizeServiceFromBackend(service))
              .toList();
        }
        return [];
      }

      throw Exception(_extractMessage(data) ?? 'Failed to fetch services.');
    } catch (e) {
      print('❌ Error in fetchMyServices: $e');
      rethrow;
    }
  }

  // ✅ نورمالايز البيانات من Backend لتتوافق مع UI
  static Map<String, dynamic> _normalizeServiceFromBackend(dynamic service) {
    if (service is! Map) return {};

    final Map<String, dynamic> normalized = {};

    // _id → serviceId
    normalized['_id'] = (service['_id'] ?? '').toString();
    normalized['serviceId'] = (service['_id'] ?? '').toString();

    // serviceName → name
    normalized['serviceName'] = (service['serviceName'] ?? '').toString();
    normalized['name'] = (service['serviceName'] ?? '').toString();

    // category
    normalized['category'] = (service['category'] ?? '').toString();

    // ✅ معالجة price (قد يكون object أو number)
    final priceData = service['price'];
    double finalPrice = 0.0;

    if (priceData is num) {
      finalPrice = priceData.toDouble();
    } else if (priceData is Map) {
      // PricingOptions object
      finalPrice = _pickFirstDouble(
            priceData['perHour'],
            priceData['perDay'],
            priceData['perPerson'],
            priceData['fullVenue'],
            priceData['basePrice'],
          ) ??
          0.0;
    } else if (priceData is String) {
      finalPrice = double.tryParse(priceData) ?? 0.0;
    }

    normalized['price'] = finalPrice;

    // discount
    normalized['discount'] = (service['discount'] ?? '').toString();

    // ✅ images - أول صورة من المصفوفة
    final images = service['images'];
    if (images is List && images.isNotEmpty) {
      normalized['images'] = List<String>.from(images.map((img) => img.toString()));
      normalized['image'] = images.first.toString(); // أول صورة
    } else {
      normalized['images'] = <String>[];
      normalized['image'] = '';
    }

    // isActive
    normalized['isActive'] = service['isActive'] ?? true;

    // location
    final location = service['location'];
    if (location is Map) {
      normalized['address'] = (location['address'] ?? '').toString();
      normalized['city'] = (location['city'] ?? '').toString();
      normalized['latitude'] = location['latitude'];
      normalized['longitude'] = location['longitude'];
    }

    // additionalInfo
    final additionalInfo = service['additionalInfo'];
    if (additionalInfo is Map) {
      normalized['additionalInfo'] = additionalInfo;
      normalized['fullDescription'] = (additionalInfo['description'] ?? '').toString();
      normalized['shortDescription'] = (additionalInfo['description'] ?? '').toString();
    } else {
      normalized['additionalInfo'] = {};
      normalized['fullDescription'] = '';
      normalized['shortDescription'] = '';
    }

    // bookingType
    normalized['bookingType'] = (service['bookingType'] ?? '').toString();

    // externalLink
    normalized['externalLink'] = (service['externalLink'] ?? '').toString();

    // payType
    normalized['payType'] = (service['payType'] ?? '').toString();

    // rating
    normalized['rating'] = service['rating'] ?? 0.0;

    // createdAt, updatedAt
    normalized['createdAt'] = (service['createdAt'] ?? '').toString();
    normalized['updatedAt'] = (service['updatedAt'] ?? '').toString();

    // bookings, likes (stats - افتراضي 0 إذا مش موجودين)
    normalized['bookings'] = service['bookings'] ?? 0;
    normalized['likes'] = service['likes'] ?? 0;

    return normalized;
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

      // ✅ تحديد bookingType بناءً على category
      final String bookingType = _mapCategoryToBookingType(category);

      // ✅ additionalInfo
      final Map<String, dynamic> additionalInfo = {
        'description': description,
      };

      final createServiceDtoForJson = {
        'serviceName': title,
        'category': category,
        'location': locationData,
        'price': {'basePrice': price}, // PricingOptions object
        'bookingType': bookingType,
        'payType': priceType,
        'additionalInfo': additionalInfo,
        'isActive': true,
      };

      request.fields['data'] = jsonEncode(createServiceDtoForJson);

      // ✅ رفع الصور
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

  // ✅ helper: map category إلى bookingType
  static String _mapCategoryToBookingType(String category) {
    switch (category) {
      case 'Venues':
      case 'Photographers':
      case 'Music & Entertainment':
      case 'Wedding Planners & Coordinators':
        return 'Hourly';

      case 'Decor & Lighting':
      case 'Car Rental & Transportation':
        return 'Full-Day';

      case 'Catering':
      case 'Cake':
        return 'Capacity';

      case 'Flower Shops':
      case 'Card Printing':
      case 'Jewelry & Accessories':
      case 'Gift & Souvenir':
        return 'Order';

      default:
        return 'Hourly';
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
        priceType = 'per hour';
      } else if (pricingModel == 'per_day' ||
          bookingType.toLowerCase().contains('full')) {
        priceType = 'per event';
      } else if (pricingModel.contains('capacity')) {
        final unit = (form['capacityUnit'] ?? '').toString();
        priceType = unit == 'piece' ? 'per_piece' : 'per person';
      } else if (pricingModel == 'per_item' ||
          bookingType.toLowerCase().contains('order')) {
        priceType = 'per_item';
      } else {
        priceType = 'per event';
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

  // ====================== 4. UPDATE service (multipart) =========================
  static Future<Map<String, dynamic>> updateService(
    String serviceId,
    Map<String, dynamic> updateData, {
    List<Map<String, dynamic>>? newImages,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Authentication token not found.');

      // ✅ إذا في صور جديدة، استخدم multipart
      if (newImages != null && newImages.isNotEmpty) {
        final url = Uri.parse('$baseUrl/services/id/$serviceId');
        final request = http.MultipartRequest('PUT', url);

        request.headers.addAll({'Authorization': 'Bearer $token'});

        // بيانات التحديث
        request.fields['data'] = jsonEncode(updateData);

        // رفع الصور الجديدة
        for (final fileData in newImages) {
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

        if (res.statusCode == 200) {
          if (data is Map<String, dynamic>) return data;
          if (data is Map) return Map<String, dynamic>.from(data);
          return {'success': true};
        }

        throw Exception(_extractMessage(data) ?? 'Failed to update service.');
      } else {
        // ✅ تحديث بدون صور - استخدم PATCH
        final res = await http.patch(
          Uri.parse('$baseUrl/services/id/$serviceId'),
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
      }
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
        Uri.parse('$baseUrl/services/id/$serviceId'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = _decodeJsonSafe(res.body);

      if (res.statusCode == 200) {
        if (data is Map<String, dynamic>) {
          return _normalizeServiceFromBackend(data);
        }
        if (data is Map) {
          return _normalizeServiceFromBackend(Map<String, dynamic>.from(data));
        }
        return {};
      }

      throw Exception(
          _extractMessage(data) ?? 'Failed to fetch service details.');
    } catch (e) {
      print('❌ Error in getServiceById: $e');
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

  static double? _pickFirstDouble(dynamic a, dynamic b, dynamic c, dynamic d,
      [dynamic e]) {
    final list = [a, b, c, d, e];
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