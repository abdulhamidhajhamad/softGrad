import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'cart.dart';
import 'chat_inside_search.dart';

const Color kPrimary = Color.fromARGB(215, 20, 20, 215);
const Color kBg = Color(0xFFF6F7FB);
const Color kText = Color(0xFF0B1220);
const Color kMuted = Color(0xFF6B7280);
const Color kDanger = Color(0xFFEF4444);

class ServiceDetailsData {
  final String id;
  final String serviceName;
  final String imageUrl;
  final String category;
  final String city;
  final double price;
  final double? oldPrice;
  final String description;

  final String companyName;
  final String contactEmail;
  final String contactPhone;

  const ServiceDetailsData({
    required this.id,
    required this.serviceName,
    required this.imageUrl,
    required this.category,
    required this.city,
    required this.price,
    required this.description,
    required this.companyName,
    required this.contactEmail,
    required this.contactPhone,
    this.oldPrice,
  });

  bool get hasDiscount =>
      oldPrice != null && oldPrice! > price && oldPrice! > 0;

  int get discountPercent {
    if (!hasDiscount) return 0;
    final p = ((oldPrice! - price) / oldPrice!) * 100;
    return p.round().clamp(1, 95);
  }
}

class ServiceInsideSearchScreen extends StatelessWidget {
  final ServiceDetailsData data;
  final String heroTag;

  const ServiceInsideSearchScreen({
    super.key,
    required this.data,
    required this.heroTag,
  });

  String _money(double v) => '₪${v.toStringAsFixed(0)}';

  void _openChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatInsideSearchScreen(
          providerName: data.companyName,
          providerEmail: data.contactEmail,
          providerPhone: data.contactPhone,
        ),
      ),
    );
  }

  void _addToCart(BuildContext context) {
    final store = CartStore.instance;

    store.add(
            CartItem(
        id: data.id,
        serviceName: data.serviceName,  // ✅ صح - استخدم serviceName بدل title
        companyName: data.companyName,   // ✅ صح - استخدم companyName بدل providerName
        price: data.price,
        imageUrl: data.imageUrl,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added to cart',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: kText,
        duration: const Duration(milliseconds: 1100),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = CartStore.instance;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: kText),
        title: Text(
          'Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: kText),
        ),
      ),

      // ✅ BODY
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            16, 10, 16, 130), // مهم عشان ما يغطي البوتوم بار
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Hero(
                  tag: heroTag,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: data.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: const Color(0xFFF1F5F9)),
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFFF1F5F9),
                        alignment: Alignment.center,
                        child: Icon(Icons.image,
                            color: Colors.black.withOpacity(0.35)),
                      ),
                    ),
                  ),
                ),
                if (data.hasDiscount)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: kDanger.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '-${data.discountPercent}%',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            data.serviceName,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: kText,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Pill(icon: Icons.grid_view_rounded, text: data.category),
              _Pill(icon: Icons.location_on_rounded, text: data.city),
              _Pill(icon: Icons.payments_rounded, text: _money(data.price)),
              if (data.hasDiscount)
                _Pill(
                  icon: Icons.local_offer_rounded,
                  text: _money(data.oldPrice!),
                  dangerStrike: true,
                ),
            ],
          ),
          const SizedBox(height: 16),
          _Card(
            title: 'Description',
            child: Text(
              data.description,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: kMuted,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _Card(
            title: 'Company Info',
            child: Column(
              children: [
                _Line(
                    icon: Icons.apartment_rounded,
                    label: 'Company',
                    value: data.companyName),
                const SizedBox(height: 10),
                _Line(
                    icon: Icons.email_rounded,
                    label: 'Email',
                    value: data.contactEmail),
                const SizedBox(height: 10),
                _Line(
                    icon: Icons.phone_rounded,
                    label: 'Phone',
                    value: data.contactPhone),
              ],
            ),
          ),
        ],
      ),

      // ✅ BOTTOM ACTIONS: Chat + Add to Cart
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border:
                Border(top: BorderSide(color: Colors.black.withOpacity(0.06))),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 24,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: ValueListenableBuilder<List<CartItem>>(
            valueListenable: store.itemsListenable,
            builder: (_, items, __) {
              final inCart = items.any((e) => e.id == data.id);

              return Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openChat(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.black.withOpacity(0.14)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                      ),
                      icon: Icon(Icons.chat_bubble_rounded, color: kPrimary),
                      label: Text(
                        'Chat',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w900, color: kText),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: inCart ? null : () => _addToCart(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kText,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                      ),
                      icon: Icon(
                        inCart
                            ? Icons.check_rounded
                            : Icons.add_shopping_cart_rounded,
                        color: kPrimary,
                      ),
                      label: Text(
                        inCart ? 'Added' : 'Add to cart',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w900,
              color: kText,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool dangerStrike;
  const _Pill(
      {required this.icon, required this.text, this.dangerStrike = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: kPrimary),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w900,
              color: dangerStrike ? kDanger : kText,
              decoration: dangerStrike ? TextDecoration.lineThrough : null,
              decorationThickness: 2.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Line({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: kPrimary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '$label: $value',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: kText,
            ),
          ),
        ),
      ],
    );
  }
}