// lib/screens/compnay_insider_provider.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services_customer_home.dart'; // ServiceItem + ServiceFavoritesStore + colors (kBg/kText/kBlue/kMuted)
import 'cart.dart' as cart; // ✅ alias to avoid conflicts
import 'chat_inside_search.dart' as chat; // ✅ prefix to avoid kText ambiguity

class CompanyInsiderProviderPage extends StatelessWidget {
  final String companyName;
  final String companyEmail;
  final String companyPhone;
  final String city;

  /// ✅ Company images are NOT service images
  final String? companyCoverUrl; // cover/banner
  final String? companyLogoUrl; // logo/avatar

  final List<ServiceItem> services;

  const CompanyInsiderProviderPage({
    super.key,
    required this.companyName,
    required this.companyEmail,
    required this.companyPhone,
    required this.city,
    required this.services,
    this.companyCoverUrl,
    this.companyLogoUrl,
  });

  String _money(double v) => '₪${v.toStringAsFixed(0)}';

  int _totalReviews() {
    int total = 0;
    for (final s in services) {
      if (s.reviewsCount > 0) total += s.reviewsCount;
    }
    return total;
  }

  /// ✅ Weighted average by review counts (more منطقي)
  double _companyAvgRating() {
    double weightedSum = 0;
    int total = 0;

    for (final s in services) {
      if (s.reviewsCount > 0) {
        weightedSum += (s.rating * s.reviewsCount);
        total += s.reviewsCount;
      }
    }

    if (total == 0) return 0;
    return weightedSum / total;
  }

  String? _safeUrl(String? u) {
    final t = (u ?? '').trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _confirmCall(BuildContext context, String phone) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Make a call?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
        ),
        content: Text(
          phone,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kText,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Call',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: kText,
        content: Text(
          'Call action: tel:$phone (enable url_launcher to dial)',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Future<void> _openEmail(BuildContext context, String email) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: kText,
        content: Text(
          'Email action: mailto:$email (enable url_launcher)',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  void _openChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => chat.ChatInsideSearchScreen(
          providerName: companyName,
          providerEmail: companyEmail,
          providerPhone: companyPhone,
        ),
      ),
    );
  }

  void _openServiceSheet(BuildContext context, ServiceItem s) {
    String priceText() {
      if (s.price <= 0) return 'Ask for price';
      if (s.hasDiscount && s.discountPrice != null) {
        return '${_money(s.discountPrice!)}  (was ${_money(s.price)})';
      }
      return _money(s.price);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.black.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.serviceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w900,
                          color: kText,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${s.category} • ${s.city}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: kMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _MiniChip(
                      icon: Icons.star_rounded,
                      text: s.rating.toStringAsFixed(1),
                    ),
                    const SizedBox(width: 8),
                    _MiniChip(
                      icon: Icons.rate_review_rounded,
                      text: '${s.reviewsCount}',
                    ),
                    const Spacer(),
                    Text(
                      priceText(),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w900,
                        color: kText,
                      ),
                    ),
                  ],
                ),
                if (s.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Description',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w900,
                      color: kText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.description,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: kMuted,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _openEmail(context, companyEmail);
                        },
                        icon: const Icon(Icons.mark_email_unread_rounded),
                        label: Text(
                          'Email company',
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w900),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kText,
                          side:
                              BorderSide(color: Colors.black.withOpacity(0.12)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _openChat(context);
                        },
                        icon: const Icon(Icons.forum_rounded),
                        label: Text(
                          'Chat company',
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w900),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kText,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final avg = _companyAvgRating();
    final totalReviews = _totalReviews();

    final cover = _safeUrl(companyCoverUrl);
    final logo = _safeUrl(companyLogoUrl);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.6,
        title: Text(
          companyName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: kText),
        ),
        iconTheme: const IconThemeData(color: kText),
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: cart.CartStore.instance.count,
            builder: (_, c, __) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    tooltip: 'Cart',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const cart.CartPage()),
                      );
                    },
                    icon: const Icon(Icons.shopping_bag_rounded, color: kText),
                  ),
                  if (c > 0)
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: kBlue,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          '$c',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        children: [
          // ===================== Company Profile Card =====================
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 22,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              children: [
                // cover
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(22)),
                  child: SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        Positioned.fill(child: _CoverImage(url: cover)),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.10),
                                  Colors.black.withOpacity(0.55),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: 14,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  companyName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.92),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.7)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.location_on_outlined,
                                        size: 16, color: kBlue),
                                    const SizedBox(width: 6),
                                    Text(
                                      city,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w900,
                                        color: kText,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _LogoAvatar(logoUrl: logo),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '$city • ${services.length} services',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w800,
                                color: kMuted,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // ✅ ONLY Avg + Reviews (no Range)
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              icon: Icons.star_rounded,
                              title: (avg == 0) ? '—' : avg.toStringAsFixed(1),
                              subtitle: 'Avg',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatTile(
                              icon: Icons.rate_review_rounded,
                              title: '$totalReviews',
                              subtitle: 'Reviews',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // actions (top only)
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              label: 'Chat',
                              icon: Icons.forum_rounded,
                              filled: true,
                              onTap: () => _openChat(context),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ActionButton(
                              label: 'Call',
                              icon: Icons.call_rounded,
                              filled: false,
                              onTap: () => _confirmCall(context, companyPhone),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ActionButton(
                              label: 'Email',
                              icon: Icons.mark_email_unread_rounded,
                              filled: false,
                              onTap: () => _openEmail(context, companyEmail),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),
                      _InfoRow(icon: Icons.email_rounded, text: companyEmail),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _confirmCall(context, companyPhone),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: _InfoRow(
                              icon: Icons.phone_rounded, text: companyPhone),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ===================== Services =====================
          Row(
            children: [
              Text(
                'Services',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w900,
                  color: kText,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                '${services.length}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w900,
                  color: kMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (services.isEmpty)
            const _EmptyBox(text: 'No services available for this company yet.')
          else
            for (final s in services) ...[
              _CompanyServiceTile(
                service: s,
                money: _money,
                onOpen: () => _openServiceSheet(context, s),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

// ===================== Widgets =====================

class _LogoAvatar extends StatelessWidget {
  final String? logoUrl;
  const _LogoAvatar({required this.logoUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: kBlue.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBlue.withOpacity(0.18)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: (logoUrl == null)
            ? const Icon(Icons.apartment_rounded, color: kBlue, size: 26)
            : Image.network(
                logoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.apartment_rounded, color: kBlue, size: 26),
              ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: filled ? kText : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: filled ? Colors.transparent : Colors.black.withOpacity(0.12),
          ),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: filled ? Colors.white : kText),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w900,
                color: filled ? Colors.white : kText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _StatTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kBlue.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kBlue.withOpacity(0.18)),
            ),
            child: Icon(icon, color: kBlue),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    maxLines: 1,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w900,
                      color: kText,
                      fontSize: 13.2,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    color: kMuted,
                    fontSize: 10.8,
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

class _CompanyServiceTile extends StatelessWidget {
  final ServiceItem service;
  final String Function(double) money;
  final VoidCallback onOpen;

  const _CompanyServiceTile({
    required this.service,
    required this.money,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    Widget priceWidget() {
      if (service.price <= 0) {
        return Text(
          'Ask for price',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w900,
            color: kText,
            fontSize: 12.8,
          ),
        );
      }

      // ✅ السعر تحت بعض (مش جنب بعض)
      if (service.hasDiscount && service.discountPrice != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              money(service.price),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w900,
                color: Colors.red,
                fontSize: 12.0,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              money(service.discountPrice!),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w900,
                color: kText,
                fontSize: 13.4,
              ),
            ),
          ],
        );
      }

      return Text(
        money(service.price),
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w900,
          color: kText,
          fontSize: 12.8,
        ),
      );
    }

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, // ✅ يخلي كل شي أعلى
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 56,
                height: 56,
                child: _CoverImage(
                  url: (service.imageUrl ?? '').trim().isEmpty
                      ? null
                      : service.imageUrl,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // ✅ النصوص
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2), // لمسة خفيفة للأعلى
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.serviceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w900,
                        color: kText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${service.category} • ${service.city}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        color: kMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    priceWidget(),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 10),

            // ✅ يمين الكارد: التقييم لفوق + المفضلة والسهم تحت
            _RightRail(service: service),
          ],
        ),
      ),
    );
  }
}

class _RightRail extends StatelessWidget {
  final ServiceItem service;
  const _RightRail({required this.service});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        _RatingPill(
          rating: service.rating,
          count: service.reviewsCount,
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<int>(
              valueListenable: ServiceFavoritesStore.listenable,
              builder: (_, __, ___) {
                final fav = ServiceFavoritesStore.isFavorite(service.id);
                return IconButton(
                  tooltip: 'Favorite',
                  onPressed: () => ServiceFavoritesStore.toggle(service.id),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints.tightFor(width: 40, height: 40),
                  icon: Icon(
                    fav
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: fav ? kBlue : kMuted,
                  ),
                );
              },
            ),
            const SizedBox(width: 2),
            const Icon(Icons.chevron_right_rounded, color: kMuted),
          ],
        ),
      ],
    );
  }
}

class _RatingPill extends StatelessWidget {
  final double rating;
  final int count;
  const _RatingPill({required this.rating, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 16, color: kBlue),
          const SizedBox(width: 6),
          Text(
            '${rating.toStringAsFixed(1)} ($count)',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w900,
              color: kText,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MiniChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: kBlue),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w900,
              color: kText,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: kBlue, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
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

class _EmptyBox extends StatelessWidget {
  final String text;
  const _EmptyBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: kMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: kMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  final String? url;
  const _CoverImage({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.trim().isEmpty) {
      return Container(
        color: kBlue.withOpacity(0.10),
        child: Icon(Icons.image_rounded, color: kBlue.withOpacity(0.9)),
      );
    }

    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: kBlue.withOpacity(0.10),
        child: Icon(Icons.broken_image_rounded, color: kBlue.withOpacity(0.9)),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: Colors.black.withOpacity(0.04),
          child: const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
          ),
        );
      },
    );
  }
}
