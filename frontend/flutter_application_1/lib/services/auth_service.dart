// lib/services/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  
  // Base URL configuration
  static String getBaseUrl() {
    return 'https://softgrad.onrender.com';
  }

  static final String baseUrl = getBaseUrl();

  // ====================== TOKEN MANAGEMENT =========================

  /// Save authentication token
  static Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      print('🔐 Token saved');
    } catch (e) {
      print('❌ Error saving token: $e');
    }
  }

  /// Get stored token
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      print('🔑 Retrieved token: ${token != null ? "Found" : "Not found"}');
      return token;
    } catch (e) {
      print('❌ Error getting token: $e');
      return null;
    }
  }

  /// Delete token
  static Future<void> deleteToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      print('🗑️ Token deleted successfully');
    } catch (e) {
      print('❌ Error deleting token: $e');
    }
  }

  // ====================== USER DATA MANAGEMENT =========================

  /// Save user data
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userDataKey, json.encode(userData));
      print('💾 User data saved: $userData');
      print('💾 User ID: ${userData['_id'] ?? userData['id']}');
    } catch (e) {
      print('❌ Error saving user data: $e');
    }
  }

  /// Get stored user data
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString(_userDataKey);
      
      if (userString == null) {
        print('❌ No user data found in storage');
        return null;
      }
      
      final userData = json.decode(userString) as Map<String, dynamic>;
      print('✅ Retrieved user data: $userData');
      print('✅ User ID: ${userData['_id'] ?? userData['id']}');
      return userData;
    } catch (e) {
      print('❌ Error getting user data: $e');
      return null;
    }
  }

  /// Clear all auth data
  static Future<void> clearAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userDataKey);
      print('🚪 Auth data cleared');
    } catch (e) {
      print('❌ Error clearing auth: $e');
    }
  }

  // ====================== USER ROLE =========================

  /// Get user role from stored user data
  static Future<String?> getUserRole() async {
    try {
      final userData = await getUserData();
      if (userData == null) {
        print('⚠️ No user data found, cannot get role');
        return null;
      }
      
      final role = userData['role'] as String?;
      print('✅ User Role from userData: $role');
      return role?.toLowerCase(); // Normalize to lowercase
    } catch (e) {
      print('❌ Error getting user role: $e');
      return null;
    }
  }

  // ====================== CONNECTION TEST =========================

  /// Test backend connection
  static Future<bool> testConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      if (response.statusCode == 200) {
        print('✅ Backend connection successful');
        return true;
      } else {
        print('❌ Backend connection failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Connection test error: $e');
      return false;
    }
  }

  // ====================== AUTHENTICATION =========================

  /// Sign up new user
  static Future<Map<String, dynamic>> signup({
    required String userName,
    required String email,
    String? password,
    String? phone,
    String? city,
    required String role,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'userName': userName,
        'email': email,
        'phone': phone,
        'city': city,
        'role': role,
      };

      if (password != null) {
        body['password'] = password;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 201) {
        final token = responseBody['token'];
        final userData = responseBody['user'];
        
        if (token != null) {
          await saveToken(token);
        }
        
        if (userData != null) {
          await saveUserData(userData);
        }
        
        return responseBody;
      } else {
        throw Exception(responseBody['message'] ?? 'Signup failed');
      }
    } catch (e) {
      print('❌ Error in signup: $e');
      rethrow;
    }
  }

  /// Sign in user (login)
 static Future<Map<String, dynamic>> login(
    String email, 
    String password,
    {String? fcmToken} // ✅ تم إضافة الباراميتر الاختياري
  ) async {
    try {
      print('📡 Attempting login for: $email');
      
      final Map<String, dynamic> body = {
          'email': email,
          'password': password,
      };

      if (fcmToken != null) {
        body['fcmToken'] = fcmToken; // ✅ إضافة الرمز
        print('💡 Passing FCM Token in login request');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body), // ✅ استخدام الماب
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];
        final userData = data['user'] ?? data['data'];
        if (token == null) {
          throw Exception('Token not found in response');
        }
        if (userData == null) {
          throw Exception('User data not found in response');
        }
        if (userData['_id'] == null && userData['id'] == null) {
          throw Exception('User ID not found in user data');
        }

        // ✅ Save both token and user data
        await saveToken(token);
        await saveUserData(userData);
        
        print('✅ Login successful');
        print('✅ Token saved: ${token.substring(0, 20)}...');
        print('✅ User ID saved: ${userData['_id'] ?? userData['id']}');
        
        return {
          'success': true,
          'token': token,
          'user': userData,
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      print('❌ Login error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // ====================== USER PROFILE =========================

  /// Get user profile
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('Authentication token not found. Please login first.');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        return responseBody;
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to get user profile');
      }
    } catch (e) {
      print('❌ Error in getUserProfile: $e');
      rethrow;
    }
  }

  // ====================== PROVIDER REGISTRATION =========================

  /// Register provider details
  static Future<Map<String, dynamic>> registerProviderDetails({
    required String companyName,
    required String description,
    required String city,
    required String phone,
    required String email,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/providers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'companyName': companyName,
          'description': description,
          'location': {
            'city': city,
          },
          'details': {
            'phone': phone,
            'email': email,
          }
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to register provider details');
      }
    } catch (e) {
      print('❌ Error in registerProviderDetails: $e');
      rethrow;
    }
  }

  // ====================== LOGO UPLOAD =========================

  /// Upload company logo (optional)
  /// Returns the logo URL if successful, null otherwise
  static Future<String?> uploadCompanyLogo({
    required dynamic logoFile, // File for mobile, Uint8List for web
    String? fileName,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final uri = Uri.parse('$baseUrl/providers/upload-logo');
      final request = http.MultipartRequest('POST', uri);
      
      request.headers['Authorization'] = 'Bearer $token';

      if (kIsWeb) {
        // للويب: استخدام bytes مباشرة
        if (logoFile is List<int>) {
          request.files.add(http.MultipartFile.fromBytes(
            'logo',
            logoFile,
            filename: fileName ?? 'company_logo.png',
          ));
        }
      } else {
        // للموبايل: استخدام File
        if (logoFile is File) {
          request.files.add(await http.MultipartFile.fromPath(
            'logo',
            logoFile.path,
            filename: fileName ?? 'company_logo.png',
          ));
        }
      }

      print('📤 Uploading company logo...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Logo uploaded successfully: ${data['logoUrl']}');
        return data['logoUrl'];
      } else {
        final errorData = json.decode(response.body);
        print('❌ Logo upload failed: ${errorData['message']}');
        return null;
      }
    } catch (e) {
      print('❌ Error uploading logo: $e');
      return null;
    }
  }
}