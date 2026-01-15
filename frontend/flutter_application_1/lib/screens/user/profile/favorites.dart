// lib/screens/favorites.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ----------- MODELS + STORE (can be reused from other screens) -----------

class FavoriteTemplate {
  final String asset; // image path
  final String name; // display name
  final String category; // Classic / Minimal / ...

  FavoriteTemplate({
    required this.asset,
    required this.name,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
        'asset': asset,
        'name': name,
        'category': category,
      };

  factory FavoriteTemplate.fromJson(Map<String, dynamic> j) {
    return FavoriteTemplate(
      asset: (j['asset'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      category: (j['category'] ?? '').toString(),
    );
  }
}

class FavoriteVendor {
  final String name; // vendor name
  final String type; // category (Venue, Photographer, ...)
  final String? image; // optional image path

  FavoriteVendor({
    required this.name,
    required this.type,
    this.image,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'image': image,
      };

  factory FavoriteVendor.fromJson(Map<String, dynamic> j) {
    return FavoriteVendor(
      name: (j['name'] ?? '').toString(),
      type: (j['type'] ?? '').toString(),
      image: j['image']?.toString(),
    );
  }
}

/// ✅ Favorite Service model (used by Offers)
class FavoriteService {
  final String id;
  final String name; // service name
  final String category; // one of your 12 categories
  final String company; // provider/company name
  final String city; // location

  /// ✅ NEW: old price before discount
  final double oldPrice;

  /// ✅ NEW price (after discount) - keep it as "price" to not break other code
  final double price;

  final double rating; // 0..5
  final String? image; // asset path or network url

  FavoriteService({
    required this.id,
    required this.name,
    required this.category,
    required this.company,
    required this.city,
    required this.oldPrice,
    required this.price,
    required this.rating,
    this.image,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'company': company,
        'city': city,
        'oldPrice': oldPrice,
        'price': price,
        'rating': rating,
        'image': image,
      };

  factory FavoriteService.fromJson(Map<String, dynamic> j) {
    double readNum(dynamic v) => (v is num) ? v.toDouble() : 0.0;

    // ✅ Backward compatible:
    // old versions saved only "price" (new price). If oldPrice missing => 0.0
    final newPrice = readNum(j['price']);
    final oldP = j.containsKey('oldPrice') ? readNum(j['oldPrice']) : 0.0;

    return FavoriteService(
      id: (j['id'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      category: (j['category'] ?? '').toString(),
      company: (j['company'] ?? '').toString(),
      city: (j['city'] ?? '').toString(),
      oldPrice: oldP,
      price: newPrice,
      rating: readNum(j['rating']),
      image: j['image']?.toString(),
    );
  }
}

/// ✅ Persistent Favorites Store (SharedPreferences)
class FavoritesStore {
  static final List<FavoriteTemplate> _templates = [];
  static final List<FavoriteVendor> _vendors = [];
  static final List<FavoriteService> _services = [];

  static bool _inited = false;

  static const String _kTemplates = 'fav_templates_v1';
  static const String _kVendors = 'fav_vendors_v1';
  static const String _kServices = 'fav_services_v2'; // ✅ bump version

  /// Call this once (FavoritesPage / OffersPage) before reading favorites
  static Future<void> init() async {
    if (_inited) return;

    final prefs = await SharedPreferences.getInstance();

    // Templates
    _templates
      ..clear()
      ..addAll(_decodeList(prefs.getStringList(_kTemplates))
          .map((j) => FavoriteTemplate.fromJson(j)));

    // Vendors
    _vendors
      ..clear()
      ..addAll(_decodeList(prefs.getStringList(_kVendors))
          .map((j) => FavoriteVendor.fromJson(j)));

    // Services
    _services
      ..clear()
      ..addAll(_decodeList(prefs.getStringList(_kServices))
          .map((j) => FavoriteService.fromJson(j)));

    _inited = true;
  }

  static List<Map<String, dynamic>> _decodeList(List<String>? raw) {
    final list = raw ?? const [];
    final out = <Map<String, dynamic>>[];
    for (final s in list) {
      try {
        final v = jsonDecode(s);
        if (v is Map<String, dynamic>) out.add(v);
      } catch (_) {}
    }
    return out;
  }

  static void _saveTemplates() {
    SharedPreferences.getInstance().then((prefs) {
      final raw = _templates.map((t) => jsonEncode(t.toJson())).toList();
      prefs.setStringList(_kTemplates, raw);
    });
  }

  static void _saveVendors() {
    SharedPreferences.getInstance().then((prefs) {
      final raw = _vendors.map((v) => jsonEncode(v.toJson())).toList();
      prefs.setStringList(_kVendors, raw);
    });
  }

  static void _saveServices() {
    SharedPreferences.getInstance().then((prefs) {
      final raw = _services.map((s) => jsonEncode(s.toJson())).toList();
      prefs.setStringList(_kServices, raw);
    });
  }

  // ---------- Templates ----------
  static List<FavoriteTemplate> get templates => List.unmodifiable(_templates);

  static bool isTemplateFavorite(String asset) =>
      _templates.any((t) => t.asset == asset);

  static void addTemplate(FavoriteTemplate t) {
    if (!isTemplateFavorite(t.asset)) {
      _templates.add(t);
      _saveTemplates();
    }
  }

  static void removeTemplateByAsset(String asset) {
    _templates.removeWhere((t) => t.asset == asset);
    _saveTemplates();
  }

  // ---------- Vendors ----------
  static List<FavoriteVendor> get vendors => List.unmodifiable(_vendors);

  static bool isVendorFavorite(String name) =>
      _vendors.any((v) => v.name == name);

  static void addVendor(FavoriteVendor v) {
    if (!isVendorFavorite(v.name)) {
      _vendors.add(v);
      _saveVendors();
    }
  }

  static void removeVendorByName(String name) {
    _vendors.removeWhere((v) => v.name == name);
    _saveVendors();
  }

  // ---------- ✅ Services ----------
  static List<FavoriteService> get services => List.unmodifiable(_services);

  static bool isServiceFavorite(String id) => _services.any((s) => s.id == id);

  static void addService(FavoriteService s) {
    if (!isServiceFavorite(s.id)) {
      _services.add(s);
      _saveServices();
    }
  }

  static void removeServiceById(String id) {
    _services.removeWhere((s) => s.id == id);
    _saveServices();
  }

  static void toggleService(FavoriteService s) {
    if (isServiceFavorite(s.id)) {
      removeServiceById(s.id);
    } else {
      addService(s);
    }
  }

  static void clearAll() {
    _templates.clear();
    _vendors.clear();
    _services.clear();
    _saveTemplates();
    _saveVendors();
    _saveServices();
  }
}

/// ------------------------- FAVORITES PAGE UI ------------------------------

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

enum _FavTab { services, vendors, templates }

class _FavoritesPageState extends State<FavoritesPage> {
  _FavTab _tab = _FavTab.services;

  Color get _mint => const Color.fromARGB(215, 20, 20, 215);
  Color get _bgChip => const Color(0xFFF2F2F2);

  String _money(double v) => "₪${v.toStringAsFixed(0)}";

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await FavoritesStore.init();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final templates = FavoritesStore.templates;
    final vendors = FavoritesStore.vendors;
    final services = FavoritesStore.services;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        titleSpacing: 20,
        toolbarHeight: 72,
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _mint.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.favorite_rounded, color: _mint, size: 26),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Favorites',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Your saved items',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (services.isNotEmpty || vendors.isNotEmpty || templates.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() => FavoritesStore.clearAll());
              },
              child: Text(
                "Clear",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  color: _mint,
                ),
              ),
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          // -------------------- Segmented control --------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Container(
              decoration: BoxDecoration(
                color: _bgChip,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: _SegmentButton(
                      label: 'Services',
                      selected: _tab == _FavTab.services,
                      mint: _mint,
                      onTap: () => setState(() => _tab = _FavTab.services),
                    ),
                  ),
                  Expanded(
                    child: _SegmentButton(
                      label: 'Vendors',
                      selected: _tab == _FavTab.vendors,
                      mint: _mint,
                      onTap: () => setState(() => _tab = _FavTab.vendors),
                    ),
                  ),
                  Expanded(
                    child: _SegmentButton(
                      label: 'Templates',
                      selected: _tab == _FavTab.templates,
                      mint: _mint,
                      onTap: () => setState(() => _tab = _FavTab.templates),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 6),

          // -------------------- Content --------------------
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _tab == _FavTab.services
                  ? _ServicesFavoritesList(
                      services: services,
                      mint: _mint,
                      money: _money,
                      onRemove: (id) => setState(
                        () => FavoritesStore.removeServiceById(id),
                      ),
                    )
                  : _tab == _FavTab.vendors
                      ? _VendorsFavoritesList(vendors: vendors)
                      : _TemplatesFavoritesGrid(templates: templates),
            ),
          ),
        ],
      ),
    );
  }
}

/// Segmented button
class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color mint;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.mint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: selected
              ? Border.all(color: mint, width: 2)
              : const Border.fromBorderSide(BorderSide.none),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: selected ? mint : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }
}

/// --------------------- ✅ Services tab content -----------------------

class _ServicesFavoritesList extends StatelessWidget {
  final List<FavoriteService> services;
  final Color mint;
  final String Function(double) money;
  final void Function(String id) onRemove;

  const _ServicesFavoritesList({
    required this.services,
    required this.mint,
    required this.money,
    required this.onRemove,
  });

  bool _isNetwork(String? s) => (s ?? '').startsWith('http');

  Widget _image(String? path) {
    if (path == null || path.isEmpty) {
      return Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child:
            Icon(Icons.image_outlined, color: Colors.black.withOpacity(0.35)),
      );
    }

    if (_isNetwork(path)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          path,
          width: 54,
          height: 54,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.broken_image_outlined,
                color: Colors.black.withOpacity(0.35)),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        path,
        width: 54,
        height: 54,
        fit: BoxFit.cover,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return const _EmptyState(message: 'No favorite services yet.');
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: services.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final s = services[index];

        final showOld =
            s.oldPrice > 0 && s.oldPrice > s.price; // ✅ only show if valid

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _image(s.image),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // name + rating
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              s.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 16, color: Colors.amber),
                              Text(
                                s.rating.toStringAsFixed(1),
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // company + city
                      Text(
                        "${s.company} • ${s.city}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          // category chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: mint.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              s.category,
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: mint,
                              ),
                            ),
                          ),
                          const Spacer(),

                          // ✅ prices: old (strikethrough) فوق الجديد
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (showOld)
                                Text(
                                  money(s.oldPrice),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF94A3B8),
                                    decoration: TextDecoration.lineThrough,
                                    decorationThickness: 2,
                                  ),
                                ),
                              Text(
                                money(s.price),
                                style: GoogleFonts.poppins(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w900,
                                  color: mint,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // remove button
                IconButton(
                  onPressed: () => onRemove(s.id),
                  icon: Icon(Icons.close_rounded,
                      color: Colors.black.withOpacity(0.55)),
                  tooltip: 'Remove',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// --------------------- Vendors tab content -----------------------

class _VendorsFavoritesList extends StatelessWidget {
  final List<FavoriteVendor> vendors;

  const _VendorsFavoritesList({required this.vendors});

  @override
  Widget build(BuildContext context) {
    if (vendors.isEmpty) {
      return const _EmptyState(message: 'No favorite vendors yet.');
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: vendors.length,
      itemBuilder: (context, index) {
        final v = vendors[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            leading: v.image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      v.image!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  )
                : const CircleAvatar(radius: 24, child: Icon(Icons.storefront)),
            title: Text(
              v.name,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, fontSize: 15),
            ),
            subtitle: Text(
              v.type,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: const Color(0xFF64748B)),
            ),
          ),
        );
      },
    );
  }
}

/// --------------------- Templates tab content -----------------------

class _TemplatesFavoritesGrid extends StatelessWidget {
  final List<FavoriteTemplate> templates;

  const _TemplatesFavoritesGrid({required this.templates});

  @override
  Widget build(BuildContext context) {
    if (templates.isEmpty) {
      return const _EmptyState(message: 'No favorite templates yet.');
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: templates.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3 / 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final t = templates[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(t.asset, fit: BoxFit.cover),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      t.name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// --------------------- Empty state -----------------------

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style:
            GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF64748B)),
        textAlign: TextAlign.center,
      ),
    );
  }
}   