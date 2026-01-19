// lib/screens/compliance_provider/compliance_provider_service.dart
// Compliance and verification service for providers

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_application_1/services/auth_service.dart';

// ============================================================================
// 📊 ENUMS - Verification statuses, provider types, and document types
// ============================================================================

/// Provider verification statuses
enum VerificationStatus {
  pending,
  underReview,
  verified,
  adminReview,
  rejected,
  expired,
  deactivated,
}

/// Supported document types
enum DocumentType {
  nationalId,
  businessLicense,
  professionalLicense,
}

/// Provider types
enum ProviderType {
  individual,
  business,
}

/// Rejection reasons
enum RejectionReason {
  expiredDocument,
  unclearDocument,
  dataMismatch,
  invalidDocument,
  invalidIdNumber,
}

// ============================================================================
// 📦 MODELS - Data models
// ============================================================================

/// Extracted data from the document
class ExtractedData {
  final String? idNumber;
  final String? extractedName;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? businessName;
  final String? commercialRegNumber;
  final String? rawText;
  final double? confidence;

  ExtractedData({
    this.idNumber,
    this.extractedName,
    this.issueDate,
    this.expiryDate,
    this.businessName,
    this.commercialRegNumber,
    this.rawText,
    this.confidence,
  });

  factory ExtractedData.fromJson(Map<String, dynamic> json) {
    return ExtractedData(
      idNumber: json['idNumber'] as String?,
      extractedName: json['extractedName'] as String?,
      issueDate: json['issueDate'] != null 
          ? DateTime.tryParse(json['issueDate'].toString()) 
          : null,
      expiryDate: json['expiryDate'] != null 
          ? DateTime.tryParse(json['expiryDate'].toString()) 
          : null,
      businessName: json['businessName'] as String?,
      commercialRegNumber: json['commercialRegNumber'] as String?,
      rawText: json['rawText'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
    );
  }
}

/// Matching result
class MatchResult {
  final bool idMatched;
  final bool nameMatched;
  final double nameSimilarityScore;
  final bool firstNameMatched;
  final bool isValid;
  final int? daysUntilExpiry;

  MatchResult({
    required this.idMatched,
    required this.nameMatched,
    required this.nameSimilarityScore,
    required this.firstNameMatched,
    required this.isValid,
    this.daysUntilExpiry,
  });

  factory MatchResult.fromJson(Map<String, dynamic> json) {
    return MatchResult(
      idMatched: json['idMatched'] ?? false,
      nameMatched: json['nameMatched'] ?? false,
      nameSimilarityScore: (json['nameSimilarityScore'] as num?)?.toDouble() ?? 0.0,
      firstNameMatched: json['firstNameMatched'] ?? false,
      isValid: json['isValid'] ?? false,
      daysUntilExpiry: json['daysUntilExpiry'] as int?,
    );
  }
}

/// 🔐 Official stamp verification result
class StampVerificationResult {
  final bool found;
  final double score;
  final double? threshold;
  final String? stampType;
  final String? error;

  StampVerificationResult({
    required this.found,
    required this.score,
    this.threshold,
    this.stampType,
    this.error,
  });

  factory StampVerificationResult.fromJson(Map<String, dynamic> json) {
    return StampVerificationResult(
      found: json['found'] ?? false,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      threshold: (json['threshold'] as num?)?.toDouble(),
      stampType: json['stampType'] as String?,
      error: json['error'] as String?,
    );
  }
  
  /// Is the stamp acceptable?
  bool get isAcceptable => found && (threshold == null || score >= threshold!);
  
  /// Match percentage as a percent value
  String get scorePercentage => '${(score * 100).toStringAsFixed(1)}%';
}

/// Document verification response
class VerificationResponse {
  final bool success;
  final VerificationStatus status;
  final String message;
  final ExtractedData? extractedData;
  final MatchResult? matchResult;
  final RejectionReason? rejectionReason;
  final String? documentUrl;
  final DateTime? expiryDate;
  final StampVerificationResult? stampVerification;

  VerificationResponse({
    required this.success,
    required this.status,
    required this.message,
    this.extractedData,
    this.matchResult,
    this.rejectionReason,
    this.documentUrl,
    this.expiryDate,
    this.stampVerification,
  });
  
  /// Is the request referred for manual review due to the stamp?
  bool get isStampReview => 
      status == VerificationStatus.adminReview && 
      stampVerification != null && 
      !stampVerification!.found;

  factory VerificationResponse.fromJson(Map<String, dynamic> json) {
    return VerificationResponse(
      success: json['success'] ?? false,
      status: _parseVerificationStatus(json['status']),
      message: json['message'] ?? '',
      extractedData: json['extractedData'] != null 
          ? ExtractedData.fromJson(json['extractedData']) 
          : null,
      matchResult: json['matchResult'] != null 
          ? MatchResult.fromJson(json['matchResult']) 
          : null,
      rejectionReason: _parseRejectionReason(json['rejectionReason']),
      documentUrl: json['documentUrl'] as String?,
      expiryDate: json['expiryDate'] != null 
          ? DateTime.tryParse(json['expiryDate'].toString()) 
          : null,
      stampVerification: json['stampVerification'] != null 
          ? StampVerificationResult.fromJson(json['stampVerification']) 
          : null,
    );
  }
}

/// Provider verification status
class ProviderVerificationStatus {
  final String providerId;
  final VerificationStatus verificationStatus;
  final ProviderType providerType;
  final String? maskedIdNumber;
  final DateTime? issueDate;
  final DateTime? licenseExpiryDate;
  final int? daysUntilExpiry;
  final bool canAddServices;
  final DateTime? lastUpdated;
  final String? notes;
  final String? documentUrl;

  ProviderVerificationStatus({
    required this.providerId,
    required this.verificationStatus,
    required this.providerType,
    this.maskedIdNumber,
    this.issueDate,
    this.licenseExpiryDate,
    this.daysUntilExpiry,
    required this.canAddServices,
    this.lastUpdated,
    this.notes,
    this.documentUrl,
  });

  factory ProviderVerificationStatus.fromJson(Map<String, dynamic> json) {
    return ProviderVerificationStatus(
      providerId: json['providerId'] ?? '',
      verificationStatus: _parseVerificationStatus(json['verificationStatus']),
      providerType: _parseProviderType(json['providerType']),
      maskedIdNumber: json['maskedIdNumber'] as String?,
      issueDate: json['issueDate'] != null 
          ? DateTime.tryParse(json['issueDate'].toString()) 
          : null,
      licenseExpiryDate: json['licenseExpiryDate'] != null 
          ? DateTime.tryParse(json['licenseExpiryDate'].toString()) 
          : null,
      daysUntilExpiry: json['daysUntilExpiry'] as int?,
      canAddServices: json['canAddServices'] ?? false,
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.tryParse(json['lastUpdated'].toString()) 
          : null,
      notes: json['notes'] as String?,
      documentUrl: json['documentUrl'] as String?,
    );
  }
}

/// Verification statistics for admin
class VerificationStats {
  final int total;
  final int verified;
  final int pendingReview;
  final int adminReview;
  final int expired;
  final int rejected;
  final int deactivated;
  final int expiringWithin30Days;

  VerificationStats({
    required this.total,
    required this.verified,
    required this.pendingReview,
    required this.adminReview,
    required this.expired,
    required this.rejected,
    required this.deactivated,
    required this.expiringWithin30Days,
  });

  factory VerificationStats.fromJson(Map<String, dynamic> json) {
    return VerificationStats(
      total: json['total'] ?? 0,
      verified: json['verified'] ?? 0,
      pendingReview: json['pendingReview'] ?? 0,
      adminReview: json['adminReview'] ?? 0,
      expired: json['expired'] ?? 0,
      rejected: json['rejected'] ?? 0,
      deactivated: json['deactivated'] ?? 0,
      expiringWithin30Days: json['expiringWithin30Days'] ?? 0,
    );
  }
}
/// Provider information for admin review
class ProviderForReview {
  final String id;
  final String? userId; // User ID for chat functionality
  final String companyName;
  final String email;
  final String? phone;
  final VerificationStatus verificationStatus;
  final ProviderType providerType;
  final String? documentUrl;
  final String? extractedText;
  final DateTime? lastUpdated;
  final String? notes;

  ProviderForReview({
    required this.id,
    this.userId,
    required this.companyName,
    required this.email,
    this.phone,
    required this.verificationStatus,
    required this.providerType,
    this.documentUrl,
    this.extractedText,
    this.lastUpdated,
    this.notes,
  });

  factory ProviderForReview.fromJson(Map<String, dynamic> json) {
    // Extract userId from populated userId field or direct field
    String? userIdValue;
    if (json['userId'] != null) {
      if (json['userId'] is String) {
        userIdValue = json['userId'];
      } else if (json['userId'] is Map) {
        userIdValue = json['userId']['_id'] ?? json['userId']['id'];
      }
    }
    
    return ProviderForReview(
      id: json['_id'] ?? json['id'] ?? '',
      userId: userIdValue,
      companyName: json['companyName'] ?? '',
      email: json['email'] ?? json['userId']?['email'] ?? '',
      phone: json['phone'] as String? ?? json['userId']?['phone'] as String?,
      verificationStatus: _parseVerificationStatus(json['verification']?['verificationStatus']),
      providerType: _parseProviderType(json['verification']?['providerType']),
      documentUrl: json['verification']?['documentUrl'] as String?,
      extractedText: json['verification']?['extractedText'] as String?,
      lastUpdated: json['verification']?['lastUpdated'] != null 
          ? DateTime.tryParse(json['verification']['lastUpdated'].toString()) 
          : null,
      notes: json['verification']?['notes'] as String?,
    );
  }
}

// ============================================================================
// 🔧 HELPER FUNCTIONS
// ============================================================================

VerificationStatus _parseVerificationStatus(String? status) {
  switch (status?.toLowerCase()) {
    case 'pending':
      return VerificationStatus.pending;
    case 'under_review':
      return VerificationStatus.underReview;
    case 'verified':
      return VerificationStatus.verified;
    case 'admin_review':
      return VerificationStatus.adminReview;
    case 'rejected':
      return VerificationStatus.rejected;
    case 'expired':
      return VerificationStatus.expired;
    case 'deactivated':
      return VerificationStatus.deactivated;
    default:
      return VerificationStatus.pending;
  }
}

ProviderType _parseProviderType(String? type) {
  switch (type?.toLowerCase()) {
    case 'business':
      return ProviderType.business;
    case 'individual':
    default:
      return ProviderType.individual;
  }
}

RejectionReason? _parseRejectionReason(String? reason) {
  if (reason == null) return null;
  switch (reason.toLowerCase()) {
    case 'expired_document':
      return RejectionReason.expiredDocument;
    case 'unclear_document':
      return RejectionReason.unclearDocument;
    case 'data_mismatch':
      return RejectionReason.dataMismatch;
    case 'invalid_document':
      return RejectionReason.invalidDocument;
    case 'invalid_id_number':
      return RejectionReason.invalidIdNumber;
    default:
      return null;
  }
}

String _getDocumentTypeValue(DocumentType type) {
  switch (type) {
    case DocumentType.nationalId:
      return 'national_id';
    case DocumentType.businessLicense:
      return 'business_license';
    case DocumentType.professionalLicense:
      return 'professional_license';
  }
}

String _getProviderTypeValue(ProviderType type) {
  switch (type) {
    case ProviderType.individual:
      return 'individual';
    case ProviderType.business:
      return 'business';
  }
}

String getVerificationStatusText(VerificationStatus status) {
  switch (status) {
    case VerificationStatus.pending:
      return 'Pending';
    case VerificationStatus.underReview:
      return 'Under Review';
    case VerificationStatus.verified:
      return 'Verified';
    case VerificationStatus.adminReview:
      return 'Admin Review';
    case VerificationStatus.rejected:
      return 'Rejected';
    case VerificationStatus.expired:
      return 'Expired';
    case VerificationStatus.deactivated:
      return 'Deactivated';
  }
}

String getVerificationStatusTextAr(VerificationStatus status) {
  switch (status) {
    case VerificationStatus.pending:
      return 'قيد الانتظار';
    case VerificationStatus.underReview:
      return 'قيد المراجعة';
    case VerificationStatus.verified:
      return 'موثق';
    case VerificationStatus.adminReview:
      return 'بانتظار المراجعة';
    case VerificationStatus.rejected:
      return 'مرفوض';
    case VerificationStatus.expired:
      return 'منتهي الصلاحية';
    case VerificationStatus.deactivated:
      return 'معطل';
  }
}

// ============================================================================
// 🌐 COMPLIANCE PROVIDER SERVICE
// ============================================================================

class ComplianceProviderService {
  static String get baseUrl => AuthService.baseUrl;

  /// الحصول على رأس المصادقة
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // ==================== Provider Endpoints ====================

  /// رفع وثيقة للتحقق
  static Future<VerificationResponse> uploadDocument({
    required dynamic file, // File for mobile, Uint8List for web
    required String fileName,
    required DocumentType documentType,
    required ProviderType providerType,
    String? idNumber,
    String? arabicName,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final uri = Uri.parse('$baseUrl/compliance/upload-document');
      final request = http.MultipartRequest('POST', uri);

      // إضافة رأس المصادقة
      request.headers['Authorization'] = 'Bearer $token';

      // إضافة الحقول
      request.fields['documentType'] = _getDocumentTypeValue(documentType);
      request.fields['providerType'] = _getProviderTypeValue(providerType);
      
      if (idNumber != null && idNumber.isNotEmpty) {
        request.fields['idNumber'] = idNumber;
      }
      
      if (arabicName != null && arabicName.isNotEmpty) {
        request.fields['arabicName'] = arabicName;
      }

      // إضافة الملف
      if (kIsWeb) {
        // للويب: file هو Uint8List
        request.files.add(http.MultipartFile.fromBytes(
          'document',
          file as List<int>,
          filename: fileName,
          contentType: MediaType('image', _getFileExtension(fileName)),
        ));
      } else {
        // للموبايل: file هو File
        final mobileFile = file as File;
        request.files.add(await http.MultipartFile.fromPath(
          'document',
          mobileFile.path,
          filename: fileName,
          contentType: MediaType('image', _getFileExtension(fileName)),
        ));
      }

      print('📤 Uploading document to: $uri');
      print('📄 Document type: ${_getDocumentTypeValue(documentType)}');
      print('👤 Provider type: ${_getProviderTypeValue(providerType)}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return VerificationResponse.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to upload document');
      }
    } catch (e) {
      print('❌ Error uploading document: $e');
      rethrow;
    }
  }

  /// جلب حالة التحقق الحالية
  static Future<ProviderVerificationStatus> getVerificationStatus() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/compliance/status'),
        headers: headers,
      );

      print('📥 Verification status response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ProviderVerificationStatus.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to get verification status');
      }
    } catch (e) {
      print('❌ Error getting verification status: $e');
      rethrow;
    }
  }

  /// جلب سجلات التحقق للمزود الحالي
  static Future<List<Map<String, dynamic>>> getMyComplianceLogs({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/compliance/logs?page=$page&limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['logs'] ?? []);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to get compliance logs');
      }
    } catch (e) {
      print('❌ Error getting compliance logs: $e');
      rethrow;
    }
  }

  // ==================== Admin Endpoints ====================

  /// جلب إحصائيات التحقق (للأدمن)
  static Future<VerificationStats> getVerificationStats() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/compliance/admin/stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return VerificationStats.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to get verification stats');
      }
    } catch (e) {
      print('❌ Error getting verification stats: $e');
      rethrow;
    }
  }

  /// جلب المزودين حسب حالة التحقق (للأدمن)
  static Future<List<ProviderForReview>> getProvidersByStatus({
    VerificationStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      String url = '$baseUrl/compliance/admin/providers?page=$page&limit=$limit';
      
      if (status != null) {
        url += '&status=${_getStatusValue(status)}';
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final providers = data['providers'] ?? data;
        return (providers as List)
            .map((p) => ProviderForReview.fromJson(p))
            .toList();
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to get providers');
      }
    } catch (e) {
      print('❌ Error getting providers by status: $e');
      rethrow;
    }
  }

  /// جلب المزودين في انتظار المراجعة (للأدمن)
  static Future<List<ProviderForReview>> getPendingReviewProviders({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/compliance/admin/pending-review?page=$page&limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final providers = data['providers'] ?? data;
        return (providers as List)
            .map((p) => ProviderForReview.fromJson(p))
            .toList();
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to get pending providers');
      }
    } catch (e) {
      print('❌ Error getting pending review providers: $e');
      rethrow;
    }
  }

  /// جلب المزودين منتهيي الصلاحية (للأدمن)
  static Future<List<ProviderForReview>> getExpiredProviders({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/compliance/admin/expired?page=$page&limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final providers = data['providers'] ?? data;
        return (providers as List)
            .map((p) => ProviderForReview.fromJson(p))
            .toList();
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to get expired providers');
      }
    } catch (e) {
      print('❌ Error getting expired providers: $e');
      rethrow;
    }
  }

  /// المراجعة اليدوية من الأدمن (قبول أو رفض)
  static Future<VerificationResponse> adminVerification({
    required String providerId,
    required bool approved,
    String? notes,
    String? rejectionReason,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = {
        'providerId': providerId,
        'approved': approved,
      };
      
      if (notes != null) body['adminNotes'] = notes;
      if (rejectionReason != null) body['rejectionReason'] = rejectionReason;

      final response = await http.put(
        Uri.parse('$baseUrl/compliance/admin/verify'),
        headers: headers,
        body: json.encode(body),
      );

      print('📥 Admin verification response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return VerificationResponse.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to verify provider');
      }
    } catch (e) {
      print('❌ Error in admin verification: $e');
      rethrow;
    }
  }

  /// جلب سجلات التحقق لمزود معين (للأدمن)
  static Future<List<Map<String, dynamic>>> getProviderLogs({
    required String providerId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/compliance/admin/logs/$providerId?page=$page&limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['logs'] ?? data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to get provider logs');
      }
    } catch (e) {
      print('❌ Error getting provider logs: $e');
      rethrow;
    }
  }

  // ==================== Helper Methods ====================

  static String _getFileExtension(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'png':
        return 'png';
      case 'webp':
        return 'webp';
      case 'pdf':
        return 'pdf';
      default:
        return 'jpeg';
    }
  }

  static String _getStatusValue(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.pending:
        return 'pending';
      case VerificationStatus.underReview:
        return 'under_review';
      case VerificationStatus.verified:
        return 'verified';
      case VerificationStatus.adminReview:
        return 'admin_review';
      case VerificationStatus.rejected:
        return 'rejected';
      case VerificationStatus.expired:
        return 'expired';
      case VerificationStatus.deactivated:
        return 'deactivated';
    }
  }
}