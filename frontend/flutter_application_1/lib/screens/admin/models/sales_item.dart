import 'package:flutter_application_1/services/auth_service.dart';

class SalesItem {
  final String id;
  final String name;
  final String? companyName;
  final String imageUrl;
  final double totalSales;
  final String type;
  final int totalBookings;
  final int canceledBookings;

  // ✅ Dynamic URL based on platform
  static String get _baseUrl => AuthService.baseUrl;

  SalesItem({
    required this.id,
    required this.name,
    this.companyName,
    required this.imageUrl,
    required this.totalSales,
    required this.type,
    this.totalBookings = 0,
    this.canceledBookings = 0,
  });

  /// Get full image URL (handles relative paths)
  String get fullImageUrl {
    if (imageUrl.isEmpty) {
      return 'https://via.placeholder.com/150';
    }
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    // Handle relative paths like /uploads/...
    if (imageUrl.startsWith('/')) {
      return '$_baseUrl$imageUrl';
    }
    return '$_baseUrl/$imageUrl';
  }

  factory SalesItem.fromJson(Map<String, dynamic> json, String itemType) {
    // Backend returns serviceName for services and packageName for packages
    String name = 'Unknown';
    if (itemType == 'service') {
      name = json['serviceName'] ?? json['name'] ?? 'Unknown Service';
    } else if (itemType == 'package') {
      name = json['packageName'] ?? json['name'] ?? 'Unknown Package';
    } else {
      name = json['name'] ?? json['serviceName'] ?? json['packageName'] ?? 'Unknown';
    }
    
    // Get the correct ID field
    String id = '';
    if (itemType == 'service') {
      id = json['serviceId'] ?? json['_id'] ?? json['id'] ?? '';
    } else if (itemType == 'package') {
      id = json['packageId'] ?? json['_id'] ?? json['id'] ?? '';
    } else {
      id = json['_id'] ?? json['id'] ?? '';
    }
    
    // Handle totalRevenue (backend) or totalSales
    final revenue = json['totalRevenue'] ?? json['totalSales'] ?? 0;
    double totalSales = 0;
    if (revenue is int) {
      totalSales = revenue.toDouble();
    } else if (revenue is double) {
      totalSales = revenue;
    }
    
    // Handle bookings count
    int totalBookings = 0;
    final bookingsVal = json['totalBookings'];
    if (bookingsVal is int) {
      totalBookings = bookingsVal;
    } else if (bookingsVal is double) {
      totalBookings = bookingsVal.toInt();
    }
    
    int canceledBookings = 0;
    final canceledVal = json['cancelledBookings'] ?? json['canceledBookings'];
    if (canceledVal is int) {
      canceledBookings = canceledVal;
    } else if (canceledVal is double) {
      canceledBookings = canceledVal.toInt();
    }
    
    // Get image URL
    String rawImageUrl = json['imageUrl'] ?? json['image'] ?? '';
    if (rawImageUrl.isEmpty && json['images'] != null && json['images'] is List && (json['images'] as List).isNotEmpty) {
      rawImageUrl = json['images'][0] ?? '';
    }
    
    print('🖼️ Raw image URL for $name: $rawImageUrl');
    
    return SalesItem(
      id: id.toString(),
      name: name,
      companyName: json['companyName'] ?? json['provider']?['companyName'],
      imageUrl: rawImageUrl,
      totalSales: totalSales,
      type: itemType,
      totalBookings: totalBookings,
      canceledBookings: canceledBookings,
    );
  }
}
