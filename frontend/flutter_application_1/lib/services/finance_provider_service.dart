// lib/services/finance_provider_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/services/auth_service.dart';

/// 📊 Model for Service Sales data
class ServiceSalesData {
  final String serviceId;
  final String serviceName;
  final double revenue;
  final int bookings;
  final double percentage;

  ServiceSalesData({
    required this.serviceId,
    required this.serviceName,
    required this.revenue,
    required this.bookings,
    required this.percentage,
  });

  factory ServiceSalesData.fromJson(Map<String, dynamic> json) {
    return ServiceSalesData(
      serviceId: json['serviceId']?.toString() ?? '',
      serviceName: json['serviceName'] ?? 'Unknown Service',
      revenue: (json['revenue'] ?? 0).toDouble(),
      bookings: json['bookings'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

/// 📅 Model for Monthly Trend data
class MonthlyTrendData {
  final String month;
  final int year;
  final double revenue;
  final int bookings;

  MonthlyTrendData({
    required this.month,
    required this.year,
    required this.revenue,
    required this.bookings,
  });

  factory MonthlyTrendData.fromJson(Map<String, dynamic> json) {
    return MonthlyTrendData(
      month: json['month'] ?? '',
      year: json['year'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
      bookings: json['bookings'] ?? 0,
    );
  }
}

/// 📈 Model for Finance Summary
class FinanceSummary {
  final double totalRevenue;
  final int totalBookings;
  final double cancelledAmount;
  final int cancelledCount;
  final double currentMonthRevenue;
  final int currentMonthBookings;
  final double lastMonthRevenue;
  final double yearToDateRevenue;
  final int yearToDateBookings;
  final double growthRate;

  FinanceSummary({
    required this.totalRevenue,
    required this.totalBookings,
    required this.cancelledAmount,
    required this.cancelledCount,
    required this.currentMonthRevenue,
    required this.currentMonthBookings,
    required this.lastMonthRevenue,
    required this.yearToDateRevenue,
    required this.yearToDateBookings,
    required this.growthRate,
  });

  factory FinanceSummary.fromJson(Map<String, dynamic> json) {
    return FinanceSummary(
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      totalBookings: json['totalBookings'] ?? 0,
      cancelledAmount: (json['cancelledAmount'] ?? 0).toDouble(),
      cancelledCount: json['cancelledCount'] ?? 0,
      currentMonthRevenue: (json['currentMonthRevenue'] ?? 0).toDouble(),
      currentMonthBookings: json['currentMonthBookings'] ?? 0,
      lastMonthRevenue: (json['lastMonthRevenue'] ?? 0).toDouble(),
      yearToDateRevenue: (json['yearToDateRevenue'] ?? 0).toDouble(),
      yearToDateBookings: json['yearToDateBookings'] ?? 0,
      growthRate: (json['growthRate'] ?? 0).toDouble(),
    );
  }
}

/// 📊 Model for Recent Booking
class RecentBooking {
  final String serviceName;
  final double price;
  final String status;
  final DateTime createdAt;
  final DateTime? bookingDate;

  RecentBooking({
    required this.serviceName,
    required this.price,
    required this.status,
    required this.createdAt,
    this.bookingDate,
  });

  factory RecentBooking.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return RecentBooking(
      serviceName: json['serviceName'] ?? 'Unknown',
      price: (json['price'] ?? 0).toDouble(),
      status: json['status'] ?? 'unknown',
      createdAt: parseDate(json['createdAt']) ?? DateTime.now(),
      bookingDate: parseDate(json['bookingDetails']?['date']),
    );
  }
}

/// 📊 Complete Finance Data Model
class FinanceData {
  final FinanceSummary summary;
  final List<ServiceSalesData> servicesSales;
  final List<MonthlyTrendData> monthlyTrend;
  final Map<String, dynamic> statusDistribution;
  final List<RecentBooking> recentBookings;

  FinanceData({
    required this.summary,
    required this.servicesSales,
    required this.monthlyTrend,
    required this.statusDistribution,
    required this.recentBookings,
  });

  factory FinanceData.fromJson(Map<String, dynamic> json) {
    return FinanceData(
      summary: FinanceSummary.fromJson(json['summary'] ?? {}),
      servicesSales: (json['servicesSales'] as List<dynamic>?)
              ?.map((e) => ServiceSalesData.fromJson(e))
              .toList() ??
          [],
      monthlyTrend: (json['monthlyTrend'] as List<dynamic>?)
              ?.map((e) => MonthlyTrendData.fromJson(e))
              .toList() ??
          [],
      statusDistribution:
          Map<String, dynamic>.from(json['statusDistribution'] ?? {}),
      recentBookings: (json['recentBookings'] as List<dynamic>?)
              ?.map((e) => RecentBooking.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// 💰 Finance Provider Service
class FinanceProviderService {
  static String get baseUrl => AuthService.baseUrl; // ✅ Dynamic URL
  // static const String baseUrl = 'http://localhost:3000'; // للـ iOS Simulator

  /// 📊 جلب الإحصائيات المالية الشاملة للـ Provider
  static Future<FinanceData> fetchFinanceStats() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/bookings/vendor/finance'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📊 Finance stats response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ Finance data fetched successfully');
        return FinanceData.fromJson(data);
      } else {
        debugPrint('❌ Failed to fetch finance stats: ${response.body}');
        throw Exception('Failed to load finance stats: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching finance stats: $e');
      rethrow;
    }
  }

  /// 📈 جلب إحصائيات المبيعات البسيطة
  static Future<Map<String, dynamic>> fetchSalesStats() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/bookings/vendor/stats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📈 Sales stats response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ Sales stats fetched successfully');
        return Map<String, dynamic>.from(data);
      } else {
        debugPrint('❌ Failed to fetch sales stats: ${response.body}');
        throw Exception('Failed to load sales stats: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching sales stats: $e');
      rethrow;
    }
  }
}
