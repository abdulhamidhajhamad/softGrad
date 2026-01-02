
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import 'cart.dart'; // ✅ CartStore + CartPage

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

// ------------------------------------------------------------
// Models
// ------------------------------------------------------------

class ServiceInPackage {
  final String id;
  final String name;
  final String category;
  final String vendorName;
  final double originalPrice;
  final double packagePrice;

  ServiceInPackage({
    required this.id,
    required this.name,
    required this.category,
    required this.vendorName,
    required this.originalPrice,
    required this.packagePrice,
  });

  double get discountAmount =>
      (originalPrice - packagePrice).clamp(0, double.infinity);
}

class PackageItem {
  final String id;
  final String name;
  final String companyName;
  final String city;
  final String imageUrl;

  final DateTime startDate;
  final DateTime endDate;

  final List<String> categories;
  final List<ServiceInPackage> services;

  PackageItem({
    required this.id,
    required this.name,
    required this.companyName,
    required this.city,
    required this.imageUrl,
    required this.startDate,
    required this.endDate,
    required this.categories,
    required this.services,
  });

  double get totalOriginal => services.fold(0.0, (s, x) => s + x.originalPrice);
  double get totalPackage => services.fold(0.0, (s, x) => s + x.packagePrice);

  double get offPercent {
    final o = totalOriginal;
    final p = totalPackage;
    if (o <= 0) return 0;
    return (((o - p) / o) * 100).clamp(0, 100);
  }
}

// ------------------------------------------------------------
// Demo Data
// ------------------------------------------------------------

List<PackageItem> demoPackages() {
  final now = DateTime.now();
  DateTime d(int add) => DateTime(now.year, now.month, now.day + add);

  return [
    PackageItem(
      id: "demo-1",
      name: "Royal Wedding Bundle",
      companyName: "Golden Moments Co.",
      city: "Nablus",
      imageUrl:
          "https://images.unsplash.com/photo-1529634806980-85c3dd6d34ac?auto=format&fit=crop&w=1200&q=60",
      startDate: d(2),
      endDate: d(30),
      categories: const ["Venues", "Photographers", "Decor & Lighting"],
      services: [
        ServiceInPackage(
          id: "s1",
          name: "Luxury Venue (4 hours)",
          category: "Venues",
          vendorName: "Golden Hall",
          originalPrice: 4500,
          packagePrice: 3600,
        ),
        ServiceInPackage(
          id: "s2",
          name: "Photography + Highlights",
          category: "Photographers",
          vendorName: "Lens Studio",
          originalPrice: 2500,
          packagePrice: 2000,
        ),
        ServiceInPackage(
          id: "s3",
          name: "Decor & Lighting Basic",
          category: "Decor & Lighting",
          vendorName: "LightCraft",
          originalPrice: 1800,
          packagePrice: 1400,
        ),
      ],
    ),
    PackageItem(
      id: "demo-2",
      name: "Classic Engagement Package",
      companyName: "White & Blue Events",
      city: "Ramallah",
      imageUrl:
          "https://images.unsplash.com/photo-1529634897861-1f81e4a6f6d7?auto=format&fit=crop&w=1200&q=60",
      startDate: d(1),
      endDate: d(20),
      categories: const ["Cake", "Flower Shops", "Card Printing"],
      services: [
        ServiceInPackage(
          id: "s4",
          name: "Engagement Cake (2-tier)",
          category: "Cake",
          vendorName: "SugarCraft",
          originalPrice: 900,
          packagePrice: 750,
        ),
        ServiceInPackage(
          id: "s5",
          name: "Bouquet + Table Flowers",
          category: "Flower Shops",
          vendorName: "Bloom House",
          originalPrice: 650,
          packagePrice: 520,
        ),
        ServiceInPackage(
          id: "s6",
          name: "Invitation Cards (100)",
          category: "Card Printing",
          vendorName: "Printy",
          originalPrice: 400,
          packagePrice: 320,
        ),
      ],
    ),
    PackageItem(
      id: "demo-3",
      name: "Music Night Pack",
      companyName: "Vibe Entertainment",
      city: "Bethlehem",
      imageUrl:
          "https://images.unsplash.com/photo-1511285560929-80b456fea0bc?auto=format&fit=crop&w=1200&q=60",
      startDate: d(5),
      endDate: d(40),
      categories: const [
        "Music & Entertainment",
        "Car Rental & Transportation"
      ],
      services: [
        ServiceInPackage(
          id: "s7",
          name: "DJ Set (3 hours)",
          category: "Music & Entertainment",
          vendorName: "Vibe DJ",
          originalPrice: 1200,
          packagePrice: 950,
        ),
        ServiceInPackage(
          id: "s8",
          name: "Wedding Car (1 day)",
          category: "Car Rental & Transportation",
          vendorName: "DriveLux",
          originalPrice: 700,
          packagePrice: 560,
        ),
      ],
    ),
  ];
}

// ------------------------------------------------------------
// Page State
// ------------------------------------------------------------

class _PackagesPageState extends State<PackagesPage> {
  final _searchCtrl = TextEditingController();

  bool _loading = true;
  List<PackageItem> _all = [];

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
    _load();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 250));
    setState(() {
      _all = demoPackages(); // ✅ front-end demo
      _loading = false;
    });
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

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  List<PackageItem> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();

    return _all.where((p) {
      final cityOk =
          (_city == 'All') || (p.city.toLowerCase() == _city.toLowerCase());
      final catOk = (_category == 'All') ||
          p.categories.any((c) => c.toLowerCase() == _category.toLowerCase());

      final searchOk = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.companyName.toLowerCase().contains(q) ||
          p.city.toLowerCase().contains(q) ||
          p.services.any((s) => s.name.toLowerCase().contains(q));

      return cityOk && catOk && searchOk;
    }).toList();
  }

  void _goToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartPage()),
    );
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
            onPressed: _load,
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
                : list.isEmpty
                    ? _EmptyState(onRefresh: _load)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final pkg = list[i];

                          return InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: _goToCart,
                            child: _PackageCard(
                              item: pkg,
                              onAdd: (p, chosenDate) async {
                                // ✅ Validate date inside window
                                final min = _dateOnly(p.startDate);
                                final max = _dateOnly(p.endDate);
                                final d = _dateOnly(chosenDate);

                                if (d.isBefore(min) || d.isAfter(max)) {
                                  _toast(
                                    "Booking date must be within the package availability window.",
                                    danger: true,
                                  );
                                  return;
                                }

                                // ✅ Add to cart + badge updates + saved in cart page
                                CartStore.instance.add(
                                  CartItem(
                                    id: 'pkg-${p.id}',
                                    title: p.name, // ✅ تغيير serviceName إلى title
                                    providerName: p.companyName, // ✅ تغيير companyName إلى providerName
                                    price: p.totalPackage,
                                    imageUrl: p.imageUrl,
                                    category: 'Packages', // ✅ تغيير ليكون نفس التنسيق
                                    city: p.city,
                                  ),
                                );

                                _toast("Added to cart ✅");
                              },
                            ),
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
                  hintText: "Search packages, company, service...",
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
  final PackageItem item;
  final Future<void> Function(PackageItem pkg, DateTime chosenDate) onAdd;

  const _PackageCard({
    required this.item,
    required this.onAdd,
  });

  @override
  State<_PackageCard> createState() => _PackageCardState();
}

class _PackageCardState extends State<_PackageCard> {
  bool _expanded = false;
  DateTime? _selectedDate;
  bool _busy = false;

  final _money = NumberFormat.currency(symbol: '₪ ', decimalDigits: 0);

  DateTime _only(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final p = widget.item;

    final dateFmt = DateFormat('MMM d, yyyy');
    final rangeText =
        "${dateFmt.format(p.startDate)}  →  ${dateFmt.format(p.endDate)}";

    final offText = "${p.offPercent.toStringAsFixed(0)}% OFF";

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
                  _Image(p.imageUrl),
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
                          p.name,
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
                // ✅ Expand services
                // ---------------------------
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _expanded = !_expanded),
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
                            "What’s inside (services)",
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: kText),
                          ),
                        ),
                        Icon(
                          _expanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: kMuted,
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  crossFadeState: _expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 180),
                  firstChild: const SizedBox(height: 0),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      children: p.services.map((s) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: kCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: kBorder),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: kBrandBlue.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.check_rounded,
                                    color: kBrandBlue, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: kText,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "${s.vendorName} • ${s.category}",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: kMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text(
                                          _money.format(s.originalPrice),
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: kMuted,
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _money.format(s.packagePrice),
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            color: kText,
                                          ),
                                        ),
                                        const Spacer(),
                                        if (s.discountAmount > 0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: kBrandBlue,
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              "-${_money.format(s.discountAmount)}",
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ---------------------------
                // ✅ Date + Add
                // ---------------------------
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () async {
                          // ✅ FIX: prevent disabled calendar
                          var first = _only(p.startDate);
                          var last = _only(p.endDate);

                          if (last.isBefore(first)) {
                            final tmp = first;
                            first = last;
                            last = tmp;
                          }

                          var initial = _selectedDate ?? _only(DateTime.now());
                          if (initial.isBefore(first)) initial = first;
                          if (initial.isAfter(last)) initial = last;

                          final picked = await showDatePicker(
                            context: context,
                            initialDate: initial,
                            firstDate: first,
                            lastDate: last,
                            builder: (ctx, child) {
                              return Theme(
                                data: Theme.of(ctx).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: kBrandBlue,
                                    onPrimary: Colors.white,
                                    onSurface: kText,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );

                          if (picked != null) {
                            setState(() => _selectedDate = _only(picked));
                          }
                        },
                        child: Container(
                          height: 46,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: kCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: kBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.event_rounded,
                                  color: kMuted, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedDate == null
                                      ? "Select booking date"
                                      : DateFormat('MMM d, yyyy')
                                          .format(_selectedDate!),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color:
                                        _selectedDate == null ? kMuted : kText,
                                  ),
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded,
                                  color: kMuted),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kBrandBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        onPressed: _busy
                            ? null
                            : () async {
                                if (_selectedDate == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Please select booking date first.",
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w800),
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: kText,
                                      duration:
                                          const Duration(milliseconds: 1000),
                                    ),
                                  );
                                  return;
                                }

                                setState(() => _busy = true);
                                try {
                                  await widget.onAdd(p, _selectedDate!);
                                } finally {
                                  if (mounted) setState(() => _busy = false);
                                }
                              },
                        child: Row(
                          children: [
                            if (_busy)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            else
                              const Icon(Icons.add_shopping_cart_rounded,
                                  size: 18),
                            const SizedBox(width: 8),
                            Text(
                              "Add",
                              style: GoogleFonts.poppins(
                                  fontSize: 12, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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