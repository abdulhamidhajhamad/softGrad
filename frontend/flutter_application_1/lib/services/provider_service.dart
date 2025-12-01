// lib/services/provider_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProviderService {
  static const String baseUrl = 'http://localhost:3000'; // أو IP الخادم
  
  // جلب token من localStorage
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // جلب جميع الـ services من الداتابيز
  Future<List<dynamic>> getMyServices() async {
    final token = await _getToken();
    
    final response = await http.get(
      Uri.parse('$baseUrl/providers'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load services');
    }
  }

  // إنشاء service جديد
  Future<dynamic> createService(Map<String, dynamic> serviceData) async {
    final token = await _getToken();
    
    final response = await http.post(
      Uri.parse('$baseUrl/providers'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(serviceData),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create service');
    }
  }

  // تحديث service
  Future<dynamic> updateService(String companyName, Map<String, dynamic> updates) async {
    final token = await _getToken();
    
    final response = await http.patch(
      Uri.parse('$baseUrl/providers/$companyName'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(updates),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update service');
    }
  }

  // حذف service
  Future<void> deleteService(String companyName) async {
    final token = await _getToken();
    
    final response = await http.delete(
      Uri.parse('$baseUrl/providers/$companyName'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete service');
    }
  }
}