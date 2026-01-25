import 'dart:typed_data';

/// Stub implementation - should not be used directly
Future<String?> downloadPng(Uint8List bytes, String fileName) {
  throw UnsupportedError('Cannot download on this platform');
}

Future<String?> downloadPdf(Uint8List bytes, String fileName) {
  throw UnsupportedError('Cannot download on this platform');
}

Future<void> shareFile(Uint8List bytes, String fileName, String text) {
  throw UnsupportedError('Cannot share on this platform');
}
