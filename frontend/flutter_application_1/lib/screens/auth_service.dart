import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://192.168.110.14:3000';

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('🔐 Status Code: ${response.statusCode}');
      print('🔐 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Login failed');
      }
    } catch (e) {
      print('❌ Login Error: $e');
      throw Exception('Network error: $e');
    }
  }

  // ✅ دالة لاختبار الاتصال
  static Future<void> testConnection() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.110.14:3000'));
      print('✅ Server connection test: ${response.statusCode}');
    } catch (e) {
      print('❌ Server connection failed: $e');
    }
  }
}