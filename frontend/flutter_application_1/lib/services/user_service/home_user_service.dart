// lib/services/user_service/home_user_service.dart
// API handlers for homepage data (packages and trending services)

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/services/auth_service.dart';

/// Model for homepage package deals
class HomePackageModel {
  final String id;
  final String title;
  final String company;
  final String imageUrl;
  final double price;
  final double originalPrice;
  final String validity;
  final List<String> services;

  HomePackageModel({
    required this.id,
    required this.title,
    required this.company,
    required this.imageUrl,
    required this.price,
    required this.originalPrice,
    required this.validity,
    required this.services,
  });

  factory HomePackageModel.fromJson(Map<String, dynamic> json) {
    return HomePackageModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Unknown Package',
      company: json['company']?.toString() ?? 'Unknown',
      imageUrl: json['imageUrl']?.toString() ?? '',
      price: _parseDouble(json['price']),
      originalPrice: _parseDouble(json['originalPrice']),
      validity: json['validity']?.toString() ?? '',
      services: (json['services'] as List<dynamic>?)
              ?.map((s) => s.toString())
              .toList() ??
          [],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

/// Model for homepage trending services
class HomeTrendingModel {
  final String id;
  final String name;
  final String company;
  final String providerId;
  final String category;
  final String desc;
  final double price;
  final double rating;
  final String imageUrl;
  final double? latitude;
  final double? longitude;

  HomeTrendingModel({
    required this.id,
    required this.name,
    required this.company,
    required this.providerId,
    required this.category,
    required this.desc,
    required this.price,
    required this.rating,
    required this.imageUrl,
    this.latitude,
    this.longitude,
  });

  factory HomeTrendingModel.fromJson(Map<String, dynamic> json) {
    return HomeTrendingModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Service',
      company: json['company']?.toString() ?? 'Unknown',
      providerId: json['providerId']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      desc: json['desc']?.toString() ?? '',
      price: _parseDouble(json['price']),
      rating: _parseDouble(json['rating']),
      imageUrl: json['imageUrl']?.toString() ?? '',
      latitude: json['latitude'] != null ? _parseDouble(json['latitude']) : null,
      longitude: json['longitude'] != null ? _parseDouble(json['longitude']) : null,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

/// Response model for homepage data
class HomeDataResponse {
  final List<HomePackageModel> packages;
  final List<HomeTrendingModel> trending;

  HomeDataResponse({
    required this.packages,
    required this.trending,
  });
}

/// Model for browse/search services
class BrowseServiceModel {
  final String id;
  final String serviceName;
  final String providerName;
  final String providerEmail;
  final String providerPhone;
  final String imageUrl;
  final String city;
  final String category;
  final double price;
  final double? oldPrice;
  final String description;

  BrowseServiceModel({
    required this.id,
    required this.serviceName,
    required this.providerName,
    required this.providerEmail,
    required this.providerPhone,
    required this.imageUrl,
    required this.city,
    required this.category,
    required this.price,
    this.oldPrice,
    required this.description,
  });

  factory BrowseServiceModel.fromJson(Map<String, dynamic> json) {
    return BrowseServiceModel(
      id: json['id']?.toString() ?? '',
      serviceName: json['serviceName']?.toString() ?? 'Unknown Service',
      providerName: json['providerName']?.toString() ?? 'Unknown',
      providerEmail: json['providerEmail']?.toString() ?? '',
      providerPhone: json['providerPhone']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      city: json['city']?.toString() ?? 'Unknown',
      category: json['category']?.toString() ?? 'General',
      price: _parseDouble(json['price']),
      oldPrice: json['oldPrice'] != null ? _parseDouble(json['oldPrice']) : null,
      description: json['description']?.toString() ?? '',
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  bool get hasDiscount => oldPrice != null && oldPrice! > 0 && oldPrice! > price;

  int get discountPercent {
    if (!hasDiscount) return 0;
    final p = ((oldPrice! - price) / oldPrice!) * 100;
    return p.round().clamp(1, 95);
  }
}

/// Service class for homepage API calls
class HomeUserService {
  static final String baseUrl = AuthService.baseUrl;

  /// Get random packages for homepage (5 packages)
  static Future<List<HomePackageModel>> getHomePackages() async {
    try {
      print('📡 Fetching home packages...');

      final response = await http.get(
        Uri.parse('$baseUrl/packages/home/random'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('📥 Packages Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Handle empty response
        if (response.body.isEmpty || response.body.trim().isEmpty) {
          print('⚠️ Empty packages response');
          return [];
        }

        final List<dynamic> data = json.decode(response.body);
        final packages =
            data.map((item) => HomePackageModel.fromJson(item)).toList();
        print('✅ Loaded ${packages.length} packages');
        return packages;
      } else {
        print('❌ Failed to load packages: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching home packages: $e');
      return [];
    }
  }

  /// Get random trending services for homepage (5 services)
  static Future<List<HomeTrendingModel>> getHomeTrendingServices() async {
    try {
      print('📡 Fetching trending services...');

      final response = await http.get(
        Uri.parse('$baseUrl/services/home/trending'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('📥 Trending Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Handle empty response
        if (response.body.isEmpty || response.body.trim().isEmpty) {
          print('⚠️ Empty trending response');
          return [];
        }

        final List<dynamic> data = json.decode(response.body);
        final services =
            data.map((item) => HomeTrendingModel.fromJson(item)).toList();
        print('✅ Loaded ${services.length} trending services');
        return services;
      } else {
        print('❌ Failed to load trending: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching trending services: $e');
      return [];
    }
  }

  /// Get all homepage data (packages + trending) in parallel
  static Future<HomeDataResponse> getHomeData() async {
    try {
      print('📡 Fetching all home data...');

      // Fetch both in parallel
      final results = await Future.wait([
        getHomePackages(),
        getHomeTrendingServices(),
      ]);

      final packages = results[0] as List<HomePackageModel>;
      final trending = results[1] as List<HomeTrendingModel>;

      print('✅ Home data loaded: ${packages.length} packages, ${trending.length} services');

      return HomeDataResponse(
        packages: packages,
        trending: trending,
      );
    } catch (e) {
      print('❌ Error fetching home data: $e');
      return HomeDataResponse(packages: [], trending: []);
    }
  }

  /// Get all services for browse/search display (Public endpoint)
  static Future<List<BrowseServiceModel>> getAllServicesForBrowse() async {
    try {
      print('📡 Fetching all services for browse...');

      final response = await http.get(
        Uri.parse('$baseUrl/services/browse/all'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('📥 Browse Services Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Handle empty response
        if (response.body.isEmpty || response.body.trim().isEmpty) {
          print('⚠️ Empty browse services response');
          return [];
        }

        final List<dynamic> data = json.decode(response.body);
        final services =
            data.map((item) => BrowseServiceModel.fromJson(item)).toList();
        print('✅ Loaded ${services.length} services for browse');
        return services;
      } else {
        print('❌ Failed to load browse services: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching browse services: $e');
      return [];
    }
  }
}