// lib/services/edit_profile_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:http_parser/http_parser.dart';

class EditProfileService {
  static final String baseUrl = AuthService.baseUrl;

  // ====================== GET USER PROFILE =========================
  
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      print('📡 Fetching user profile...');
      
      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ User profile fetched successfully');
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to fetch user profile');
      }
    } catch (e) {
      print('❌ Error fetching user profile: $e');
      rethrow;
    }
  }

  // ====================== GET PROVIDER DETAILS =========================
  
  static Future<Map<String, dynamic>> getProviderDetails() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      print('📡 Fetching provider details...');
      
      final response = await http.get(
        Uri.parse('$baseUrl/providers/my-details'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Provider details fetched successfully');
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to fetch provider details');
      }
    } catch (e) {
      print('❌ Error fetching provider details: $e');
      rethrow;
    }
  }

  // ====================== UPDATE USER PROFILE =========================
  
  /// ✅ تحديث معلومات المستخدم - كل الحقول اختيارية
  static Future<Map<String, dynamic>> updateUserProfile({
    String? userName,
    String? email,
    String? phone,
    String? city,
    String? currentPassword,
    String? newPassword,
    String? confirmNewPassword, // ✅ إضافة هذا الحقل
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      print('📡 Updating user profile...');

      // ✅ إنشاء body فقط بالحقول التي تم تعديلها
      final Map<String, dynamic> body = {};
      
      // حقول الملف الشخصي (اختيارية)
      if (userName != null && userName.isNotEmpty) body['userName'] = userName;
      if (email != null && email.isNotEmpty) body['email'] = email;
      if (phone != null && phone.isNotEmpty) body['phone'] = phone;
      if (city != null && city.isNotEmpty) body['city'] = city;
      
      // ✅ كلمات المرور: إرسالها فقط إذا كانت موجودة جميعها
      if (currentPassword != null && currentPassword.isNotEmpty && 
          newPassword != null && newPassword.isNotEmpty &&
          confirmNewPassword != null && confirmNewPassword.isNotEmpty) {
        body['currentPassword'] = currentPassword;
        body['newPassword'] = newPassword;
        body['confirmNewPassword'] = confirmNewPassword; // ✅ إرسال التأكيد
      }

      print('📤 Update body: $body');

      final response = await http.patch(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // تحديث البيانات المحفوظة محلياً
        if (data['user'] != null) {
          await AuthService.saveUserData(data['user']);
        }
        
        print('✅ User profile updated successfully');
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to update user profile');
      }
    } catch (e) {
      print('❌ Error updating user profile: $e');
      rethrow;
    }
  }

  // ====================== UPDATE PROVIDER DETAILS =========================
  
  static Future<Map<String, dynamic>> updateProviderDetails({
    String? companyName,
    String? email,
    String? phone,
    String? city,
    String? description,
    String? logoPath,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      print('📡 Updating provider details...');

      // ✅ رفع الشعار أولاً إذا موجود
      String? uploadedLogoUrl;
      if (logoPath != null && logoPath.isNotEmpty) {
        uploadedLogoUrl = await _uploadLogo(logoPath, token);
      }

      final Map<String, dynamic> body = {};

      // ✅ اسم الشركة
      if (companyName != null && companyName.isNotEmpty) {
        body['companyName'] = companyName;
      }

      // ✅ الوصف
      if (description != null && description.isNotEmpty) {
        body['description'] = description;
      }

      // ✅ details - فقط إذا كان في تعديل
      if (email != null || phone != null) {
        final Map<String, dynamic> details = {};
        if (email != null && email.isNotEmpty) {
          details['email'] = email;
        }
        if (phone != null && phone.isNotEmpty) {
          details['phone'] = phone;
        }
        if (details.isNotEmpty) {
          body['details'] = details;
        }
      }

      // ✅ location - فقط إذا كان في تعديل
      if (city != null && city.isNotEmpty) {
        body['location'] = {'city': city};
      }

      // ✅ الشعار المرفوع
      if (uploadedLogoUrl != null) {
        body['logoUrl'] = uploadedLogoUrl;
      }

      print('📤 Update body: $body');

      final response = await http.patch(
        Uri.parse('$baseUrl/providers/my-details'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Provider details updated successfully');
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to update provider details');
      }
    } catch (e) {
      print('❌ Error updating provider details: $e');
      rethrow;
    }
  }

  // ====================== UPLOAD LOGO =========================
  
  /// رفع شعار الشركة إلى السيرفر
  static Future<String?> _uploadLogo(String filePath, String token) async {
    try {
      print('📤 Uploading logo: $filePath');
      
      final file = File(filePath);
      if (!await file.exists()) {
        print('❌ Logo file does not exist');
        return null;
      }

      // تحديد نوع الملف
      String mimeType = 'image/jpeg';
      final extension = filePath.toLowerCase().split('.').last;
      if (extension == 'png') {
        mimeType = 'image/png';
      } else if (extension == 'gif') {
        mimeType = 'image/gif';
      } else if (extension == 'webp') {
        mimeType = 'image/webp';
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/providers/upload-logo'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(await http.MultipartFile.fromPath(
        'logo',
        filePath,
        contentType: MediaType.parse(mimeType),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Upload response status: ${response.statusCode}');
      print('📥 Upload response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        final logoUrl = data['logoUrl'] as String?;
        print('✅ Logo uploaded successfully: $logoUrl');
        return logoUrl;
      } else {
        print('❌ Failed to upload logo: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error uploading logo: $e');
      return null;
    }
  }
}