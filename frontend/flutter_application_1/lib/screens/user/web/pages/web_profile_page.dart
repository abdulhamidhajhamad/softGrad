// lib/screens/user/web/pages/web_profile_page.dart
//
// ✅ Web Profile Page - Redesigned
// ✅ Uses real user data from API
// ✅ Matches app profile features
// ✅ Modern, clean design

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../web_theme.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/user_service/review_service.dart';
import 'package:flutter_application_1/models/review_model.dart';

class WebProfilePage extends StatefulWidget {
  const WebProfilePage({super.key});

  @override
  State<WebProfilePage> createState() => _WebProfilePageState();
}

class _WebProfilePageState extends State<WebProfilePage> {
  Map<String, dynamic>? _userData;
  List<PendingReview> _pendingReviews = [];
  bool _isLoading = true;
  String? _userRole;

  // Notification settings
  bool _bookingUpdates = true;
  bool _offersAndDiscounts = true;
  bool _reminders = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await AuthService.getUserData();
      final userRole = await AuthService.getUserRole();
      List<PendingReview> pendingReviews = [];
      
      // Only load pending reviews for regular users
      if (userRole == 'user' || userRole == 'customer') {
        try {
          pendingReviews = await ReviewService.getPendingReviews();
        } catch (e) {
          print('❌ Error loading reviews: $e');
        }
      }
      
      setState(() {
        _userData = userData;
        _userRole = userRole;
        _pendingReviews = pendingReviews;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: kWebPrimary),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 1200;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: isWideScreen ? _buildWideLayout() : _buildNarrowLayout(),
    );
  }

  // ============================================
  // WIDE LAYOUT (Desktop)
  // ============================================
  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left sidebar - Profile Card
        SizedBox(
          width: 360,
          child: _buildProfileSidebar(),
        ),
        const SizedBox(width: 32),
        // Main content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAccountInfoCard(),
              const SizedBox(height: 24),
              _buildSecurityCard(),
              const SizedBox(height: 24),
              if (_userRole == 'user' || _userRole == 'customer') ...[
                _buildQuickActionsCard(),
                const SizedBox(height: 24),
                if (_pendingReviews.isNotEmpty) _buildPendingReviewsCard(),
              ],
              const SizedBox(height: 24),
              _buildNotificationsCard(),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================
  // NARROW LAYOUT (Tablet)
  // ============================================
  Widget _buildNarrowLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProfileSidebar(),
        const SizedBox(height: 24),
        _buildAccountInfoCard(),
        const SizedBox(height: 24),
        _buildSecurityCard(),
        const SizedBox(height: 24),
        if (_userRole == 'user' || _userRole == 'customer') ...[
          _buildQuickActionsCard(),
          const SizedBox(height: 24),
          if (_pendingReviews.isNotEmpty) _buildPendingReviewsCard(),
        ],
        const SizedBox(height: 24),
        _buildNotificationsCard(),
        const SizedBox(height: 32),
        _buildLogoutButton(),
      ],
    );
  }

  // ============================================
  // PROFILE SIDEBAR
  // ============================================
  Widget _buildProfileSidebar() {
    final name = _userData?['userName'] ?? _userData?['name'] ?? 'User';
    final email = _userData?['email'] ?? '';
    final phone = _userData?['phone'] ?? _userData?['phoneNumber'] ?? '';
    final city = _userData?['city'] ?? '';
    final imageUrl = _userData?['imageUrl'];

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kWebPrimary, Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: kWebPrimary.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.4), width: 4),
            ),
            child: ClipOval(
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      errorWidget: (context, url, error) => _buildAvatarFallback(name),
                    )
                  : _buildAvatarFallback(name),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Name
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          // Email
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.email_rounded, size: 16, color: Colors.white70),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  email,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone_rounded, size: 16, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  phone,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
          
          if (city.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_rounded, size: 16, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  city,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 28),
          
          // Edit profile button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showEditProfileDialog,
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: kWebPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Divider
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.2),
          ),
          
          const SizedBox(height: 24),
          
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getRoleIcon(),
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  _getRoleDisplayName(),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Pending reviews badge (if any)
          if (_pendingReviews.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: kWebWarning.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.rate_review_rounded, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    '${_pendingReviews.length} Pending Review${_pendingReviews.length > 1 ? 's' : ''}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 32),
          
          // Logout button (only in wide layout)
          MediaQuery.of(context).size.width > 1200
              ? _buildLogoutButton()
              : const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    return Container(
      color: Colors.white.withOpacity(0.2),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: GoogleFonts.poppins(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  IconData _getRoleIcon() {
    switch (_userRole) {
      case 'provider':
        return Icons.store_rounded;
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  String _getRoleDisplayName() {
    switch (_userRole) {
      case 'provider':
        return 'Service Provider';
      case 'admin':
        return 'Administrator';
      default:
        return 'Customer';
    }
  }

  // ============================================
  // ACCOUNT INFO CARD
  // ============================================
  Widget _buildAccountInfoCard() {
    final name = _userData?['userName'] ?? _userData?['name'] ?? 'N/A';
    final email = _userData?['email'] ?? 'N/A';
    final phone = _userData?['phone'] ?? _userData?['phoneNumber'] ?? 'N/A';
    final city = _userData?['city'] ?? 'N/A';

    return _buildCard(
      title: 'Account Information',
      icon: Icons.person_rounded,
      child: Column(
        children: [
          _buildInfoRow(Icons.person_rounded, 'Full Name', name),
          _buildInfoDivider(),
          _buildInfoRow(Icons.email_rounded, 'Email Address', email),
          _buildInfoDivider(),
          _buildInfoRow(Icons.phone_rounded, 'Phone Number', phone),
          _buildInfoDivider(),
          _buildInfoRow(Icons.location_on_rounded, 'City', city),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: kWebPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: kWebPrimary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: kWebTextMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: kWebTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 80),
      child: Divider(height: 1, color: kWebBorder),
    );
  }

  // ============================================
  // SECURITY CARD
  // ============================================
  Widget _buildSecurityCard() {
    return _buildCard(
      title: 'Security',
      icon: Icons.security_rounded,
      child: InkWell(
        onTap: _showChangePasswordDialog,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Change Password',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kWebTextPrimary,
                      ),
                    ),
                    Text(
                      'Update your login password',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: kWebTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: kWebBgSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: kWebTextMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // QUICK ACTIONS CARD (MY BOOKINGS)
  // ============================================
  Widget _buildQuickActionsCard() {
    return _buildCard(
      title: 'Quick Actions',
      icon: Icons.flash_on_rounded,
      child: InkWell(
        onTap: () {
          // Navigate to bookings
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('My Bookings - Coming soon'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: kWebPrimary,
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: kWebPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.event_note_rounded, color: kWebPrimary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Bookings',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kWebTextPrimary,
                      ),
                    ),
                    Text(
                      'View and manage your bookings',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: kWebTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: kWebBgSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: kWebTextMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // PENDING REVIEWS CARD
  // ============================================
  Widget _buildPendingReviewsCard() {
    return _buildCard(
      title: 'Pending Reviews',
      icon: Icons.rate_review_rounded,
      badge: '${_pendingReviews.length}',
      child: Column(
        children: _pendingReviews.take(3).map((review) {
          return _buildPendingReviewItem(review);
        }).toList(),
      ),
    );
  }

  Widget _buildPendingReviewItem(PendingReview review) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWebWarning.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kWebWarning.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: kWebBgSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: review.serviceImage != null
                  ? CachedNetworkImage(
                      imageUrl: review.serviceImage!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.store_rounded,
                        color: kWebTextMuted,
                      ),
                    )
                  : const Icon(Icons.store_rounded, color: kWebTextMuted),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  review.serviceName,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kWebTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  review.companyName,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: kWebTextMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: kWebWarning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    review.daysAgo,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: kWebWarning,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Open review dialog
            },
            icon: const Icon(Icons.star_rounded, size: 16),
            label: const Text('Review'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kWebWarning,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // NOTIFICATIONS CARD
  // ============================================
  Widget _buildNotificationsCard() {
    return _buildCard(
      title: 'Notification Settings',
      icon: Icons.notifications_rounded,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            _buildNotificationToggle(
              'Booking Updates',
              'Get notified about your bookings',
              Icons.event_available_rounded,
              _bookingUpdates,
              (v) => setState(() => _bookingUpdates = v),
            ),
            const SizedBox(height: 12),
            _buildNotificationToggle(
              'Offers & Discounts',
              'Receive promotional offers',
              Icons.local_offer_rounded,
              _offersAndDiscounts,
              (v) => setState(() => _offersAndDiscounts = v),
            ),
            const SizedBox(height: 12),
            _buildNotificationToggle(
              'Reminders',
              'Get reminders for your events',
              Icons.alarm_rounded,
              _reminders,
              (v) => setState(() => _reminders = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationToggle(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: value ? kWebPrimary.withOpacity(0.05) : kWebBgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value ? kWebPrimary.withOpacity(0.2) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: value ? kWebPrimary.withOpacity(0.15) : kWebBorder,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: value ? kWebPrimary : kWebTextMuted,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kWebTextPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: kWebTextMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: kWebPrimary,
          ),
        ],
      ),
    );
  }

  // ============================================
  // CARD WRAPPER
  // ============================================
  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
    String? badge,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kWebBorder.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: kWebPrimaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: kWebTextPrimary,
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: kWebWarning,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: kWebBorder.withOpacity(0.5)),
          // Content
          child,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ============================================
  // LOGOUT BUTTON
  // ============================================
  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _showLogoutConfirmation,
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('Sign Out'),
        style: OutlinedButton.styleFrom(
          foregroundColor: kWebError,
          side: const BorderSide(color: kWebError, width: 1.5),
          backgroundColor: kWebError.withOpacity(0.05),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ============================================
  // DIALOGS
  // ============================================
  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _userData?['userName'] ?? '');
    final phoneController = TextEditingController(text: _userData?['phone'] ?? _userData?['phoneNumber'] ?? '');
    final cityController = TextEditingController(text: _userData?['city'] ?? '');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: kWebPrimaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.edit_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Text('Edit Profile', style: WebTypography.h4),
                ],
              ),
              const SizedBox(height: 28),
              
              _buildTextField(
                controller: nameController,
                label: 'Full Name',
                icon: Icons.person_rounded,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: phoneController,
                label: 'Phone Number',
                icon: Icons.phone_rounded,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: cityController,
                label: 'City',
                icon: Icons.location_on_rounded,
              ),
              
              const SizedBox(height: 32),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kWebTextMuted,
                        side: const BorderSide(color: kWebBorder),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Implement profile update API
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile updated successfully!'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: kWebSuccess,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kWebPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.lock_rounded, color: Color(0xFFF59E0B)),
                  ),
                  const SizedBox(width: 16),
                  Text('Change Password', style: WebTypography.h4),
                ],
              ),
              const SizedBox(height: 28),
              
              _buildTextField(
                controller: currentPasswordController,
                label: 'Current Password',
                icon: Icons.lock_outline_rounded,
                isPassword: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: newPasswordController,
                label: 'New Password',
                icon: Icons.lock_rounded,
                isPassword: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: confirmPasswordController,
                label: 'Confirm New Password',
                icon: Icons.lock_rounded,
                isPassword: true,
              ),
              
              const SizedBox(height: 32),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kWebTextMuted,
                        side: const BorderSide(color: kWebBorder),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Implement password change API
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password changed successfully!'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: kWebSuccess,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Update Password'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: kWebError.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: kWebError,
                  size: 36,
                ),
              ),
              const SizedBox(height: 24),
              Text('Sign Out?', style: WebTypography.h4),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to sign out of your account?',
                style: WebTypography.body.copyWith(color: kWebTextMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kWebTextMuted,
                        side: const BorderSide(color: kWebBorder),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await AuthService.clearAuth();
                        if (mounted) {
                          Navigator.pop(context);
                          Navigator.of(context).pushReplacementNamed('/login');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kWebError,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Sign Out'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: kWebTextPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: kWebTextMuted,
        ),
        prefixIcon: Icon(icon, color: kWebPrimary, size: 20),
        filled: true,
        fillColor: kWebBgSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: kWebBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kWebPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
