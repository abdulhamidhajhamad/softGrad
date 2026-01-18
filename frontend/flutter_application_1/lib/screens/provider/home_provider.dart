import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/notification_provider_service.dart';
import 'package:flutter_application_1/services/booked_provider_service.dart';
import 'package:flutter_application_1/services/chat_provider_service.dart';
import 'package:flutter_application_1/services/offer_service.dart';

// Local imports
import 'finance_provider.dart';
import 'offers_provider.dart';

// Other screens
import 'package:flutter_application_1/screens/edit_profile_provider.dart';
import 'package:flutter_application_1/screens/services_provider.dart';
import 'package:flutter_application_1/screens/signin.dart';
import 'package:flutter_application_1/screens/provider/booking_provider.dart';
import 'package:flutter_application_1/screens/messages_provider.dart';
import 'package:flutter_application_1/screens/notifications_provider.dart';
import 'package:flutter_application_1/screens/reviews_provider.dart';
import 'package:flutter_application_1/screens/provider/packages_provider.dart';

// ============================================================================
// 🎨 THEME COLORS
// ============================================================================
const Color kPrimaryColor = Color(0xFF6C63FF);
const Color kPrimaryLight = Color(0xFFE8E6FF);
const Color kBackgroundColor = Color(0xFFF8F9FC);
const Color kCardColor = Colors.white;
const Color kTextPrimary = Color(0xFF1A1D26);
const Color kTextSecondary = Color(0xFF6B7280);
const Color kSuccessColor = Color(0xFF10B981);
const Color kWarningColor = Color(0xFFFF6B35);

// ============================================================================
// 🏠 PROVIDER MODEL
// ============================================================================
class ProviderModel {
  final String brandName;
  final String email;
  final String phone;
  final String description;
  final String city;

  int? bookings;
  int? views;
  int? messages;
  int? reviews;

  ProviderModel({
    required this.brandName,
    required this.email,
    required this.phone,
    required this.description,
    required this.city,
    this.bookings,
    this.views,
    this.messages,
    this.reviews,
  });
}

// ============================================================================
// 🏠 HOME PROVIDER SCREEN
// ============================================================================
class HomeProviderScreen extends StatefulWidget {
  final ProviderModel provider;

  const HomeProviderScreen({Key? key, required this.provider}) : super(key: key);

  @override
  State<HomeProviderScreen> createState() => _HomeProviderScreenState();
}

class _HomeProviderScreenState extends State<HomeProviderScreen>
    with WidgetsBindingObserver {
  late ProviderModel provider;
  int _activeOffersCount = 0;
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    provider = widget.provider;
    _loadActiveOffersCount();
    WidgetsBinding.instance.addObserver(this);
    _initializeConnections();
  }

  Future<void> _loadActiveOffersCount() async {
    final result = await OfferService.getMyServicesWithOffers();
    if (result['success'] == true && mounted) {
      setState(() {
        _activeOffersCount = (result['activeOffers'] as List?)?.length ?? 0;
      });
    }
  }

  Future<void> _initializeConnections() async {
    debugPrint('🚀 Initializing real-time connections...');
    await NotificationProviderService.initRealtimeNotifications();
    await _updateUnreadCount();
    await BookedProviderService.fetchUnseenCount();
    await _initializeChatConnection();

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && !NotificationProviderService.isConnected()) {
        NotificationProviderService.reconnect();
      }
    });
  }

  Future<void> _initializeChatConnection() async {
    try {
      final userData = await AuthService.getUserData();
      final userId =
          userData?['_id']?.toString() ?? userData?['id']?.toString();
      if (userId != null) {
        ChatProviderService().currentUserId = userId;
        await ChatProviderService().initSocket();
        await ChatProviderService().fetchUnreadCount();
      }
    } catch (e) {
      debugPrint('❌ Error initializing chat: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _initializeConnections();
    }
  }

  Future<void> _updateUnreadCount() async {
    if (!mounted) return;
    await NotificationProviderService.updateUnreadCountOnConnect();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _handleSignOut() async {
    NotificationProviderService.closeRealtimeConnection();
    await AuthService.deleteToken();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => SignInScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1100;
        final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1100;
        
        if (isDesktop || isTablet) {
          return _buildWebLayout(isDesktop);
        }
        return _buildMobileLayout();
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 🌐 WEB LAYOUT - Sidebar + TopBar + Content
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildWebLayout(bool isDesktop) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Row(
        children: [
          // ═══ SIDEBAR ═══
          _buildSidebar(isDesktop),
          
          // ═══ MAIN CONTENT ═══
          Expanded(
            child: Column(
              children: [
                // ═══ TOP BAR ═══
                _buildTopBar(),
                
                // ═══ CONTENT AREA ═══
                Expanded(
                  child: _buildWebContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 📱 SIDEBAR
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSidebar(bool isDesktop) {
    final sidebarWidth = _isSidebarCollapsed ? 80.0 : 280.0;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: kCardColor,
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // ═══ LOGO HEADER ═══
          Container(
            height: 80,
            padding: EdgeInsets.symmetric(horizontal: _isSidebarCollapsed ? 16 : 24),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(LucideIcons.store, color: Colors.white, size: 24),
                ),
                if (!_isSidebarCollapsed) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Provider Hub',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: kTextPrimary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          Divider(color: Colors.grey.shade200, height: 1),
          
          // ═══ NAV ITEMS ═══
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  _buildNavItem(0, LucideIcons.layoutDashboard, 'Dashboard'),
                  _buildNavItem(1, LucideIcons.calendarCheck, 'Bookings'),
                  _buildNavItem(2, LucideIcons.messageSquare, 'Messages'),
                  _buildNavItem(3, LucideIcons.bell, 'Notifications'),
                  
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: _isSidebarCollapsed ? 16 : 24,
                      vertical: 16,
                    ),
                    child: Divider(color: Colors.grey.shade200),
                  ),
                  
                  if (!_isSidebarCollapsed)
                    Padding(
                      padding: const EdgeInsets.only(left: 24, bottom: 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'MANAGEMENT',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: kTextSecondary,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  
                  _buildNavItem(4, LucideIcons.sparkles, 'Services'),
                  _buildNavItem(5, LucideIcons.package, 'Packages'),
                  _buildNavItem(6, LucideIcons.tag, 'Offers'),
                  _buildNavItem(7, LucideIcons.wallet, 'Finance'),
                  _buildNavItem(8, LucideIcons.star, 'Reviews'),
                ],
              ),
            ),
          ),
          
          // ═══ COLLAPSE BUTTON ═══
          Divider(color: Colors.grey.shade200, height: 1),
          InkWell(
            onTap: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
            child: Container(
              height: 56,
              padding: EdgeInsets.symmetric(horizontal: _isSidebarCollapsed ? 0 : 24),
              child: Row(
                mainAxisAlignment: _isSidebarCollapsed 
                    ? MainAxisAlignment.center 
                    : MainAxisAlignment.start,
                children: [
                  Icon(
                    _isSidebarCollapsed 
                        ? LucideIcons.chevronsRight 
                        : LucideIcons.chevronsLeft,
                    size: 20,
                    color: kTextSecondary,
                  ),
                  if (!_isSidebarCollapsed) ...[
                    const SizedBox(width: 12),
                    Text(
                      'Collapse',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: kTextSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // ═══ SIGN OUT ═══
          Container(
            padding: EdgeInsets.all(_isSidebarCollapsed ? 16 : 20),
            child: _HoverButton(
              onTap: _handleSignOut,
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: _isSidebarCollapsed ? 0 : 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: _isSidebarCollapsed 
                      ? MainAxisAlignment.center 
                      : MainAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.logOut, size: 20, color: Colors.red.shade600),
                    if (!_isSidebarCollapsed) ...[
                      const SizedBox(width: 12),
                      Text(
                        'Sign Out',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    
    // Badge counts
    Widget? badge;
    if (index == 1) {
      badge = ValueListenableBuilder<int>(
        valueListenable: BookedProviderService.unseenCountNotifier,
        builder: (_, count, __) => count > 0 ? _buildBadge(count) : const SizedBox.shrink(),
      );
    } else if (index == 2) {
      badge = ValueListenableBuilder<int>(
        valueListenable: ChatProviderService.unreadGlobalCount,
        builder: (_, count, __) => count > 0 ? _buildBadge(count) : const SizedBox.shrink(),
      );
    } else if (index == 3) {
      badge = ValueListenableBuilder<bool>(
        valueListenable: NotificationProviderService.hasUnreadNotifier,
        builder: (_, hasUnread, __) => hasUnread ? _buildDot() : const SizedBox.shrink(),
      );
    } else if (index == 6 && _activeOffersCount > 0) {
      badge = _buildBadge(_activeOffersCount);
    }
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _isSidebarCollapsed ? 12 : 16,
        vertical: 4,
      ),
      child: _HoverButton(
        onTap: () => _handleNavigation(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            vertical: 14,
            horizontal: _isSidebarCollapsed ? 0 : 16,
          ),
          decoration: BoxDecoration(
            color: isSelected ? kPrimaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: _isSidebarCollapsed 
                ? MainAxisAlignment.center 
                : MainAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: isSelected ? Colors.white : kTextSecondary,
                  ),
                  if (badge != null && _isSidebarCollapsed)
                    Positioned(right: -6, top: -6, child: badge),
                ],
              ),
              if (!_isSidebarCollapsed) ...[
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : kTextSecondary,
                    ),
                  ),
                ),
                if (badge != null) badge,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildDot() {
    return Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
    );
  }

  void _handleNavigation(int index) {
    setState(() => _selectedIndex = index);
    
    switch (index) {
      case 0:
        // Dashboard - stay here
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingsScreen()));
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesProviderScreen()));
        break;
      case 3:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsProviderScreen()));
        break;
      case 4:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ServicesProviderScreen()));
        break;
      case 5:
        Navigator.push(context, MaterialPageRoute(builder: (_) => PackagesProviderScreen()));
        break;
      case 6:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const OffersProviderScreen()));
        break;
      case 7:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const FinanceProviderScreen()));
        break;
      case 8:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewsProviderScreen()));
        break;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 🔝 TOP BAR
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildTopBar() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: kCardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Welcome Text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back! 👋',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: kTextSecondary,
                ),
              ),
              Text(
                provider.brandName,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: kTextPrimary,
                ),
              ),
            ],
          ),
          
          const Spacer(),
          
          // Quick Action Buttons
          _TopBarButton(
            icon: LucideIcons.calendarCheck,
            label: 'Bookings',
            notificationBuilder: () => ValueListenableBuilder<int>(
              valueListenable: BookedProviderService.unseenCountNotifier,
              builder: (_, count, __) => count > 0 ? _buildBadge(count) : const SizedBox.shrink(),
            ),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingsScreen())),
          ),
          const SizedBox(width: 12),
          _TopBarButton(
            icon: LucideIcons.messageSquare,
            label: 'Messages',
            notificationBuilder: () => ValueListenableBuilder<int>(
              valueListenable: ChatProviderService.unreadGlobalCount,
              builder: (_, count, __) => count > 0 ? _buildBadge(count) : const SizedBox.shrink(),
            ),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesProviderScreen())),
          ),
          const SizedBox(width: 12),
          _TopBarButton(
            icon: LucideIcons.bell,
            label: 'Alerts',
            notificationBuilder: () => ValueListenableBuilder<bool>(
              valueListenable: NotificationProviderService.hasUnreadNotifier,
              builder: (_, hasUnread, __) => hasUnread ? _buildDot() : const SizedBox.shrink(),
            ),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsProviderScreen())),
          ),
          
          const SizedBox(width: 24),
          Container(width: 1, height: 40, color: Colors.grey.shade200),
          const SizedBox(width: 24),
          
          // Profile
          _HoverButton(
            onTap: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditProfileProvider(provider: provider)),
              );
              if (updated != null && updated is ProviderModel) {
                setState(() => provider = updated);
              }
            },
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      provider.brandName.isNotEmpty ? provider.brandName[0].toUpperCase() : '?',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.brandName,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kTextPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(LucideIcons.mapPin, size: 12, color: kTextSecondary),
                        const SizedBox(width: 4),
                        Text(
                          provider.city,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: kTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(LucideIcons.chevronDown, size: 18, color: kTextSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 📊 WEB CONTENT - Dashboard Grid
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildWebContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══ WELCOME BANNER ═══
          _buildWelcomeBanner(),
          const SizedBox(height: 28),
          
          // ═══ STATS ROW ═══
          Row(
            children: [
              Expanded(child: _buildWebStatCard(
                icon: LucideIcons.calendarCheck,
                title: 'Bookings',
                color: kPrimaryColor,
                valueBuilder: () => ValueListenableBuilder<int>(
                  valueListenable: BookedProviderService.unseenCountNotifier,
                  builder: (_, count, __) => Text(
                    count > 0 ? '$count New' : '0',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: kTextPrimary,
                    ),
                  ),
                ),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingsScreen())),
              )),
              const SizedBox(width: 20),
              Expanded(child: _buildWebStatCard(
                icon: LucideIcons.messageSquare,
                title: 'Messages',
                color: kSuccessColor,
                valueBuilder: () => ValueListenableBuilder<int>(
                  valueListenable: ChatProviderService.unreadGlobalCount,
                  builder: (_, count, __) => Text(
                    count > 0 ? '$count New' : '0',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: kTextPrimary,
                    ),
                  ),
                ),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesProviderScreen())),
              )),
              const SizedBox(width: 20),
              Expanded(child: _buildWebStatCard(
                icon: LucideIcons.bell,
                title: 'Notifications',
                color: kWarningColor,
                valueBuilder: () => ValueListenableBuilder<bool>(
                  valueListenable: NotificationProviderService.hasUnreadNotifier,
                  builder: (_, hasUnread, __) => Text(
                    hasUnread ? 'New' : '0',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: kTextPrimary,
                    ),
                  ),
                ),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsProviderScreen())),
              )),
              const SizedBox(width: 20),
              Expanded(child: _buildWebStatCard(
                icon: LucideIcons.tag,
                title: 'Active Offers',
                color: Colors.purple,
                valueBuilder: () => Text(
                  '$_activeOffersCount',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: kTextPrimary,
                  ),
                ),
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const OffersProviderScreen()));
                  _loadActiveOffersCount();
                },
              )),
            ],
          ),
          const SizedBox(height: 28),
          
          // ═══ QUICK ACTIONS + BUSINESS INFO ═══
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Actions
              Expanded(
                flex: 2,
                child: _buildQuickActionsCard(),
              ),
              const SizedBox(width: 24),
              // Business Info
              Expanded(
                flex: 1,
                child: _buildBusinessInfoCard(),
              ),
            ],
          ),
          const SizedBox(height: 28),
          
          // ═══ MANAGEMENT SECTION ═══
          Text(
            'Business Management',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildManagementCard(
                icon: LucideIcons.wallet,
                title: 'Finance Overview',
                subtitle: 'Track revenue & insights',
                color: kSuccessColor,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FinanceProviderScreen())),
              )),
              const SizedBox(width: 20),
              Expanded(child: _buildManagementCard(
                icon: LucideIcons.package,
                title: 'Packages',
                subtitle: 'Create & manage packages',
                color: kPrimaryColor,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PackagesProviderScreen())),
              )),
              const SizedBox(width: 20),
              Expanded(child: _buildManagementCard(
                icon: LucideIcons.tag,
                title: 'Offers & Discounts',
                subtitle: _activeOffersCount > 0 ? '$_activeOffersCount active offers' : 'Create special offers',
                color: kWarningColor,
                badge: _activeOffersCount > 0 ? '$_activeOffersCount' : null,
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const OffersProviderScreen()));
                  _loadActiveOffersCount();
                },
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.3),
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
                Text(
                  'Welcome to your Dashboard! 🎉',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your services, track bookings, and grow your business all in one place.',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _HoverButton(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServicesProviderScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(LucideIcons.sparkles, size: 18, color: kPrimaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Manage Services',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: kPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _HoverButton(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingsScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.calendarCheck, size: 18, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'View Bookings',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(LucideIcons.layoutDashboard, size: 56, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildWebStatCard({
    required IconData icon,
    required String title,
    required Color color,
    required Widget Function() valueBuilder,
    required VoidCallback onTap,
  }) {
    return _HoverCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 24, color: color),
                ),
                Icon(LucideIcons.arrowUpRight, size: 18, color: kTextSecondary),
              ],
            ),
            const SizedBox(height: 20),
            valueBuilder(),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: kTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kPrimaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(LucideIcons.zap, size: 20, color: kPrimaryColor),
              ),
              const SizedBox(width: 14),
              Text(
                'Quick Actions',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: kTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildQuickActionTile(
                icon: LucideIcons.sparkles,
                title: 'Services',
                subtitle: 'Manage your services',
                color: kPrimaryColor,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServicesProviderScreen())),
              )),
              const SizedBox(width: 16),
              Expanded(child: _buildQuickActionTile(
                icon: LucideIcons.star,
                title: 'Reviews',
                subtitle: 'View all reviews',
                color: const Color(0xFFFFB800),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewsProviderScreen())),
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return _HoverCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: kTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInfoCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kPrimaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(LucideIcons.building, size: 20, color: kPrimaryColor),
              ),
              const SizedBox(width: 14),
              Text(
                'Business Info',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: kTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (provider.description.isNotEmpty) ...[
            Text(
              provider.description,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: kTextSecondary,
                height: 1.6,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 16),
          ],
          _buildInfoRow(LucideIcons.mail, 'Email', provider.email),
          const SizedBox(height: 16),
          _buildInfoRow(LucideIcons.phone, 'Phone', provider.phone),
          const SizedBox(height: 16),
          _buildInfoRow(LucideIcons.mapPin, 'Location', provider.city),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: kBackgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: kPrimaryColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: kTextSecondary,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManagementCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    String? badge,
    required VoidCallback onTap,
  }) {
    return _HoverCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 26, color: color),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: kTextPrimary,
                          ),
                        ),
                      ),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            badge,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: kTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(LucideIcons.chevronRight, size: 20, color: kTextSecondary),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 📱 MOBILE LAYOUT - Original Design
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildMobileHeader()),
            SliverToBoxAdapter(child: _buildMobileQuickStats()),
            SliverToBoxAdapter(child: _buildMobileMainActions()),
            SliverToBoxAdapter(child: _buildMobileManagementSection()),
            SliverToBoxAdapter(child: _buildMobileAboutSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MobileIconBtn(
                icon: Icons.menu_rounded,
                onTap: _showMenuSheet,
              ),
              Text(
                "Dashboard",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                ),
              ),
              _MobileIconBtn(
                icon: Icons.settings_outlined,
                onTap: () async {
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfileProvider(provider: provider),
                    ),
                  );
                  if (updated != null && updated is ProviderModel) {
                    setState(() => provider = updated);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    provider.brandName.isNotEmpty
                        ? provider.brandName[0].toUpperCase()
                        : "?",
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.brandName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 16, color: kTextSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            provider.city,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(fontSize: 13, color: kTextSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileQuickStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: ValueListenableBuilder<int>(
              valueListenable: BookedProviderService.unseenCountNotifier,
              builder: (context, count, _) {
                return _MobileStatCard(
                  icon: Icons.calendar_today_rounded,
                  label: "Bookings",
                  value: count > 0 ? "$count New" : "0",
                  color: kPrimaryColor,
                  hasNotification: count > 0,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BookingsScreen()),
                    );
                    BookedProviderService.fetchUnseenCount();
                  },
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ValueListenableBuilder<int>(
              valueListenable: ChatProviderService.unreadGlobalCount,
              builder: (context, count, _) {
                return _MobileStatCard(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: "Messages",
                  value: count > 0 ? "$count New" : "0",
                  color: kSuccessColor,
                  hasNotification: count > 0,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MessagesProviderScreen()),
                    );
                    ChatProviderService().fetchUnreadCount();
                  },
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: NotificationProviderService.hasUnreadNotifier,
              builder: (context, hasUnread, _) {
                return _MobileStatCard(
                  icon: Icons.notifications_none_rounded,
                  label: "Alerts",
                  value: hasUnread ? "New" : "0",
                  color: kWarningColor,
                  hasNotification: hasUnread,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsProviderScreen()),
                    );
                    _updateUnreadCount();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileMainActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quick Actions",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MobileActionCard(
                  icon: Icons.auto_awesome_rounded,
                  title: "Services",
                  subtitle: "Manage",
                  color: kPrimaryColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ServicesProviderScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MobileActionCard(
                  icon: Icons.star_outline_rounded,
                  title: "Reviews",
                  subtitle: "View All",
                  color: const Color(0xFFFFB800),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReviewsProviderScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileManagementSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Business Management",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _MobileManagementTile(
            icon: Icons.account_balance_wallet_rounded,
            title: "Finance Overview",
            subtitle: "Track revenue & insights",
            color: kSuccessColor,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FinanceProviderScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _MobileManagementTile(
            icon: Icons.inventory_2_rounded,
            title: "Packages",
            subtitle: "Create & manage packages",
            color: kPrimaryColor,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PackagesProviderScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _MobileManagementTile(
            icon: Icons.local_offer_rounded,
            title: "Offers & Discounts",
            subtitle: _activeOffersCount > 0
                ? "$_activeOffersCount active offers"
                : "Create special offers",
            color: kWarningColor,
            badge: _activeOffersCount > 0 ? "$_activeOffersCount" : null,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OffersProviderScreen()),
              );
              _loadActiveOffersCount();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileAboutSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Business Info",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kCardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (provider.description.isNotEmpty) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kPrimaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.info_outline_rounded, size: 18, color: kPrimaryColor),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "About",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: kTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    provider.description,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: kTextSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 16),
                ],
                _MobileContactRow(
                  icon: Icons.email_outlined,
                  label: "Email",
                  value: provider.email,
                ),
                const SizedBox(height: 16),
                _MobileContactRow(
                  icon: Icons.phone_outlined,
                  label: "Phone",
                  value: provider.phone,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMenuSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                _MobileMenuTile(
                  icon: Icons.notifications_none_rounded,
                  title: "Notifications",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsProviderScreen()),
                    );
                  },
                ),
                _MobileMenuTile(
                  icon: Icons.settings_outlined,
                  title: "Settings",
                  onTap: () async {
                    Navigator.pop(context);
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfileProvider(provider: provider),
                      ),
                    );
                    if (updated != null && updated is ProviderModel) {
                      setState(() => provider = updated);
                    }
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(),
                ),
                _MobileMenuTile(
                  icon: Icons.logout_rounded,
                  title: "Sign Out",
                  isDestructive: true,
                  onTap: () {
                    Navigator.pop(context);
                    _handleSignOut();
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 🧩 WEB WIDGETS
// ════════════════════════════════════════════════════════════════════════════

class _HoverButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _HoverButton({required this.child, required this.onTap});

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: _isHovered ? 0.8 : 1.0,
          child: widget.child,
        ),
      ),
    );
  }
}

class _HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _HoverCard({required this.child, required this.onTap});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..translate(0.0, _isHovered ? -4.0 : 0.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: kPrimaryColor.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : [],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget Function() notificationBuilder;
  final VoidCallback onTap;

  const _TopBarButton({
    required this.icon,
    required this.label,
    required this.notificationBuilder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _HoverButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: kBackgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 20, color: kTextSecondary),
                Positioned(
                  right: -4,
                  top: -4,
                  child: notificationBuilder(),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: kTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 🧩 MOBILE WIDGETS
// ════════════════════════════════════════════════════════════════════════════

class _MobileIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MobileIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kPrimaryLight,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Icon(icon, color: kPrimaryColor, size: 22),
        ),
      ),
    );
  }
}

class _MobileStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool hasNotification;
  final VoidCallback onTap;

  const _MobileStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
    this.hasNotification = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kCardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  if (hasNotification)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: kCardColor, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: kTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MobileActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kCardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: kTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileManagementTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _MobileManagementTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kCardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: kTextPrimary,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              badge!,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: kTextSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MobileContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kPrimaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: kPrimaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: kTextSecondary,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: kTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MobileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MobileMenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red : kTextPrimary;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      onTap: onTap,
    );
  }
}
