import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Download PNG file on Mobile
Future<String?> downloadPng(Uint8List bytes, String fileName) async {
  try {
    // Try to save to Downloads folder first (Android)
    Directory? saveDir;
    
    if (Platform.isAndroid) {
      // Try external storage Downloads folder
      saveDir = Directory('/storage/emulated/0/Download');
      if (!await saveDir.exists()) {
        // Fallback to app documents directory
        saveDir = await getApplicationDocumentsDirectory();
      }
    } else if (Platform.isIOS) {
      // On iOS, save to documents and then share
      saveDir = await getApplicationDocumentsDirectory();
    } else {
      // Desktop platforms
      saveDir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    }
    
    final path = '${saveDir.path}/$fileName';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    
    // On iOS, also offer to share since we can't access Downloads directly
    if (Platform.isIOS) {
      await Share.shareXFiles([XFile(path)], text: 'Save to your device');
    }
    
    return path;
  } catch (e) {
    // Fallback to app documents
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/$fileName';
      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);
      return path;
    } catch (e2) {
      return null;
    }
  }
}

/// Download PDF file on Mobile
Future<String?> downloadPdf(Uint8List bytes, String fileName) async {
  try {
    Directory? saveDir;
    
    if (Platform.isAndroid) {
      saveDir = Directory('/storage/emulated/0/Download');
      if (!await saveDir.exists()) {
        saveDir = await getApplicationDocumentsDirectory();
      }
    } else if (Platform.isIOS) {
      saveDir = await getApplicationDocumentsDirectory();
    } else {
      saveDir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    }
    
    final path = '${saveDir.path}/$fileName';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    
    if (Platform.isIOS) {
      await Share.shareXFiles([XFile(path)], text: 'Save to your device');
    }
    
    return path;
  } catch (e) {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/$fileName';
      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);
      return path;
    } catch (e2) {
      return null;
    }
  }
}

/// Share file on Mobile using native share sheet
Future<void> shareFile(Uint8List bytes, String fileName, String text) async {
  try {
    // Save to temp first
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/$fileName';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    
    // Use share_plus to open native share sheet
    await Share.shareXFiles(
      [XFile(path)],
      text: text,
      subject: 'Wedding Invitation',
    );
  } catch (e) {
    rethrow;
  }
}
