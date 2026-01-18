// lib/services/user_service/offers_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/services/auth_service.dart';

/// Model for an offer/deal service
class OfferService {
  final String id;
  final String name;
  final String company;
  final String providerId;
  final String category;
  final String description;
  final String bookingType;
  final String payType;
  final bool hasFixedLocation;
  
  // Prices
  final double originalPrice;
  final double discountedPrice;
  final int discountPercentage;
  
  // Offer details
  final DateTime? offerStartDate;
  final DateTime? offerEndDate;
  final String offerDescription;
  
  // Media
  final String imageUrl;
  final List<String> images;
  
  // Location
  final double? latitude;
  final double? longitude;
  final String city;
  
  // Reviews
  final double rating;
  final int totalReviews;
  
  // Booking constraints
  final List<String> workingDays;
  final List<int> availableHours;
  final int? minBookingHours;
  final int? maxBookingHours;
  final int? maxCapacity;
  final int cleanupTimeMinutes;

  OfferService({
    required this.id,
    required this.name,
    required this.company,
    required this.providerId,
    required this.category,
    required this.description,
    required this.bookingType,
    required this.payType,
    required this.hasFixedLocation,
    required this.originalPrice,
    required this.discountedPrice,
    required this.discountPercentage,
    this.offerStartDate,
    this.offerEndDate,
    required this.offerDescription,
    required this.imageUrl,
    required this.images,
    this.latitude,
    this.longitude,
    required this.city,
    required this.rating,
    required this.totalReviews,
    required this.workingDays,
    required this.availableHours,
    this.minBookingHours,
    this.maxBookingHours,
    this.maxCapacity,
    required this.cleanupTimeMinutes,
  });

  factory OfferService.fromJson(Map<String, dynamic> json) {
    return OfferService(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Service',
      company: json['company']?.toString() ?? 'Unknown',
      providerId: json['providerId']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      description: json['description']?.toString() ?? '',
      bookingType: json['bookingType']?.toString() ?? 'daily',
      payType: json['payType']?.toString() ?? 'per day',
      hasFixedLocation: json['hasFixedLocation'] ?? true,
      originalPrice: (json['originalPrice'] as num?)?.toDouble() ?? 0.0,
      discountedPrice: (json['discountedPrice'] as num?)?.toDouble() ?? 0.0,
      discountPercentage: (json['discountPercentage'] as num?)?.toInt() ?? 0,
      offerStartDate: json['offerStartDate'] != null 
          ? DateTime.tryParse(json['offerStartDate'].toString()) 
          : null,
      offerEndDate: json['offerEndDate'] != null 
          ? DateTime.tryParse(json['offerEndDate'].toString()) 
          : null,
      offerDescription: json['offerDescription']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      city: json['city']?.toString() ?? 'Unknown',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
      workingDays: (json['workingDays'] as List<dynamic>?)
          ?.map((e) => e.toString().toLowerCase())
          .toList() ?? [],
      availableHours: (json['availableHours'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ?? [],
      minBookingHours: (json['minBookingHours'] as num?)?.toInt(),
      maxBookingHours: (json['maxBookingHours'] as num?)?.toInt(),
      maxCapacity: (json['maxCapacity'] as num?)?.toInt(),
      cleanupTimeMinutes: (json['cleanupTimeMinutes'] as num?)?.toInt() ?? 0,
    );
  }

  /// Calculate remaining time for the offer
  Duration? get remainingTime {
    if (offerEndDate == null) return null;
    final now = DateTime.now();
    if (offerEndDate!.isBefore(now)) return Duration.zero;
    return offerEndDate!.difference(now);
  }

  /// Get formatted remaining time string
  String get remainingTimeString {
    final remaining = remainingTime;
    if (remaining == null) return '';
    if (remaining == Duration.zero) return 'Expired';
    
    if (remaining.inDays > 0) {
      return '${remaining.inDays} Day${remaining.inDays > 1 ? 's' : ''} Left';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours} Hour${remaining.inHours > 1 ? 's' : ''} Left';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes} Min Left';
    } else {
      return 'Ending Soon';
    }
  }

  /// Check if offer is still valid
  bool get isValid {
    if (offerEndDate == null) return true;
    return offerEndDate!.isAfter(DateTime.now());
  }

  /// Calculate savings amount
  double get savingsAmount => originalPrice - discountedPrice;
}

/// Service for fetching offers from the backend
class OffersRepository {
  static final String baseUrl = AuthService.baseUrl;

  /// Fetch all active offers
  Future<List<OfferService>> fetchActiveOffers() async {
    try {
      final token = await AuthService.getToken();
      
      final response = await http.get(
        Uri.parse('$baseUrl/services/offers/active'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print('📡 Offers Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ Fetched ${data.length} active offers');
        return data.map((json) => OfferService.fromJson(json)).toList();
      } else {
        print('❌ Failed to fetch offers: ${response.body}');
        throw Exception('Failed to fetch offers');
      }
    } catch (e) {
      print('❌ Error fetching offers: $e');
      rethrow;
    }
  }

  /// Fetch single offer/service details
  Future<Map<String, dynamic>> fetchOfferDetails(String serviceId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/services/$serviceId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load offer details');
      }
    } catch (e) {
      print('❌ Error fetching offer details: $e');
      rethrow;
    }
  }
}
