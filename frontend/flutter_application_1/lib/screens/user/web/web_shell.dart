// lib/screens/user/web/web_shell.dart
//
// ✅ Web Layout Shell with Sidebar Navigation
// ✅ Modern, clean, and responsive
// ✅ Contains the main structure for all web pages

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'web_theme.dart';
import 'web_responsive_wrapper.dart';
import 'pages/web_home_page.dart';
import 'pages/web_search_page.dart';
import 'pages/web_offers_page.dart';
import 'pages/web_packages_page.dart';
import 'pages/web_ai_page.dart';
import 'pages/web_chat_page.dart';
import 'pages/web_cart_page.dart';
import 'pages/web_profile_page.dart';
import 'package:flutter_application_1/screens/user/payment/cart.dart' show CartStore;
import 'package:flutter_application_1/services/user_service/chat_user_service.dart';
import 'package:flutter_application_1/services/notification_provider_service.dart';
import 'package:flutter_application_1/services/service_locator.dart';

class WebShell extends StatefulWidget {
  final String userName;
  const WebShell({super.key, this.userName = 'Guest'});

  @override
  State<WebShell> createState() => _WebShellState();
}

class _WebShellState extends State<WebShell> {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    _initializeConnections();
  }

  Future<void> _initializeConnections() async {
    await NotificationProviderService.initRealtimeNotifications();
    final service = getIt<ChatUserService>();
    await service.initializeUserId();
    await service.initSocket();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= WebBreakpoints.wideDesktop;
    
    return Scaffold(
      backgroundColor: kWebBgPrimary,
      body: Row(
        children: [
          // ✅ Sidebar Navigation
          _WebSidebar(
            selectedIndex: _selectedIndex,
            isCollapsed: _isSidebarCollapsed,
            onToggleCollapse: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
            onItemSelected: (index) => setState(() => _selectedIndex = index),
            userName: widget.userName,
          ),
          
          // ✅ Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Header Bar
                _WebTopBar(
                  userName: widget.userName,
                  onNotificationTap: () => setState(() => _selectedIndex = 7),
                  onCartTap: () => setState(() => _selectedIndex = 6),
                  onProfileTap: () => setState(() => _selectedIndex = 7),
                ),
                
                // Page Content
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                    child: _buildPage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0:
        return WebHomePage(
          key: const ValueKey('home'),
          userName: widget.userName,
          onNavigate: (index) => setState(() => _selectedIndex = index),
        );
      case 1:
        return const WebSearchPage(key: ValueKey('search'));
      case 2:
        return const WebOffersPage(key: ValueKey('offers'));
      case 3:
        return const WebPackagesPage(key: ValueKey('packages'));
      case 4:
        return const WebAiPage(key: ValueKey('ai'));
      case 5:
        return const WebChatPage(key: ValueKey('chat'));
      case 6:
        return const WebCartPage(key: ValueKey('cart'));
      case 7:
        return const WebProfilePage(key: ValueKey('profile'));
      default:
        return WebHomePage(
          key: const ValueKey('home'),
          userName: widget.userName,
          onNavigate: (index) => setState(() => _selectedIndex = index),
        );
    }
  }
}

// =====================================================
// 🎨 SIDEBAR NAVIGATION
// =====================================================

class _WebSidebar extends StatelessWidget {
  final int selectedIndex;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final Function(int) onItemSelected;
  final String userName;

  const _WebSidebar({
    required this.selectedIndex,
    required this.isCollapsed,
    required this.onToggleCollapse,
    required this.onItemSelected,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final sidebarWidth = isCollapsed ? 80.0 : 260.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: sidebarWidth,
      decoration: WebDecorations.sidebar,
      child: Column(
        children: [
          // Logo Header
          _buildHeader(),
          
          const SizedBox(height: 16),
          
          // Navigation Items
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  _NavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    isSelected: selectedIndex == 0,
                    isCollapsed: isCollapsed,
                    onTap: () => onItemSelected(0),
                  ),
                  _NavItem(
                    icon: Icons.search_rounded,
                    label: 'Explore',
                    isSelected: selectedIndex == 1,
                    isCollapsed: isCollapsed,
                    onTap: () => onItemSelected(1),
                  ),
                  _NavItem(
                    icon: Icons.local_offer_rounded,
                    label: 'Offers',
                    isSelected: selectedIndex == 2,
                    isCollapsed: isCollapsed,
                    onTap: () => onItemSelected(2),
                    badge: 'HOT',
                  ),
                  _NavItem(
                    icon: Icons.inventory_2_rounded,
                    label: 'Packages',
                    isSelected: selectedIndex == 3,
                    isCollapsed: isCollapsed,
                    onTap: () => onItemSelected(3),
                  ),
                  
                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Divider(
                      color: Colors.white.withOpacity(0.1),
                      thickness: 1,
                    ),
                  ),
                  
                  _NavItem(
                    icon: Icons.auto_awesome_rounded,
                    label: 'AI Assistant',
                    isSelected: selectedIndex == 4,
                    isCollapsed: isCollapsed,
                    onTap: () => onItemSelected(4),
                    isPremium: true,
                  ),
                  _NavItem(
                    icon: Icons.chat_bubble_rounded,
                    label: 'Messages',
                    isSelected: selectedIndex == 5,
                    isCollapsed: isCollapsed,
                    onTap: () => onItemSelected(5),
                    badgeCount: _getUnreadChatCount(),
                  ),
                  _NavItem(
                    icon: Icons.shopping_cart_rounded,
                    label: 'Cart',
                    isSelected: selectedIndex == 6,
                    isCollapsed: isCollapsed,
                    onTap: () => onItemSelected(6),
                    badgeCount: CartStore.instance.count.value,
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Section
          _buildBottomSection(),
        ],
      ),
    );
  }

  int _getUnreadChatCount() {
    try {
      return ChatUserService.unreadGlobalCount.value;
    } catch (_) {
      return 0;
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCollapsed ? 16 : 20,
        vertical: 24,
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: kWebPrimaryGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: kWebPrimary.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.celebration_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          
          if (!isCollapsed) ...[
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'EventPlanner',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Collapse Toggle
          InkWell(
            onTap: onToggleCollapse,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isCollapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                color: Colors.white60,
                size: 22,
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Profile Quick Access
          _NavItem(
            icon: Icons.person_rounded,
            label: 'Profile',
            isSelected: selectedIndex == 7,
            isCollapsed: isCollapsed,
            onTap: () => onItemSelected(7),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// 🎨 NAV ITEM
// =====================================================

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;
  final String? badge;
  final int? badgeCount;
  final bool isPremium;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
    this.badge,
    this.badgeCount,
    this.isPremium = false,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isSelected || _isHovered;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(
              horizontal: widget.isCollapsed ? 12 : 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? kWebPrimary.withOpacity(0.2)
                  : _isHovered
                      ? Colors.white.withOpacity(0.08)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: widget.isSelected
                  ? Border.all(color: kWebPrimary.withOpacity(0.4))
                  : null,
            ),
            child: Row(
              mainAxisAlignment: widget.isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                // Icon with optional premium glow
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: widget.isPremium
                          ? BoxDecoration(
                              gradient: kWebPrimaryGradient,
                              borderRadius: BorderRadius.circular(8),
                            )
                          : null,
                      child: Icon(
                        widget.icon,
                        size: 22,
                        color: widget.isSelected
                            ? kWebPrimaryLight
                            : widget.isPremium
                                ? Colors.white
                                : Colors.white.withOpacity(isActive ? 0.95 : 0.7),
                      ),
                    ),
                    
                    // Badge count
                    if (widget.badgeCount != null && widget.badgeCount! > 0)
                      Positioned(
                        right: -8,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: kWebError,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            widget.badgeCount! > 9 ? '9+' : '${widget.badgeCount}',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                
                if (!widget.isCollapsed) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: widget.isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(isActive ? 0.95 : 0.75),
                      ),
                    ),
                  ),
                  
                  // Text badge (HOT, NEW, etc.)
                  if (widget.badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.badge!,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================
// 🎨 TOP BAR
// =====================================================

class _WebTopBar extends StatelessWidget {
  final String userName;
  final VoidCallback onNotificationTap;
  final VoidCallback onCartTap;
  final VoidCallback onProfileTap;

  const _WebTopBar({
    required this.userName,
    required this.onNotificationTap,
    required this.onCartTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: kWebBgCard,
        border: Border(
          bottom: BorderSide(color: kWebBorder.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          // Page Title / Breadcrumb
          Expanded(
            child: Row(
              children: [
                Text(
                  'Welcome back,',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: kWebTextMuted,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  userName.split(' ').first,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: kWebTextPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                const Text('👋', style: TextStyle(fontSize: 18)),
              ],
            ),
          ),
          
          // Search Bar
          Container(
            width: 320,
            height: 44,
            decoration: WebDecorations.searchField,
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(Icons.search_rounded, color: kWebTextMuted, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Search services, vendors...',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: kWebTextMuted,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: kWebBgSecondary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '⌘ K',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: kWebTextMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 24),
          
          // Action Icons
          _TopBarIcon(
            icon: Icons.notifications_outlined,
            badgeCount: _getNotificationCount(),
            onTap: onNotificationTap,
          ),
          const SizedBox(width: 8),
          _TopBarIcon(
            icon: Icons.shopping_cart_outlined,
            badgeCount: CartStore.instance.count.value,
            onTap: onCartTap,
          ),
          const SizedBox(width: 16),
          
          // Profile Avatar
          InkWell(
            onTap: onProfileTap,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: kWebPrimaryGradient,
                shape: BoxShape.circle,
                boxShadow: WebShadows.primary,
              ),
              child: Center(
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'G',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getNotificationCount() {
    return NotificationProviderService.unreadCountNotifier.value;
  }
}

class _TopBarIcon extends StatefulWidget {
  final IconData icon;
  final int badgeCount;
  final VoidCallback onTap;

  const _TopBarIcon({
    required this.icon,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  State<_TopBarIcon> createState() => _TopBarIconState();
}

class _TopBarIconState extends State<_TopBarIcon> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _isHovered ? kWebBgSecondary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                widget.icon,
                size: 22,
                color: _isHovered ? kWebPrimary : kWebTextSecondary,
              ),
              if (widget.badgeCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    decoration: BoxDecoration(
                      color: kWebError,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        widget.badgeCount > 9 ? '9+' : '${widget.badgeCount}',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
