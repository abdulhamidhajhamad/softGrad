// lib/services/package_service/add_to_cart_packages.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/payment_service/cart_service.dart';

/// 📦 Service Booking Details for Package
/// ✅ Matches backend structure EXACTLY (no isFullVenue for packages)
class PackageServiceBooking {
  final String serviceId;
  final BookingDetailsForPackage bookingDetails;

  PackageServiceBooking({
    required this.serviceId,
    required this.bookingDetails,
  });

  Map<String, dynamic> toJson() {
    return {
      'serviceId': serviceId,
      'bookingDetails': bookingDetails.toJson(),
    };
  }
}

/// 📅 Booking Details (matches backend DTO)
/// ✅ Backend expects: date, startHour?, endHour?, numberOfPeople?, clientLocation?, bookingDescription?
class BookingDetailsForPackage {
  final String date;
  final int? startHour;
  final int? endHour;
  final int? numberOfPeople;
  final Map<String, dynamic>? clientLocation;
  final String? bookingDescription;

  BookingDetailsForPackage({
    required this.date,
    this.startHour,
    this.endHour,
    this.numberOfPeople,
    this.clientLocation,
    this.bookingDescription,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'date': date,
    };
    
    // Only include fields if they have values
    if (startHour != null) json['startHour'] = startHour;
    if (endHour != null) json['endHour'] = endHour;
    if (numberOfPeople != null) json['numberOfPeople'] = numberOfPeople;
    if (clientLocation != null) json['clientLocation'] = clientLocation;
    if (bookingDescription != null && bookingDescription!.trim().isNotEmpty) {
      json['bookingDescription'] = bookingDescription;
    }
    
    return json;
  }
}

/// 📦 Add Package to Cart DTO
class AddPackageToCartDto {
  final String packageId;
  final List<PackageServiceBooking> serviceBookings;

  AddPackageToCartDto({
    required this.packageId,
    required this.serviceBookings,
  });

  Map<String, dynamic> toJson() {
    return {
      'packageId': packageId,
      'serviceBookings': serviceBookings.map((s) => s.toJson()).toList(),
    };
  }
}

/// 🛒 Package Cart Service
class PackageCartService {
  static final String baseUrl = AuthService.baseUrl;

  /// ✅ Add Package to Cart
  static Future<CartResponse> addPackageToCart(AddPackageToCartDto dto) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Please login first');
      }

      print('🛒 Adding package to cart...');
      print('📦 Package ID: ${dto.packageId}');
      print('📝 Services: ${dto.serviceBookings.length}');

      final response = await http.post(
        Uri.parse('$baseUrl/cart/add-package'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(dto.toJson()),
      );

      print('📥 Add package response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('✅ Package added to cart successfully');
        return CartResponse.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to add package to cart');
      }
    } catch (e) {
      print('❌ Error adding package to cart: $e');
      rethrow;
    }
  }

  /// 📋 Validate Package Booking (Client-side)
  static String? validateServiceBooking({
    required String bookingType,
    required DateTime date,
    int? startHour,
    int? endHour,
    int? numberOfPeople,
    bool? isFullVenue,
    int? maxHours,
    int? maxCapacity,
    bool hasFixedLocation = true,
    String? clientCity,
    String? clientAddress,
    String? locationDescription,
  }) {
    // 1. Check date is not in the past
    final today = DateTime.now();
    final dateOnly = DateTime(date.year, date.month, date.day);
    final todayOnly = DateTime(today.year, today.month, today.day);
    
    if (dateOnly.isBefore(todayOnly)) {
      return 'Booking date cannot be in the past';
    }

    // 2. Validate based on booking type
    switch (bookingType.toLowerCase()) {
      case 'hourly':
        if (startHour == null || endHour == null) {
          return 'Please select start and end hours';
        }
        if (startHour >= endHour) {
          return 'End hour must be after start hour';
        }
        final hours = endHour - startHour;
        if (hours <= 0) {
          return 'Booking duration must be at least 1 hour';
        }
        if (maxHours != null && hours > maxHours) {
          return 'Maximum $maxHours hours allowed for this package';
        }
        break;

      case 'capacity':
        if (numberOfPeople == null || numberOfPeople <= 0) {
          return 'Please specify number of people';
        }
        if (maxCapacity != null && numberOfPeople > maxCapacity) {
          return 'Maximum $maxCapacity people allowed for this package';
        }
        break;

      case 'mixed':
        if (isFullVenue == true) {
          // Full venue booking - no additional validation
          break;
        }
        if (numberOfPeople == null || numberOfPeople <= 0) {
          return 'Please specify number of people';
        }
        if (maxCapacity != null && numberOfPeople > maxCapacity) {
          return 'Maximum $maxCapacity people allowed for this package';
        }
        break;

      case 'daily':
        // Date already validated above
        break;

      default:
        // Display or other types - no specific validation
        break;
    }

    // ✅ Validate location for services without fixed location
    if (!hasFixedLocation) {
      if (clientCity == null || clientCity.isEmpty) {
        return 'Please select your city';
      }
      // Address is required now
      if (clientAddress == null || clientAddress.trim().isEmpty) {
        return 'Please enter your address';
      }
    }

    return null; // ✅ Valid
  }
}