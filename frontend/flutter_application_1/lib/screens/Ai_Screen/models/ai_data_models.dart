// lib/screens/Ai_Screen/models/ai_data_models.dart
import 'package:flutter/material.dart';

class FormData {
  String eventType;
  int guestCount;
  RangeValues budgetRange;
  DateTime? eventDate;
  TimeOfDay? startTime; // ✅ Added
  TimeOfDay? endTime; // ✅ Added
  String city;
  List<String> vibeStyles;
  String venueType;
  List<String> selectedServices;

  FormData({
    this.eventType = 'Wedding',
    this.guestCount = 100,
    this.budgetRange = const RangeValues(10000, 50000),
    this.eventDate,
    this.startTime, // ✅ Added
    this.endTime, // ✅ Added
    this.city = '',
    this.vibeStyles = const [],
    this.venueType = 'Indoor',
    this.selectedServices = const [],
  });

  FormData copyWith({
    String? eventType,
    int? guestCount,
    RangeValues? budgetRange,
    DateTime? eventDate,
    TimeOfDay? startTime, // ✅ Added
    TimeOfDay? endTime, // ✅ Added
    String? city,
    List<String>? vibeStyles,
    String? venueType,
    List<String>? selectedServices,
  }) {
    return FormData(
      eventType: eventType ?? this.eventType,
      guestCount: guestCount ?? this.guestCount,
      budgetRange: budgetRange ?? this.budgetRange,
      eventDate: eventDate ?? this.eventDate,
      startTime: startTime ?? this.startTime, // ✅ Added
      endTime: endTime ?? this.endTime, // ✅ Added
      city: city ?? this.city,
      vibeStyles: vibeStyles ?? this.vibeStyles,
      venueType: venueType ?? this.venueType,
      selectedServices: selectedServices ?? this.selectedServices,
    );
  }
}

class PackageResult {
  final String id;
  final String name;
  final double price;
  final String description;
  final List<ServiceItem> services;
  final String packageLevel;

  PackageResult({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.services,
    required this.packageLevel,
  });

  // ✅ Factory constructor from JSON (Backend response)
  factory PackageResult.fromJson(Map<String, dynamic> json) {
    // Parse services array
    final servicesList = (json['services'] as List<dynamic>?)
        ?.map((serviceJson) => ServiceItem.fromJson(serviceJson))
        .toList() ?? [];

    // Calculate total price
    final finalPrice = (json['finalPrice'] as num?)?.toDouble() ?? 0.0;
    final targetPrice = (json['targetPrice'] as num?)?.toDouble() ?? finalPrice;

    // Determine package level based on price or name
    String packageLevel = 'Standard';
    final packageName = json['packageName'] as String? ?? '';
    if (packageName.toLowerCase().contains('budget') || 
        packageName.toLowerCase().contains('basic')) {
      packageLevel = 'Basic';
    } else if (packageName.toLowerCase().contains('premium') || 
               packageName.toLowerCase().contains('luxury')) {
      packageLevel = 'Premium';
    }

    return PackageResult(
      id: json['_id'] ?? json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: packageName,
      price: finalPrice,
      description: json['description'] as String? ?? '',
      services: servicesList,
      packageLevel: packageLevel,
    );
  }
}

class ServiceItem {
  final String category;
  final String name;
  final double price;

  ServiceItem({
    required this.category,
    required this.name,
    required this.price,
  });

  // ✅ Factory constructor from JSON (Backend service object)
  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    // Get service name
    final serviceName = json['serviceName'] as String? ?? 
                        json['name'] as String? ?? 
                        'Unknown Service';

    // Get category
    final category = json['category'] as String? ?? 'General';

    // Parse price (can be number or object)
    double servicePrice = 0.0;
    final priceData = json['price'];
    
    if (priceData is num) {
      servicePrice = priceData.toDouble();
    } else if (priceData is Map<String, dynamic>) {
      // Handle price object (perPerson, perEvent, etc)
      servicePrice = (priceData['perPerson'] as num?)?.toDouble() ??
                     (priceData['perEvent'] as num?)?.toDouble() ??
                     (priceData['perHour'] as num?)?.toDouble() ??
                     (priceData['perDay'] as num?)?.toDouble() ?? 
                     0.0;
    }

    return ServiceItem(
      category: category,
      name: serviceName,
      price: servicePrice,
    );
  }
}

// ✅ Response wrapper for API call
class AiPackageResponse {
  final bool success;
  final List<PackageResult>? packages;
  final String? error;

  AiPackageResponse({
    required this.success,
    this.packages,
    this.error,
  });
}