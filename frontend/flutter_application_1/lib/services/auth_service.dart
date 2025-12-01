import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://192.168.110.22:3000';


  static Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      print('✅ Token saved successfully: $token');
    } catch (e) {
      print('❌ Error saving token: $e');
    }
  }

  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      print('🔑 Retrieved token: $token');
      return token;
    } catch (e) {
      print('❌ Error getting token: $e');
      return null;
    }
  }

  
  static Future<void> deleteToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      print('✅ Token deleted successfully');
    } catch (e) {
      print('❌ Error deleting token: $e');
    }
  }

 
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

 
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
        final responseData = jsonDecode(response.body);
        
        // حفظ التوكن تلقائياً عند التسجيل الدخول
        if (responseData.containsKey('token')) {
          await saveToken(responseData['token']);
        }
        
        return responseData;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Login failed');
      }
    } catch (e) {
      print('❌ Login Error: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<void> testConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl'));
      print('✅ Server connection test: ${response.statusCode}');
    } catch (e) {
      print('❌ Server connection failed: $e');
    }
  }

static Future<Map<String, dynamic>> getUserProfile() async {
  try {
    final token = await getToken();
    
    if (token == null) {
      throw Exception('No token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/auth/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
    );

    print('👤 Profile Status Code: ${response.statusCode}');
    print('👤 Profile Response: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user profile');
    }
  } catch (e) {
    print('❌ Profile Error: $e');
    throw Exception('Network error: $e');
  }
}
}