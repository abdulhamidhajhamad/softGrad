// lib/services/package_service/package_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/services/auth_service.dart';

/// 📦 Package Service Model (matches backend)
class PackageServiceItem {
  final String serviceId;
  final String serviceName;
  final String category;
  final String bookingType; // 'hourly', 'daily', 'capacity', 'mixed'
  final double originalPrice;
  final double newPrice;
  final int? maxHours;
  final int? maxCapacity;
  final bool hasFixedLocation;
  final List<String> workingDays;
  final List<int> availableHours;
  final int? minBookingHours;
  final int? maxBookingHours;

  PackageServiceItem({
    required this.serviceId,
    required this.serviceName,
    required this.category,
    required this.bookingType,
    required this.originalPrice,
    required this.newPrice,
    this.maxHours,
    this.maxCapacity,
    this.hasFixedLocation = true,
    this.workingDays = const [],
    this.availableHours = const [],
    this.minBookingHours,
    this.maxBookingHours,
  });

  factory PackageServiceItem.fromJson(Map<String, dynamic> json) {
    return PackageServiceItem(
      serviceId: json['serviceId']?.toString() ?? '',
      serviceName: json['serviceName']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      bookingType: json['bookingType']?.toString().toLowerCase() ?? 'display',
      originalPrice: (json['originalPrice'] is num) 
          ? (json['originalPrice'] as num).toDouble() 
          : 0.0,
      newPrice: (json['newPrice'] is num) 
          ? (json['newPrice'] as num).toDouble() 
          : 0.0,
      maxHours: json['maxHours'] as int?,
      maxCapacity: json['maxCapacity'] as int?,
      hasFixedLocation: json['hasFixedLocation'] ?? true,
      workingDays: (json['workingDays'] as List?)?.map((e) => e.toString().toLowerCase()).toList() ?? [],
      availableHours: (json['availableHours'] as List?)?.map((e) => (e as num).toInt()).toList() ?? [],
      minBookingHours: json['minBookingHours'] as int?,
      maxBookingHours: json['maxBookingHours'] as int?,
    );
  }
}

/// 📦 Package Model (matches backend)
class PackageModel {
  final String id;
  final String packageName;
  final String companyName;
  final String city;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> categories;
  final List<PackageServiceItem> services;
  final String? imageUrl;
  final bool isActive;

  PackageModel({
    required this.id,
    required this.packageName,
    required this.companyName,
    required this.city,
    required this.startDate,
    required this.endDate,
    required this.categories,
    required this.services,
    this.imageUrl,
    required this.isActive,
  });

  double get totalOriginal => services.fold(0.0, (sum, s) => sum + s.originalPrice);
  double get totalPackage => services.fold(0.0, (sum, s) => sum + s.newPrice);
  
  double get discountPercent {
    if (totalOriginal <= 0) return 0;
    return (((totalOriginal - totalPackage) / totalOriginal) * 100).clamp(0, 100);
  }

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      packageName: json['packageName']?.toString() ?? '',
      companyName: json['companyName']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      startDate: DateTime.parse(json['startDate']?.toString() ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['endDate']?.toString() ?? DateTime.now().toIso8601String()),
      categories: (json['categories'] as List?)?.map((e) => e.toString()).toList() ?? [],
      services: (json['services'] as List?)
          ?.map((s) => PackageServiceItem.fromJson(s))
          .toList() ?? [],
      imageUrl: json['imageUrl']?.toString(),
      isActive: json['isActive'] == true,
    );
  }
}

/// 📦 Package Service - API Handler
class PackageService {
  static final String baseUrl = AuthService.baseUrl;

  /// 🔹 Fetch All Active Packages
  static Future<List<PackageModel>> getActivePackages() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Please login first');
      }

      print('📦 Fetching active packages...');
      
      final response = await http.get(
        Uri.parse('$baseUrl/packages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Packages response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final packages = data
            .map((json) => PackageModel.fromJson(json))
            .where((p) => p.isActive)
            .toList();
        
        print('✅ Loaded ${packages.length} active packages');
        return packages;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to load packages');
      }
    } catch (e) {
      print('❌ Error fetching packages: $e');
      rethrow;
    }
  }

  /// 🔹 Fetch Single Package by ID
  static Future<PackageModel> getPackageById(String packageId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Please login first');
      }

      print('📦 Fetching package: $packageId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/packages/$packageId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Package response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PackageModel.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to load package');
      }
    } catch (e) {
      print('❌ Error fetching package: $e');
      rethrow;
    }
  }
}