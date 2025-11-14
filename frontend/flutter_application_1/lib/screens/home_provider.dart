// lib/screens/home_provider.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Color palette
const Color kPrimaryColor = Color.fromARGB(215, 20, 20, 215);
const Color kTextColor = Colors.black;
const Color kBackgroundColor = Colors.white;

// Orange color for contact icons
const Color kContactIconColor = Color(0xFFFF7A00);
const Color kContactCircleColor = Color(0xFFFFE6CC);

/// Provider Data Model (FINAL VERSION)
class ProviderModel {
  final String brandName;
  final String email;
  final String phone;
  final String category;
  final String description;
  final String city;

  // Dashboard stats
  final int bookings;
  final int views;
  final int messages;
  final int reviews;

  ProviderModel({
    required this.brandName,
    required this.email,
    required this.phone,
    required this.category,
    required this.description,
    required this.city,
    this.bookings = 3,
    this.views = 1240,
    this.messages = 4,
    this.reviews = 2,
  });
}

class HomeProviderScreen extends StatelessWidget {
  final ProviderModel provider;

  const HomeProviderScreen({
    Key? key,
    required this.provider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          backgroundColor: kBackgroundColor,
          elevation: 0,
          centerTitle: true,
          toolbarHeight: 80,
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "WELCOME",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                "♡",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: kTextColor,
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: kPrimaryColor,
          onPressed: () {},
          child: const Icon(Icons.support_agent, color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ModernHeaderCard(provider: provider),
              const SizedBox(height: 25),
              Text(
                "Business Performance",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: kTextColor,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _StatCard(
                    icon: Icons.calendar_month,
                    label: "Active Bookings",
                    value: provider.bookings.toString(),
                  ),
                  _StatCard(
                    icon: Icons.visibility,
                    label: "Total Views",
                    value: provider.views.toString(),
                  ),
                  _StatCard(
                    icon: Icons.message,
                    label: "Messages",
                    value: provider.messages.toString(),
                  ),
                  _StatCard(
                    icon: Icons.reviews,
                    label: "Pending Reviews",
                    value: provider.reviews.toString(),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Text(
                "Quick Actions",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: kTextColor,
                ),
              ),
              const SizedBox(height: 14),
              _ActionButton(
                title: "Edit Profile",
                icon: Icons.edit,
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _ActionButton(
                title: "Services",
                icon: Icons.add_circle,
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _ActionButton(
                title: "Messages",
                icon: Icons.chat_bubble,
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _ActionButton(
                title: "Manage Bookings",
                icon: Icons.event_available,
                onTap: () {},
              ),
              const SizedBox(height: 30),
              Text(
                "Grow Your Business",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: kTextColor,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 150,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    _TipCard(text: "Respond quickly to messages"),
                    _TipCard(text: "Upload high quality photos"),
                    _TipCard(text: "Keep your calendar up-to-date"),
                    _TipCard(text: "Offer seasonal discounts"),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

/// ============================================================================
/// CATEGORY → ICON MAPPER
/// ============================================================================
IconData mapCategoryToIcon(String category) {
  switch (category.toLowerCase()) {
    case "flowers":
      return Icons.local_florist;
    case "makeup":
      return Icons.brush;
    case "hair":
      return Icons.cut;
    case "dj":
      return Icons.music_note;
    case "hall":
      return Icons.location_city;
    case "dress":
      return Icons.checkroom;
    case "photography":
      return Icons.camera_alt;
    case "cake":
      return Icons.cake;
    case "decor":
      return Icons.chair_alt;
    case "video":
      return Icons.videocam;
    default:
      return Icons.business_center;
  }
}

/// ============================================================================
/// Modern Header Card (With Edit Profile button added)
/// ============================================================================
class ModernHeaderCard extends StatelessWidget {
  final ProviderModel provider;

  const ModernHeaderCard({Key? key, required this.provider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final IconData dynamicIcon = mapCategoryToIcon(provider.category);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kBackgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TOP ROW = icon + brand name + category + EDIT PROFILE BUTTON
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: const Color(0xFFF2F2FF),
                child: Icon(dynamicIcon, color: kPrimaryColor, size: 34),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.brandName,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.category,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              // *** NEW --- EDIT PROFILE BUTTON ***
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F0FF), // Very light blue background
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit,
                        color: const Color.fromARGB(190, 0, 0, 0), size: 18),
                    const SizedBox(width: 4),
                    Text(
                      "Edit",
                      style: GoogleFonts.poppins(
                        color: const Color.fromARGB(190, 0, 0, 0),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            provider.description,
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.45,
              color: Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 25),

          _ContactRow(icon: Icons.location_on, label: provider.city),
          const SizedBox(height: 15),
          _ContactRow(icon: Icons.phone, label: provider.phone),
          const SizedBox(height: 15),
          _ContactRow(icon: Icons.email, label: provider.email),
        ],
      ),
    );
  }
}

/// ============================================================================
/// Contact Row (orange icons)
/// ============================================================================
class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ContactRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: kContactCircleColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(icon, size: 20, color: kContactIconColor),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}

/// ============================================================================
/// Stat Card
/// ============================================================================
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: kPrimaryColor, size: 28),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// Action Button
/// ============================================================================
class _ActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: kPrimaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: kPrimaryColor, size: 26),
            const SizedBox(width: 14),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: kTextColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16, color: kTextColor),
          ],
        ),
      ),
    );
  }
}

/// ============================================================================
/// Tip Card
/// ============================================================================
class _TipCard extends StatelessWidget {
  final String text;
  const _TipCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
