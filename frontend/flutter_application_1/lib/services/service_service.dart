// lib/services/service_service.dart

import 'dart:convert';
// import 'dart:io'; // ❌ تم حذفه لإصلاح مشكلة الـ Web
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/services/auth_service.dart'; 
import 'package:image_picker/image_picker.dart'; // ⭐️ إضافة لاستخدام XFile

/// Model class for a single Service entity.
class ServiceModel {
  final String id;
  final String name; 
  final String description; 
  final double price;
  final String category;
  final bool isActive;
  final int reviewsCount;
  final double rating;
  final String? imageUrl;  

  ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.isActive,
    required this.reviewsCount,
    required this.rating,
    this.imageUrl,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    final additionalInfo = json['additionalInfo'] as Map<String, dynamic>?;
    final description = additionalInfo?['description'] ?? ''; 
    
    final List<dynamic> images = json['images'] ?? []; 
    final String? firstImageUrl = images.isNotEmpty ? images.first as String? : null;

    final reviews = json['reviews'] as List<dynamic>?;
    final reviewsCount = reviews?.length ?? 0;

    return ServiceModel(
      id: json['_id'] ?? '',
      name: json['serviceName'] ?? 'No Name',
      description: description,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] ?? 'General',
      isActive: json['isActive'] ?? true,
      reviewsCount: reviewsCount, 
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      imageUrl: firstImageUrl, 
    );
  }
}

/// Service class for making API calls related to provider services.
class ServiceService {
  static final String baseUrl = AuthService.getBaseUrl();
  static const String _myServicesEndpoint = '/services/my-services';
  
  // ---------------------------- دالة إضافة خدمة (Multipart)
  // ⭐️ تم تحديث التوقيع لقبول List<XFile>
  static Future<void> addService(
      Map<String, dynamic> serviceData, List<XFile> imageFiles) async { // ⬅️ List<XFile>
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Authentication token missing. Please log in again.');
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/services'),
    );

    request.headers.addAll({
      'Authorization': 'Bearer $token',
    });

    request.fields['data'] = jsonEncode(serviceData);
    
    // 4. إضافة ملفات الصور
    for (XFile file in imageFiles) { 
      // ⭐️ قراءة البايتات بدلاً من المسار (مهم للويب)
      final bytes = await file.readAsBytes();
      final filename = file.name; 

      request.files.add(
        http.MultipartFile.fromBytes(
          'images', 
          bytes,
          filename: filename,
        ),
      );
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📝 Add Service Status Code: ${response.statusCode}');
      print('📝 Add Service Response Body: ${response.body}');

      if (response.statusCode == 201) {
        print('✅ Service added successfully');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to add service');
      }
    } catch (e) {
      print('❌ Add Service Error: $e');
      throw Exception('Network error while adding service: $e');
    }
  }

  // ---------------------------- دالة جلب الخدمات
  static Future<List<ServiceModel>> fetchMyServices() async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Authentication token missing. Please log in again.');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl$_myServicesEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', 
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> servicesJson = jsonDecode(response.body);
        return servicesJson
            .map((json) => ServiceModel.fromJson(json))
            .toList();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load services');
      }
    } catch (e) {
      throw Exception('Network error while fetching services: $e');
    }
  }

  // ... (يمكنك إضافة باقي الدوال هنا)
}