// lib/utils/url_helper_web.dart
import 'dart:html' as html;

String getCurrentUrl() {
  return html.window.location.href;
}

/// Get query parameters from URL
Map<String, String> getQueryParameters() {
  final uri = Uri.parse(html.window.location.href);
  
  // Check normal query parameters
  if (uri.queryParameters.isNotEmpty) {
    return uri.queryParameters;
  }
  
  // Check hash fragment for parameters (Flutter web uses hash routing)
  if (uri.fragment.isNotEmpty && uri.fragment.contains('?')) {
    final fragmentQuery = uri.fragment.split('?').last;
    final fragmentUri = Uri.parse('http://dummy?$fragmentQuery');
    return fragmentUri.queryParameters;
  }
  
  return {};
}

/// Listen to URL changes (for web navigation)
void listenToUrlChanges(Function(String) callback) {
  html.window.onPopState.listen((event) {
    callback(html.window.location.href);
  });
}