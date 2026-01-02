// lib/widgets/package_services_view.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/services/package_service/package_service.dart';

const Color kBrandBlue = Color.fromARGB(215, 20, 20, 215);
const Color kBg = Color(0xFFF6F7FB);
const Color kCard = Colors.white;
const Color kText = Color(0xFF0B1220);
const Color kMuted = Color(0xFF6B7280);
const Color kBorder = Color(0xFFE5E7EB);

/// 📦 Package Services View Page (What's Inside)
class PackageServicesViewPage extends StatelessWidget {
  final PackageModel package;

  const PackageServicesViewPage({super.key, required this.package});

  String _money(double v) => '₪${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: kText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "What's Inside",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: kText,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        children: [
          // Package Info Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
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
                        color: kBrandBlue.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.inventory_2_rounded,
                        color: kBrandBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            package.packageName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: kText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${package.companyName} • ${package.city}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: kMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Price Summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _PriceColumn(
                          label: 'Original Total',
                          value: _money(package.totalOriginal),
                          strikethrough: true,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: kBorder,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PriceColumn(
                          label: 'Package Price',
                          value: _money(package.totalPackage),
                          highlight: true,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: kBorder,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PriceColumn(
                          label: 'You Save',
                          value: _money(package.totalOriginal - package.totalPackage),
                          success: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Services Header
          Text(
            'Included Services (${package.services.length})',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: kText,
            ),
          ),

          const SizedBox(height: 12),

          // Services Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 220,
            ),
            itemCount: package.services.length,
            itemBuilder: (context, i) {
              final service = package.services[i];
              return _ServiceCard(service: service);
            },
          ),

          const SizedBox(height: 20),

          // Package Info Footer
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Valid from ${DateFormat('MMM d').format(package.startDate)} to ${DateFormat('MMM d, yyyy').format(package.endDate)}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Colors.blue.shade800,
                    ),
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

/// 🎴 Service Card (Read-only, styled like services_customer_home.dart)
class _ServiceCard extends StatelessWidget {
  final PackageServiceItem service;

  const _ServiceCard({required this.service});

  String _money(double v) => '₪${v.toStringAsFixed(0)}';

  IconData _getIcon() {
    switch (service.category.toLowerCase()) {
      case 'venues':
        return Icons.location_city_rounded;
      case 'photographers':
        return Icons.camera_alt_rounded;
      case 'catering':
        return Icons.restaurant_rounded;
      case 'cake':
        return Icons.cake_rounded;
      case 'flower shops':
        return Icons.local_florist_rounded;
      case 'decor & lighting':
        return Icons.lightbulb_rounded;
      case 'music & entertainment':
        return Icons.music_note_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDiscount = service.originalPrice > service.newPrice;

    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Header
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: kBrandBlue.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Center(
              child: Icon(
                _getIcon(),
                color: kBrandBlue,
                size: 32,
              ),
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.serviceName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: kText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: kMuted,
                    ),
                  ),
                  const Spacer(),

                  // Price
                  if (hasDiscount) ...[
                    Text(
                      _money(service.originalPrice),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        color: kMuted,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _money(service.newPrice),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: kBrandBlue,
                          ),
                        ),
                      ),
                      if (hasDiscount)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Text(
                            '-${_money(service.originalPrice - service.newPrice)}',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Constraints
                  if (service.maxHours != null ||
                      service.maxCapacity != null) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (service.maxHours != null)
                          _Tag(
                            icon: Icons.access_time_rounded,
                            text: 'Max ${service.maxHours}h',
                          ),
                        if (service.maxCapacity != null)
                          _Tag(
                            icon: Icons.people_rounded,
                            text: 'Max ${service.maxCapacity}',
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 🏷️ Tag Widget
class _Tag extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Tag({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: kMuted),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: kText,
            ),
          ),
        ],
      ),
    );
  }
}

/// 💰 Price Column
class _PriceColumn extends StatelessWidget {
  final String label;
  final String value;
  final bool strikethrough;
  final bool highlight;
  final bool success;

  const _PriceColumn({
    required this.label,
    required this.value,
    this.strikethrough = false,
    this.highlight = false,
    this.success = false,
  });

  @override
  Widget build(BuildContext context) {
    Color valueColor = kText;
    if (highlight) valueColor = kBrandBlue;
    if (success) valueColor = Colors.green.shade700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: kMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: valueColor,
            decoration: strikethrough ? TextDecoration.lineThrough : null,
          ),
        ),
      ],
    );
  }
}