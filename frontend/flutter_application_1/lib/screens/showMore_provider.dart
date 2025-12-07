// lib/screens/showMore_provider.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'full_image_viewer_provider.dart';

// NEW: import شاشة الريفيوز
import 'service_reviews_provider.dart';

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
  // دالة صغيرة لتحويل service['reviews'] (لو موجودة) إلى List<ServiceReview>
  List<ServiceReview> _extractReviews() {
    final raw = widget.service['reviews'];
    if (raw is! List) return [];

    return raw
        .map<ServiceReview?>((item) {
          if (item is! Map) return null;
          final map = Map<String, dynamic>.from(item as Map);

          int rating =
              int.tryParse(map['rating']?.toString() ?? '') ?? 0; // 0..∞
          if (rating < 1) rating = 1;
          if (rating > 5) rating = 5;

          DateTime createdAt;
          final rawDate = map['createdAt'];
          if (rawDate is DateTime) {
            createdAt = rawDate;
          } else {
            createdAt =
                DateTime.tryParse(rawDate?.toString() ?? '') ?? DateTime.now();
          }

          return ServiceReview(
            id: map['id']?.toString() ?? '',
            customerName: map['customerName']?.toString() ?? 'Customer',
            rating: rating,
            comment: map['comment']?.toString() ?? '',
            createdAt: createdAt,
          );
        })
        .whereType<ServiceReview>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.service;

    final images = List<String>.from(s['images'] ?? []);
    final highlights = List<String>.from(s['highlights'] ?? []);
    final packages = List<Map<String, dynamic>>.from(s['packages'] ?? []);

    // -----------------------------
    // ⭐ حساب الخصم والسعر الجديد
    // -----------------------------
    final double oldPrice = (s['price'] ?? 0).toDouble();
    final bool hasDiscount =
        s["discount"] != null && s["discount"].toString().trim().isNotEmpty;

    double finalPrice = oldPrice;
    if (hasDiscount) {
      final d = double.tryParse(s['discount'].toString()) ?? 0;
      finalPrice = oldPrice - (oldPrice * (d / 100));
    }

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
        // NEW: زر Reviews يفتح شاشة الريفيوز
        actions: [
          IconButton(
            icon: const Icon(Icons.rate_review_outlined, color: Colors.black),
            tooltip: 'View reviews',
            onPressed: () {
              final reviews = _extractReviews();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ServiceReviewsProviderScreen(
                    service: s,
                    reviews: reviews,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 14),

            // ⭐ الصورة + badge الخصم (بدون حذف شيء)
            Stack(
              children: [
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

                // ⭐ Badge خصم — إضافة فقط بدون حذف شيء
                if (hasDiscount)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "-${s['discount']}%",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 24),

            // -----------------------
            // المعلومات الأساسية
            // -----------------------
            _sectionTitle("Basic Info"),
            _card(
              Column(
                children: [
                  _iconInfo("Service Name", s["name"] ?? "-", Icons.star),
                  if (s["brand"] != null &&
                      s["brand"].toString().trim().isNotEmpty) ...[
                    _divider(),
                    _iconInfo("Brand Name", s["brand"], Icons.storefront),
                  ],
                  if (s["tagline"] != null &&
                      s["tagline"].toString().trim().isNotEmpty) ...[
                    _divider(),
                    _iconInfo("Short Tagline", s["tagline"], Icons.short_text),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // -----------------------
            // القسم: الفئة والموقع
            // -----------------------
            _sectionTitle("Category & Location"),
            _card(
              Column(
                children: [
                  _iconInfo("Category", s["category"] ?? "-",
                      Icons.grid_view_rounded),
                  _divider(),
                  _iconInfo(
                      "City", s["city"] ?? "-", Icons.location_on_outlined),
                  if (s["address"] != null &&
                      s["address"].toString().trim().isNotEmpty) ...[
                    _divider(),
                    _iconInfo("Address", s["address"], Icons.map_outlined),
                  ]
                ],
              ),
            ),

            const SizedBox(height: 20),

            // -----------------------
            // ⭐ القسم: السعر والخصم
            // -----------------------
            _sectionTitle("Pricing & Packages"),
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // سعر (معدل + شطب)
                  Row(
                    children: [
                      if (hasDiscount)
                        Text(
                          "₪${oldPrice.toStringAsFixed(0)}",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      if (hasDiscount) const SizedBox(width: 8),
                      Text(
                        "₪${finalPrice.toStringAsFixed(0)}",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: hasDiscount ? Colors.red : Colors.black,
                        ),
                      ),
                    ],
                  ),

                  if (hasDiscount) ...[
                    const SizedBox(height: 12),
                    _divider(),
                    _iconInfo("Discount", "${s['discount']}%",
                        Icons.local_offer_outlined),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // -----------------------
            // التفاصيل (وصف واحد)
            // -----------------------
            _sectionTitle("Description"),
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _textTitle("Description"),
                  _textBody(
                    s["fullDescription"] ?? s["shortDescription"] ?? "-",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // -----------------------
            // الهايلايت
            // -----------------------
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

            // -----------------------
            // الباكجات
            // -----------------------
            if (packages.isNotEmpty) ...[
              _sectionTitle("Packages"),
              Column(children: packages.map((p) => _packageCard(p)).toList()),
            ],

            const SizedBox(height: 90),
          ],
        ),
      ),
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
          onPressed: () => Navigator.pop(context, {
            "edit": true,
            "service": s, // ← لازم نرجّع بيانات الخدمة الأصلية
          }),
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

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _card(Widget child) => Container(
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

  Widget _divider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Container(
          height: 1,
          color: Colors.grey.shade300,
        ),
      );

  Widget _iconInfo(String title, String value, IconData icon) => Row(
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

  Widget _textTitle(String text) => Text(
        text,
        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
      );

  Widget _textBody(String? text) => Text(
        text ?? "-",
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.grey.shade800,
          height: 1.4,
        ),
      );

  Widget _packageCard(Map<String, dynamic> p) => Container(
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
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.grey.shade700),
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
                    "₪${p["price"]}",
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
