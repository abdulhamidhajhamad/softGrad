import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional imports
import 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart'
    if (dart.library.io) 'download_helper_mobile.dart' as helper;

/// Helper class for downloading files across platforms
class DownloadHelper {
  /// Download PNG file
  static Future<String?> downloadPng(Uint8List bytes, String fileName) {
    return helper.downloadPng(bytes, fileName);
  }

  /// Download PDF file
  static Future<String?> downloadPdf(Uint8List bytes, String fileName) {
    return helper.downloadPdf(bytes, fileName);
  }

  /// Share file (for mobile and web)
  static Future<void> shareFile(Uint8List bytes, String fileName, String text) {
    return helper.shareFile(bytes, fileName, text);
  }

  /// Check if running on web
  static bool get isWeb => kIsWeb;
}
