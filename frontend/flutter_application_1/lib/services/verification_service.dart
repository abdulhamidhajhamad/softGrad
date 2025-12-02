import 'dart:convert';
import 'package:http/http.dart' as http;

class VerificationService {
  static const String baseUrl = 'http://192.168.110.22:3000';


  static Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String verificationCode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'verificationCode': verificationCode,
        }),
      );

      print('📧 Verify Email Status: ${response.statusCode}');
      print('📧 Verify Email Response: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Email verification failed');
      }
    } catch (e) {
      print('❌ Verify Email Error: $e');
      throw Exception('Network error: $e');
    }
  }

  // إعادة إرسال رمز التحقق
  static Future<Map<String, dynamic>> resendVerificationCode({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/resend-verification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
        }),
      );

      print('🔄 Resend Code Status: ${response.statusCode}');
      print('🔄 Resend Code Response: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to resend code');
      }
    } catch (e) {
      print('❌ Resend Code Error: $e');
      throw Exception('Network error: $e');
    }
  }
}