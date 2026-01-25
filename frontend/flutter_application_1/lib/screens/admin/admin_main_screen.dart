import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:async';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/reviews_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/service_sales_screen.dart';
import 'screens/package_sales_screen.dart';
import 'screens/verification_requests_screen.dart';
import 'package:flutter_application_1/screens/signin.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/admin_service/admin_service.dart';
import 'package:flutter_application_1/services/socket_service.dart';

class AdminMainScreen extends StatefulWidget {
  final String adminName;
  
  const AdminMainScreen({
    super.key,
    this.adminName = 'Admin',
  });

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;
  int _unreadNotifications = 0;
  int _unreadMessages = 0;
  StreamSubscription? _notificationSubscription;
  StreamSubscription? _messageSubscription;
  int _notificationKey = 0;
  bool _isSidebarCollapsed = false;

  // Navigation items for sidebar
  final List<_NavItem> _navItems = [
    _NavItem(icon: LucideIcons.layoutDashboard, label: 'Dashboard', index: 0),
    _NavItem(icon: LucideIcons.star, label: 'Reviews', index: 1),
    _NavItem(icon: LucideIcons.messageCircle, label: 'Messages', index: 2),
    _NavItem(icon: LucideIcons.bell, label: 'Notifications', index: 3),
    _NavItem(icon: LucideIcons.briefcase, label: 'Services', index: 4),
    _NavItem(icon: LucideIcons.package, label: 'Packages', index: 5),
    _NavItem(icon: LucideIcons.shieldCheck, label: 'Verification', index: 6),
  ];

  @override
  void initState() {
    super.initState();
    _fetchUnreadCounts();
    _setupRealtimeUpdates();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _messageSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchUnreadCounts() async {
    try {
      if (_currentIndex != 3) {
        final notifCount = await AdminService.getUnreadNotificationsCount();
        if (mounted && _currentIndex != 3) {
          setState(() => _unreadNotifications = notifCount);
        }
      }
      
      if (_currentIndex != 2) {
        final msgCount = await AdminService.getUnreadMessagesCount();
        if (mounted && _currentIndex != 2) {
          setState(() => _unreadMessages = msgCount);
        }
      }
    } catch (e) {
      print('❌ Error fetching unread counts: $e');
    }
  }

  void _setupRealtimeUpdates() {
    _notificationSubscription = SocketService.notificationStream.listen((data) {
      _fetchUnreadCounts();
    });
    
    _messageSubscription = SocketService.messageStream.listen((data) {
      _fetchUnreadCounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;
        
        if (isDesktop || (isTablet && kIsWeb)) {
          return _buildWebLayout(context, isCollapsed: isTablet);
        } else {
          return _buildMobileLayout(context);
        }
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 🖥️ WEB/DESKTOP LAYOUT - Sidebar + TopBar + Content
  // ═══════════════════════════════════════════════════════════════
  Widget _buildWebLayout(BuildContext context, {bool isCollapsed = false}) {
    final sidebarWidth = _isSidebarCollapsed || isCollapsed ? 80.0 : 260.0;
    
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Row(
        children: [
          // ═══ SIDEBAR ═══
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: sidebarWidth,
            child: _buildSidebar(isCollapsed: _isSidebarCollapsed || isCollapsed),
          ),
          
          // ═══ MAIN CONTENT AREA ═══
          Expanded(
            child: Column(
              children: [
                // ═══ TOP BAR ═══
                _buildTopBar(),
                
                // ═══ PAGE CONTENT ═══
                Expanded(
                  child: _buildPageContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 📱 MOBILE LAYOUT - Bottom Navigation
  // ═══════════════════════════════════════════════════════════════
  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _getTitle(),
          style: GoogleFonts.poppins(
            color: kTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          _buildProfileButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildPageContent(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 🎨 SIDEBAR WIDGET
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSidebar({bool isCollapsed = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // ═══ LOGO HEADER ═══
          Container(
            height: 72,
            padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 16 : 24),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade100),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.partyPopper,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Eventry',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: kTextColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // ═══ NAVIGATION ITEMS ═══
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              children: [
                if (!isCollapsed)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 12),
                    child: Text(
                      'MAIN MENU',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade400,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ..._navItems.map((item) => _buildSidebarItem(
                  item: item,
                  isCollapsed: isCollapsed,
                  badgeCount: item.index == 2 ? _unreadMessages : 
                             item.index == 3 ? _unreadNotifications : 0,
                )),
              ],
            ),
          ),
          
          // ═══ COLLAPSE BUTTON ═══
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade100),
              ),
            ),
            child: _HoverButton(
              onTap: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isSidebarCollapsed ? LucideIcons.chevronsRight : LucideIcons.chevronsLeft,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                    if (!isCollapsed) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Collapse',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          
          // ═══ LOGOUT BUTTON ═══
          Container(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: _HoverButton(
              onTap: _logout,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.logOut, size: 18, color: Colors.red.shade600),
                    if (!isCollapsed) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Logout',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
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

  Widget _buildSidebarItem({
    required _NavItem item,
    required bool isCollapsed,
    int badgeCount = 0,
  }) {
    final isSelected = _currentIndex == item.index;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: _HoverButton(
        onTap: () => _onNavTap(item.index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: isCollapsed ? 12 : 16,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: isSelected ? kPrimaryColor.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected 
                ? Border.all(color: kPrimaryColor.withOpacity(0.2))
                : null,
          ),
          child: Row(
            mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    item.icon,
                    size: 20,
                    color: isSelected ? kPrimaryColor : Colors.grey.shade500,
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -8,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          badgeCount > 9 ? '9+' : '$badgeCount',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.label,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? kPrimaryColor : Colors.grey.shade700,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: kPrimaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 🔝 TOP BAR WIDGET (Web only)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildTopBar() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ═══ PAGE TITLE ═══
          Text(
            _getTitle(),
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: kTextColor,
            ),
          ),
          
          const Spacer(),
          
          // ═══ NOTIFICATION BELL ═══
          _HoverButton(
            onTap: () => _onNavTap(3),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _currentIndex == 3 ? kPrimaryColor.withOpacity(0.1) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    LucideIcons.bell,
                    size: 20,
                    color: _currentIndex == 3 ? kPrimaryColor : Colors.grey.shade600,
                  ),
                  if (_unreadNotifications > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          _unreadNotifications > 9 ? '9+' : '$_unreadNotifications',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // ═══ MESSAGES ═══
          _HoverButton(
            onTap: () => _onNavTap(2),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _currentIndex == 2 ? kPrimaryColor.withOpacity(0.1) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    LucideIcons.messageCircle,
                    size: 20,
                    color: _currentIndex == 2 ? kPrimaryColor : Colors.grey.shade600,
                  ),
                  if (_unreadMessages > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          _unreadMessages > 9 ? '9+' : '$_unreadMessages',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 20),
          
          // ═══ DIVIDER ═══
          Container(
            width: 1,
            height: 32,
            color: Colors.grey.shade200,
          ),
          
          const SizedBox(width: 20),
          
          // ═══ PROFILE ═══
          _HoverButton(
            onTap: () {},
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: kPrimaryColor.withOpacity(0.3), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: kPrimaryColor.withOpacity(0.1),
                    child: Text(
                      widget.adminName[0].toUpperCase(),
                      style: GoogleFonts.poppins(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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
                      widget.adminName,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kTextColor,
                      ),
                    ),
                    Text(
                      'Administrator',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(LucideIcons.chevronDown, size: 16, color: Colors.grey.shade400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 📄 PAGE CONTENT
  // ═══════════════════════════════════════════════════════════════
  Widget _buildPageContent() {
    switch (_currentIndex) {
      case 0:
        return const HomeScreen();
      case 1:
        return const ReviewsScreen();
      case 2:
        return const MessagesScreen();
      case 3:
        return NotificationsScreen(key: ValueKey(_notificationKey));
      case 4:
        return const ServiceSalesScreen();
      case 5:
        return const PackageSalesScreen();
      case 6:
        return const VerificationRequestsScreen();
      default:
        return const HomeScreen();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 📱 BOTTOM NAV BAR (Mobile only)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, LucideIcons.home, 'Home'),
              _buildNavItem(1, LucideIcons.star, 'Reviews'),
              _buildNavItem(6, LucideIcons.shieldCheck, 'Verify'),
              _buildNavItem(2, LucideIcons.messageCircle, 'Chat', badgeCount: _unreadMessages),
              _buildNavItem(3, LucideIcons.bell, 'Alerts', badgeCount: _unreadNotifications),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {int badgeCount = 0}) {
    final isSelected = _currentIndex == index;
    
    return InkWell(
      onTap: () => _onNavTap(index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: isSelected ? kPrimaryColor : Colors.grey[500], size: 20),
                if (badgeCount > 0)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? kPrimaryColor : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileButton() {
    return PopupMenuButton<String>(
      icon: CircleAvatar(
        backgroundColor: kPrimaryColor.withOpacity(0.1),
        child: Text(
          widget.adminName[0].toUpperCase(),
          style: GoogleFonts.poppins(color: kPrimaryColor, fontWeight: FontWeight.bold),
        ),
      ),
      onSelected: (value) {
        if (value == 'logout') _logout();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              const Icon(LucideIcons.user, size: 18),
              const SizedBox(width: 8),
              Text(widget.adminName, style: GoogleFonts.poppins()),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(LucideIcons.logOut, size: 18, color: Colors.red[600]),
              const SizedBox(width: 8),
              Text('Logout', style: GoogleFonts.poppins(color: Colors.red[600])),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 🔧 HELPERS
  // ═══════════════════════════════════════════════════════════════
  String _getTitle() {
    switch (_currentIndex) {
      case 0: return 'Dashboard';
      case 1: return 'Reviews';
      case 2: return 'Messages';
      case 3: return 'Notifications';
      case 4: return 'Services';
      case 5: return 'Packages';
      case 6: return 'Verification';
      default: return 'Admin';
    }
  }

  Future<void> _onNavTap(int index) async {
    if (_currentIndex == 3 && index != 3) {
      try {
        await AdminService.markAllNotificationsAsRead();
        _notificationKey++;
      } catch (e) {
        print('❌ Error marking notifications: $e');
      }
    }
    
    if (mounted) {
      setState(() {
        _currentIndex = index;
        if (index == 2) _unreadMessages = 0;
        if (index == 3) _unreadNotifications = 0;
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Logout', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to logout?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Logout', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.clearAuth();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SignInScreen()),
          (route) => false,
        );
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// 📦 HELPER CLASSES
// ═══════════════════════════════════════════════════════════════

class _NavItem {
  final IconData icon;
  final String label;
  final int index;
  
  const _NavItem({required this.icon, required this.label, required this.index});
}

/// Hover effect wrapper for web
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
          child: AnimatedScale(
            duration: const Duration(milliseconds: 150),
            scale: _isHovered ? 1.02 : 1.0,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
