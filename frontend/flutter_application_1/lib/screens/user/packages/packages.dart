// lib/screens/packages.dart (REFACTORED)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../payment/cart.dart';
import 'package:flutter_application_1/services/package_service/package_service.dart';
import 'package:flutter_application_1/services/package_service/add_to_cart_packages.dart';
import 'package:flutter_application_1/widgets/package_booking_modal.dart';
import 'package:flutter_application_1/widgets/package_services_view.dart';
import 'package:flutter_application_1/services/payment_service/cart_service.dart';

/// ✅ Brand Blue (ARGB)
const Color kBrandBlue = Color.fromARGB(215, 20, 20, 215);

/// 🎨 Clean palette
const Color kBg = Color(0xFFF6F7FB);
const Color kCard = Colors.white;
const Color kText = Color(0xFF0B1220);
const Color kMuted = Color(0xFF6B7280);
const Color kBorder = Color(0xFFE5E7EB);
const Color kDanger = Color(0xFFEF4444);

class PackagesPage extends StatefulWidget {
  const PackagesPage({super.key});

  @override
  State<PackagesPage> createState() => _PackagesPageState();
}

class _PackagesPageState extends State<PackagesPage> {
  final _searchCtrl = TextEditingController();

  bool _loading = true;
  String? _error;
  List<PackageModel> _allPackages = [];

  String _city = 'All';
  String _category = 'All';

  final _cities = const [
    'All',
    'Nablus',
    'Ramallah',
    'Jenin',
    'Tulkarm',
    'Qalqilia',
    'Salfit',
    'Tubas',
    'Hebron',
    'Bethlehem',
  ];

  final _categories = const [
    'All',
    'Venues',
    'Photographers',
    'Catering',
    'Cake',
    'Flower Shops',
    'Decor & Lighting',
    'Music & Entertainment',
    'Wedding Planners & Coordinators',
    'Card Printing',
    'Jewelry & Accessories',
    'Car Rental & Transportation',
    'Gift & Souvenir',
  ];

  @override
  void initState() {
    super.initState();
    _loadPackages();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPackages() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final packages = await PackageService.getActivePackages();
      setState(() {
        _allPackages = packages;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _toast(String msg, {bool danger = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        backgroundColor: danger ? kDanger : kText,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1100),
      ),
    );
  }

  List<PackageModel> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();

    return _allPackages.where((p) {
      final cityOk =
          (_city == 'All') || (p.city.toLowerCase() == _city.toLowerCase());
      final catOk = (_category == 'All') ||
          p.categories.any((c) => c.toLowerCase() == _category.toLowerCase());

      final searchOk = q.isEmpty ||
          p.packageName.toLowerCase().contains(q) ||
          p.companyName.toLowerCase().contains(q) ||
          p.city.toLowerCase().contains(q) ||
          p.services.any((s) => s.serviceName.toLowerCase().contains(q));

      return cityOk && catOk && searchOk;
    }).toList();
  }

  void _goToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartPage()),
    );
  }

  Future<void> _handleAddToCart(PackageModel package) async {
    // 1. Show booking modal to collect service details
    final bookings = await showPackageBookingModal(
      context: context,
      package: package,
    );

    if (bookings == null || bookings.isEmpty) {
      // User cancelled
      return;
    }

    // 2. Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: kBrandBlue),
      ),
    );

    try {
      // 3. Call API to add package to cart
      final dto = AddPackageToCartDto(
        packageId: package.id,
        serviceBookings: bookings,
      );

      final cartResponse = await PackageCartService.addPackageToCart(dto);

      // 4. Update cart store
      CartStore.instance.updateFromBackend(cartResponse.items);

      // 5. Close loading
      if (mounted) Navigator.pop(context);

      // 6. Show success
      _toast('Package added to cart ✅');
    } catch (e) {
      // Close loading
      if (mounted) Navigator.pop(context);

      // Show error
      _toast(
        e.toString().replaceAll('Exception: ', ''),
        danger: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: kText),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Packages',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: kText,
          ),
        ),
        actions: [
          // ✅ Cart icon with LIVE badge
          ValueListenableBuilder<int>(
            valueListenable: CartStore.instance.count,
            builder: (_, c, __) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    tooltip: "Cart",
                    onPressed: _goToCart,
                    icon: const Icon(Icons.shopping_cart_rounded, color: kText),
                  ),
                  if (c > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: kBrandBlue,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(
                          '$c',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            onPressed: _loadPackages,
            icon: const Icon(Icons.refresh_rounded, color: kText),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          _TopControls(
            searchCtrl: _searchCtrl,
            cities: _cities,
            city: _city,
            onCityChanged: (v) => setState(() => _city = v),
          ),
          _CategoryStrip(
            categories: _categories,
            selected: _category,
            onSelected: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _ErrorState(error: _error!, onRetry: _loadPackages)
                    : list.isEmpty
                        ? _EmptyState(onRefresh: _loadPackages)
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                            itemCount: list.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final pkg = list[i];
                              return _PackageCard(
                                package: pkg,
                                onAdd: () => _handleAddToCart(pkg),
                                onViewInside: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          PackageServicesViewPage(package: pkg),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// Widgets
// ------------------------------------------------------------

class _TopControls extends StatelessWidget {
  final TextEditingController searchCtrl;
  final List<String> cities;
  final String city;
  final ValueChanged<String> onCityChanged;

  const _TopControls({
    required this.searchCtrl,
    required this.cities,
    required this.city,
    required this.onCityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBorder),
              ),
              child: TextField(
                controller: searchCtrl,
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600, color: kText),
                decoration: InputDecoration(
                  hintText: "Search packages...",
                  hintStyle: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w500, color: kMuted),
                  prefixIcon: const Icon(Icons.search_rounded, color: kMuted),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: city,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: kMuted),
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w800, color: kText),
                items: cities
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => v == null ? null : onCityChanged(v),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  const _CategoryStrip({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  IconData _iconFor(String c) {
    switch (c) {
      case 'Venues':
        return Icons.location_city_rounded;
      case 'Photographers':
        return Icons.photo_camera_rounded;
      case 'Catering':
        return Icons.restaurant_rounded;
      case 'Cake':
        return Icons.cake_rounded;
      case 'Flower Shops':
        return Icons.local_florist_rounded;
      case 'Decor & Lighting':
        return Icons.lightbulb_rounded;
      case 'Music & Entertainment':
        return Icons.music_note_rounded;
      case 'Wedding Planners & Coordinators':
        return Icons.event_available_rounded;
      case 'Card Printing':
        return Icons.mail_rounded;
      case 'Jewelry & Accessories':
        return Icons.diamond_rounded;
      case 'Car Rental & Transportation':
        return Icons.directions_car_rounded;
      case 'Gift & Souvenir':
        return Icons.card_giftcard_rounded;
      default:
        return Icons.grid_view_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = categories[i];
          final isOn = c == selected;

          return InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => onSelected(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isOn ? kBrandBlue : kCard,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: isOn ? Colors.transparent : kBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_iconFor(c),
                      size: 16, color: isOn ? Colors.white : kMuted),
                  const SizedBox(width: 8),
                  Text(
                    c,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: isOn ? Colors.white : kText,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PackageCard extends StatefulWidget {
  final PackageModel package;
  final VoidCallback onAdd;
  final VoidCallback onViewInside;

  const _PackageCard({
    required this.package,
    required this.onAdd,
    required this.onViewInside,
  });

  @override
  State<_PackageCard> createState() => _PackageCardState();
}

class _PackageCardState extends State<_PackageCard> {
  bool _expanded = false;

  final _money = NumberFormat.currency(symbol: '₪ ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final p = widget.package;

    final dateFmt = DateFormat('MMM d, yyyy');
    final rangeText =
        "${dateFmt.format(p.startDate)}  →  ${dateFmt.format(p.endDate)}";

    final offText = "${p.discountPercent.toStringAsFixed(0)}% OFF";

    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: SizedBox(
              height: 150,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _Image(p.imageUrl ?? ''),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.35),
                          Colors.black.withOpacity(0.05),
                          Colors.black.withOpacity(0.45),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: _Pill(
                      text: p.city,
                      icon: Icons.place_rounded,
                      bg: Colors.white.withOpacity(0.92),
                      fg: kText,
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: _Pill(
                      text: offText,
                      icon: Icons.local_offer_rounded,
                      bg: kBrandBlue,
                      fg: Colors.white,
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.packageName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.companyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9),
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
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.date_range_rounded,
                        size: 16, color: kMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        rangeText,
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: kText),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: kBg,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: kBorder),
                      ),
                      child: Text(
                        "${p.services.length} services",
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: kText),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _PriceCol(
                          label: "Original",
                          value: _money.format(p.totalOriginal),
                          muted: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PriceCol(
                          label: "Package",
                          value: _money.format(p.totalPackage),
                          accent: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PriceCol(
                          label: "You Save",
                          value: _money.format(
                              (p.totalOriginal - p.totalPackage)
                                  .clamp(0, double.infinity)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // ---------------------------
                // ✅ What's inside button
                // ---------------------------
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: widget.onViewInside,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.view_list_rounded,
                            size: 18, color: kText),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "What's inside (services)",
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: kText),
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: kMuted),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ---------------------------
                // ✅ Add to Cart Button (NO date picker here)
                // ---------------------------
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBrandBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: widget.onAdd,
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                    label: Text(
                      "Add to Cart",
                      style: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w900),
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

class _Image extends StatelessWidget {
  final String url;
  const _Image(this.url);

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) {
      return Container(
        color: Colors.black.withOpacity(0.06),
        child: const Center(
            child: Icon(Icons.image_rounded, color: kMuted, size: 34)),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        color: Colors.black.withOpacity(0.05),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (_, __, ___) => Container(
        color: Colors.black.withOpacity(0.06),
        child: const Center(
            child: Icon(Icons.broken_image_rounded, color: kMuted, size: 34)),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color bg;
  final Color fg;

  const _Pill(
      {required this.text,
      required this.icon,
      required this.bg,
      required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(
                fontSize: 11, fontWeight: FontWeight.w900, color: fg),
          ),
        ],
      ),
    );
  }
}

class _PriceCol extends StatelessWidget {
  final String label;
  final String value;
  final bool muted;
  final bool accent;

  const _PriceCol(
      {required this.label,
      required this.value,
      this.muted = false,
      this.accent = false});

  @override
  Widget build(BuildContext context) {
    final valueColor = accent ? kBrandBlue : (muted ? kMuted : kText);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
              fontSize: 11, fontWeight: FontWeight.w700, color: kMuted),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
              fontSize: 13, fontWeight: FontWeight.w900, color: valueColor),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;
  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_rounded, color: kMuted, size: 34),
            const SizedBox(height: 10),
            Text(
              "No packages found.",
              style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w900, color: kText),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => onRefresh(),
              child: Text(
                "Refresh",
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900, color: kBrandBlue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: kDanger, size: 48),
            const SizedBox(height: 12),
            Text(
              "Failed to load packages",
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w900, color: kText),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w600, color: kMuted),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                "Retry",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}