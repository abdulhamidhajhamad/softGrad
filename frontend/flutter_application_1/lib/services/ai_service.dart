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
      if (formData.selectedServices.isEmpty) {
        throw Exception('Please select at least one service');
      }

      // Use event date if provided, otherwise default to 30 days from now
      final eventDate = formData.eventDate ?? DateTime.now().add(const Duration(days: 30));
      
      // Use times if provided, otherwise default
      final startTime = formData.startTime ?? const TimeOfDay(hour: 18, minute: 0);
      final endTime = formData.endTime ?? const TimeOfDay(hour: 23, minute: 0);

      // Get services sorted by priority
      final sortedServices = List<SelectedService>.from(formData.selectedServices)
        ..sort((a, b) => a.priority.compareTo(b.priority));
      
      // Combine userTags: vibeStyles + venueType + service names
      final List<String> userTags = [
        ...formData.vibeStyles,
        formData.venueType,
        ...sortedServices.map((s) => s.customName ?? s.name),
      ];

      // Format time to "HH:mm"
      final startTimeStr = _formatTimeOfDay(startTime);
      final endTimeStr = _formatTimeOfDay(endTime);

      // Format date to ISO string
      final eventDateStr = eventDate.toIso8601String();

      // Add custom event type if "Other" is selected
      final effectiveEventType = formData.eventType == 'Other' && formData.customEventType != null
          ? formData.customEventType!
          : formData.eventType;

      // 🆕 Build service priorities with budget percentages
      final servicePriorities = sortedServices.map((s) => {
        'name': s.customName ?? s.name,
        'priority': s.priority,
        'budgetPercent': s.budgetPercent,  // 🆕 Include budget percentage
      }).toList();

      // Prepare request body
      final requestBody = {
        'city': formData.city,
        'guestCount': formData.guestCount,
        'budgetMin': formData.budgetRange.start.toInt(),
        'budgetMax': formData.budgetRange.end.toInt(),
        'eventType': effectiveEventType,
        'eventDate': eventDateStr,
        'startTime': startTimeStr,
        'endTime': endTimeStr,
        'userTags': userTags,
        'venueType': formData.venueType,
        'packagePreference': formData.packagePreference == PackagePreference.withOptions ? 'withOptions' : 'withinBudget',
        'servicePriorities': servicePriorities,  // 🆕 Send service priorities with budgets
        'budgetFlexibility': formData.variationPercentage,  // 🆕 Budget flexibility
        if (formData.notes.isNotEmpty) 'additionalNotes': formData.notes,
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

  /// Search for a single service
  static Future<SingleServiceResponse> searchSingleService(SingleServiceData data) async {
    try {
      print('🔍 Searching for single service...');
      
      // Get auth token
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required. Please login first.');
      }

      // Validate required fields
      if (data.serviceType.isEmpty) {
        throw Exception('Service type is required');
      }
      if (data.city.isEmpty) {
        throw Exception('City is required');
      }

      // Use event date if provided, otherwise default to 30 days from now
      final eventDate = data.eventDate ?? DateTime.now().add(const Duration(days: 30));
      
      // Use times if provided, otherwise default
      final startTime = data.startTime ?? const TimeOfDay(hour: 18, minute: 0);
      final endTime = data.endTime ?? const TimeOfDay(hour: 23, minute: 0);

      // Format time to "HH:mm"
      final startTimeStr = _formatTimeOfDay(startTime);
      final endTimeStr = _formatTimeOfDay(endTime);

      // Format date to ISO string
      final eventDateStr = eventDate.toIso8601String();

      // Add custom event type if "Other" is selected
      final effectiveEventType = data.eventType == 'Other' && data.customEventType != null
          ? data.customEventType!
          : data.eventType;

      // Add custom service type if "Other" is selected
      final effectiveServiceType = data.serviceType == 'Other' && data.customServiceType != null
          ? data.customServiceType!
          : data.serviceType;

      // Prepare request body
      final requestBody = {
        'category': effectiveServiceType,
        'city': data.city,
        'guestCount': data.guestCount,
        'budgetMin': data.minBudget.toInt(),
        'budgetMax': data.maxBudget.toInt(),
        'eventType': effectiveEventType,
        'eventDate': eventDateStr,
        'startTime': startTimeStr,
        'endTime': endTimeStr,
        'venueType': data.venueType,
        // 🆕 Add budget flexibility if enabled
        if (data.hasBudgetFlexibility) 'budgetFlexibility': data.budgetFlexibilityPercent,
        if (data.notes.isNotEmpty) 'notes': data.notes,
      };

      print('📤 Single Service Request: ${json.encode(requestBody)}');

      // Make API call to single service endpoint
      final response = await http.post(
        Uri.parse('$baseUrl/ai-search/single-service'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        List<dynamic> data;
        
        if (responseData is List) {
          data = responseData;
        } else if (responseData is Map && responseData['services'] != null) {
          data = responseData['services'] as List;
        } else {
          data = [];
        }
        
        if (data.isEmpty) {
          throw Exception('No services found matching your criteria. Try adjusting your preferences.');
        }

        // Convert to ServiceSearchResult list
        final results = data.map((serviceJson) {
          return ServiceSearchResult.fromJson(serviceJson);
        }).toList();

        print('✅ Successfully found ${results.length} services');

        return SingleServiceResponse(
          success: true,
          results: results,
        );
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to find services';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Error in searchSingleService: $e');
      return SingleServiceResponse(
        success: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}