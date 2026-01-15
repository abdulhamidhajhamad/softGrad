// lib/screens/Ai_Screen/models/ai_data_models.dart
import 'package:flutter/material.dart';

/// Safely convert any value to double (handles String, num, null)
double _safeToDouble(dynamic value, [double fallback = 0.0]) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

/// Search mode - Single Service or Full Package
enum SearchMode {
  singleService,
  fullPackage,
}

/// Event types available for selection
class EventType {
  final String name;
  final String nameAr;
  final IconData icon;
  final Color color;

  const EventType({
    required this.name,
    required this.nameAr,
    required this.icon,
    required this.color,
  });

  static const List<EventType> allTypes = [
    EventType(name: 'Wedding', nameAr: 'حفل زفاف', icon: Icons.favorite, color: Color(0xFFE91E63)),
    EventType(name: 'Engagement', nameAr: 'خطوبة', icon: Icons.card_giftcard, color: Color(0xFF9C27B0)),
    EventType(name: 'Birthday', nameAr: 'عيد ميلاد', icon: Icons.cake, color: Color(0xFFFF9800)),
    EventType(name: 'Anniversary', nameAr: 'ذكرى سنوية', icon: Icons.celebration, color: Color(0xFF4CAF50)),
    EventType(name: 'Baby Shower', nameAr: 'استقبال مولود', icon: Icons.child_care, color: Color(0xFF03A9F4)),
    EventType(name: 'Graduation', nameAr: 'حفل تخرج', icon: Icons.school, color: Color(0xFF3F51B5)),
    EventType(name: 'Corporate Event', nameAr: 'فعالية شركات', icon: Icons.business_center, color: Color(0xFF607D8B)),
    EventType(name: 'Conference', nameAr: 'مؤتمر', icon: Icons.groups, color: Color(0xFF795548)),
    EventType(name: 'Henna Night', nameAr: 'ليلة الحناء', icon: Icons.spa, color: Color(0xFFFF5722)),
    EventType(name: 'Religious Event', nameAr: 'مناسبة دينية', icon: Icons.mosque, color: Color(0xFF009688)),
    EventType(name: 'Other', nameAr: 'أخرى', icon: Icons.more_horiz, color: Color(0xFF9E9E9E)),
  ];
}

/// Service categories available
class ServiceCategory {
  final String name;
  final String nameAr;
  final IconData icon;
  final Color color;

  const ServiceCategory({
    required this.name,
    required this.nameAr,
    required this.icon,
    required this.color,
  });

  static const List<ServiceCategory> allServices = [
    ServiceCategory(name: 'Venue', nameAr: 'قاعة', icon: Icons.apartment_rounded, color: Color(0xFF1414D7)),
    ServiceCategory(name: 'Photography', nameAr: 'تصوير', icon: Icons.camera_alt_rounded, color: Color(0xFFE91E63)),
    ServiceCategory(name: 'Videography', nameAr: 'فيديو', icon: Icons.videocam_rounded, color: Color(0xFF9C27B0)),
    ServiceCategory(name: 'Catering', nameAr: 'طعام', icon: Icons.restaurant_menu_rounded, color: Color(0xFFFF9800)),
    ServiceCategory(name: 'Cake', nameAr: 'كيك', icon: Icons.cake_rounded, color: Color(0xFFF44336)),
    ServiceCategory(name: 'Decoration', nameAr: 'ديكور', icon: Icons.auto_fix_high_rounded, color: Color(0xFF4CAF50)),
    ServiceCategory(name: 'Flowers', nameAr: 'ورود', icon: Icons.local_florist_rounded, color: Color(0xFFE91E63)),
    ServiceCategory(name: 'Music & DJ', nameAr: 'موسيقى ودي جي', icon: Icons.music_note_rounded, color: Color(0xFF3F51B5)),
    ServiceCategory(name: 'Entertainment', nameAr: 'ترفيه', icon: Icons.theater_comedy_rounded, color: Color(0xFF00BCD4)),
    ServiceCategory(name: 'Wedding Planner', nameAr: 'منظم حفلات', icon: Icons.event_note_rounded, color: Color(0xFF795548)),
    ServiceCategory(name: 'Makeup & Hair', nameAr: 'مكياج وتصفيف', icon: Icons.face_retouching_natural_rounded, color: Color(0xFFFF4081)),
    ServiceCategory(name: 'Transportation', nameAr: 'مواصلات', icon: Icons.directions_car_rounded, color: Color(0xFF607D8B)),
    ServiceCategory(name: 'Invitation Cards', nameAr: 'بطاقات دعوة', icon: Icons.mail_rounded, color: Color(0xFF009688)),
    ServiceCategory(name: 'Jewelry', nameAr: 'مجوهرات', icon: Icons.diamond_rounded, color: Color(0xFFFFD700)),
    ServiceCategory(name: 'Lighting', nameAr: 'إضاءة', icon: Icons.lightbulb_rounded, color: Color(0xFFFFC107)),
    ServiceCategory(name: 'Sound System', nameAr: 'نظام صوت', icon: Icons.speaker_rounded, color: Color(0xFF673AB7)),
    ServiceCategory(name: 'Other', nameAr: 'أخرى', icon: Icons.more_horiz_rounded, color: Color(0xFF9E9E9E)),
  ];
}

/// Cities in Palestine
class CityData {
  static const List<String> palestinianCities = [
    'Ramallah',
    'Jerusalem',
    'Nablus',
    'Hebron',
    'Bethlehem',
    'Jenin',
    'Tulkarm',
    'Qalqilya',
    'Jericho',
    'Gaza',
    'Rafah',
    'Khan Yunis',
    'Deir al-Balah',
    'Salfit',
    'Tubas',
  ];
}

/// Selected service with priority and budget percentage
class SelectedService {
  final String name;
  final int priority;
  final String? customName;
  final int budgetPercent;  // نسبة الميزانية المخصصة لهذه الخدمة (1-100)

  SelectedService({
    required this.name,
    required this.priority,
    this.customName,
    this.budgetPercent = 0,  // 0 يعني يحدد تلقائياً من الـ AI
  });

  SelectedService copyWith({
    String? name,
    int? priority,
    String? customName,
    int? budgetPercent,
  }) {
    return SelectedService(
      name: name ?? this.name,
      priority: priority ?? this.priority,
      customName: customName ?? this.customName,
      budgetPercent: budgetPercent ?? this.budgetPercent,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'name': customName ?? name,
    'priority': priority,
    'budgetPercent': budgetPercent,
  };
}

/// Package generation preference
enum PackagePreference {
  withinBudget,
  withOptions,
}

/// Variation type for budget flexibility
enum VariationType {
  lower,    // أقل من الميزانية
  higher,   // أعلى من الميزانية
  both,     // كلاهما
}

/// Main form data model
class FormData {
  String eventType;
  String? customEventType;
  int guestCount;
  RangeValues budgetRange;
  DateTime? eventDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  String city;
  String venueType;
  List<SelectedService> selectedServices;
  String notes;
  PackagePreference packagePreference;
  List<String> vibeStyles;
  String customDetails;
  // Budget flexibility fields (same as single service)
  bool hasBudgetFlexibility;
  int budgetFlexibilityPercent;
  VariationType budgetFlexibilityType;
  // Legacy fields for budget variations (kept for compatibility)
  int extraPackagesCount;     // عدد الباقات الإضافية
  int variationPercentage;    // النسبة المئوية للتغيير
  VariationType variationType; // نوع التغيير

  FormData({
    this.eventType = 'Wedding',
    this.customEventType,
    this.guestCount = 100,
    this.budgetRange = const RangeValues(10000, 50000),
    this.eventDate,
    this.startTime,
    this.endTime,
    this.city = '',
    this.venueType = 'Indoor',
    this.selectedServices = const [],
    this.notes = '',
    this.packagePreference = PackagePreference.withinBudget,
    this.vibeStyles = const [],
    this.customDetails = '',
    this.hasBudgetFlexibility = false,
    this.budgetFlexibilityPercent = 10,
    this.budgetFlexibilityType = VariationType.both,
    this.extraPackagesCount = 2,
    this.variationPercentage = 15,
    this.variationType = VariationType.both,
  });

  FormData copyWith({
    String? eventType,
    String? customEventType,
    int? guestCount,
    RangeValues? budgetRange,
    DateTime? eventDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? city,
    String? venueType,
    List<SelectedService>? selectedServices,
    String? notes,
    PackagePreference? packagePreference,
    List<String>? vibeStyles,
    String? customDetails,
    bool? hasBudgetFlexibility,
    int? budgetFlexibilityPercent,
    VariationType? budgetFlexibilityType,
    int? extraPackagesCount,
    int? variationPercentage,
    VariationType? variationType,
  }) {
    return FormData(
      eventType: eventType ?? this.eventType,
      customEventType: customEventType ?? this.customEventType,
      guestCount: guestCount ?? this.guestCount,
      budgetRange: budgetRange ?? this.budgetRange,
      eventDate: eventDate ?? this.eventDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      city: city ?? this.city,
      venueType: venueType ?? this.venueType,
      selectedServices: selectedServices ?? this.selectedServices,
      notes: notes ?? this.notes,
      packagePreference: packagePreference ?? this.packagePreference,
      vibeStyles: vibeStyles ?? this.vibeStyles,
      customDetails: customDetails ?? this.customDetails,
      hasBudgetFlexibility: hasBudgetFlexibility ?? this.hasBudgetFlexibility,
      budgetFlexibilityPercent: budgetFlexibilityPercent ?? this.budgetFlexibilityPercent,
      budgetFlexibilityType: budgetFlexibilityType ?? this.budgetFlexibilityType,
      extraPackagesCount: extraPackagesCount ?? this.extraPackagesCount,
      variationPercentage: variationPercentage ?? this.variationPercentage,
      variationType: variationType ?? this.variationType,
    );
  }

  List<String> get serviceNames => selectedServices
      .map((s) => s.customName ?? s.name)
      .toList();
}

class PackageResult {
  final String id;
  final String name;
  final double price;
  final String description;
  final List<ServiceItem> services;
  final String packageLevel;
  final double? originalBudgetMin;
  final double? originalBudgetMax;

  PackageResult({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.services,
    required this.packageLevel,
    this.originalBudgetMin,
    this.originalBudgetMax,
  });

  factory PackageResult.fromJson(Map<String, dynamic> json) {
    final servicesList = (json['services'] as List<dynamic>?)
        ?.map((serviceJson) => ServiceItem.fromJson(serviceJson))
        .toList() ?? [];

    final finalPrice = _safeToDouble(json['finalPrice']);

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
  final String id;  // Service ID لإضافتها للسلة
  final String category;
  final String name;
  final double price;
  final String? priceType;  // per person, per event, per hour
  final String? providerName;
  final String? providerId;
  final double? rating;
  final int? reviewCount;
  final String? imageUrl;
  final String? description;
  final Map<String, dynamic>? bookingType;

  ServiceItem({
    required this.id,
    required this.category,
    required this.name,
    required this.price,
    this.priceType,
    this.providerName,
    this.providerId,
    this.rating,
    this.reviewCount,
    this.imageUrl,
    this.description,
    this.bookingType,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    final serviceName = json['serviceName'] as String? ?? 
                        json['name'] as String? ?? 
                        'Unknown Service';

    final category = json['category'] as String? ?? 'General';
    final serviceId = json['_id'] as String? ?? json['id'] as String? ?? '';

    double servicePrice = 0.0;
    String? priceType;
    final priceData = json['price'];
    
    if (priceData is num) {
      servicePrice = priceData.toDouble();
    } else if (priceData is String) {
      servicePrice = double.tryParse(priceData) ?? 0.0;
    } else if (priceData is Map<String, dynamic>) {
      if (priceData['perPerson'] != null) {
        servicePrice = _safeToDouble(priceData['perPerson']);
        priceType = 'per person';
      } else if (priceData['perEvent'] != null) {
        servicePrice = _safeToDouble(priceData['perEvent']);
        priceType = 'per event';
      } else if (priceData['perHour'] != null) {
        servicePrice = _safeToDouble(priceData['perHour']);
        priceType = 'per hour';
      } else if (priceData['perDay'] != null) {
        servicePrice = _safeToDouble(priceData['perDay']);
        priceType = 'per day';
      }
    }

    return ServiceItem(
      id: serviceId,
      category: category,
      name: serviceName,
      price: servicePrice,
      priceType: priceType ?? json['payType'] as String?,
      providerName: json['providerName'] as String? ?? json['companyName'] as String? ?? 'Provider',
      providerId: json['providerId']?.toString(),
      rating: _safeToDouble(json['averageRating']) > 0 
          ? _safeToDouble(json['averageRating']) 
          : _safeToDouble(json['rating']),
      reviewCount: json['totalReviews'] as int? ?? json['reviewCount'] as int?,
      imageUrl: json['imageUrl'] ?? json['image'] ?? (json['images'] is List && (json['images'] as List).isNotEmpty ? json['images'][0] : null),
      description: json['description'] as String?,
      bookingType: json['bookingType'] as Map<String, dynamic>?,
    );
  }
}

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

/// Single Service Search Data
class SingleServiceData {
  String serviceType;
  String? customServiceType;
  String city;
  DateTime? eventDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  int guestCount;
  double minBudget;
  double maxBudget;
  String eventType;
  String? customEventType;
  String venueType;
  String notes;
  // Budget flexibility options
  bool hasBudgetFlexibility;    // هل يريد مرونة في الميزانية
  int budgetFlexibilityPercent; // نسبة المرونة (0-50%)
  VariationType budgetFlexibilityType; // نوع المرونة (أقل/أعلى/كلاهما)

  SingleServiceData({
    this.serviceType = '',
    this.customServiceType,
    this.city = '',
    this.eventDate,
    this.startTime,
    this.endTime,
    this.guestCount = 100,
    this.minBudget = 0,
    this.maxBudget = 50000,
    this.eventType = 'Wedding',
    this.customEventType,
    this.venueType = 'Indoor',
    this.notes = '',
    this.hasBudgetFlexibility = false,
    this.budgetFlexibilityPercent = 10,
    this.budgetFlexibilityType = VariationType.both,
  });

  SingleServiceData copyWith({
    String? serviceType,
    String? customServiceType,
    String? city,
    DateTime? eventDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    int? guestCount,
    double? minBudget,
    double? maxBudget,
    String? eventType,
    String? customEventType,
    String? venueType,
    String? notes,
    bool? hasBudgetFlexibility,
    int? budgetFlexibilityPercent,
    VariationType? budgetFlexibilityType,
  }) {
    return SingleServiceData(
      serviceType: serviceType ?? this.serviceType,
      customServiceType: customServiceType ?? this.customServiceType,
      city: city ?? this.city,
      eventDate: eventDate ?? this.eventDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      guestCount: guestCount ?? this.guestCount,
      minBudget: minBudget ?? this.minBudget,
      maxBudget: maxBudget ?? this.maxBudget,
      eventType: eventType ?? this.eventType,
      customEventType: customEventType ?? this.customEventType,
      venueType: venueType ?? this.venueType,
      notes: notes ?? this.notes,
      hasBudgetFlexibility: hasBudgetFlexibility ?? this.hasBudgetFlexibility,
      budgetFlexibilityPercent: budgetFlexibilityPercent ?? this.budgetFlexibilityPercent,
      budgetFlexibilityType: budgetFlexibilityType ?? this.budgetFlexibilityType,
    );
  }

  bool get isValid {
    return serviceType.isNotEmpty && 
           city.isNotEmpty && 
           eventDate != null;
  }
}

/// Single Service Search Response
class SingleServiceResponse {
  final bool success;
  final List<ServiceSearchResult>? results;
  final String? error;

  SingleServiceResponse({
    required this.success,
    this.results,
    this.error,
  });
}

/// Single Service Search Result
class ServiceSearchResult {
  final String id;
  final String serviceName;
  final String providerName;
  final String providerId;
  final String category;
  final double price;           // السعر الأساسي
  final double calculatedPrice; // السعر المحسوب (للوقت/الأشخاص)
  final String? payType;        // per hour, per person, per day, etc.
  final double? rating;
  final int? reviewCount;
  final String? imageUrl;
  final String? description;
  final bool isAvailable;
  final String? city;
  final String? bookingType;
  final Map<String, dynamic>? additionalInfo;

  ServiceSearchResult({
    required this.id,
    required this.serviceName,
    required this.providerName,
    required this.providerId,
    required this.category,
    required this.price,
    this.calculatedPrice = 0,
    this.payType,
    this.rating,
    this.reviewCount,
    this.imageUrl,
    this.description,
    this.isAvailable = true,
    this.city,
    this.bookingType,
    this.additionalInfo,
  });

  /// Get display price based on pay type
  String get priceLabel {
    switch (payType?.toLowerCase()) {
      case 'perhour':
      case 'per hour':
        return 'per hour';
      case 'perperson':
      case 'per person':
        return 'per person';
      case 'perday':
      case 'per day':
        return 'per day';
      case 'display':
        return 'display only';
      default:
        return 'per event';
    }
  }

  factory ServiceSearchResult.fromJson(Map<String, dynamic> json) {
    double servicePrice = 0.0;
    String? payType;
    final priceData = json['price'];
    
    if (priceData is num) {
      servicePrice = priceData.toDouble();
    } else if (priceData is String) {
      servicePrice = double.tryParse(priceData) ?? 0.0;
    } else if (priceData is Map<String, dynamic>) {
      if (priceData['perPerson'] != null) {
        servicePrice = _safeToDouble(priceData['perPerson']);
        payType = 'per person';
      } else if (priceData['perEvent'] != null) {
        servicePrice = _safeToDouble(priceData['perEvent']);
        payType = 'per event';
      } else if (priceData['perHour'] != null) {
        servicePrice = _safeToDouble(priceData['perHour']);
        payType = 'per hour';
      } else if (priceData['perDay'] != null) {
        servicePrice = _safeToDouble(priceData['perDay']);
        payType = 'per day';
      }
    }

    // Get payType from dedicated field if not parsed from price
    payType = payType ?? json['payType'] as String?;

    // Get calculated price if available
    final calcPrice = _safeToDouble(json['calculatedPrice'], servicePrice);

    // Get city from location
    String? city;
    if (json['location'] is Map) {
      city = json['location']['city'] as String?;
    }

    return ServiceSearchResult(
      id: json['_id'] ?? json['id'] ?? '',
      serviceName: json['serviceName'] ?? json['name'] ?? 'Unknown Service',
      providerName: json['providerName'] ?? json['companyName'] ?? 'Provider',
      providerId: json['providerId'] ?? '',
      category: json['category'] ?? 'General',
      price: servicePrice,
      calculatedPrice: calcPrice,
      payType: payType,
      rating: _safeToDouble(json['averageRating']) > 0 
          ? _safeToDouble(json['averageRating']) 
          : _safeToDouble(json['rating']),
      reviewCount: json['totalReviews'] as int? ?? json['reviewCount'] as int?,
      imageUrl: json['imageUrl'] ?? json['image'] ?? (json['images'] is List && (json['images'] as List).isNotEmpty ? json['images'][0] : null),
      description: json['description'],
      isAvailable: json['isAvailable'] ?? true,
      city: city,
      bookingType: json['bookingType'] as String?,
      additionalInfo: json['additionalInfo'] as Map<String, dynamic>?,
    );
  }
}