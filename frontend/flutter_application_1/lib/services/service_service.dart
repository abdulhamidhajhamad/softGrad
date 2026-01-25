// lib/services/service_service.dart

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:flutter_application_1/services/auth_service.dart';

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

class ServiceService {
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String getBaseUrl() {
    if (_envBaseUrl.trim().isNotEmpty) return _envBaseUrl.trim();
    return 'https://softgrad.onrender.com';
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

  // ✅ Normalize service data from backend
  static Map<String, dynamic> _normalizeServiceFromBackend(dynamic service) {
    if (service is! Map) return {};

    final Map<String, dynamic> normalized = {};

    // IDs
    normalized['_id'] = (service['_id'] ?? '').toString();
    normalized['serviceId'] = (service['_id'] ?? '').toString();

    // Basic info
    normalized['serviceName'] = (service['serviceName'] ?? '').toString();
    normalized['name'] = (service['serviceName'] ?? '').toString();
    normalized['category'] = (service['category'] ?? '').toString();
    
    // ✅ Booking Type
    normalized['bookingType'] = (service['bookingType'] ?? '').toString();
    
    // ✅ Description (direct field)
    normalized['description'] = (service['description'] ?? '').toString();

    // ✅ NEW: Simple price (single number, optional for display)
    final priceData = service['price'];
    if (priceData is num) {
      normalized['price'] = priceData.toDouble();
    } else {
      normalized['price'] = 0.0; // For display services
    }

    // Discount
    normalized['discount'] = (service['discount'] ?? '').toString();

    // Images
    final images = service['images'];
    if (images is List && images.isNotEmpty) {
      normalized['images'] = List<String>.from(images.map((img) => img.toString()));
      normalized['image'] = images.first.toString();
    } else {
      normalized['images'] = <String>[];
      normalized['image'] = '';
    }

    // Status
    normalized['isActive'] = service['isActive'] ?? true;
    
    // ✅ hasFixedLocation
    normalized['hasFixedLocation'] = service['hasFixedLocation'] ?? true;

    // Location
    final location = service['location'];
    if (location is Map) {
      normalized['address'] = (location['address'] ?? '').toString();
      normalized['city'] = (location['city'] ?? '').toString();
      normalized['latitude'] = location['latitude'];
      normalized['longitude'] = location['longitude'];
    }

    // Additional info
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

    // ✅ NEW: Pay type (per hour, per person, per day, display)
    normalized['payType'] = (service['payType'] ?? '').toString();

    // ✅ NEW: Optional fields
    if (service['maxCapacity'] != null) {
      normalized['maxCapacity'] = service['maxCapacity'];
    }
    if (service['minBookingHours'] != null) {
      normalized['minBookingHours'] = service['minBookingHours'];
    }
    if (service['maxBookingHours'] != null) {
      normalized['maxBookingHours'] = service['maxBookingHours'];
    }
    if (service['availableHours'] != null) {
      normalized['availableHours'] = service['availableHours'];
    }
    if (service['cleanupTimeMinutes'] != null) {
      normalized['cleanupTimeMinutes'] = service['cleanupTimeMinutes'];
    }
    if (service['workingDays'] != null) {
      normalized['workingDays'] = service['workingDays'];
    }
    
    // ✅ NEW: timeSlots & venueType
    if (service['timeSlots'] != null) {
      normalized['timeSlots'] = service['timeSlots'];
    }
    
    normalized['venueType'] = (service['venueType'] ?? '').toString();
    if (normalized['venueType'] == '' && service['additionalInfo'] != null) {
      normalized['venueType'] = (service['additionalInfo']['venueType'] ?? '').toString();
    }

    // External link
    normalized['externalLink'] = (service['externalLink'] ?? '').toString();

    // Rating
    normalized['rating'] = service['rating'] ?? 0.0;

    // Timestamps
    normalized['createdAt'] = (service['createdAt'] ?? '').toString();
    normalized['updatedAt'] = (service['updatedAt'] ?? '').toString();

    // Stats
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
  required String bookingType,
  double? latitude,
  double? longitude,
  String? address,
  String? city,
  required String companyName,
  int? maxCapacity,
  int? minBookingHours,
  int? maxBookingHours,
  List<int>? availableHours,
  int? cleanupTimeMinutes,
  List<String>? workingDays,
  String? venueType,
  bool hasFixedLocation = true, // 🆕 إضافة hasFixedLocation parameter
  List<Map<String, String>>? timeSlots, // ✅ NEW: Time slots for hourly bookings
}) async {
  try {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Authentication token not found.');

    final url = Uri.parse('$baseUrl/services');
    final request = http.MultipartRequest('POST', url);

    request.headers.addAll({'Authorization': 'Bearer $token'});

    // 🆕 الموقع يُرسل فقط إذا كانت الخدمة لها موقع ثابت
    final Map<String, dynamic>? locationData = hasFixedLocation ? {
      'latitude': latitude ?? 0.0,
      'longitude': longitude ?? 0.0,
      'address': address ?? '',
      'city': city ?? '',
    } : null;

    final Map<String, dynamic> additionalInfo = {
      'description': description,
    };

    // 🆕 إضافة venueType في additionalInfo للقاعات
    if (venueType != null && category == 'Venues') {
      additionalInfo['venueType'] = venueType;
    }

    // 🆕 إضافة maxCapacity في additionalInfo للقاعات
    if (maxCapacity != null && category == 'Venues') {
      additionalInfo['maxCapacity'] = maxCapacity;
    }

    // ✅ إضافة highlights (key-value pairs) في additionalInfo
    if (highlights.isNotEmpty) {
      for (final item in highlights) {
        final key = item['key']?.trim();
        final value = item['value']?.trim();
        if (key != null && key.isNotEmpty && value != null && value.isNotEmpty) {
          additionalInfo[key] = value;
        }
      }
    }

    final createServiceDtoForJson = <String, dynamic>{
      'serviceName': title,
      'category': category,
      'price': price,
      'payType': priceType,
      'bookingType': bookingType,
      'additionalInfo': additionalInfo,
      'isActive': true,
      'hasFixedLocation': hasFixedLocation, // 🆕
      'venueType': venueType, //  NEW: Top-level field for proper schema persistence
    };

    // 🆕 إضافة الموقع فقط إذا كانت الخدمة لها موقع ثابت
    if (locationData != null) {
      createServiceDtoForJson['location'] = locationData;
    }

    // Add optional fields only if provided
    if (maxCapacity != null) {
      createServiceDtoForJson['maxCapacity'] = maxCapacity;
    }
    if (minBookingHours != null) {
      createServiceDtoForJson['minBookingHours'] = minBookingHours;
    }
    if (maxBookingHours != null) {
      createServiceDtoForJson['maxBookingHours'] = maxBookingHours;
    }
    if (availableHours != null && availableHours.isNotEmpty) {
      createServiceDtoForJson['availableHours'] = availableHours;
    }
    if (cleanupTimeMinutes != null) {
      createServiceDtoForJson['cleanupTimeMinutes'] = cleanupTimeMinutes;
    }
    if (workingDays != null && workingDays.isNotEmpty) {
      createServiceDtoForJson['workingDays'] = workingDays;
    }
    // ✅ NEW: Add timeSlots if provided
    if (timeSlots != null && timeSlots.isNotEmpty) {
      createServiceDtoForJson['timeSlots'] = timeSlots;
    }

    request.fields['data'] = jsonEncode(createServiceDtoForJson);

    // Upload images
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

  // ====================== ✅ Unified method for ALL Add screens =========================
  static Future<Map<String, dynamic>> addServiceFromBookingForm(
    Map<String, dynamic> form) async {
  final String category = (form['category'] ?? '').toString();
  final String title = (form['name'] ?? form['serviceName'] ?? '').toString();
  final String description = (form['description'] ?? '').toString();
  final String bookingTypeRaw = (form['bookingType'] ?? 'daily').toString().toLowerCase();
  
  // ✅ Extract price
  final double price = _pickFirstDouble(
        form['price'],
        form['pricePerUnit'],
        form['finalPrice'],
        form['finalPricePerUnit'],
      ) ??
      0.0;

  // ✅ Determine payType based on form data
  String priceType = (form['priceType'] ?? '').toString().trim();
  if (priceType.isEmpty) {
    final String bookingType = (form['bookingType'] ?? '').toString().toLowerCase();
    final String pricingModel = (form['pricingModel'] ?? '').toString();

    if (pricingModel == 'per_hour' || bookingType.contains('hour')) {
      priceType = 'per hour';
    } else if (pricingModel == 'per_day' || bookingType.contains('day') || bookingType.contains('full')) {
      priceType = 'per day';
    } else if (pricingModel.contains('capacity') || pricingModel == 'per_person' || bookingType.contains('capacity')) {
      final unit = (form['capacityUnit'] ?? '').toString();
      priceType = unit == 'piece' ? 'per piece' : 'per person';
    } else if (pricingModel == 'per_piece') {
      priceType = 'per piece'; // 🆕 دعم per piece مباشرة
    } else if (pricingModel == 'per_item' || bookingType.contains('order') || bookingType.contains('display')) {
      priceType = 'display';
    } else {
      priceType = 'per hour'; // default
    }
  }

  final String address = (form['address'] ?? '').toString();
  final String city = (form['city'] ?? '').toString();

  final double? latitude = _toDoubleOrNull(form['latitude']);
  final double? longitude = _toDoubleOrNull(form['longitude']);

  // 🆕 استخراج hasFixedLocation
  final bool hasFixedLocation = form['hasFixedLocation'] ?? true;

  final highlights = _normalizeHighlights(form['highlights']);
  // ✅ Fix: Also check for mediaItems (new multi-media format)
  final imageFilesData = _normalizeImages(form['coverImage'], form['images'], form['mediaItems']);

  String companyName = (form['companyName'] ?? '').toString().trim();
  if (companyName.isEmpty) {
    companyName = (await fetchCompanyName()) ?? '';
  }

  // ✅ Validation
  if (category.isEmpty) throw Exception('Category is required.');
  if (title.trim().isEmpty) throw Exception('Service name is required.');
  if (description.trim().isEmpty) throw Exception('Description is required.');
  
  // 🆕 التحقق من الموقع فقط إذا كانت الخدمة لها موقع ثابت
  if (hasFixedLocation) {
    if (address.trim().isEmpty) throw Exception('Address is required.');
    if (city.trim().isEmpty) throw Exception('City is required.');
  }
  
  if (priceType != 'display' && price <= 0) {
    throw Exception('Price must be > 0.');
  }

  // ✅ Extract optional fields
  int? maxCapacity;
  int? minBookingHours;
  int? maxBookingHours;
  List<int>? availableHours;
  int? cleanupTimeMinutes;
  List<String>? workingDays;

  if (form['maxCapacity'] != null) {
    maxCapacity = int.tryParse(form['maxCapacity'].toString());
  }
  if (form['minHours'] != null) {
    minBookingHours = int.tryParse(form['minHours'].toString());
  }
  if (form['maxHours'] != null) {
    maxBookingHours = int.tryParse(form['maxHours'].toString());
  }
  if (form['breakMinutes'] != null) {
    cleanupTimeMinutes = int.tryParse(form['breakMinutes'].toString());
  }
  
  // Working days
  if (form['days'] is List) {
    workingDays = (form['days'] as List)
        .map((day) => day.toString().toLowerCase())
        .toList();
  }

  // 🆕 استخراج venueType من الـ form
  String? venueType;
  if (category == 'Venues' && form['venueType'] != null) {
    venueType = form['venueType'].toString().toLowerCase();
  }

  // ✅ NEW: Extract timeSlots from form
  List<Map<String, String>>? timeSlots;
  if (form['slotsPreview'] is List) {
    timeSlots = (form['slotsPreview'] as List)
        .map((slot) => {
              'startTime': slot['start'].toString(),
              'endTime': slot['end'].toString(),
            })
        .cast<Map<String, String>>()
        .toList();
  }

  return addService(
    title: title.trim(),
    description: description.trim(),
    price: price,
    highlights: highlights,
    imageFilesData: imageFilesData,
    category: category,
    priceType: priceType,
    bookingType: bookingTypeRaw, 
    latitude: hasFixedLocation ? latitude : null, // 🆕
    longitude: hasFixedLocation ? longitude : null, // 🆕
    address: hasFixedLocation ? address.trim() : null, // 🆕
    city: hasFixedLocation ? city.trim() : null, // 🆕
    companyName: companyName,
    maxCapacity: maxCapacity,
    minBookingHours: minBookingHours,
    maxBookingHours: maxBookingHours,
    availableHours: availableHours,
    cleanupTimeMinutes: cleanupTimeMinutes,
    workingDays: workingDays,
    venueType: venueType,
    timeSlots: timeSlots, //  NEW
    hasFixedLocation: hasFixedLocation, // 🆕
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

      if (newImages != null && newImages.isNotEmpty) {
        final url = Uri.parse('$baseUrl/services/id/$serviceId');
        final request = http.MultipartRequest('PUT', url);

        request.headers.addAll({'Authorization': 'Bearer $token'});
        request.fields['data'] = jsonEncode(updateData);

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
        // ✅ استخدام PUT بدلاً من PATCH مع multipart/form-data
        final url = Uri.parse('$baseUrl/services/id/$serviceId');
        final request = http.MultipartRequest('PUT', url);

        request.headers.addAll({'Authorization': 'Bearer $token'});
        request.fields['data'] = jsonEncode(updateData);

        final streamed = await request.send();
        final res = await http.Response.fromStream(streamed);

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
      dynamic cover, dynamic images, dynamic mediaItems) {
    final out = <Map<String, dynamic>>[];

    void addBytes(Uint8List bytes, {String name = 'cover.jpg', bool isVideo = false}) {
      if (bytes.isEmpty) return;
      // ✅ Determine extension based on video flag
      String finalName = name;
      if (isVideo && !name.toLowerCase().endsWith('.mp4') && !name.toLowerCase().endsWith('.mov')) {
        finalName = name.replaceAll(RegExp(r'\.[^.]+$'), '.mp4');
        if (finalName == name) finalName = '$name.mp4';
      }
      out.add({'bytes': bytes.toList(), 'name': finalName});
    }

    // ✅ Priority 1: Process mediaItems (new multi-media format from add service screens)
    if (mediaItems is List && mediaItems.isNotEmpty) {
      int i = 0;
      for (final item in mediaItems) {
        i++;
        if (item is Map) {
          final bytesRaw = item['bytes'];
          final isVideo = item['isVideo'] == true;
          final fileName = (item['fileName'] ?? (isVideo ? 'video_$i.mp4' : 'image_$i.jpg')).toString();
          
          Uint8List? bytes;
          if (bytesRaw is Uint8List) {
            bytes = bytesRaw;
          } else if (bytesRaw is List<int>) {
            bytes = Uint8List.fromList(bytesRaw);
          }
          
          if (bytes != null && bytes.isNotEmpty) {
            addBytes(bytes, name: fileName, isVideo: isVideo);
          }
        }
      }
      // If we got media from mediaItems, return early
      if (out.isNotEmpty) return out;
    }

    // ✅ Priority 2: Process cover image (backwards compatibility)
    if (cover is Uint8List) {
      addBytes(cover, name: 'cover.jpg');
    } else if (cover is Map) {
      final b = cover['bytes'];
      final n = (cover['name'] ?? 'cover.jpg').toString();
      if (b is Uint8List) addBytes(b, name: n);
      if (b is List<int>) out.add({'bytes': b, 'name': n});
    }

    // ✅ Priority 3: Process images list (backwards compatibility)
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
