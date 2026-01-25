// lib/core/constants/api_endpoints.dart
// ╔════════════════════════════════════════════════════════════════════════════╗
// ║  🌐 API Endpoints - All API URLs in one place                               ║
// ║  Centralized API configuration                                              ║
// ╚════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// API Configuration - Base URLs and Endpoints
class ApiEndpoints {
  ApiEndpoints._(); // Private constructor

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔗 Base URL Configuration
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Get the appropriate base URL based on platform
  /// Get the appropriate base URL based on platform
  static String getBaseUrl() {
    return 'https://softgrad.onrender.com';
  }

  /// Base URL for all API calls
  static final String baseUrl = getBaseUrl();
  
  /// WebSocket URL (same as base for Socket.IO)
  static final String wsUrl = getBaseUrl();

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔐 Auth Endpoints
  // ═══════════════════════════════════════════════════════════════════════════
  
  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';
  static String get logout => '$baseUrl/auth/logout';
  static String get refreshToken => '$baseUrl/auth/refresh';
  static String get forgotPassword => '$baseUrl/auth/forgot-password';
  static String get resetPassword => '$baseUrl/auth/reset-password';
  static String get verifyEmail => '$baseUrl/auth/verify-email';
  static String get verifyCode => '$baseUrl/auth/verify-code';
  static String get resendCode => '$baseUrl/auth/resend-code';

  // ═══════════════════════════════════════════════════════════════════════════
  // 👤 User Endpoints
  // ═══════════════════════════════════════════════════════════════════════════
  
  static String get profile => '$baseUrl/user/profile';
  static String get updateProfile => '$baseUrl/user/update-profile';
  static String get changePassword => '$baseUrl/user/change-password';
  static String get uploadImage => '$baseUrl/user/upload-image';
  static String get favorites => '$baseUrl/user/favorites';
  static String toggleFavoriteService(String id) => '$baseUrl/user/favorites/service/$id';
  static String toggleFavoritePackage(String id) => '$baseUrl/user/favorites/package/$id';

  // ═══════════════════════════════════════════════════════════════════════════
  // 🛍️ Service Endpoints
  // ═══════════════════════════════════════════════════════════════════════════
  
  static String get services => '$baseUrl/service';
  static String get allServices => '$baseUrl/service/all';
  static String serviceById(String id) => '$baseUrl/service/$id';
  static String servicesByProvider(String providerId) => '$baseUrl/service/provider/$providerId';
  static String servicesByCategory(String category) => '$baseUrl/service/category/$category';
  static String get createService => '$baseUrl/service/create';
  static String updateService(String id) => '$baseUrl/service/update/$id';
  static String deleteService(String id) => '$baseUrl/service/delete/$id';

  // ═══════════════════════════════════════════════════════════════════════════
  // 📦 Package Endpoints
  // ═══════════════════════════════════════════════════════════════════════════
  
  static String get packages => '$baseUrl/package';
  static String get allPackages => '$baseUrl/package/all';
  static String packageById(String id) => '$baseUrl/package/$id';
  static String packagesByProvider(String providerId) => '$baseUrl/package/provider/$providerId';
  static String get createPackage => '$baseUrl/package/create';
  static String updatePackage(String id) => '$baseUrl/package/update/$id';
  static String deletePackage(String id) => '$baseUrl/package/delete/$id';

  // ═══════════════════════════════════════════════════════════════════════════
  // 📅 Booking Endpoints
  // ═══════════════════════════════════════════════════════════════════════════
  
  static String get bookings => '$baseUrl/booking';
  static String get myBookings => '$baseUrl/booking/my-bookings';
  static String get providerBookings => '$baseUrl/booking/provider-bookings';
  static String bookingById(String id) => '$baseUrl/booking/$id';
  static String get createBooking => '$baseUrl/booking/create';
  static String updateBookingStatus(String id) => '$baseUrl/booking/status/$id';
  static String get unseenCount => '$baseUrl/booking/unseen-count';
  static String get markAllSeen => '$baseUrl/booking/mark-seen';

  // ═══════════════════════════════════════════════════════════════════════════
  // 💬 Chat Endpoints
  // ═══════════════════════════════════════════════════════════════════════════
  
  static String get chat => '$baseUrl/chat';
  static String get myChats => '$baseUrl/chat/my-chats';
  static String chatMessages(String chatId) => '$baseUrl/chat/messages/$chatId';
  static String get sendMessage => '$baseUrl/chat/send';
  static String get unreadCount => '$baseUrl/chat/unread-count';
  static String markRead(String chatId) => '$baseUrl/chat/mark-read/$chatId';
  static String deleteChat(String chatId) => '$baseUrl/chat/$chatId';
  static String get startChat => '$baseUrl/chat/start';

  // ═══════════════════════════════════════════════════════════════════════════
  // ⭐ Review Endpoints
  // ═══════════════════════════════════════════════════════════════════════════
  
  static String get reviews => '$baseUrl/review';
  static String reviewsByService(String serviceId) => '$baseUrl/review/service/$serviceId';
  static String reviewsByProvider(String providerId) => '$baseUrl/review/provider/$providerId';
  static String get myReviews => '$baseUrl/review/my-reviews';
  static String get pendingReviews => '$baseUrl/review/pending';
  static String get createReview => '$baseUrl/review/create';
  static String replyToReview(String id) => '$baseUrl/review/reply/$id';
  static String deleteReview(String id) => '$baseUrl/review/$id';

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔔 Notification Endpoints
  // ═══════════════════════════════════════════════════════════════════════════
  
  static String get notifications => '$baseUrl/notification';
  static String get myNotifications => '$baseUrl/notification/my-notifications';
  static String get unreadNotifications => '$baseUrl/notification/unread';
  static String markNotificationRead(String id) => '$baseUrl/notification/read/$id';
  static String get markAllRead => '$baseUrl/notification/read-all';
  static String deleteNotification(String id) => '$baseUrl/notification/$id';

  // ═══════════════════════════════════════════════════════════════════════════
  // 🛒 Cart Endpoints
  // ═══════════════════════════════════════════════════════════════════════════
  
  static String get cart => '$baseUrl/cart';
  static String get addToCart => '$baseUrl/cart/add';
  static String removeFromCart(String itemId) => '$baseUrl/cart/remove/$itemId';
  static String get clearCart => '$baseUrl/cart/clear';
  static String get cartTotal => '$baseUrl/cart/total';

  // ═══════════════════════════════════════════════════════════════════════════
  // 💳 Payment Endpoints
  // ═══════════════════════════════════════════════════════════════════════════
  
  static String get checkout => '$baseUrl/payment/checkout';
  static String get confirmPayment => '$baseUrl/payment/confirm';
  static String get createPaymentIntent => '$baseUrl/payment/create-payment-intent';
  static String get paymentHistory => '$baseUrl/payment/history';

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎁 Promotion Endpoints
  // ═══════════════════════════════════════════════════════════════════════════
  
  static String get promotions => '$baseUrl/promotion';
  static String get promoCodes => '$baseUrl/promotion/admin/codes';
  static String applyPromoCode(String code) => '$baseUrl/promotion/apply/$code';
  static String get createPromoCode => '$baseUrl/promotion/create';

  // ═══════════════════════════════════════════════════════════════════════════
  // 👑 Admin Endpoints
  // ═══════════════════════════════════════════════════════════════════════════
  
  static String get adminDashboard => '$baseUrl/admin/dashboard';
  static String get adminUsers => '$baseUrl/admin/users';
  static String get adminProviders => '$baseUrl/admin/providers';
  static String get adminReviews => '$baseUrl/admin/reviews';
  static String get adminChats => '$baseUrl/admin/chats';
  static String get serviceSales => '$baseUrl/admin/service-sales';
  static String get packageSales => '$baseUrl/admin/package-sales';
  static String get usersCount => '$baseUrl/admin/users-count';
  static String get providersCount => '$baseUrl/admin/providers-count';
  static String deleteUser(String id) => '$baseUrl/admin/user/$id';
  static String deleteProvider(String id) => '$baseUrl/admin/provider/$id';

  // ═══════════════════════════════════════════════════════════════════════════
  // 🏪 Provider Endpoints
  // ═══════════════════════════════════════════════════════════════════════════
  
  static String get providerProfile => '$baseUrl/provider/profile';
  static String get providerStats => '$baseUrl/provider/stats';
  static String get becomeProvider => '$baseUrl/provider/become';
}

// ═══════════════════════════════════════════════════════════════════════════════
// 🔄 Legacy constants (for backward compatibility)
// ═══════════════════════════════════════════════════════════════════════════════

/// Legacy base URL constant
final String kBaseUrl = ApiEndpoints.baseUrl;
final String kWsUrl = ApiEndpoints.wsUrl;
