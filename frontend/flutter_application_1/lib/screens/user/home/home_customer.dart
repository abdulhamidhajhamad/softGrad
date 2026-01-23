// lib/screens/home_customer.dart

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_application_1/screens/user/search/search.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/screens/notifications_provider.dart';
import 'package:flutter_application_1/services/user_service/home_user_service.dart';
import 'package:flutter_application_1/services/user_service/chat_user_service.dart';
import 'package:flutter_application_1/services/user_service/review_service.dart';
import 'package:flutter_application_1/services/notification_provider_service.dart';
import 'package:flutter_application_1/services/service_locator.dart'; // ✅ Added for getIt
import 'package:flutter_application_1/widgets/booking_details_modal.dart';
import 'package:flutter_application_1/screens/review_screen/my_bookings_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// ✅ Web imports
import 'package:flutter_application_1/screens/user/web/web_responsive_wrapper.dart';
import 'package:flutter_application_1/screens/user/web/web_shell.dart';

import '../profile/favorites.dart';
import 'package:flutter_application_1/services/user_service/favorites_service.dart';
import 'package:flutter_application_1/screens/Ai_Screen/ai_screen_layout.dart';
import '../payment/cart.dart';
import '../profile/profile.dart';
import '../notifications/notifications.dart';
import 'offers.dart';
import '../packages/packages.dart';
import '../../templates.dart';
import 'services_customer_home.dart';
import '../../signin.dart';

// ✅ Chat page
import '../chat/chat_customer_home_page.dart';
/// ✅ RGB(215, 20, 20, 215)
const Color kNavBlue = Color.fromARGB(215, 20, 20, 215);

/// ✅ خلفية
const Color kPageBg = Color(0xFFF6F7FB);

class HomePage extends StatefulWidget {
  final String userName;
  const HomePage({Key? key, this.userName = "Guest"}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _index = 0;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // ✅ تهيئة الاتصالات Real-time
    _initializeConnections();

    _tabs = [
      _HomeTab(
        userName: widget.userName,
        onOpenSearch: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SearchScreen()),
        ),
        onOpenOffers: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OffersPage()),
        ),
        onOpenPackages: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PackagesPage()),
        ),
        onOpenTemplates: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TemplatesPage()),
        ),
        onOpenVendors: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SearchScreen()),
        ),
      ),

      /// ✅ بدل Categories
      const ChatCustomerHomePage(),

      /// AI
const AiScreenLayout(),
      /// Cart
      const CartPage(),

      /// Profile
      ProfileScreen(
        currentUser: User(
          fullName: widget.userName,
          email: 'you@example.com',
          phone: '+970000000000',
          location: 'Nablus, Palestine',
        ),
      ),
    ];
  }

  void _setIndex(int i) {
    if (_index == i) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  /// ✅ تهيئة جميع الاتصالات Real-time
  Future<void> _initializeConnections() async {
    debugPrint('🚀 Customer: Initializing real-time connections...');
    
    // 1. تهيئة اتصال الإشعارات (لكي يعرف الـ backend أن اليوزر online)
    await NotificationProviderService.initRealtimeNotifications();
    
    // 2. تهيئة اتصال الشات - ✅ استخدام getIt
    final service = getIt<ChatUserService>();
    await service.initializeUserId();
    await service.initSocket();
    
    debugPrint('✅ Customer: Real-time connections initialized');
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      debugPrint('✅ Customer App resumed, reconnecting...');
      _initializeConnections();
    }
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Check if we should show web layout (Web platform + large screen)
    final shouldShowWeb = kIsWeb && 
        MediaQuery.of(context).size.width >= WebBreakpoints.tablet;
    
    if (shouldShowWeb) {
      // ✅ Show Web Layout
      return WebShell(userName: widget.userName);
    }
    
    // ✅ Mobile Layout
    return Scaffold(
      backgroundColor: kPageBg,
      extendBody: true,
      drawer: const _AppDrawer(),
      body: _tabs[_index],

      /// ✅ Bottom Nav CLEAN (بدون إطار أزرق) + بدون overflow
      bottomNavigationBar: _CleanBottomNav(
        index: _index,
        onChanged: _setIndex,
      ),
    );
  }
}

////////////////////////////////////////////////////////////////////////////////
/// ✅ Bottom Nav CLEAN: White/Glass + Icons Small + No Overflow
////////////////////////////////////////////////////////////////////////////////

class _CleanBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _CleanBottomNav({
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final gap = min(86.0, w * 0.22);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        child: SizedBox(
          height: 84, // ✅ أقل من قبل عشان ما يطلع overflow
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // ✅ Base bar (أبيض)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 62,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.97),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: Colors.black.withOpacity(0.06)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 22,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _NavItemSmall(
                        selected: index == 0,
                        icon: Icons.home_rounded,
                        label: "Home",
                        onTap: () => onChanged(0),
                      ),
                      // ✅ Chat مع Badge للرسائل غير المقروءة
                      ValueListenableBuilder<int>(
                        valueListenable: ChatUserService.unreadGlobalCount,
                        builder: (context, unreadCount, child) {
                          return _NavItemSmall(
                            selected: index == 1,
                            icon: Icons.chat_bubble_rounded,
                            label: "Chat",
                            badge: unreadCount,
                            onTap: () => onChanged(1),
                          );
                        },
                      ),

                      // gap for center AI
                      SizedBox(width: gap),

                      _NavItemSmall(
                        selected: index == 3,
                        icon: Icons.shopping_bag_rounded,
                        label: "Cart",
                        onTap: () => onChanged(3),
                      ),
                      _NavItemSmall(
                        selected: index == 4,
                        icon: Icons.person_rounded,
                        label: "Profile",
                        onTap: () => onChanged(4),
                      ),
                    ],
                  ),
                ),
              ),

              // ✅ Center AI (أصغر)
              Positioned(
                bottom: 18,
                child: _CenterAIFabSmall(
                  active: index == 2,
                  onTap: () => onChanged(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterAIFabSmall extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const _CenterAIFabSmall({
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: active ? 62 : 58,
        height: active ? 62 : 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: kNavBlue,
          border: Border.all(color: kPageBg, width: 6),
          boxShadow: [
            BoxShadow(
              color: kNavBlue.withOpacity(0.30),
              blurRadius: 22,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: const Icon(
          Icons.auto_awesome_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

class _NavItemSmall extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge; // ✅ Badge للرسائل غير المقروءة

  const _NavItemSmall({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0, // ✅ default = 0
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = kNavBlue.withOpacity(selected ? 1 : 0.70);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: SizedBox(
        width: 62,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ✅ Stack للأيقونة مع Badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: selected ? 24 : 22, color: iconColor),
                // ✅ Badge
                if (badge > 0)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B30), // أحمر Apple-style
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF3B30).withOpacity(0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          badge > 99 ? '99+' : badge.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: badge > 99 ? 9 : 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            // ✅ نخليه يظهر بس لما selected لتفادي overflow
            SizedBox(
              height: 12,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 160),
                opacity: selected ? 1 : 0,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: kNavBlue,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////////////////////////
/// ✅ Home Tab
////////////////////////////////////////////////////////////////////////////////

class _HomeTab extends StatefulWidget {
  final String userName;
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenPackages;
  final VoidCallback onOpenOffers;
  final VoidCallback onOpenTemplates;
  final VoidCallback onOpenVendors;

  const _HomeTab({
    Key? key,
    required this.userName,
    required this.onOpenSearch,
    required this.onOpenPackages,
    required this.onOpenOffers,
    required this.onOpenTemplates,
    required this.onOpenVendors,
  }) : super(key: key);

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final _repo = HomeRepository();
  late Future<HomePayload> _future;
  List<dynamic> _upcomingBookings = [];
  bool _isLoadingBookings = true;

  @override
  void initState() {
    super.initState();
    _future = _repo.loadHome();
    _loadUpcomingBookings();
  }

  Future<void> _loadUpcomingBookings() async {
    try {
      setState(() => _isLoadingBookings = true);
      final allBookings = await ReviewService.getUserBookings();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final upcoming = allBookings.where((booking) {
        final bookingDateStr = booking['bookingDate'];
        if (bookingDateStr == null) return false;
        final bookingDate = DateTime.parse(bookingDateStr);
        final bookingDay = DateTime(bookingDate.year, bookingDate.month, bookingDate.day);
        return bookingDay.isAfter(today) || bookingDay.isAtSameMomentAs(today);
      }).take(3).toList(); // Only show up to 3 upcoming bookings on home

      setState(() {
        _upcomingBookings = upcoming;
        _isLoadingBookings = false;
      });
    } catch (e) {
      print('❌ Error loading upcoming bookings: $e');
      setState(() => _isLoadingBookings = false);
    }
  }

  Future<void> _refresh() async {
    setState(() => _future = _repo.loadHome(forceRefresh: true));
    await _future;
    await _loadUpcomingBookings();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.userName.trim().isEmpty ? "there" : widget.userName;
    final firstName = name.split(' ').first;
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;
    if (hour < 12) {
      greeting = 'Good Morning';
      greetingIcon = Icons.wb_sunny_rounded;
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
      greetingIcon = Icons.light_mode_rounded;
    } else {
      greeting = 'Good Evening';
      greetingIcon = Icons.nights_stay_rounded;
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: kNavBlue,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ✅ Modern Minimal AppBar (White, no image)
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            expandedHeight: 0,
            toolbarHeight: 64,
            leading: Builder(
              builder: (ctx) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: IconButton(
                  icon: Icon(Icons.menu_rounded, color: const Color(0xFF0B1220), size: 26),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                  tooltip: 'Menu',
                ),
              ),
            ),
            title: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kNavBlue, kNavBlue.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.celebration_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'Eventry',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0B1220),
                  ),
                ),
              ],
            ),
            actions: [
              // ✅ Favorites
              IconButton(
                icon: Icon(Icons.favorite_rounded, color: const Color(0xFFFF3B30), size: 24),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FavoritesPage()),
                  );
                },
                tooltip: 'Favorites',
              ),

              // ✅ Notifications with Badge - Same alignment as Favorites
              ValueListenableBuilder<int>(
                valueListenable: NotificationProviderService.unreadCountNotifier,
                builder: (context, unreadCount, _) {
                  return SizedBox(
                    width: 48,
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(Icons.notifications_rounded, color: const Color(0xFF0B1220), size: 24),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NotificationsProviderScreen(
                                  providerId: widget.userName,
                                ),
                              ),
                            );
                          },
                          tooltip: 'Notifications',
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 4,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF3B30),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF3B30).withOpacity(0.40),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  unreadCount > 9 ? '9+' : unreadCount.toString(),
                                  style: GoogleFonts.poppins(
                                    fontSize: unreadCount > 9 ? 8 : 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
            ],
          ),

          // ✅ Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ Greeting Card (Modern Glass Effect)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kNavBlue, const Color(0xFF4F46E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: kNavBlue.withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(greetingIcon, color: Colors.amber, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    greeting,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Hi, $firstName! 👋',
                                style: GoogleFonts.poppins(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Let's plan your perfect event!",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.event_available_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ✅ Search Bar
                  _TopSearchBar(
                    hint: "Search services, packages, vendors...",
                    onTap: widget.onOpenSearch,
                  ),

                  const SizedBox(height: 22),

                  // ✅ Quick Actions (Centered Grid)
                  Text(
                    'Quick Actions',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0B1220),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _QuickActionChip(
                        icon: Icons.storefront_rounded,
                        label: 'Services',
                        color: kNavBlue,
                        onTap: widget.onOpenVendors,
                      ),
                      _QuickActionChip(
                        icon: Icons.inventory_2_rounded,
                        label: 'Packages',
                        color: const Color(0xFFF57C00),
                        onTap: widget.onOpenPackages,
                      ),
                      _QuickActionChip(
                        icon: Icons.local_offer_rounded,
                        label: 'Offers',
                        color: const Color(0xFF8B5CF6),
                        onTap: widget.onOpenOffers,
                      ),
                      _QuickActionChip(
                        icon: Icons.description_rounded,
                        label: 'Templates',
                        color: const Color(0xFF059669),
                        onTap: widget.onOpenTemplates,
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // ✅ FutureBuilder for main content
                  FutureBuilder<HomePayload>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const _HomeMiniSkeleton();
                      }
                      if (snap.hasError || !snap.hasData) {
                        return _InlineError(onRetry: _refresh);
                      }

                      final data = snap.data!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeaderWithAction(
                            title: "Package Deals!",
                            actionText: "View all",
                            onAction: widget.onOpenPackages,
                          ),
                          const SizedBox(height: 12),
                          HomePackageCarousel(packages: data.packages),

                          const SizedBox(height: 20),

                          _HeaderWithAction(
                            title: "Trending Services",
                            actionText: "View more",
                            onAction: widget.onOpenVendors,
                          ),
                          const SizedBox(height: 12),
                          HomeTrendingRail(
                            services: data.trending,
                            onOpen: (s) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ServiceDetailsPage(service: s),
                                ),
                              );
                            },
                          ),

                          // ✅ NEW: My Upcoming Bookings Section
                          const SizedBox(height: 24),
                          _buildUpcomingBookingsSection(),

                          // ✅ مساحة كافية عشان الـ nav ما يغطي
                          const SizedBox(height: 140),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ NEW: Widget to build upcoming bookings section
  Widget _buildUpcomingBookingsSection() {
    if (_isLoadingBookings) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: kNavBlue),
          ),
        ),
      );
    }

    if (_upcomingBookings.isEmpty) {
      return const SizedBox.shrink(); // Don't show section if no upcoming bookings
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'My Upcoming Bookings',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to profile -> bookings (tab index 4)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyBookingsScreen(),
                  ),
                );
              },
              child: Text(
                'View all',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w900,
                  color: kNavBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._upcomingBookings.map((booking) => _buildBookingCard(booking)).toList(),
      ],
    );
  }

  /// ✅ NEW: Build individual booking card
  Widget _buildBookingCard(dynamic booking) {
    final serviceName = booking['serviceName'] ?? 'Service';
    final status = booking['status'] ?? 'confirmed';
    final bookingDateStr = booking['bookingDate'] ?? '';
    
    DateTime? bookingDate;
    String formattedDate = 'N/A';
    
    if (bookingDateStr.isNotEmpty) {
      try {
        bookingDate = DateTime.parse(bookingDateStr);
        formattedDate = '${bookingDate.day}/${bookingDate.month}/${bookingDate.year}';
      } catch (e) {
        formattedDate = bookingDateStr;
      }
    }

    Color statusColor;
    IconData statusIcon;
    switch (status.toLowerCase()) {
      case 'confirmed':
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'pending':
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.schedule_rounded;
        break;
      case 'cancelled':
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = const Color(0xFF64748B);
        statusIcon = Icons.info_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // ✅ Date Circle
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: kNavBlue.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (bookingDate != null) ...[
                  Text(
                    '${bookingDate.day}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: kNavBlue,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    _getMonthAbbrev(bookingDate.month),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: kNavBlue,
                    ),
                  ),
                ] else
                  Icon(Icons.calendar_today_rounded, color: kNavBlue, size: 22),
              ],
            ),
          ),
          const SizedBox(width: 12),
          
          // ✅ Service Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  serviceName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0B1220),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      status.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // ✅ Arrow
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: kNavBlue,
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthAbbrev(int month) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 
                    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[month - 1];
  }
}

class _TopSearchBar extends StatelessWidget {
  final String hint;
  final VoidCallback onTap;

  const _TopSearchBar({required this.hint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final borderC = Colors.black.withOpacity(0.08);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderC),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: kNavBlue.withOpacity(0.85)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
            Icon(Icons.tune_rounded, color: kNavBlue.withOpacity(0.80)),
          ],
        ),
      ),
    );
  }
}

/// ✅ Quick Action Chip - Responsive & Centered
class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // حساب العرض بناءً على حجم الشاشة - 4 عناصر مع مسافات
    final itemWidth = (screenWidth - 32 - 36) / 4; // 32 padding + 36 gaps (12*3)
    final clampedWidth = itemWidth.clamp(70.0, 90.0);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          width: clampedWidth,
          height: 95,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0B1220),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: kNavBlue.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: kNavBlue),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderWithAction extends StatelessWidget {
  final String title;
  final String actionText;
  final VoidCallback onAction;

  const _HeaderWithAction({
    required this.title,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(
            actionText,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w900,
              color: kNavBlue,
            ),
          ),
        ),
      ],
    );
  }
}

class _ToolCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color tint;
  final Color iconColor;
  final VoidCallback onTap;

  const _ToolCard({
    required this.title,
    required this.icon,
    required this.tint,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderC = Colors.black.withOpacity(0.08);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderC),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: kNavBlue.withOpacity(0.60),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeMiniSkeleton extends StatelessWidget {
  const _HomeMiniSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget box({double h = 16, double w = double.infinity}) => Container(
          height: h,
          width: w,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        box(h: 16, w: 170),
        const SizedBox(height: 10),
        box(h: 260),
        const SizedBox(height: 18),
        box(h: 16, w: 190),
        const SizedBox(height: 10),
        box(h: 170),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  final Future<void> Function() onRetry;
  const _InlineError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD2D2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Color(0xFFD32F2F)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Couldn’t load packages/services. Pull to refresh or retry.",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: () => onRetry(),
            child: Text(
              "Retry",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.favorite_border),
              title: const Text('Favorites'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FavoritesPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () async {
                await AuthService.deleteToken();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => SignInScreen()),
                  (_) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////////////////////////
/// ✅ Data + UI: Packages + Trending
////////////////////////////////////////////////////////////////////////////////

class HomePackageDeal {
  final String id;
  final String imageUrl;
  final String title;
  final String company;
  final List<String> services;
  final double price;
  final double originalPrice;
  final String validity;

  HomePackageDeal({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.company,
    required this.services,
    required this.price,
    required this.originalPrice,
    required this.validity,
  });
}

class HomeTrendingService {
  final String id;
  final String name;
  final String company;
  final String providerId;
  final String category;
  final double price;
  final String imageUrl;
  final String desc;
  final double? latitude;
  final double? longitude;

  HomeTrendingService({
    required this.id,
    required this.name,
    required this.company,
    required this.providerId,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.desc,
    this.latitude,
    this.longitude,
  });
}

class HomePayload {
  final List<HomePackageDeal> packages;
  final List<HomeTrendingService> trending;
  HomePayload({required this.packages, required this.trending});
}

class HomeRepository {
  Future<HomePayload> loadHome({bool forceRefresh = false}) async {
    try {
      // Fetch data from backend API
      final homeData = await HomeUserService.getHomeData();

      // Convert API models to UI models
      final packages = homeData.packages.map((pkg) => HomePackageDeal(
        id: pkg.id,
        imageUrl: pkg.imageUrl.isNotEmpty 
            ? pkg.imageUrl 
            : 'https://images.unsplash.com/photo-1519225468359-2996bc01c5dc?auto=format&fit=crop&q=80&w=1200',
        title: pkg.title,
        company: pkg.company,
        services: pkg.services,
        price: pkg.price,
        originalPrice: pkg.originalPrice,
        validity: pkg.validity,
      )).toList();

      final trending = homeData.trending.map((svc) => HomeTrendingService(
        id: svc.id,
        name: svc.name,
        company: svc.company,
        providerId: svc.providerId,
        category: svc.category,
        price: svc.price,
        imageUrl: svc.imageUrl.isNotEmpty 
            ? svc.imageUrl 
            : 'https://images.unsplash.com/photo-1522673607200-1645062cd495?auto=format&fit=crop&q=80&w=600',
        desc: svc.desc.isNotEmpty ? svc.desc : 'Quality service for your special day',
        latitude: svc.latitude,
        longitude: svc.longitude,
      )).toList();

      return HomePayload(packages: packages, trending: trending);
    } catch (e) {
      print('❌ Error loading home data: $e');
      // Return empty data on error - UI will show error state
      return HomePayload(packages: [], trending: []);
    }
  }
}

class HomePackageCarousel extends StatefulWidget {
  final List<HomePackageDeal> packages;
  const HomePackageCarousel({Key? key, required this.packages})
      : super(key: key);

  @override
  State<HomePackageCarousel> createState() => _HomePackageCarouselState();
}

class _HomePackageCarouselState extends State<HomePackageCarousel> {
  late final PageController _controller;
  int _page = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.88);

    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || widget.packages.isEmpty) return;
      final next = (_page + 1) % widget.packages.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.packages.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 280,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.packages.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _PackageHeroCard(pkg: widget.packages[i]),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.packages.length, (i) {
            final active = i == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 7,
              width: active ? 18 : 7,
              decoration: BoxDecoration(
                color: active ? kNavBlue : Colors.black.withOpacity(0.12),
                borderRadius: BorderRadius.circular(99),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _PackageHeroCard extends StatelessWidget {
  final HomePackageDeal pkg;
  const _PackageHeroCard({required this.pkg});

  @override
  Widget build(BuildContext context) {
    final offPct = _discountPercent(pkg.originalPrice, pkg.price);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // ✅ Background Image
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: pkg.imageUrl,
                fit: BoxFit.cover,
                memCacheWidth: 1000,
                memCacheHeight: 1000,
                maxHeightDiskCache: 1000,
                maxWidthDiskCache: 1000,
                placeholder: (_, __) => Container(
                  color: const Color(0xFFF1F5F9),
                  child: const Center(child: CircularProgressIndicator(color: kNavBlue)),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: const Color(0xFFF1F5F9),
                  child: const Icon(Icons.image_rounded, size: 48, color: Colors.grey),
                ),
              ),
            ),
            
            // ✅ Gradient Overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.4, 1.0],
                    colors: [
                      Colors.black.withOpacity(0.02),
                      Colors.black.withOpacity(0.15),
                      Colors.black.withOpacity(0.75),
                    ],
                  ),
                ),
              ),
            ),
            
            // ✅ Discount Badge (Top Right) - Modern Style
            if (offPct > 0)
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF3B30), Color(0xFFFF6B6B)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF3B30).withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "$offPct% OFF",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ✅ Company Badge (Top Left)
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.90),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  pkg.company,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0B1220),
                  ),
                ),
              ),
            ),

            // ✅ Content (Bottom)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pkg.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // ✅ Service chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                  children: pkg.services.take(3).map((s) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        s,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                
                // ✅ Price Row
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "₪${pkg.price.toStringAsFixed(0)}",
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        if (pkg.originalPrice > pkg.price)
                          Text(
                            "₪${pkg.originalPrice.toStringAsFixed(0)}",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white60,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(Icons.arrow_forward_rounded, color: kNavBlue, size: 22),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class HomeTrendingRail extends StatefulWidget {
  final List<HomeTrendingService> services;
  final ValueChanged<HomeTrendingService> onOpen;

  const HomeTrendingRail({
    Key? key,
    required this.services,
    required this.onOpen,
  }) : super(key: key);

  @override
  State<HomeTrendingRail> createState() => _HomeTrendingRailState();
}

class _HomeTrendingRailState extends State<HomeTrendingRail> {
  late final ScrollController _scrollController;
  Timer? _autoScrollTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || widget.services.isEmpty) return;
      
      _currentIndex = (_currentIndex + 1) % widget.services.length;
      
      // Calculate scroll position (card width ~320 + spacing 14)
      final cardWidth = 320.0 + 14.0;
      final targetOffset = _currentIndex * cardWidth;
      final maxScroll = _scrollController.position.maxScrollExtent;
      
      // If reached end, go back to start
      if (targetOffset > maxScroll) {
        _currentIndex = 0;
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.services.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 178,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.services.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final s = widget.services[i];
          return _TrendingCard(service: s, onTap: () => widget.onOpen(s));
        },
      ),
    );
  }
}

class _TrendingCard extends StatelessWidget {
  final HomeTrendingService service;
  final VoidCallback onTap;

  const _TrendingCard({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    final double cardW = min(sw * 0.86, 360.0).toDouble();
    const cardH = 150.0;
    const imgW = 96.0;
    const imgH = 126.0;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: SizedBox(
        width: cardW,
        height: cardH,
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: service.imageUrl,
                  width: imgW,
                  height: imgH,
                  fit: BoxFit.cover,

                  // ✅ مهم لتخفيف كراش الإيميوليتر
                  memCacheWidth: 600,
                  memCacheHeight: 600,
                  maxHeightDiskCache: 700,
                  maxWidthDiskCache: 700,

                  placeholder: (_, __) =>
                      Container(color: const Color(0xFFF1F5F9)),
                  errorWidget: (_, __, ___) => Container(
                    color: const Color(0xFFF1F5F9),
                    child: const Icon(Icons.image),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: kNavBlue.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            service.category,
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              color: kNavBlue,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: List.generate(
                            5,
                            (_) => const Icon(Icons.star,
                                size: 11, color: Colors.amber),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      service.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      service.company,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      service.desc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          "\$${service.price.toStringAsFixed(0)}",
                          style: GoogleFonts.poppins(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: kNavBlue,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: kNavBlue,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: kNavBlue.withOpacity(0.22),
                                blurRadius: 14,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ServiceDetailsPage extends StatefulWidget {
  final HomeTrendingService service;
  const ServiceDetailsPage({super.key, required this.service});

  @override
  State<ServiceDetailsPage> createState() => _ServiceDetailsPageState();
}

class _ServiceDetailsPageState extends State<ServiceDetailsPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _serviceData;
  String? _bookingType;

  // ✅ Media Slider State
  List<String> _mediaUrls = [];
  int _currentMediaIndex = 0;
  PageController? _mediaPageController;
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();
    _mediaPageController = PageController();
    _loadServiceDetails();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _mediaPageController?.dispose();
    super.dispose();
  }

  // ✅ Auto-slide every 4 seconds
  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    if (_mediaUrls.length <= 1) return;
    
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _mediaPageController == null) return;
      final next = (_currentMediaIndex + 1) % _mediaUrls.length;
      _mediaPageController!.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  void _resetAutoSlide() {
    _autoSlideTimer?.cancel();
    _startAutoSlide();
  }

  bool _isVideoUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.webm');
  }

  Future<void> _loadServiceDetails() async {
    try {
      setState(() => _isLoading = true);
      
      // Import user_service_service for API call
      final response = await _fetchServiceDetails(widget.service.id);
      
      // 🔍 Debug prints
      print('📦 Service Details Response: $response');
      print('📷 Images field: ${response['images']}');
      print('📷 Images type: ${response['images']?.runtimeType}');
      
      setState(() {
        _serviceData = response;
        _bookingType = response['bookingType']?.toString().toLowerCase();
        
        // ✅ Extract media URLs from images array
        _mediaUrls = [];
        if (response['images'] != null && response['images'] is List) {
          for (var img in response['images']) {
            if (img != null && img.toString().isNotEmpty) {
              _mediaUrls.add(img.toString());
            }
          }
        }
        // Fallback to single image if no images array
        if (_mediaUrls.isEmpty && widget.service.imageUrl.isNotEmpty) {
          _mediaUrls.add(widget.service.imageUrl);
        }
        
        print('📷 Final _mediaUrls: $_mediaUrls');
        print('📷 _mediaUrls length: ${_mediaUrls.length}');
        
        _isLoading = false;
      });
      
      // Start auto-slide after data is loaded
      _startAutoSlide();
      
    } catch (e) {
      print('❌ Error loading service details: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load service details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _fetchServiceDetails(String serviceId) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${AuthService.baseUrl}/services/$serviceId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      // Handle case where API returns a List instead of Map
      if (decoded is List) {
        if (decoded.isNotEmpty && decoded[0] is Map<String, dynamic>) {
          return decoded[0] as Map<String, dynamic>;
        }
        throw Exception('Invalid service data format');
      }
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw Exception('Unexpected response format');
    } else {
      throw Exception('Failed to load service');
    }
  }

  String _money(double v) => '₪${v.toStringAsFixed(0)}';

  Future<void> _startChat() async {
    if (widget.service.providerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot start chat: Provider not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: kNavBlue),
      ),
    );

    try {
      // ✅ استخدام getIt للحصول على نفس الـ instance
      final chatService = getIt<ChatUserService>();
      await chatService.initializeUserId();
      await chatService.initSocket();
      
      final chatId = await chatService.createChat(widget.service.providerId);
      
      if (mounted) Navigator.pop(context); // Close loading
      
      if (chatId != null && mounted) {
        // Navigate to chat - using the ChatThreadPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatThreadPage(
              thread: ChatThreadModel(
                id: chatId,
                type: ThreadType.vendor,
                title: widget.service.company,
                lastMessage: '',
                lastTime: DateTime.now(),
                unreadCount: 0,
                online: false,
              ),
            ),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to start chat'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openBookingModal() async {
    if (_serviceData == null || _bookingType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service details not loaded yet'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if already in cart
    final inCart = CartStore.instance.contains(widget.service.id);
    if (inCart) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
          content: Text(
            'This service is already in your cart',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
          ),
          action: SnackBarAction(
            label: 'View Cart',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartPage()),
              );
            },
          ),
        ),
      );
      return;
    }

    await showBookingModal(
      context: context,
      serviceId: widget.service.id,
      serviceName: widget.service.name,
      bookingTypeString: _bookingType!,
      serviceData: _serviceData!,
      onSuccess: () {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            content: Text(
              'Added to cart successfully!',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.service;
    
    return Scaffold(
      backgroundColor: kPageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.6,
        iconTheme: const IconThemeData(color: Color(0xFF0B1220)),
        title: Text(
          "Service Details",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0B1220),
          ),
        ),
        actions: [
          // ✅ Favorite Button in AppBar
          _FavoriteButton(
            serviceId: s.id,
            serviceName: s.name,
            category: s.category,
            company: s.company,
            price: s.price,
            rating: _serviceData?['rating']?.toDouble() ?? 0.0,
            imageUrl: s.imageUrl,
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.black.withOpacity(0.06))),
          ),
          child: Row(
            children: [
              // ✅ Start Chat button (LEFT)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _startChat,
                  icon: Icon(Icons.chat_bubble_rounded, color: kNavBlue),
                  label: Text(
                    'Start Chat with Provider', 
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: const Color(0xFF0B1220)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.black.withOpacity(0.14)),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // ✅ Add to Cart button (RIGHT)
              Expanded(
                child: ValueListenableBuilder<List<CartItem>>(
                  valueListenable: CartStore.instance.itemsListenable,
                  builder: (_, items, ___) {
                    final inCart = items.any((item) => item.id == s.id);
                    final isDisplayOnly = _bookingType?.toLowerCase() == 'display';

                    return ElevatedButton.icon(
                      onPressed: (inCart || _isLoading || isDisplayOnly) ? null : _openBookingModal,
                      icon: Icon(
                        inCart ? Icons.check_circle_rounded 
                            : isDisplayOnly ? Icons.visibility_rounded 
                            : Icons.add_shopping_cart_rounded,
                        color: (inCart || isDisplayOnly) ? Colors.white70 : kNavBlue,
                      ),
                      label: Text(
                        inCart ? 'In Cart' 
                            : isDisplayOnly ? 'Display Only' 
                            : 'Add to Cart',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (inCart || isDisplayOnly) ? Colors.grey : const Color(0xFF0B1220),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.withOpacity(0.6),
                        disabledForegroundColor: Colors.white70,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kNavBlue))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ✅ Media Slider (Images/Videos)
                if (_mediaUrls.isNotEmpty)
                  _buildMediaSlider(),
                
                const SizedBox(height: 16),
                
                // Service Info Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.black.withOpacity(0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: kNavBlue.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              s.category,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: kNavBlue,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                _serviceData?['rating']?.toString() ?? '0',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0B1220),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        s.name,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0B1220),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        s.company,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // ✅ Price with booking type indicator
                      _buildPriceSection(),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Description - only show if has content
                if (_hasDescription())
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.black.withOpacity(0.06)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0B1220),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getDescription(),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Service Information Section
                _buildServiceInformationSection(),
                
                // Company Info - only show if has any data
                if (_hasCompanyInfo())
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.black.withOpacity(0.06)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Company Info',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0B1220),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._buildCompanyInfoRows(),
                      ],
                    ),
                  ),
                
                // ✅ Map Section - only show if service has location
                if (_hasLocation())
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.black.withOpacity(0.06)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0B1220),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              height: 300,
                              child: FlutterMap(
                                options: MapOptions(
                                  initialCenter: LatLng(
                                    widget.service.latitude ?? 32.2211,
                                    widget.service.longitude ?? 35.2544,
                                  ),
                                  initialZoom: 15.0,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.example.flutter_application_1',
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: LatLng(
                                          widget.service.latitude ?? 32.2211,
                                          widget.service.longitude ?? 35.2544,
                                        ),
                                        width: 40,
                                        height: 40,
                                        child: const Icon(
                                          Icons.location_pin,
                                          size: 40,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 100), // Space for bottom bar
              ],
            ),
    );
  }

  // ✅ Helper methods for clean display
  bool _hasDescription() {
    final desc1 = _serviceData?['description']?.toString().trim() ?? '';
    final desc2 = widget.service.desc.trim();
    return desc1.isNotEmpty || desc2.isNotEmpty;
  }

  String _getDescription() {
    final desc1 = _serviceData?['description']?.toString().trim() ?? '';
    if (desc1.isNotEmpty) return desc1;
    return widget.service.desc.isNotEmpty ? widget.service.desc : '';
  }

  bool _hasCompanyInfo() {
    final companyName = _serviceData?['companyInfo']?['name']?.toString().trim() ?? 
                        _serviceData?['companyName']?.toString().trim() ??
                        widget.service.company.trim();
    final city = _serviceData?['city']?.toString().trim() ?? '';
    final email = _serviceData?['companyInfo']?['email']?.toString().trim() ?? '';
    final phone = _serviceData?['companyInfo']?['phone']?.toString().trim() ?? '';
    
    return (companyName.isNotEmpty && companyName != 'Unknown' && companyName != 'N/A') ||
           (city.isNotEmpty && city != 'N/A') ||
           (email.isNotEmpty && email != 'N/A') ||
           (phone.isNotEmpty && phone != 'N/A');
  }

  bool _hasLocation() {
    return widget.service.latitude != null && widget.service.longitude != null;
  }

  List<Widget> _buildCompanyInfoRows() {
    final rows = <Widget>[];
    
    // Company Name - from API or fallback to widget
    final companyName = _serviceData?['companyInfo']?['name']?.toString().trim() ?? 
                        _serviceData?['companyName']?.toString().trim() ??
                        widget.service.company.trim();
    if (companyName.isNotEmpty && companyName != 'Unknown' && companyName != 'N/A') {
      rows.add(_InfoRow(icon: Icons.business_rounded, text: companyName));
    }
    
    // City/Location
    final city = _serviceData?['city']?.toString().trim() ?? '';
    if (city.isNotEmpty && city != 'N/A') {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 8));
      rows.add(_InfoRow(icon: Icons.location_on_rounded, text: city));
    }
    
    // Email
    final email = _serviceData?['companyInfo']?['email']?.toString().trim() ?? '';
    if (email.isNotEmpty && email != 'N/A') {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 8));
      rows.add(_InfoRow(icon: Icons.email_rounded, text: email));
    }
    
    // Phone
    final phone = _serviceData?['companyInfo']?['phone']?.toString().trim() ?? '';
    if (phone.isNotEmpty && phone != 'N/A') {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 8));
      rows.add(_InfoRow(icon: Icons.phone_rounded, text: phone));
    }
    
    return rows;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 📋 SERVICE INFORMATION SECTION - Modern Design
  // ══════════════════════════════════════════════════════════════════════════
  
  Widget _buildServiceInformationSection() {
    final venueType = _serviceData?['venueType']?.toString();
    final maxCapacity = _serviceData?['maxCapacity'];
    final minHours = _serviceData?['minBookingHours'];
    final maxHours = _serviceData?['maxBookingHours'];
    final workingDays = _serviceData?['workingDays'] as List?;
    final availableHours = _serviceData?['availableHours'] as List?;
    final bookingType = _bookingType ?? 'hourly';
    final additionalInfo = _serviceData?['additionalInfo'] as Map<String, dynamic>?;
    
    // Check if we have any info to show
    final hasVenueInfo = venueType != null && venueType.isNotEmpty;
    final hasCapacity = maxCapacity != null && maxCapacity > 0;
    final hasBookingHours = (minHours != null && minHours > 0) || (maxHours != null && maxHours > 0);
    final hasWorkingHours = availableHours != null && availableHours.isNotEmpty;
    final hasWorkingDays = workingDays != null && workingDays.isNotEmpty;
    
    // Filter additional info
    final customInfo = <String, dynamic>{};
    if (additionalInfo != null) {
      additionalInfo.forEach((key, value) {
        if (key != 'description' && value != null && value.toString().isNotEmpty) {
          customInfo[key] = value;
        }
      });
    }
    
    final hasCustomInfo = customInfo.isNotEmpty;
    
    // If no info at all, don't show the section
    if (!hasVenueInfo && !hasCapacity && !hasBookingHours && !hasWorkingHours && !hasWorkingDays && !hasCustomInfo) {
      return const SizedBox.shrink();
    }

    // Format working hours (e.g., "9:00 AM - 8:00 PM")
    String? workingHoursStr;
    if (availableHours != null && availableHours.isNotEmpty) {
      final hours = availableHours.map((e) => e as int).toList()..sort();
      if (hours.isNotEmpty) {
        final startHour = hours.first;
        final endHour = hours.last;
        workingHoursStr = '${_formatHour(startHour)} - ${_formatHour(endHour + 1)}';
      }
    }

    // Format working days (e.g., "Sunday - Saturday")
    String? workingDaysStr;
    if (workingDays != null && workingDays.isNotEmpty) {
      if (workingDays.length == 7) {
        workingDaysStr = 'Every Day';
      } else {
        final dayOrder = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
        final sortedDays = workingDays.map((d) => d.toString().toLowerCase()).toList()
          ..sort((a, b) => dayOrder.indexOf(a).compareTo(dayOrder.indexOf(b)));
        
        // Check if consecutive days
        bool isConsecutive = true;
        for (int i = 1; i < sortedDays.length; i++) {
          if (dayOrder.indexOf(sortedDays[i]) - dayOrder.indexOf(sortedDays[i-1]) != 1) {
            isConsecutive = false;
            break;
          }
        }
        
        if (isConsecutive && sortedDays.length > 2) {
          workingDaysStr = '${_capitalizeDay(sortedDays.first)} - ${_capitalizeDay(sortedDays.last)}';
        } else {
          workingDaysStr = sortedDays.map((d) => _capitalizeDay(d)).join(', ');
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kNavBlue.withOpacity(0.15), kNavBlue.withOpacity(0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.info_outline_rounded, color: kNavBlue, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Service Information',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0B1220),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // ═══════════════════════════════════════════
            // SECTION 1: Basic Service Info (Grid Layout)
            // ═══════════════════════════════════════════
            if (hasVenueInfo || hasCapacity || hasBookingHours) ...[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  // Venue Type
                  if (hasVenueInfo)
                    _buildInfoChip(
                      icon: venueType == 'indoor' ? Icons.home_rounded : Icons.park_rounded,
                      label: venueType == 'indoor' ? 'Indoor Venue' : 'Outdoor Venue',
                      color: venueType == 'indoor' ? const Color(0xFF3B82F6) : const Color(0xFF10B981),
                    ),
                  
                  // Max Capacity
                  if (hasCapacity)
                    _buildInfoChip(
                      icon: Icons.groups_rounded,
                      label: '$maxCapacity Guests Max',
                      color: const Color(0xFFF59E0B),
                    ),
                  
                  // Booking Type
                  _buildInfoChip(
                    icon: _getBookingIcon(bookingType),
                    label: _getBookingLabel(bookingType),
                    color: const Color(0xFF6366F1),
                  ),
                  
                  // Min Booking
                  if (minHours != null && minHours > 0)
                    _buildInfoChip(
                      icon: Icons.timer_outlined,
                      label: 'Min $minHours ${minHours == 1 ? 'Hour' : 'Hours'}',
                      color: const Color(0xFF8B5CF6),
                    ),
                  
                  // Max Booking
                  if (maxHours != null && maxHours > 0)
                    _buildInfoChip(
                      icon: Icons.timelapse_rounded,
                      label: 'Max $maxHours Hours',
                      color: const Color(0xFFEC4899),
                    ),
                ],
              ),
            ],
            
            // ═══════════════════════════════════════════
            // SECTION 2: Additional Info
            // ═══════════════════════════════════════════
            if (hasCustomInfo) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.playlist_add_check_rounded, size: 18, color: const Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Text(
                          'Additional Details',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...customInfo.entries.map((entry) => _buildAdditionalInfoRow(entry.key, entry.value.toString())),
                  ],
                ),
              ),
            ],
            
            // ═══════════════════════════════════════════
            // SECTION 3: Working Hours & Days
            // ═══════════════════════════════════════════
            if (hasWorkingHours || hasWorkingDays) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0891B2).withOpacity(0.08),
                      const Color(0xFF06B6D4).withOpacity(0.04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF0891B2).withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    // Working Hours
                    if (workingHoursStr != null)
                      _buildScheduleRow(
                        icon: Icons.access_time_rounded,
                        title: 'Working Hours',
                        value: workingHoursStr,
                        iconColor: const Color(0xFF0891B2),
                      ),
                    
                    if (workingHoursStr != null && workingDaysStr != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: const Color(0xFF0891B2).withOpacity(0.15)),
                      ),
                    
                    // Working Days
                    if (workingDaysStr != null)
                      _buildScheduleRow(
                        icon: Icons.calendar_month_rounded,
                        title: 'Available Days',
                        value: workingDaysStr,
                        iconColor: const Color(0xFF0891B2),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Modern Info Chip Widget
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  // Additional Info Row Widget
  Widget _buildAdditionalInfoRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 7, right: 12),
            decoration: BoxDecoration(
              color: kNavBlue.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$key: ',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Schedule Row Widget (for working hours & days)
  Widget _buildScheduleRow({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper: Format hour to AM/PM
  String _formatHour(int hour) {
    if (hour == 0 || hour == 24) return '12:00 AM';
    if (hour == 12) return '12:00 PM';
    if (hour < 12) return '$hour:00 AM';
    return '${hour - 12}:00 PM';
  }

  // Helper: Capitalize day name
  String _capitalizeDay(String day) {
    if (day.isEmpty) return day;
    return day[0].toUpperCase() + day.substring(1);
  }

  // Helper: Get booking type icon
  IconData _getBookingIcon(String bookingType) {
    switch (bookingType.toLowerCase()) {
      case 'hourly': return Icons.schedule_rounded;
      case 'daily': return Icons.today_rounded;
      case 'capacity': return Icons.people_rounded;
      case 'mixed': return Icons.layers_rounded;
      case 'display': return Icons.visibility_rounded;
      default: return Icons.event_rounded;
    }
  }

  // Helper: Get booking type label
  String _getBookingLabel(String bookingType) {
    switch (bookingType.toLowerCase()) {
      case 'hourly': return 'Hourly Booking';
      case 'daily': return 'Daily Booking';
      case 'capacity': return 'Per Person';
      case 'mixed': return 'Flexible Booking';
      case 'display': return 'Display Only';
      default: return 'Standard Booking';
    }
  }

  Widget _buildPriceSection() {
    final allPrices = _serviceData?['allPrices'] as Map<String, dynamic>?;
    final bookingType = _bookingType?.toLowerCase() ?? 'daily';
    
    String priceLabel;
    double displayPrice = widget.service.price;
    IconData priceIcon;
    
    switch (bookingType) {
      case 'hourly':
        priceLabel = 'per hour';
        priceIcon = Icons.schedule_rounded;
        displayPrice = (allPrices?['perHour'] as num?)?.toDouble() ?? widget.service.price;
        break;
      case 'capacity':
        priceLabel = 'per person';
        priceIcon = Icons.person_rounded;
        displayPrice = (allPrices?['perPerson'] as num?)?.toDouble() ?? widget.service.price;
        break;
      case 'daily':
        priceLabel = 'per day';
        priceIcon = Icons.calendar_today_rounded;
        displayPrice = (allPrices?['perDay'] as num?)?.toDouble() ?? widget.service.price;
        break;
      case 'mixed':
        priceLabel = 'per event';
        priceIcon = Icons.event_rounded;
        displayPrice = (allPrices?['perEvent'] as num?)?.toDouble() ?? widget.service.price;
        break;
      case 'display':
        priceLabel = 'display only';
        priceIcon = Icons.visibility_rounded;
        displayPrice = (allPrices?['displayPrice'] as num?)?.toDouble() ?? widget.service.price;
        break;
      default:
        priceLabel = 'per service';
        priceIcon = Icons.payments_rounded;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kNavBlue.withOpacity(0.08), kNavBlue.withOpacity(0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kNavBlue.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kNavBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(priceIcon, color: kNavBlue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _money(displayPrice),
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: kNavBlue,
                  ),
                ),
                Text(
                  priceLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          if (bookingType == 'display')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'View Only',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.orange.shade800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ✅ Media Slider Widget
  Widget _buildMediaSlider() {
    if (_mediaUrls.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Center(
          child: Icon(Icons.image, size: 48, color: Colors.grey),
        ),
      );
    }

    return Container(
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // PageView Slider
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: PageView.builder(
              controller: _mediaPageController,
              itemCount: _mediaUrls.length,
              onPageChanged: (index) {
                setState(() => _currentMediaIndex = index);
                _resetAutoSlide();
              },
              itemBuilder: (context, index) {
                final url = _mediaUrls[index];
                final isVideo = _isVideoUrl(url);

                if (isVideo) {
                  return GestureDetector(
                    onTap: () => _openFullScreenGallery(index),
                    child: Container(
                      color: Colors.black,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.videocam_rounded,
                              size: 64,
                              color: Colors.white54,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return GestureDetector(
                  onTap: () => _openFullScreenGallery(index),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (_, __) => Container(
                      color: const Color(0xFFF1F5F9),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: const Color(0xFFF1F5F9),
                      child: const Icon(Icons.broken_image, size: 48),
                    ),
                  ),
                );
              },
            ),
          ),

          // Image Counter Badge
          if (_mediaUrls.length > 1)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_library_rounded, size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      '${_currentMediaIndex + 1}/${_mediaUrls.length}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Dot Indicators
          if (_mediaUrls.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_mediaUrls.length, (index) {
                  final isActive = index == _currentMediaIndex;
                  final dotSize = _mediaUrls.length >= 7 ? 6.0 : 8.0;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: EdgeInsets.symmetric(horizontal: _mediaUrls.length >= 7 ? 2 : 3),
                    width: isActive ? (dotSize * 2.5) : dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(dotSize / 2),
                      boxShadow: isActive
                          ? [BoxShadow(color: Colors.black26, blurRadius: 4)]
                          : null,
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  // ✅ Open Full Screen Gallery
  void _openFullScreenGallery(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenGalleryHome(
          mediaUrls: _mediaUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

// ✅ Full Screen Gallery Widget
class _FullScreenGalleryHome extends StatefulWidget {
  final List<String> mediaUrls;
  final int initialIndex;

  const _FullScreenGalleryHome({
    required this.mediaUrls,
    required this.initialIndex,
  });

  @override
  State<_FullScreenGalleryHome> createState() => _FullScreenGalleryHomeState();
}

class _FullScreenGalleryHomeState extends State<_FullScreenGalleryHome> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _isVideoUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.webm');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.mediaUrls.length}',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.mediaUrls.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          final url = widget.mediaUrls[index];
          final isVideo = _isVideoUrl(url);

          if (isVideo) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.videocam_rounded, size: 64, color: Colors.white54),
                  const SizedBox(height: 16),
                  Text(
                    'Video Preview',
                    style: GoogleFonts.poppins(color: Colors.white70),
                  ),
                ],
              ),
            );
          }

          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (_, __) => const CircularProgressIndicator(color: Colors.white),
                errorWidget: (_, __, ___) => const Icon(
                  Icons.broken_image,
                  size: 64,
                  color: Colors.white54,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  
  const _InfoRow({required this.icon, required this.text});
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: kNavBlue),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }
}

// ✅ Helper function - مرة واحدة بس!
int _discountPercent(double original, double discounted) {
  if (original <= 0) return 0;
  final v = ((original - discounted) / original) * 100;
  return v.isNaN ? 0 : v.clamp(0, 95).round();
}

////////////////////////////////////////////////////////////////////////////////
/// ✅ Map Section for Services with Location
////////////////////////////////////////////////////////////////////////////////

class HomeServicesMapSection extends StatefulWidget {
  final List<HomeTrendingService> services;
  final Function(HomeTrendingService) onServiceTap;

  const HomeServicesMapSection({
    Key? key,
    required this.services,
    required this.onServiceTap,
  }) : super(key: key);

  @override
  State<HomeServicesMapSection> createState() => _HomeServicesMapSectionState();
}

class _HomeServicesMapSectionState extends State<HomeServicesMapSection> {
  late MapController _mapController;
  HomeTrendingService? _selectedService;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  LatLng _getCenterPoint() {
    if (widget.services.isEmpty) {
      return const LatLng(32.2211, 35.2544); // Default: Nablus
    }

    double sumLat = 0;
    double sumLng = 0;
    int count = 0;

    for (var service in widget.services) {
      if (service.latitude != null && service.longitude != null) {
        sumLat += service.latitude!;
        sumLng += service.longitude!;
        count++;
      }
    }

    if (count == 0) {
      return const LatLng(32.2211, 35.2544);
    }

    return LatLng(sumLat / count, sumLng / count);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // ✅ Map with OpenStreetMap tiles
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _getCenterPoint(),
                initialZoom: 11.0,
                minZoom: 8.0,
                maxZoom: 18.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.flutter_application_1',
                ),
                // ✅ Red markers for services
                MarkerLayer(
                  markers: widget.services.map((service) {
                    if (service.latitude == null || service.longitude == null) {
                      return null;
                    }

                    final isSelected = _selectedService?.id == service.id;

                    return Marker(
                      width: isSelected ? 50 : 40,
                      height: isSelected ? 50 : 40,
                      point: LatLng(service.latitude!, service.longitude!),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedService = service;
                          });
                          // Move map to service location
                          _mapController.move(
                            LatLng(service.latitude!, service.longitude!),
                            14.0,
                          );
                        },
                        child: Icon(
                          Icons.location_pin,
                          size: isSelected ? 50 : 40,
                          color: Colors.red,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).whereType<Marker>().toList(),
                ),
              ],
            ),

            // ✅ Service info card when selected
            if (_selectedService != null)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => widget.onServiceTap(_selectedService!),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Service image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _selectedService!.imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: _selectedService!.imageUrl,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(
                                    width: 70,
                                    height: 70,
                                    color: kNavBlue.withOpacity(0.1),
                                    child: const Icon(
                                      Icons.business_rounded,
                                      color: kNavBlue,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 70,
                                  height: 70,
                                  color: kNavBlue.withOpacity(0.1),
                                  child: const Icon(
                                    Icons.business_rounded,
                                    color: kNavBlue,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        // Service info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedService!.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1F2937),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _selectedService!.company,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF6B7280),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: kNavBlue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '₪${_selectedService!.price.toStringAsFixed(0)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: kNavBlue,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 18,
                                    color: kNavBlue,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ✅ Close button
            if (_selectedService != null)
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedService = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 20,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// ✅ Modern Favorite Button Widget for Services
class _FavoriteButton extends StatefulWidget {
  final String serviceId;
  final String serviceName;
  final String category;
  final String company;
  final double price;
  final double rating;
  final String? imageUrl;

  const _FavoriteButton({
    required this.serviceId,
    required this.serviceName,
    required this.category,
    required this.company,
    required this.price,
    required this.rating,
    this.imageUrl,
  });

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isFavorite = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _checkFavoriteStatus();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkFavoriteStatus() async {
    await FavoritesService.instance.init();
    if (mounted) {
      setState(() {
        _isFavorite = FavoritesService.instance.isServiceFavorite(widget.serviceId);
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;
    
    // Animate
    _controller.forward().then((_) => _controller.reverse());

    setState(() {
      _isLoading = true;
      _isFavorite = !_isFavorite; // Optimistic update
    });

    final success = await FavoritesService.instance.toggleServiceFavorite(widget.serviceId);
    
    if (!success && mounted) {
      // Revert on failure
      setState(() {
        _isFavorite = !_isFavorite;
      });
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }

    // Show snackbar
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _isFavorite 
                    ? 'Added to your favorites!' 
                    : 'Removed from favorites',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: _isFavorite ? const Color(0xFF10B981) : const Color(0xFF64748B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'VIEW',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavoritesPage()),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _isFavorite 
              ? const Color(0xFFFF4B6E).withOpacity(0.1) 
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          onPressed: _toggleFavorite,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: child,
            ),
            child: Icon(
              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              key: ValueKey(_isFavorite),
              color: _isFavorite ? const Color(0xFFFF4B6E) : const Color(0xFF64748B),
              size: 22,
            ),
          ),
          tooltip: _isFavorite ? 'Remove from favorites' : 'Add to favorites',
        ),
      ),
    );
  }
}