// lib/services/forgot_password_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class ForgotPasswordService {
  // Base URL configuration (matches auth_service.dart)
  static String getBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:3000';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    } else {
      return 'http://localhost:3000';
    }
  }

  static final String baseUrl = getBaseUrl();

  /// Request password reset - sends email with reset link
  static Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      print('📧 Requesting password reset for: $email');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseBody['message'] ?? 'Password reset email sent successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to send reset email',
        };
      }
    } catch (e) {
      print('❌ Error requesting password reset: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  /// Verify reset token validity
  static Future<Map<String, dynamic>> verifyResetToken({
    required String token,
    required String email,
  }) async {
    try {
      print('🔍 Verifying reset token for: $email');
      
      final response = await http.get(
        Uri.parse('$baseUrl/auth/verify-reset-token?token=$token&email=$email'),
        headers: {'Content-Type': 'application/json'},
      );

      print('📥 Verify response status: ${response.statusCode}');
      print('📥 Verify response body: ${response.body}');

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'valid': responseBody['valid'] ?? true,
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Invalid or expired token',
        };
      }
    } catch (e) {
      print('❌ Error verifying token: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  /// Reset password with token
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      print('🔐 Resetting password for: $email');
      
      // Client-side validation
      if (newPassword != confirmPassword) {
        return {
          'success': false,
          'message': 'Passwords do not match',
        };
      }

      if (newPassword.length < 6) {
        return {
          'success': false,
          'message': 'Password must be at least 6 characters',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'token': token,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        }),
      );

      print('📥 Reset response status: ${response.statusCode}');
      print('📥 Reset response body: ${response.body}');

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseBody['message'] ?? 'Password reset successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to reset password',
        };
      }
    } catch (e) {
      print('❌ Error resetting password: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }
}