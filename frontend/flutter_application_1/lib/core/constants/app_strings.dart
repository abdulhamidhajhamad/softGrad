// lib/core/constants/app_strings.dart
// ╔════════════════════════════════════════════════════════════════════════════╗
// ║  📝 App Strings - Text constants                                            ║
// ║  All static text used in the app                                            ║
// ╚════════════════════════════════════════════════════════════════════════════╝

/// App Strings - Static text constants
class AppStrings {
  AppStrings._(); // Private constructor

  // ═══════════════════════════════════════════════════════════════════════════
  // 📱 App Info
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const String appName = 'Eventry';
  static const String appTagline = 'Plan Your Perfect Wedding';

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔐 Auth
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const String signIn = 'Sign In';
  static const String signUp = 'Sign Up';
  static const String signOut = 'Sign Out';
  static const String logout = 'Logout';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String resetPassword = 'Reset Password';
  static const String createAccount = 'Create Account';
  static const String alreadyHaveAccount = 'Already have an account?';
  static const String dontHaveAccount = "Don't have an account?";

  // ═══════════════════════════════════════════════════════════════════════════
  // 👤 Profile
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const String profile = 'Profile';
  static const String editProfile = 'Edit Profile';
  static const String myProfile = 'My Profile';
  static const String fullName = 'Full Name';
  static const String phone = 'Phone';
  static const String city = 'City';
  static const String save = 'Save';
  static const String cancel = 'Cancel';

  // ═══════════════════════════════════════════════════════════════════════════
  // 🛍️ Services
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const String services = 'Services';
  static const String myServices = 'My Services';
  static const String addService = 'Add Service';
  static const String editService = 'Edit Service';
  static const String deleteService = 'Delete Service';
  static const String serviceDetails = 'Service Details';
  static const String bookNow = 'Book Now';
  static const String addToCart = 'Add to Cart';

  // ═══════════════════════════════════════════════════════════════════════════
  // 📦 Packages
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const String packages = 'Packages';
  static const String myPackages = 'My Packages';
  static const String addPackage = 'Add Package';
  static const String packageDetails = 'Package Details';

  // ═══════════════════════════════════════════════════════════════════════════
  // 📅 Bookings
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const String bookings = 'Bookings';
  static const String myBookings = 'My Bookings';
  static const String bookingDetails = 'Booking Details';
  static const String pending = 'Pending';
  static const String confirmed = 'Confirmed';
  static const String completed = 'Completed';
  static const String cancelled = 'Cancelled';

  // ═══════════════════════════════════════════════════════════════════════════
  // 💬 Chat
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const String messages = 'Messages';
  static const String chat = 'Chat';
  static const String sendMessage = 'Send Message';
  static const String typeMessage = 'Type a message...';
  static const String noMessages = 'No messages yet';

  // ═══════════════════════════════════════════════════════════════════════════
  // ⭐ Reviews
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const String reviews = 'Reviews';
  static const String myReviews = 'My Reviews';
  static const String writeReview = 'Write a Review';
  static const String pendingReviews = 'Pending Reviews';

  // ═══════════════════════════════════════════════════════════════════════════
  // 🛒 Cart
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const String cart = 'Cart';
  static const String checkout = 'Checkout';
  static const String total = 'Total';
  static const String subtotal = 'Subtotal';
  static const String clearCart = 'Clear Cart';
  static const String emptyCart = 'Your cart is empty';
  static const String proceedToCheckout = 'Proceed to Checkout';

  // ═══════════════════════════════════════════════════════════════════════════
  // ❤️ Favorites
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const String favorites = 'Favorites';
  static const String addToFavorites = 'Add to Favorites';
  static const String removeFromFavorites = 'Remove from Favorites';
  static const String noFavorites = 'No favorites yet';

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔔 Notifications
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const String notifications = 'Notifications';
  static const String noNotifications = 'No notifications';
  static const String markAllRead = 'Mark all as read';

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔍 Search
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const String search = 'Search';
  static const String searchServices = 'Search services...';
  static const String noResults = 'No results found';
  static const String filter = 'Filter';
  static const String sort = 'Sort';

  // ═══════════════════════════════════════════════════════════════════════════
  // 📍 Cities (Palestine)
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const List<String> cities = [
    'Nablus',
    'Ramallah',
    'Jerusalem',
    'Hebron',
    'Bethlehem',
    'Jenin',
    'Tulkarm',
    'Qalqilya',
    'Jericho',
    'Salfit',
    'Tubas',
    'Gaza',
    'Khan Yunis',
    'Rafah',
    'Deir al-Balah',
    'Al-Bireh',
    'Other',
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // 🏷️ Categories
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const List<String> categories = [
    'Venues',
    'Photographers',
    'Catering',
    'Cake',
    'Music & Entertainment',
    'Event Planners',
    'Decor & Lighting',
    'Car Rental and Transportation',
    'Flower Shops',
    'Card Printing',
    'Jewelry & Accessories',
    'Gift & Souvenir',
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // ⚠️ Errors & Messages
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const String error = 'Error';
  static const String success = 'Success';
  static const String loading = 'Loading...';
  static const String retry = 'Retry';
  static const String ok = 'OK';
  static const String yes = 'Yes';
  static const String no = 'No';
  static const String confirm = 'Confirm';
  static const String delete = 'Delete';
  static const String somethingWentWrong = 'Something went wrong';
  static const String noInternetConnection = 'No internet connection';
  static const String sessionExpired = 'Session expired. Please login again.';

  // ═══════════════════════════════════════════════════════════════════════════
  // 💰 Currency
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const String currencySymbol = '₪';
  static String formatPrice(double price) => '$currencySymbol${price.toStringAsFixed(0)}';
}

// Legacy constants for backward compatibility
const List<String> kCities = AppStrings.cities;
const List<String> kWeddingCategories = AppStrings.categories;
