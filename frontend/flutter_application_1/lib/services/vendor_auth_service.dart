import 'dart:convert';
import 'package:http/http.dart' as http;

class VendorAuthService {
  static const String baseUrl = 'http://localhost:3000';

  static Future<Map<String, dynamic>> signup({
    required String userName,
    required String email,
    required String password,
    required String phone,
    required String city,
    required String category,
    required String description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userName': userName,
          'email': email,
          'password': password,
          'phone': phone,
          'city': city,
          'role': 'vendor',
          'category': category,
          'description': description,
        }),
      );

      print('🏪 Vendor Signup Status: ${response.statusCode}');
      print('🏪 Vendor Response: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Vendor signup failed');
      }
    } catch (e) {
      print('❌ Vendor Signup Error: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<void> testConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl'));
      print('✅ Vendor Server connection test: ${response.statusCode}');
    } catch (e) {
      print('❌ Vendor Server connection failed: $e');
    }
  }
}
