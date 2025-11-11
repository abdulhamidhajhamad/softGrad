// lib/screens/profile.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'edit_profile.dart';
import 'security_password.dart';

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

/// Profile screen
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

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = _isDarkMode ? Colors.black : Colors.white;
    final Color cardColor =
        _isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5);
    final Color textPrimary =
        _isDarkMode ? Colors.white : const Color(0xFF111111);
    final Color textSecondary =
        _isDarkMode ? Colors.white70 : const Color(0xFF555555);
    final Color iconColor =
        _isDarkMode ? Colors.white70 : const Color(0xFF1A1A2E);

    final sectionTitleStyle = GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: textPrimary,
    );

    final bodyStyle = GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: textSecondary,
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: iconColor),
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isDarkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              color: iconColor,
            ),
            onPressed: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          children: [
            _ProfileHeader(
              user: widget.currentUser,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              iconColor: iconColor,
              isDarkMode: _isDarkMode,
            ),
            const SizedBox(height: 24),

            // Account Info
            Text('Account Info', style: sectionTitleStyle),
            const SizedBox(height: 8),
            _SectionCard(
              backgroundColor: cardColor,
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.person_outline,
                    label: 'Full Name',
                    value: widget.currentUser.fullName,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    iconColor: iconColor,
                  ),
                  const Divider(height: 1),
                  _InfoRow(
                    icon: Icons.mail_outline,
                    label: 'Email',
                    value: widget.currentUser.email,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    iconColor: iconColor,
                  ),
                  const Divider(height: 1),
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: widget.currentUser.phone,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    iconColor: iconColor,
                  ),
                  const Divider(height: 1),
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    value: widget.currentUser.location,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    iconColor: iconColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Settings
            Text('Settings', style: sectionTitleStyle),
            const SizedBox(height: 8),

            // App Theme Selection
            Text('App Theme', style: sectionTitleStyle),
            const SizedBox(height: 8),
            Row(
              children: [
                _ThemeButton(
                  label: 'Light',
                  selected: !_isDarkMode,
                  onTap: () => setState(() => _isDarkMode = false),
                ),
                const SizedBox(width: 8),
                _ThemeButton(
                  label: 'Dark',
                  selected: _isDarkMode,
                  onTap: () => setState(() => _isDarkMode = true),
                ),
                const SizedBox(width: 8),
                _ThemeButton(
                  label: 'System',
                  selected: false,
                  onTap: () {
                    final brightness =
                        WidgetsBinding.instance.window.platformBrightness;
                    setState(() => _isDarkMode = brightness == Brightness.dark);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            _SectionCard(
              backgroundColor: cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(
                      children: [
                        Icon(Icons.notifications_none_outlined,
                            color: iconColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Notifications',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      'Choose which notifications you want to receive.',
                      style: bodyStyle,
                    ),
                  ),
                  _NotificationToggleRow(
                    title: 'Booking updates',
                    subtitle:
                        'Notifications about confirmed bookings, changes, or cancellations.',
                    value: _bookingUpdates,
                    onChanged: (v) => setState(() => _bookingUpdates = v),
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    iconColor: iconColor,
                  ),
                  _NotificationToggleRow(
                    title: 'Offers & discounts',
                    subtitle:
                        'Promotions and vendor offers tailored to your plan.',
                    value: _offersAndDiscounts,
                    onChanged: (v) => setState(() => _offersAndDiscounts = v),
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    iconColor: iconColor,
                  ),
                  _NotificationToggleRow(
                    title: 'Reminders & checklist',
                    subtitle:
                        'Reminders about tasks, deadlines, and your wedding timeline.',
                    value: _remindersAndChecklist,
                    onChanged: (v) =>
                        setState(() => _remindersAndChecklist = v),
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    iconColor: iconColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Security
            Text('Security', style: sectionTitleStyle),
            const SizedBox(height: 8),
            _SectionCard(
              backgroundColor: cardColor,
              child: ListTile(
                leading: Icon(Icons.lock_reset_outlined, color: iconColor),
                title: Text(
                  'Change password',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Update your login password regularly.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
                trailing: Icon(Icons.chevron_right_rounded, color: iconColor),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SecurityPasswordScreen(
                        isDarkMode: _isDarkMode,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

            // Sign Out
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/signin', (route) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Sign Out',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'You can sign in again anytime using your email.',
                style: bodyStyle,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final User user;
  final Color textPrimary;
  final Color textSecondary;
  final Color iconColor;
  final bool isDarkMode;

  const _ProfileHeader({
    Key? key,
    required this.user,
    required this.textPrimary,
    required this.textSecondary,
    required this.iconColor,
    required this.isDarkMode,
  }) : super(key: key);

  String _getInitials(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: kAccentColor.withOpacity(0.15),
          backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
              ? NetworkImage(user.avatarUrl!)
              : null,
          child: user.avatarUrl == null || user.avatarUrl!.isEmpty
              ? Text(
                  _getInitials(user.fullName),
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: kAccentColor,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.fullName,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditProfileScreen(
                  user: user,
                  isDarkMode: isDarkMode,
                ),
              ),
            );
          },
          style: TextButton.styleFrom(
            foregroundColor: kAccentColor,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          icon: const Icon(Icons.edit_outlined, size: 18, color: kAccentColor),
          label: Text(
            'Edit',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: kAccentColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  const _SectionCard(
      {Key? key, required this.child, required this.backgroundColor})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: child,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color textPrimary;
  final Color textSecondary;
  final Color iconColor;
  const _InfoRow({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    required this.textPrimary,
    required this.textSecondary,
    required this.iconColor,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: textSecondary)),
                const SizedBox(height: 2),
                Text(value,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color textPrimary;
  final Color textSecondary;
  final Color iconColor;

  const _NotificationToggleRow({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.textPrimary,
    required this.textSecondary,
    required this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      value: value,
      onChanged: onChanged,
      activeColor: kAccentColor,
      title: Text(title,
          style: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
      subtitle: Text(subtitle,
          style: GoogleFonts.poppins(fontSize: 12, color: textSecondary)),
      secondary: Icon(Icons.checklist_outlined, color: iconColor),
    );
  }
}

// === Theme Button ===
class _ThemeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeButton({
    Key? key,
    required this.label,
    required this.selected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? kAccentColor : Colors.transparent,
            border: Border.all(
              color: selected ? kAccentColor : Colors.grey.shade400,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: selected ? Colors.white : Colors.grey.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
