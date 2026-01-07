import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:async';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/reviews_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/notifications_screen.dart';
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
  int _notificationKey = 0; // Key to force rebuild NotificationsScreen

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
      // Only fetch counts if not on that specific screen
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
          // Profile/Logout button
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: kPrimaryColor.withOpacity(0.1),
              child: Text(
                widget.adminName[0].toUpperCase(),
                style: GoogleFonts.poppins(
                  color: kPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
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
                    Text(
                      'Logout',
                      style: GoogleFonts.poppins(color: Colors.red[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeScreen(),
          const ReviewsScreen(),
          const MessagesScreen(),
          NotificationsScreen(key: ValueKey(_notificationKey)), // Rebuild on key change
        ],
      ),
      bottomNavigationBar: Container(
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, LucideIcons.home, 'Home'),
                _buildNavItem(1, LucideIcons.star, 'Reviews'),
                _buildNavItem(2, LucideIcons.messageCircle, 'Messages', badgeCount: _unreadMessages),
                _buildNavItem(3, LucideIcons.bell, 'Notifications', badgeCount: _unreadNotifications),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Admin Dashboard';
      case 1:
        return 'Reviews';
      case 2:
        return 'Messages';
      case 3:
        return 'Notifications';
      default:
        return 'Admin';
    }
  }

  Widget _buildNavItem(int index, IconData icon, String label, {int badgeCount = 0}) {
    final isSelected = _currentIndex == index;
    
    return InkWell(
      onTap: () async {
        // عند الخروج من الإشعارات (كان في 3 وراح لمكان تاني)
        if (_currentIndex == 3 && index != 3) {
          // Mark all notifications as read when leaving - wait for it
          try {
            await AdminService.markAllNotificationsAsRead();
            print('✅ All notifications marked as read on exit');
            // Increment key to force rebuild NotificationsScreen next time
            _notificationKey++;
          } catch (e) {
            print('❌ Error marking notifications: $e');
          }
        }
        
        if (mounted) {
          setState(() {
            _currentIndex = index;
            // Reset badge IMMEDIATELY for the specific screen entered
            if (index == 2) {
              // Messages tab - reset messages badge only
              _unreadMessages = 0;
            } else if (index == 3) {
              // Notifications tab - reset notifications badge only
              _unreadNotifications = 0;
            }
          });
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                Icon(
                  icon,
                  color: isSelected ? kPrimaryColor : Colors.grey[500],
                  size: 22,
                ),
                // ✅ Red badge for unread count
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
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
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

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Logout',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.poppins(),
        ),
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
            child: Text(
              'Logout',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
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
