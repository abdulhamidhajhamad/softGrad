// lib/core/navigation/url_strategy_web.dart
import 'dart:html' as html;

/// Parse URL query parameters (Web only)
Map<String, String> getUrlParameters() {
  final uri = Uri.parse(html.window.location.href);
  return uri.queryParameters;
}

/// Redirect to sign-in page (Web only)
void redirectToSignIn() {
  html.window.location.href = '/signin';
}

/// Redirect to forgot password page (Web only)
void redirectToForgotPassword() {
  html.window.location.href = '/forgot-password';
}