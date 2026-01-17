// lib/screens/profile.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'edit_profile_customer.dart';
import '../../security_password.dart';
import 'package:flutter_application_1/screens/review_screen/my_bookings_screen.dart';
import 'package:flutter_application_1/services/auth_service.dart';

/// Simple user data model for the profile screen
class User {
  final String fullName;
  final String email;
  final String phone;
  final String location;
  final String? avatarUrl;

  const User({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.location,
    this.avatarUrl,
  });
}

const Color kAccentColor = Color.fromARGB(215, 20, 20, 215);

class ProfileScreen extends StatefulWidget {
  final User currentUser;
  const ProfileScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isDarkMode = false;
  bool _bookingUpdates = true;
  bool _offersAndDiscounts = true;
  bool _remindersAndChecklist = true;

  late User _currentUser;
  bool _isLoading = true;
  String? _userRole; // ✅ ADDED

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadUserRole(); // ✅ ADDED
  }

  // ✅ NEW METHOD: Load User Role
  Future<void> _loadUserRole() async {
    final role = await AuthService.getUserRole();
    setState(() {
      _userRole = role?.toLowerCase(); // Normalize to lowercase
    });
    print('🔑 User Role: $_userRole'); // Debug
  }

  Future<void> _loadUserProfile() async {
    try {
      final userData = await AuthService.getUserProfile();

      setState(() {
        _currentUser = User(
          fullName: userData['userName'] ?? 'Guest',
          email: userData['email'] ?? 'No email',
          phone: userData['phone'] ?? 'No phone',
          location: userData['city'] ?? 'No location',
          avatarUrl: userData['imageUrl'],
        );
        _isLoading = false;
      });
    } catch (e) {
      // fallback to provided user
      setState(() {
        _currentUser = widget.currentUser;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);

    if (_isLoading) {
      return Theme(
        data: baseTheme.copyWith(
          textTheme: GoogleFonts.poppinsTextTheme(baseTheme.textTheme),
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFFF6F7FB),
          body: const Center(
            child: CircularProgressIndicator(color: kAccentColor),
          ),
        ),
      );
    }

    return Theme(
      data: baseTheme.copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(baseTheme.textTheme),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ✅ Modern App Bar
            SliverAppBar(
              pinned: true,
              floating: false,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              expandedHeight: 0,
              toolbarHeight: 64,
              automaticallyImplyLeading: false,
              title: Text(
                'Profile',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0B1220),
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Icon(Icons.settings_rounded, color: const Color(0xFF64748B)),
                  onPressed: () => _showSettingsSheet(context),
                  tooltip: 'Settings',
                ),
                const SizedBox(width: 4),
              ],
            ),

            // ✅ Profile Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ Profile Card (Modern Design)
                    _buildProfileCard(),

                    const SizedBox(height: 20),

                    // ✅ Quick Actions
                    _buildQuickActions(),

                    const SizedBox(height: 24),

                    // ✅ Account Info Section
                    _buildSectionTitle('Account Info'),
                    const SizedBox(height: 12),
                    _buildAccountInfoCard(),

                    const SizedBox(height: 24),

                    // ✅ Security Section
                    _buildSectionTitle('Security'),
                    const SizedBox(height: 12),
                    _buildSecurityCard(),

                    const SizedBox(height: 24),

                    // ✅ Sign Out Button
                    _buildSignOutButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ Profile Card Widget
  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kAccentColor, const Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: kAccentColor.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
            ),
            child: CircleAvatar(
              radius: 38,
              backgroundImage: _currentUser.avatarUrl != null 
                  ? NetworkImage(_currentUser.avatarUrl!) 
                  : null,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: _currentUser.avatarUrl == null
                  ? const Icon(Icons.person_rounded, size: 38, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentUser.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.email_rounded, size: 14, color: Colors.white70),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _currentUser.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 14, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(
                      _currentUser.location,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Edit Button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfileScreen(
                    user: _currentUser,
                    isDarkMode: false,
                  ),
                ),
              ).then((_) => _loadUserProfile());
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Quick Actions (My Bookings)
  Widget _buildQuickActions() {
    // Only show for regular users
    if (_userRole != 'user' && _userRole != 'customer') {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: kAccentColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.event_note_rounded, color: kAccentColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Bookings',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0B1220),
                    ),
                  ),
                  Text(
                    'View and manage your bookings',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: kAccentColor),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ Section Title
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: const Color(0xFF0B1220),
      ),
    );
  }

  /// ✅ Account Info Card
  Widget _buildAccountInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.person_rounded, 'Full Name', _currentUser.fullName),
          _buildDivider(),
          _buildInfoRow(Icons.email_rounded, 'Email', _currentUser.email),
          _buildDivider(),
          _buildInfoRow(Icons.phone_rounded, 'Phone', _currentUser.phone),
          _buildDivider(),
          _buildInfoRow(Icons.location_on_rounded, 'Location', _currentUser.location),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: kAccentColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: kAccentColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0B1220),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.black.withOpacity(0.06), indent: 68);
  }

  /// ✅ Security Card
  Widget _buildSecurityCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SecurityPasswordScreen(isDarkMode: false),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.lock_rounded, color: Color(0xFFF59E0B), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Change Password',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0B1220),
                    ),
                  ),
                  Text(
                    'Update your login password',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ Sign Out Button
  Widget _buildSignOutButton() {
    return GestureDetector(
      onTap: () async {
        // Show confirmation dialog
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Sign Out',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
            ),
            content: Text(
              'Are you sure you want to sign out?',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Sign Out', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
            const SizedBox(width: 8),
            Text(
              'Sign Out',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ Settings Bottom Sheet
  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Settings',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0B1220),
              ),
            ),
            const SizedBox(height: 20),

            // Notifications Toggle
            _buildSettingsToggle(
              'Booking Updates',
              'Get notified about your bookings',
              _bookingUpdates,
              (v) => setState(() => _bookingUpdates = v),
            ),
            _buildSettingsToggle(
              'Offers & Discounts',
              'Receive promotional offers',
              _offersAndDiscounts,
              (v) => setState(() => _offersAndDiscounts = v),
            ),
            _buildSettingsToggle(
              'Reminders',
              'Get reminders for your events',
              _remindersAndChecklist,
              (v) => setState(() => _remindersAndChecklist = v),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsToggle(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0B1220),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: kAccentColor,
          ),
        ],
      ),
    );
  }
}