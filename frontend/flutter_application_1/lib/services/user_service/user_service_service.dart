//API Handle
// lib/services/user_service_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/services/auth_service.dart';

class UserServiceService {
  static final String baseUrl = AuthService.baseUrl;

  // ====================== GET HOME SERVICES =========================
  
  static Future<Map<String, dynamic>> getHomeServices() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      print('📡 Fetching home services...');
      
      final response = await http.get(
        Uri.parse('$baseUrl/services/home-service'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Home services fetched successfully');
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to fetch home services');
      }
    } catch (e) {
      print('❌ Error fetching home services: $e');
      rethrow;
    }
  }

  // ====================== GET SERVICE DETAILS =========================
  
  static Future<Map<String, dynamic>> getServiceDetails(String serviceId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      print('📡 Fetching service details for ID: $serviceId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/services/$serviceId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Service details fetched successfully');
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to fetch service details');
      }
    } catch (e) {
      print('❌ Error fetching service details: $e');
      rethrow;
    }
  }

  // ====================== ADD/REMOVE SERVICE FROM FAVORITES =========================
  
  static Future<Map<String, dynamic>> toggleServiceFavorite(String serviceId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      print('📡 Toggling favorite for service ID: $serviceId');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/favorites/service/$serviceId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Service favorite toggled successfully');
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to toggle service favorite');
      }
    } catch (e) {
      print('❌ Error toggling service favorite: $e');
      rethrow;
    }
  }

  // ====================== GET USER FAVORITES =========================
  
  static Future<Map<String, dynamic>> getUserFavorites() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      print('📡 Fetching user favorites...');
      
      final response = await http.get(
        Uri.parse('$baseUrl/auth/favorites'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ User favorites fetched successfully');
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to fetch user favorites');
      }
    } catch (e) {
      print('❌ Error fetching user favorites: $e');
      rethrow;
    }
  }
}