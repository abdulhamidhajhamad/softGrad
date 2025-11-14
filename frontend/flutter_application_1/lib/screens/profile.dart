// lib/screens/profile.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'edit_profile.dart';
import 'security_password.dart';
import 'provider.dart';

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

            // Become a Provider section
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Material(
                color: _isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                elevation: 1,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isDarkMode
                        ? const Color(0xFF1E1E1E) // darker for dark mode
                        : const Color.fromARGB(
                            157, 198, 222, 249), // light blue for light mode
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _isDarkMode
                            ? Colors.black.withOpacity(0.2)
                            : Colors.black12.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.storefront_rounded,
                        size: 36,
                        color: _isDarkMode ? Colors.white : Colors.black,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Become a Provider',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color:
                                    _isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'List your wedding services and reach couples planning their big day.',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: _isDarkMode
                                    ? Colors.white70
                                    : Colors.black87,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: 180,
                              height: 40,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kAccentColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProviderScreen(
                                          isDarkMode: _isDarkMode),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Switch to Provider Mode',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Settings Section
            Text('Settings', style: sectionTitleStyle),
            const SizedBox(height: 8),

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
                    title: 'Booking Updates',
                    subtitle:
                        'Notifications about confirmed bookings, changes, or cancellations.',
                    value: _bookingUpdates,
                    onChanged: (v) => setState(() => _bookingUpdates = v),
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    iconColor: iconColor,
                  ),
                  _NotificationToggleRow(
                    title: 'Offers & Discounts',
                    subtitle:
                        'Promotions and vendor offers tailored to your plan.',
                    value: _offersAndDiscounts,
                    onChanged: (v) => setState(() => _offersAndDiscounts = v),
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    iconColor: iconColor,
                  ),
                  _NotificationToggleRow(
                    title: 'Reminders & Checklist',
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

            // Security Section
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
            const SizedBox(height: 22),

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
            const SizedBox(height: 14),
            Center(
              child: Text(
                'You can sign in again anytime using your email.',
                style: bodyStyle.copyWith(fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Helper Widgets ----------------

class _ProfileHeader extends StatelessWidget {
  final User user;
  final Color textPrimary;
  final Color textSecondary;
  final Color iconColor;
  final bool isDarkMode;

  const _ProfileHeader({
    required this.user,
    required this.textPrimary,
    required this.textSecondary,
    required this.iconColor,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundImage:
              user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
          backgroundColor: isDarkMode ? Colors.white12 : Colors.grey.shade200,
          child: user.avatarUrl == null
              ? Icon(Icons.person, size: 40, color: iconColor)
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.fullName,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textPrimary)),
              const SizedBox(height: 4),
              Text(user.email,
                  style: TextStyle(fontSize: 14, color: textSecondary)),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.edit, color: iconColor),
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
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Color backgroundColor;
  final Widget child;
  const _SectionCard({required this.backgroundColor, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
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
    required this.icon,
    required this.label,
    required this.value,
    required this.textPrimary,
    required this.textSecondary,
    required this.iconColor,
  });
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(label, style: TextStyle(fontSize: 14, color: textSecondary)),
      subtitle: Text(value,
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w500, color: textPrimary)),
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
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.textPrimary,
    required this.textSecondary,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title,
          style: TextStyle(fontWeight: FontWeight.w500, color: textPrimary)),
      subtitle:
          Text(subtitle, style: TextStyle(fontSize: 12, color: textSecondary)),
      activeColor: kAccentColor,
    );
  }
}

class _ThemeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? kAccentColor : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
