// lib/screens/home_provider.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Color palette
const Color kPrimaryColor = Color.fromARGB(215, 20, 20, 215);
const Color kTextColor = Colors.black;
const Color kBackgroundColor = Colors.white;

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
          centerTitle: false,
          title: Text(
            "Welcome, ${provider.brandName}",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: kTextColor,
            ),
          ),
        ),

        // Support Button
        floatingActionButton: FloatingActionButton(
          backgroundColor: kPrimaryColor,
          onPressed: () {},
          child: const Icon(Icons.support_agent, color: Colors.white),
        ),

        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderCard(provider: provider),
              const SizedBox(height: 20),

              // ============================
              // Stats
              // ============================
              Text(
                "Your Stats",
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

              // ============================
              // Quick Actions
              // ============================
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
                title: "Add New Service",
                icon: Icons.add_circle,
                onTap: () {},
              ),
              const SizedBox(height: 12),

              _ActionButton(
                title: "View Messages",
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

              // ============================
              // Tips
              // ============================
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

// ============================================================================
// Header Card
// ============================================================================
class _HeaderCard extends StatelessWidget {
  final ProviderModel provider;

  const _HeaderCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: kPrimaryColor.withOpacity(0.1),
            child: Icon(
              Icons.business_center,
              size: 32,
              color: kPrimaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.brandName,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: kTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  provider.category,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  provider.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "City: ${provider.city}",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  "Phone: ${provider.phone}",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  "Email: ${provider.email}",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Stat Card
// ============================================================================
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
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
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

// ============================================================================
// Action Button
// ============================================================================
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

// ============================================================================
// Tip Card
// ============================================================================
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
            spreadRadius: 1,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: kTextColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
