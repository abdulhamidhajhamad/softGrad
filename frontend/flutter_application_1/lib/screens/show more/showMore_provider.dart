// lib/screens/showMore_provider.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../full_image_viewer_provider.dart';
import '../service_reviews_provider.dart';

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
  // -------------------- Reviews --------------------
  List<ServiceReview> _extractReviews() {
    final raw = widget.service['reviews'];
    if (raw is! List) return [];

    return raw
        .map<ServiceReview?>((item) {
          if (item is! Map) return null;
          final map = Map<String, dynamic>.from(item as Map);

          int rating = int.tryParse(map['rating']?.toString() ?? '') ?? 0;
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

  // -------------------- Dynamic highlights (key/value) --------------------
  List<Map<String, String>> _normalizeHighlights(dynamic raw) {
    final out = <Map<String, String>>[];

    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          final m = Map<String, dynamic>.from(item);
          final k = (m['key'] ?? '').toString().trim();
          final v = (m['value'] ?? '').toString().trim();
          if (k.isNotEmpty || v.isNotEmpty) {
            out.add({'key': k, 'value': v});
          }
        } else if (item is String) {
          final s = item.trim();
          if (s.isEmpty) continue;

          if (s.contains('•')) {
            final parts = s.split('•');
            final k = parts.first.trim();
            final v = parts.length > 1 ? parts.sublist(1).join('•').trim() : '';
            out.add({'key': k, 'value': v});
          } else if (s.contains(':')) {
            final parts = s.split(':');
            final k = parts.first.trim();
            final v = parts.length > 1 ? parts.sublist(1).join(':').trim() : '';
            out.add({'key': k, 'value': v});
          } else {
            out.add({'key': s, 'value': ''});
          }
        }
      }
    }

    return out;
  }

  String _highlightText(Map<String, String> h) {
    final k = (h['key'] ?? '').trim();
    final v = (h['value'] ?? '').trim();
    if (k.isNotEmpty && v.isNotEmpty) return '$k • $v';
    if (k.isNotEmpty) return k;
    return v.isNotEmpty ? v : '-';
  }

  // -------------------- Dynamic key/value extra fields from DB --------------------
  List<MapEntry<String, String>> _extractDynamicPairs(Map<String, dynamic> s) {
    // keys already displayed in UI
    const excluded = {
      '_id',
      '__v',
      'images',
      'highlights',
      'packages',
      'reviews',
      'serviceName',
      'name',
      'brand',
      'companyName',
      'tagline',
      'category',
      'city',
      'address',
      'description',
      'shortDescription',
      'fullDescription',
      'price',
      'discount',
      'createdAt',
      'updatedAt',
      'likes',
      'bookings',
    };

    final out = <MapEntry<String, String>>[];

    void addPair(String k, dynamic v) {
      final key = k.trim();
      if (key.isEmpty) return;
      if (excluded.contains(key)) return;
      if (v == null) return;

      // ignore big/complex objects we handle elsewhere
      if (v is List && v.isEmpty) return;

      String valueStr = '';

      if (v is num || v is bool) {
        valueStr = v.toString();
      } else if (v is String) {
        valueStr = v.trim();
      } else if (v is DateTime) {
        valueStr = v.toIso8601String();
      } else if (v is List) {
        // list of primitives -> join
        final primitives = v.where(
            (e) => e is String || e is num || e is bool || e is DateTime);
        if (primitives.isNotEmpty) {
          valueStr = primitives
              .map((e) => e is DateTime ? e.toIso8601String() : e.toString())
              .join(', ');
        } else {
          return;
        }
      } else if (v is Map) {
        // flatten one level
        final m = Map<String, dynamic>.from(v);
        for (final e in m.entries) {
          final kk = '${key}.${e.key}';
          addPair(kk, e.value);
        }
        return;
      } else {
        // unknown type -> skip
        return;
      }

      if (valueStr.isEmpty) return;
      out.add(MapEntry(key, valueStr));
    }

    // 1) Top-level entries
    for (final e in s.entries) {
      addPair(e.key, e.value);
    }

    // 2) If additionalInfo exists (common pattern)
    final addInfo = s['additionalInfo'];
    if (addInfo is Map) {
      final m = Map<String, dynamic>.from(addInfo);
      for (final e in m.entries) {
        addPair('additionalInfo.${e.key}', e.value);
      }
    }

    // 3) If location exists, include latitude/longitude if not shown
    final loc = s['location'];
    if (loc is Map) {
      final m = Map<String, dynamic>.from(loc);
      // address/city already shown, but lat/long useful
      if (m.containsKey('latitude'))
        addPair('location.latitude', m['latitude']);
      if (m.containsKey('longitude'))
        addPair('location.longitude', m['longitude']);
    }

    // remove duplicates (keep first)
    final seen = <String>{};
    final unique = <MapEntry<String, String>>[];
    for (final p in out) {
      if (seen.add(p.key)) unique.add(p);
    }
    return unique;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.service;

    final images = List<String>.from(s['images'] ?? []);
    final highlightsPairs = _normalizeHighlights(s['highlights']);
    final packages = List<Map<String, dynamic>>.from(s['packages'] ?? []);

    // -----------------------------
    // Discount
    // -----------------------------
    final double oldPrice = (s['price'] ?? 0).toDouble();
    final bool hasDiscount =
        s["discount"] != null && s["discount"].toString().trim().isNotEmpty;

    double finalPrice = oldPrice;
    if (hasDiscount) {
      final d = double.tryParse(s['discount'].toString()) ?? 0;
      finalPrice = oldPrice - (oldPrice * (d / 100));
    }

    // ✅ Dynamic extra fields from DB
    final extraPairs = _extractDynamicPairs(Map<String, dynamic>.from(s));

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
                      height: 280,
                      decoration: BoxDecoration(color: Colors.grey.shade200),
                      child: images.isEmpty
                          ? Center(
                              child: Icon(Icons.image_outlined,
                                  color: Colors.grey, size: 60),
                            )
                          : PageView.builder(
                              itemCount: images.length,
                              itemBuilder: (_, i) => Image.network(
                                images[i],
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                  ),
                ),
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

            _sectionTitle("Basic Info"),
            _card(
              Column(
                children: [
                  _iconInfo(
                    "Service Name",
                    (s["serviceName"] ?? s["name"] ?? "-").toString(),
                    Icons.star,
                  ),
                  if (s["companyName"] != null &&
                      s["companyName"].toString().trim().isNotEmpty) ...[
                    _divider(),
                    _iconInfo("Company Name", s["companyName"].toString(),
                        Icons.storefront),
                  ],
                  if (s["brand"] != null &&
                      s["brand"].toString().trim().isNotEmpty) ...[
                    _divider(),
                    _iconInfo(
                        "Brand Name", s["brand"].toString(), Icons.storefront),
                  ],
                  if (s["tagline"] != null &&
                      s["tagline"].toString().trim().isNotEmpty) ...[
                    _divider(),
                    _iconInfo("Short Tagline", s["tagline"].toString(),
                        Icons.short_text),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            _sectionTitle("Category & Location"),
            _card(
              Column(
                children: [
                  _iconInfo(
                    "Category",
                    (s["category"] ?? "-").toString(),
                    Icons.grid_view_rounded,
                  ),
                  _divider(),
                  _iconInfo(
                    "City",
                    (s["location"]?["city"] ?? s["city"] ?? "-").toString(),
                    Icons.location_on_outlined,
                  ),
                  _divider(),
                  _iconInfo(
                    "Address",
                    ((s["location"]?["address"] ?? s["address"] ?? "")
                            .toString()
                            .trim()
                            .isEmpty)
                        ? "-"
                        : (s["location"]?["address"] ?? s["address"])
                            .toString(),
                    Icons.map_outlined,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _sectionTitle("Description"),
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _textTitle("Description"),
                  const SizedBox(height: 8),
                  _textBody(
                    (s["description"] ??
                            s["fullDescription"] ??
                            s["shortDescription"] ??
                            "-")
                        .toString(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _sectionTitle("Pricing Information"),
            _card(
              Column(
                children: [
                  _iconInfo(
                    "Price",
                    "₪${finalPrice.toStringAsFixed(0)}",
                    Icons.attach_money_rounded,
                  ),
                  if (hasDiscount) ...[
                    _divider(),
                    _iconInfo(
                      "Discount",
                      "-${s['discount']}%",
                      Icons.local_offer_outlined,
                    ),
                  ],
                ],
              ),
            ),

            // ✅✅ Dynamic extra fields from DB (key/value loop)
            if (extraPairs.isNotEmpty) ...[
              const SizedBox(height: 20),
              _sectionTitle("Additional Details"),
              _card(
                Column(
                  children: [
                    for (int i = 0; i < extraPairs.length; i++) ...[
                      _iconInfo(
                        extraPairs[i].key,
                        extraPairs[i].value,
                        Icons.info_outline_rounded,
                      ),
                      if (i != extraPairs.length - 1) _divider(),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ✅ Highlights key/value
            if (highlightsPairs.isNotEmpty) ...[
              _sectionTitle("Key Highlights"),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: highlightsPairs
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
                            Text(
                              _highlightText(h),
                              style: GoogleFonts.poppins(
                                  fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 28),
            ],

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
            "service": s,
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
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      );

  Widget _divider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Container(height: 1, color: Colors.grey.shade300),
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
              (p["name"] ?? "-").toString(),
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              (p["desc"] ?? p["description"] ?? "-").toString(),
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
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Text(
                    "₪${(p["price"] ?? "-").toString()}",
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