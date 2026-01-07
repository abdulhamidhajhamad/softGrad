// lib/services/ai_service.dart

import 'dart:convert';
import 'package:flutter/material.dart'; // ✅ Added for TimeOfDay
import 'package:http/http.dart' as http;
import '../screens/Ai_Screen/models/ai_data_models.dart';
import 'auth_service.dart';

class AiService {
  static final String baseUrl = AuthService.baseUrl;

  /// Generate AI Packages based on form data
  static Future<AiPackageResponse> generatePackages(FormData formData) async {
    try {
      print('🤖 Generating AI Packages...');
      
      // Get auth token
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required. Please login first.');
      }

      // Validate required fields
      if (formData.city.isEmpty) {
        throw Exception('City is required');
      }
      if (formData.eventDate == null) {
        throw Exception('Event date is required');
      }
      if (formData.startTime == null || formData.endTime == null) {
        throw Exception('Start time and end time are required');
      }

      // Combine userTags: vibeStyles + venueType + selectedServices
      final List<String> userTags = [
        ...formData.vibeStyles,
        formData.venueType,
        ...formData.selectedServices,
      ];

      // Format time to "HH:mm" or "HH:mm AM/PM"
      final startTimeStr = _formatTimeOfDay(formData.startTime!);
      final endTimeStr = _formatTimeOfDay(formData.endTime!);

      // Format date to ISO string
      final eventDateStr = formData.eventDate!.toIso8601String();

      // Prepare request body
      final requestBody = {
        'city': formData.city,
        'guestCount': formData.guestCount,
        'budgetMin': formData.budgetRange.start.toInt(),
        'budgetMax': formData.budgetRange.end.toInt(),
        'eventType': formData.eventType,
        'eventDate': eventDateStr,
        'startTime': startTimeStr,
        'endTime': endTimeStr,
        'userTags': userTags,
      };

      print('📤 Request Body: ${json.encode(requestBody)}');

      // Make API call
      final response = await http.post(
        Uri.parse('$baseUrl/ai-search'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        if (data.isEmpty) {
          throw Exception('No packages found matching your criteria. Try adjusting your preferences.');
        }

        // Convert to PackageResult list
        final packages = data.map((packageJson) {
          return PackageResult.fromJson(packageJson);
        }).toList();

        print('✅ Successfully generated ${packages.length} packages');

        return AiPackageResponse(
          success: true,
          packages: packages,
        );
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to generate packages';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Error in generatePackages: $e');
      return AiPackageResponse(
        success: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Format TimeOfDay to string "HH:mm"
  static String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Test AI service connection
  static Future<bool> testConnection() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final response = await http.get(
        Uri.parse('$baseUrl/ai-search/health'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ AI Service connection test failed: $e');
      return false;
    }
  }
}