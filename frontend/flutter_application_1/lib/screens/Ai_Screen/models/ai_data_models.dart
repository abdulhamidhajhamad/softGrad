// lib/screens/Ai_Screen/models/ai_data_models.dart
import 'package:flutter/material.dart';
class FormData {
  String eventType;
  int guestCount;
  RangeValues budgetRange;
  DateTime? eventDate;
  String city;
  List<String> vibeStyles;
  String venueType;
  List<String> selectedServices;
  String customDetails;

  FormData({
    this.eventType = 'Wedding',
    this.guestCount = 100,
    this.budgetRange = const RangeValues(10000, 50000),
    this.eventDate,
    this.city = '',
    this.vibeStyles = const [],
    this.venueType = 'Indoor',
    this.selectedServices = const [],
    this.customDetails = '',
  });

  FormData copyWith({
    String? eventType,
    int? guestCount,
    RangeValues? budgetRange,
    DateTime? eventDate,
    String? city,
    List<String>? vibeStyles,
    String? venueType,
    List<String>? selectedServices,
    String? customDetails,
  }) {
    return FormData(
      eventType: eventType ?? this.eventType,
      guestCount: guestCount ?? this.guestCount,
      budgetRange: budgetRange ?? this.budgetRange,
      eventDate: eventDate ?? this.eventDate,
      city: city ?? this.city,
      vibeStyles: vibeStyles ?? this.vibeStyles,
      venueType: venueType ?? this.venueType,
      selectedServices: selectedServices ?? this.selectedServices,
      customDetails: customDetails ?? this.customDetails,
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
}

