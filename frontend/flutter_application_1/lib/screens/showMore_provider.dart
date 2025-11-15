// lib/screens/showMore_provider.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'full_image_viewer_provider.dart';

const Color kPrimaryColor = Color.fromARGB(215, 20, 20, 215);

class ShowMoreProviderScreen extends StatefulWidget {
  final Map<String, dynamic> service;
  final Function(Map<String, dynamic>)? onEdit;

  const ShowMoreProviderScreen({
    Key? key,
    required this.service,
    this.onEdit,
  }) : super(key: key);

  @override
  State<ShowMoreProviderScreen> createState() => _ShowMoreProviderScreenState();
}

class _ShowMoreProviderScreenState extends State<ShowMoreProviderScreen> {
  @override
  Widget build(BuildContext context) {
    final s = widget.service;

    final images = List<String>.from(s['images'] ?? []);
    final highlights = List<String>.from(s['highlights'] ?? []);
    final packages = List<Map<String, dynamic>>.from(s['packages'] ?? []);

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.3,
        centerTitle: true,
        title: Text(
          "Service Details",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 14),

            // ===========================
            // COVER IMAGES (Carousel)
            // ===========================
            GestureDetector(
              onTap: () {
                if (images.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullImageViewer(images: images),
                    ),
                  );
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  height: 260,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                  ),
                  child: images.isEmpty
                      ? Center(
                          child: Icon(Icons.image_outlined,
                              color: Colors.grey, size: 60),
                        )
                      : PageView.builder(
                          itemCount: images.length,
                          itemBuilder: (_, i) => Image.file(
                            File(images[i]),
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ===========================
            // BASIC INFO
            // ===========================
            _sectionTitle("Basic Info"),
            _card(
              Column(
                children: [
                  _iconInfo("Service Name", s["name"] ?? "-", Icons.star),
                  _divider(),
                  _iconInfo("Brand Name", s["brand"] ?? "-", Icons.storefront),
                  _divider(),
                  _iconInfo("Short Tagline", s["shortDescription"] ?? "-",
                      Icons.short_text),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ===========================
            // CATEGORY & LOCATION
            // ===========================
            _sectionTitle("Category & Location"),
            _card(
              Column(
                children: [
                  _iconInfo("Category", s["category"] ?? "-",
                      Icons.grid_view_rounded),
                  _divider(),
                  _iconInfo(
                      "City", s["city"] ?? "-", Icons.location_on_outlined),
                  _divider(),
                  _iconInfo("Address", s["address"] ?? "-", Icons.map_outlined),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ===========================
            // PRICING
            // ===========================
            _sectionTitle("Pricing & Packages"),
            _card(
              Column(
                children: [
                  _iconInfo("Starting Price", "\$${s['price']}",
                      Icons.payments_rounded),
                  _divider(),
                  _iconInfo("Price Type", s["priceType"] ?? "-",
                      Icons.timer_outlined),
                  if (s["discount"] != null &&
                      s["discount"].toString().isNotEmpty) ...[
                    _divider(),
                    _iconInfo("Discount", "${s['discount']}%",
                        Icons.local_offer_outlined),
                  ]
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ===========================
            // DESCRIPTIONS
            // ===========================
            _sectionTitle("Description & Details"),
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _textTitle("Short Description"),
                  _textBody(s["shortDescription"]),
                  const SizedBox(height: 14),
                  _textTitle("Full Description"),
                  _textBody(s["fullDescription"]),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ===========================
            // HIGHLIGHTS
            // ===========================
            if (highlights.isNotEmpty) ...[
              _sectionTitle("Key Highlights"),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: highlights
                    .map(
                      (h) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded,
                                size: 18, color: kPrimaryColor),
                            const SizedBox(width: 8),
                            Text(h,
                                style: GoogleFonts.poppins(
                                    fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 28),
            ],

            // ===========================
            // PACKAGES — Modern Premium Cards
            // ===========================
            if (packages.isNotEmpty) ...[
              _sectionTitle("Packages"),
              Column(
                children: packages.map((p) => _packageCard(p)).toList(),
              ),
            ],

            const SizedBox(height: 90),
          ],
        ),
      ),

      // ===========================
      // EDIT BUTTON
      // ===========================
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () => Navigator.pop(context, {"edit": true}),
          icon: const Icon(Icons.edit, color: Colors.white),
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          label: Text(
            "Edit This Service",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // ===========================
  // WIDGET HELPERS
  // ===========================

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _card(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        height: 1,
        color: Colors.grey.shade300,
      ),
    );
  }

  Widget _iconInfo(String title, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: Colors.black87),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _textTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
    );
  }

  Widget _textBody(String? text) {
    return Text(
      text ?? "-",
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.grey.shade800,
        height: 1.4,
      ),
    );
  }

  Widget _packageCard(Map<String, dynamic> p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            kPrimaryColor.withOpacity(0.08),
            kPrimaryColor.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p["name"],
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            p["desc"],
            style:
                GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 5,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Text(
                  "\$${p["price"]}",
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: kPrimaryColor),
                ),
              ),
              Text(
                "View details →",
                style: GoogleFonts.poppins(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              )
            ],
          ),
        ],
      ),
    );
  }
}
