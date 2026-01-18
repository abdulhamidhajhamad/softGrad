// lib/screens/user/web/web_responsive_wrapper.dart
//
// ✅ Responsive Wrapper: Detects platform and renders Web or Mobile version
// ✅ Supports different screen sizes for responsive web design

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Breakpoints for responsive design
class WebBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double wideDesktop = 1600;
}

/// Screen size categories
enum ScreenSize { mobile, tablet, desktop, wideDesktop }

/// Get current screen size category
ScreenSize getScreenSize(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width < WebBreakpoints.mobile) return ScreenSize.mobile;
  if (width < WebBreakpoints.tablet) return ScreenSize.tablet;
  if (width < WebBreakpoints.desktop) return ScreenSize.desktop;
  return ScreenSize.wideDesktop;
}

/// Check if current platform is web
bool isWebPlatform() => kIsWeb;

/// Check if screen is large enough for web layout (tablet+)
bool shouldShowWebLayout(BuildContext context) {
  if (!kIsWeb) return false;
  final width = MediaQuery.of(context).size.width;
  return width >= WebBreakpoints.tablet;
}

/// Responsive wrapper that shows different layouts based on platform/size
class ResponsiveUserWrapper extends StatelessWidget {
  /// Mobile/App layout (original design)
  final Widget mobileLayout;

  /// Web/Desktop layout (new design)
  final Widget webLayout;

  const ResponsiveUserWrapper({
    super.key,
    required this.mobileLayout,
    required this.webLayout,
  });

  @override
  Widget build(BuildContext context) {
    // Always show mobile layout for native apps
    if (!kIsWeb) return mobileLayout;

    // For web, check screen size
    final width = MediaQuery.of(context).size.width;
    
    // Show web layout only on larger screens
    if (width >= WebBreakpoints.tablet) {
      return webLayout;
    }

    // Show mobile layout on small web screens
    return mobileLayout;
  }
}

/// Extension for easy responsive values
extension ResponsiveExtension on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  
  ScreenSize get screenSize => getScreenSize(this);
  
  bool get isMobile => screenWidth < WebBreakpoints.mobile;
  bool get isTablet => screenWidth >= WebBreakpoints.mobile && screenWidth < WebBreakpoints.desktop;
  bool get isDesktop => screenWidth >= WebBreakpoints.desktop;
  bool get isWideDesktop => screenWidth >= WebBreakpoints.wideDesktop;
  
  bool get isWebLargeScreen => kIsWeb && screenWidth >= WebBreakpoints.tablet;
  
  /// Get responsive value based on screen size
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
    T? wideDesktop,
  }) {
    final size = screenSize;
    switch (size) {
      case ScreenSize.wideDesktop:
        return wideDesktop ?? desktop ?? tablet ?? mobile;
      case ScreenSize.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenSize.tablet:
        return tablet ?? mobile;
      case ScreenSize.mobile:
        return mobile;
    }
  }
  
  /// Get responsive padding
  EdgeInsets get responsivePadding => responsive(
    mobile: const EdgeInsets.all(16),
    tablet: const EdgeInsets.all(24),
    desktop: const EdgeInsets.all(32),
    wideDesktop: const EdgeInsets.all(48),
  );
  
  /// Get content max width for centering
  double get contentMaxWidth => responsive(
    mobile: double.infinity,
    tablet: 720,
    desktop: 1100,
    wideDesktop: 1400,
  );
}
