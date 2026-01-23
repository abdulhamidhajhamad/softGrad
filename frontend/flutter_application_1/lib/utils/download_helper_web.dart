// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:convert';

/// Download PNG file on Web
Future<String?> downloadPng(Uint8List bytes, String fileName) async {
  try {
    final blob = html.Blob([bytes], 'image/png');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';
    html.document.body!.children.add(anchor);
    anchor.click();
    html.document.body!.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
    return 'Downloaded $fileName';
  } catch (e) {
    return null;
  }
}

/// Download PDF file on Web
Future<String?> downloadPdf(Uint8List bytes, String fileName) async {
  try {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';
    html.document.body!.children.add(anchor);
    anchor.click();
    html.document.body!.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
    return 'Downloaded $fileName';
  } catch (e) {
    return null;
  }
}

/// Share file on Web using Web Share API
Future<void> shareFile(Uint8List bytes, String fileName, String text) async {
  try {
    // Check if Web Share API is supported
    final navigator = html.window.navigator;
    
    // Try to use Web Share API Level 2 (with files)
    final file = html.File([bytes], fileName, {'type': 'image/png'});
    
    // Check if canShare is supported
    final shareData = {
      'files': [file],
      'title': 'Wedding Invitation',
      'text': text,
    };
    
    // Use JavaScript interop to share
    await html.window.navigator.share(shareData);
  } catch (e) {
    // Fallback: open a new window with the image for manual sharing
    final base64 = base64Encode(bytes);
    final dataUrl = 'data:image/png;base64,$base64';
    html.window.open(dataUrl, '_blank');
  }
}
