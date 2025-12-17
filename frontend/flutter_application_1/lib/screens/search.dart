// lib/screens/search.dart
//
// ✅ Ultra-modern Search UI (Wedding services marketplace style)
// ✅ Tap on service -> opens modern Details screen from:
//    service_insider_search.dart  (ServiceInsiderSearchScreen)
//
// Requires:
//   google_fonts: ^6.x
//   cached_network_image: ^3.x

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ✅ NEW: use your external details + cart files
import 'service_inside_search.dart';
import 'cart.dart';

// -----------------------------------------------------------------------------
// Theme
// -----------------------------------------------------------------------------
const Color kPrimary = Color.fromARGB(215, 20, 20, 215); // your blue
const Color kBg = Color(0xFFF6F7FB);
const Color kText = Color(0xFF0B1220);
const Color kMuted = Color(0xFF6B7280);

const Color kSuccess = Color(0xFF10B981);
const Color kDanger = Color(0xFFEF4444);

const List<String> kWeddingCategories = [
  'Venues',
  'Photographers',
  'Catering',
  'Cake',
  'Music & Entertainment',
  'Wedding Planners',
  'Decor & Lighting',
  'Car Rental',
  'Flower Shops',
  'Card Printing',
  'Jewelry & Accessories',
  'Gift & Souvenir',
];

// -----------------------------------------------------------------------------
// Tabs & Sort
// -----------------------------------------------------------------------------
enum SearchTab { all, categories, city }

enum SortOption { relevance, priceHighLow, priceLowHigh }

// -----------------------------------------------------------------------------
// Model (Dummy for UI demo)
// -----------------------------------------------------------------------------
class SearchResultModel {
  final String id;
  final String serviceName;

  // Provider/company
  final String providerName;
  final String providerEmail;
  final String providerPhone;

  // Media
  final String imageUrl;

  // Meta
  final String city;
  final String category;

  /// Final/current price
  final double price;

  /// Old/original price (if discount exists)
  final double? oldPrice;

  // Optional service description for details page
  final String description;

  const SearchResultModel({
    required this.id,
    required this.serviceName,
    required this.providerName,
    required this.providerEmail,
    required this.providerPhone,
    required this.imageUrl,
    required this.city,
    required this.category,
    required this.price,
    required this.description,
    this.oldPrice,
  });

  bool get hasDiscount =>
      oldPrice != null && oldPrice! > 0 && oldPrice! > price;

  int get discountPercent {
    if (!hasDiscount) return 0;
    final p = ((oldPrice! - price) / oldPrice!) * 100;
    return p.round().clamp(1, 95);
  }
}

// -----------------------------------------------------------------------------
// Screen
// -----------------------------------------------------------------------------
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const String kAll = '__all__';

  final _queryCtrl = TextEditingController();
  Timer? _debounce;

  // UI state
  SearchTab _tab = SearchTab.all;

  SortOption _sort = SortOption.relevance;
  String _category = kAll;
  String _city = kAll;

  // Demo data
  late final List<SearchResultModel> _allResults = _dummyResults();
  List<SearchResultModel> _visible = const [];

  @override
  void initState() {
    super.initState();
    _visible = _allResults;
    _queryCtrl.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryCtrl.removeListener(_onQueryChanged);
    _queryCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 170), _applyUiFilters);
  }

  void _applyUiFilters() {
    final q = _queryCtrl.text.trim().toLowerCase();

    List<SearchResultModel> res = [..._allResults];

    if (_category != kAll) {
      res = res.where((e) => e.category == _category).toList();
    }
    if (_city != kAll) {
      res = res.where((e) => e.city == _city).toList();
    }

    if (q.isNotEmpty) {
      res = res.where((e) {
        final hay =
            '${e.serviceName} ${e.providerName} ${e.providerEmail} ${e.city} ${e.category}'
                .toLowerCase();
        return hay.contains(q);
      }).toList();
    }

    res = _sortList(res);

    if (!mounted) return;
    setState(() => _visible = res);
  }

  List<SearchResultModel> _sortList(List<SearchResultModel> list) {
    final res = [...list];
    switch (_sort) {
      case SortOption.relevance:
        return res;
      case SortOption.priceHighLow:
        res.sort((a, b) => b.price.compareTo(a.price));
        return res;
      case SortOption.priceLowHigh:
        res.sort((a, b) => a.price.compareTo(b.price));
        return res;
    }
  }

  void _openFilterSheet() {
    FocusScope.of(context).unfocus();

    final cities = <String>[
      kAll,
      ..._uniqueSorted(_allResults.map((e) => e.city))
    ];
    final categories = <String>[kAll, ...kWeddingCategories];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => FilterBottomSheet(
        kAllValue: kAll,
        cities: cities,
        categories: categories,
        initialSort: _sort,
        initialCategory: _category,
        initialCity: _city,
        onClear: () {
          setState(() {
            _sort = SortOption.relevance;
            _category = kAll;
            _city = kAll;
            _queryCtrl.clear();
            _tab = SearchTab.all;
          });
          _applyUiFilters();
        },
        onApply: (sort, category, city) {
          setState(() {
            _sort = sort;
            _category = category;
            _city = city;
          });
          _applyUiFilters();
        },
      ),
    );
  }

  void _removeFilterChip(String kind) {
    setState(() {
      if (kind == 'sort') _sort = SortOption.relevance;
      if (kind == 'category') _category = kAll;
      if (kind == 'city') _city = kAll;
    });
    _applyUiFilters();
  }

  int _gridCount(double w) {
    if (w < 720) return 1; // list
    if (w < 1100) return 2;
    return 3;
  }

  // ✅ NEW: open external details screen + map model
  void _openDetails(SearchResultModel item) {
    final data = ServiceDetailsData(
      id: item.id,
      serviceName: item.serviceName,
      imageUrl: item.imageUrl,
      category: item.category,
      city: item.city,
      price: item.price,
      oldPrice: item.oldPrice,
      description: item.description.isNotEmpty
          ? item.description
          : 'No description yet.',
      companyName: item.providerName,
      contactEmail: item.providerEmail,
      contactPhone: item.providerPhone,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceInsideSearchScreen(
          data: data,
          heroTag: 'service_image_${item.id}',
        ),
      ),
    );
  }

  void _openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: _SearchAppBar(onBack: () => Navigator.pop(context)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final screenW = c.maxWidth;
            final contentW = (screenW >= 1000) ? 1100.0 : screenW;
            final crossAxisCount = _gridCount(contentW);

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentW),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                        child: SearchHeader(
                          controller: _queryCtrl,
                          onFilterTap: _openFilterSheet,
                          onSubmitted: (_) => FocusScope.of(context).unfocus(),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: SearchTypeTabs(
                          value: _tab,
                          onChanged: (t) => setState(() => _tab = t),
                        ),
                      ),
                    ),
                    if (_tab == SearchTab.categories)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: _QuickChipsBar(
                            title: 'Pick a category',
                            icon: Icons.grid_view_rounded,
                            selected: _category,
                            allValue: kAll,
                            allLabel: 'All',
                            items: kWeddingCategories,
                            onChanged: (v) {
                              setState(() => _category = v);
                              _applyUiFilters();
                            },
                          ),
                        ),
                      )
                    else if (_tab == SearchTab.city)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: _QuickChipsBar(
                            title: 'Pick a city',
                            icon: Icons.location_city_rounded,
                            selected: _city,
                            allValue: kAll,
                            allLabel: 'All',
                            items:
                                _uniqueSorted(_allResults.map((e) => e.city)),
                            onChanged: (v) {
                              setState(() => _city = v);
                              _applyUiFilters();
                            },
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: ActiveFilterChips(
                          allValue: kAll,
                          sort: _sort,
                          category: _category,
                          city: _city,
                          onRemove: _removeFilterChip,
                          onClearAll: () {
                            setState(() {
                              _sort = SortOption.relevance;
                              _category = kAll;
                              _city = kAll;
                            });
                            _applyUiFilters();
                          },
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: Row(
                          children: [
                            Text(
                              '${_visible.length} results',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w800,
                                color: kMuted,
                                fontSize: 12.8,
                              ),
                            ),
                            const Spacer(),
                            ValueListenableBuilder<int>(
                              valueListenable: CartStore.instance.count,
                              builder: (_, count, __) {
                                return _CartMiniBadge(
                                  count: count,
                                  onTap: _openCart,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_visible.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                          child: _EmptyState(
                            onClear: () {
                              setState(() {
                                _queryCtrl.clear();
                                _tab = SearchTab.all;
                                _sort = SortOption.relevance;
                                _category = kAll;
                                _city = kAll;
                              });
                              _applyUiFilters();
                            },
                            onOpenFilters: _openFilterSheet,
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                        sliver: (crossAxisCount == 1)
                            ? SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, i) {
                                    final item = _visible[i];
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        bottom:
                                            i == _visible.length - 1 ? 0 : 12,
                                      ),
                                      child: SearchResultCard(
                                        item: item,
                                        onView: () => _openDetails(item),
                                      ),
                                    );
                                  },
                                  childCount: _visible.length,
                                ),
                              )
                            : SliverGrid(
                                delegate: SliverChildBuilderDelegate(
                                  (context, i) {
                                    final item = _visible[i];
                                    return SearchResultCard(
                                      item: item,
                                      onView: () => _openDetails(item),
                                    );
                                  },
                                  childCount: _visible.length,
                                ),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  mainAxisExtent: 320,
                                ),
                              ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // helpers
  List<String> _uniqueSorted(Iterable<String> items) {
    final s = items.toSet().toList();
    s.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return s;
  }

  List<SearchResultModel> _dummyResults() {
    return const [
      SearchResultModel(
        id: '1',
        serviceName: 'Grand Pearl Hall',
        providerName: 'Pearl Group',
        providerEmail: 'contact@pearlgroup.ps',
        providerPhone: '+970 599 123 456',
        city: 'Nablus',
        category: 'Venues',
        price: 2400,
        oldPrice: 2800,
        description:
            'Luxury hall with premium lighting, seating layout, and full event staff. Suitable for large weddings.',
        imageUrl:
            'https://images.unsplash.com/photo-1529634806980-85c3dd6d34ac?auto=format&fit=crop&q=80&w=1200',
      ),
      SearchResultModel(
        id: '2',
        serviceName: 'Golden Lens Studio',
        providerName: 'Golden Lens',
        providerEmail: 'hello@goldenlens.ps',
        providerPhone: '+970 598 222 333',
        city: 'Ramallah',
        category: 'Photographers',
        price: 950,
        description:
            'Cinematic photo + video package with editing, highlights, and same-day teaser.',
        imageUrl:
            'https://images.unsplash.com/photo-1520854221256-17451cc330e7?auto=format&fit=crop&q=80&w=1200',
      ),
      SearchResultModel(
        id: '3',
        serviceName: 'Royal Catering',
        providerName: 'Royal Taste',
        providerEmail: 'orders@royaltaste.ps',
        providerPhone: '+970 597 777 888',
        city: 'Hebron',
        category: 'Catering',
        price: 1800,
        oldPrice: 2100,
        description:
            'Full buffet menu options with staff, setup, and premium desserts. Customizable per guests.',
        imageUrl:
            'https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?auto=format&fit=crop&q=80&w=1200',
      ),
      SearchResultModel(
        id: '4',
        serviceName: 'Signature Cake',
        providerName: 'SweetCraft',
        providerEmail: 'sweet@sweetcraft.ps',
        providerPhone: '+970 592 444 555',
        city: 'Jenin',
        category: 'Cake',
        price: 420,
        description:
            'Multi-tier wedding cake with custom flavors, design consultation, and delivery.',
        imageUrl:
            'https://images.unsplash.com/photo-1541783245831-57d6fb0926d3?auto=format&fit=crop&q=80&w=1200',
      ),
      SearchResultModel(
        id: '5',
        serviceName: 'DJ Pulse - Premium Set',
        providerName: 'SoundWave',
        providerEmail: 'book@soundwave.ps',
        providerPhone: '+970 595 666 777',
        city: 'Ramallah',
        category: 'Music & Entertainment',
        price: 520,
        oldPrice: 650,
        description:
            'DJ set with pro sound system, lighting, MC hosting, and custom playlist.',
        imageUrl:
            'https://images.unsplash.com/photo-1516280440614-6697288d5d38?auto=format&fit=crop&q=80&w=1200',
      ),
      SearchResultModel(
        id: '6',
        serviceName: 'Bloom & Co. Bouquet',
        providerName: 'Florist Team',
        providerEmail: 'flowers@bloomco.ps',
        providerPhone: '+970 596 101 202',
        city: 'Tulkarm',
        category: 'Flower Shops',
        price: 260,
        description:
            'Fresh bouquet + venue floral styling. Seasonal options and color theme matching.',
        imageUrl:
            'https://images.unsplash.com/photo-1522673607200-1645062cd495?auto=format&fit=crop&q=80&w=1200',
      ),
      SearchResultModel(
        id: '7',
        serviceName: 'Elegant Invitations Pack',
        providerName: 'Card House',
        providerEmail: 'prints@cardhouse.ps',
        providerPhone: '+970 594 808 909',
        city: 'Qalqilya',
        category: 'Card Printing',
        price: 160,
        oldPrice: 220,
        description:
            'Invitation set with premium paper, envelopes, and custom typography design.',
        imageUrl:
            'https://images.unsplash.com/photo-1520975958225-9cc2f4b7c3b2?auto=format&fit=crop&q=80&w=1200',
      ),
      SearchResultModel(
        id: '8',
        serviceName: 'Diamond Touch Set',
        providerName: 'Jewelry Hub',
        providerEmail: 'support@jewelryhub.ps',
        providerPhone: '+970 590 303 404',
        city: 'Nablus',
        category: 'Jewelry & Accessories',
        price: 1200,
        description:
            'Accessories set with premium finishing. Options available for custom sizing.',
        imageUrl:
            'https://images.unsplash.com/photo-1522312346375-d1a52e2b99b3?auto=format&fit=crop&q=80&w=1200',
      ),
    ];
  }
}

// =============================================================================
// AppBar
// =============================================================================
class _SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onBack;
  const _SearchAppBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: kBg,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back_rounded),
        color: kText,
        tooltip: 'Back',
      ),
      title: Text(
        'Search',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w900,
          color: kText,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// =============================================================================
// Search Header (search field + filter button)
// =============================================================================
class SearchHeader extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onFilterTap;
  final ValueChanged<String> onSubmitted;

  const SearchHeader({
    super.key,
    required this.controller,
    required this.onFilterTap,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kPrimary.withOpacity(0.18)),
            ),
            child: Icon(Icons.search_rounded, color: kPrimary, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              style: GoogleFonts.poppins(
                fontSize: 13.8,
                fontWeight: FontWeight.w700,
                color: kText,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search services, categories, cities..',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13.2,
                  fontWeight: FontWeight.w600,
                  color: kMuted,
                ),
              ),
              onSubmitted: onSubmitted,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onFilterTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    kPrimary.withOpacity(0.16),
                    kPrimary.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: kPrimary.withOpacity(0.22)),
              ),
              child: Icon(Icons.tune_rounded, color: kPrimary, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Tabs: All / Categories / City
// =============================================================================
class SearchTypeTabs extends StatelessWidget {
  final SearchTab value;
  final ValueChanged<SearchTab> onChanged;

  const SearchTypeTabs({
    super.key,
    required this.value,
    required this.onChanged,
  });

  String _label(SearchTab t) {
    switch (t) {
      case SearchTab.all:
        return 'All';
      case SearchTab.categories:
        return 'Categories';
      case SearchTab.city:
        return 'City';
    }
  }

  IconData _icon(SearchTab t) {
    switch (t) {
      case SearchTab.all:
        return Icons.manage_search_rounded;
      case SearchTab.categories:
        return Icons.grid_view_rounded;
      case SearchTab.city:
        return Icons.location_city_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = SearchTab.values;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final t in tabs) ...[
            _TypePill(
              selected: t == value,
              icon: _icon(t),
              label: _label(t),
              onTap: () => onChanged(t),
            ),
            const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TypePill({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Feedback.forTap(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color:
                selected ? Colors.transparent : Colors.black.withOpacity(0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? kPrimary.withOpacity(0.18)
                  : Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: selected
                    ? Colors.white
                    : const Color.fromARGB(255, 0, 0, 0)),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 12.2,
                color: selected ? Colors.white : kText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Quick Chips Bar
// =============================================================================
class _QuickChipsBar extends StatelessWidget {
  final String title;
  final IconData icon;

  final String selected;
  final String allValue;
  final String allLabel;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _QuickChipsBar({
    required this.title,
    required this.icon,
    required this.selected,
    required this.allValue,
    required this.allLabel,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kPrimary.withOpacity(0.18)),
                ),
                child: Icon(icon, color: kPrimary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900,
                    fontSize: 13.2,
                    color: kText,
                  ),
                ),
              ),
              if (selected != allValue)
                TextButton(
                  onPressed: () => onChanged(allValue),
                  child: Text(
                    'Reset',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w900,
                      color: kPrimary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _ChoiceChipPill(
                  label: allLabel,
                  active: selected == allValue,
                  onTap: () => onChanged(allValue),
                ),
                const SizedBox(width: 8),
                for (final v in items) ...[
                  _ChoiceChipPill(
                    label: v,
                    active: selected == v,
                    onTap: () => onChanged(v),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceChipPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ChoiceChipPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Feedback.forTap(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? kText : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active
                ? kPrimary.withOpacity(0.28)
                : Colors.black.withOpacity(0.08),
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: kPrimary.withOpacity(0.20),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (active) ...[
              Icon(Icons.check_rounded, size: 16, color: kPrimary),
              const SizedBox(width: 6),
            ],
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w900,
                  fontSize: 12.0,
                  color: active ? Colors.white : kText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Active filter chips row
// =============================================================================
class ActiveFilterChips extends StatelessWidget {
  final String allValue;
  final SortOption sort;
  final String category;
  final String city;
  final ValueChanged<String> onRemove; // "sort" | "category" | "city"
  final VoidCallback onClearAll;

  const ActiveFilterChips({
    super.key,
    required this.allValue,
    required this.sort,
    required this.category,
    required this.city,
    required this.onRemove,
    required this.onClearAll,
  });

  String _sortLabel(SortOption s) {
    switch (s) {
      case SortOption.relevance:
        return 'Relevance';
      case SortOption.priceHighLow:
        return 'Price: High → Low';
      case SortOption.priceLowHigh:
        return 'Price: Low → High';
    }
  }

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (sort != SortOption.relevance) {
      chips.add(_MiniChip(
        label: _sortLabel(sort),
        icon: Icons.sort_rounded,
        onClear: () => onRemove('sort'),
      ));
    }
    if (category != allValue) {
      chips.add(_MiniChip(
        label: category,
        icon: Icons.grid_view_rounded,
        onClear: () => onRemove('category'),
      ));
    }
    if (city != allValue) {
      chips.add(_MiniChip(
        label: city,
        icon: Icons.location_city_rounded,
        onClear: () => onRemove('city'),
      ));
    }

    if (chips.isEmpty) return const SizedBox(height: 2);

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                for (final c in chips) ...[c, const SizedBox(width: 8)],
              ],
            ),
          ),
        ),
        TextButton(
          onPressed: onClearAll,
          child: Text(
            'Clear',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w900,
              color: kText,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onClear;

  const _MiniChip({
    required this.label,
    required this.icon,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kPrimary.withOpacity(0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: kText),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: kText,
              ),
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onClear,
            borderRadius: BorderRadius.circular(999),
            child: Icon(Icons.close_rounded,
                size: 16, color: kText.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Result Card
// =============================================================================
class SearchResultCard extends StatelessWidget {
  final SearchResultModel item;
  final VoidCallback onView;

  const SearchResultCard({
    super.key,
    required this.item,
    required this.onView,
  });

  String _money(double v) => '₪${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Feedback.forTap(context);
          onView();
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'service_image_${item.id}',
                        child: CachedNetworkImage(
                          imageUrl: item.imageUrl,
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
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.00),
                                Colors.black.withOpacity(0.20),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (item.hasDiscount)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: _DiscountBadge(percent: item.discountPercent),
                        ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: _ModernPricePill(
                          price: _money(item.price),
                          oldPrice:
                              item.hasDiscount ? _money(item.oldPrice!) : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.serviceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w900,
                        fontSize: 15.2,
                        color: const Color.fromARGB(215, 20, 20, 215),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.providerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.4,
                        color: kMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          icon: Icons.grid_view_rounded,
                          text: item.category,
                          tone: _ChipTone.primarySoft,
                        ),
                        _InfoChip(
                          icon: Icons.location_on_rounded,
                          text: item.city,
                          tone: _ChipTone.neutral,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 11.8,
                              color: kMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _PrimaryPillButton(
                          label: 'Full Details',
                          icon: Icons.arrow_forward_rounded,
                          onTap: onView,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscountBadge extends StatelessWidget {
  final int percent;
  const _DiscountBadge({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: kDanger.withOpacity(0.92),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Text(
        '-$percent%',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w900,
          fontSize: 12.0,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ModernPricePill extends StatelessWidget {
  final String price;
  final String? oldPrice;

  const _ModernPricePill({
    required this.price,
    required this.oldPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            price,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w900,
              fontSize: 12.4,
              color: kText,
            ),
          ),
          if (oldPrice != null) ...[
            const SizedBox(width: 8),
            Text(
              oldPrice!,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w900,
                fontSize: 12.0,
                color: kDanger,
                decoration: TextDecoration.lineThrough,
                decorationThickness: 2.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _ChipTone { neutral, primarySoft }

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final _ChipTone tone;

  const _InfoChip({
    required this.icon,
    required this.text,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final bg = (tone == _ChipTone.primarySoft)
        ? kPrimary.withOpacity(0.12)
        : const Color(0xFFF3F4F6);
    final bd = (tone == _ChipTone.primarySoft)
        ? kPrimary.withOpacity(0.20)
        : const Color.fromARGB(255, 189, 110, 110).withOpacity(0.08);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: bd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: kPrimary),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w900,
                fontSize: 11.8,
                color: kText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryPillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryPillButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Feedback.forTap(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
        decoration: BoxDecoration(
          color: kText,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: kPrimary.withOpacity(0.30)),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w900,
                fontSize: 12.0,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: kPrimary.withOpacity(0.95), size: 18),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Filter Bottom Sheet
// =============================================================================
class FilterBottomSheet extends StatefulWidget {
  final String kAllValue;
  final List<String> cities;
  final List<String> categories;

  final SortOption initialSort;
  final String initialCategory;
  final String initialCity;

  final VoidCallback onClear;
  final void Function(SortOption sort, String category, String city) onApply;

  const FilterBottomSheet({
    super.key,
    required this.kAllValue,
    required this.cities,
    required this.categories,
    required this.initialSort,
    required this.initialCategory,
    required this.initialCity,
    required this.onClear,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late SortOption _sort;
  late String _category;
  late String _city;

  @override
  void initState() {
    super.initState();
    _sort = widget.initialSort;
    _category = widget.initialCategory;
    _city = widget.initialCity;
  }

  String _sortLabel(SortOption s) {
    switch (s) {
      case SortOption.relevance:
        return 'Relevance';
      case SortOption.priceHighLow:
        return 'Price: High → Low';
      case SortOption.priceLowHigh:
        return 'Price: Low → High';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Filters',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: kText,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        widget.onClear();
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Clear',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w900,
                          color: kPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _DropdownGeneric<SortOption>(
                  icon: Icons.sort_rounded,
                  title: 'Sort by',
                  value: _sort,
                  items: SortOption.values,
                  labelBuilder: _sortLabel,
                  onChanged: (v) =>
                      setState(() => _sort = v ?? SortOption.relevance),
                ),
                const SizedBox(height: 10),
                _DropdownString(
                  icon: Icons.grid_view_rounded,
                  title: 'Category',
                  value: _category,
                  items: widget.categories,
                  allValue: widget.kAllValue,
                  allLabel: 'All categories',
                  onChanged: (v) => setState(() => _category = v),
                ),
                const SizedBox(height: 10),
                _DropdownString(
                  icon: Icons.location_city_rounded,
                  title: 'City',
                  value: _city,
                  items: widget.cities,
                  allValue: widget.kAllValue,
                  allLabel: 'All cities',
                  onChanged: (v) => setState(() => _city = v),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side:
                              BorderSide(color: Colors.black.withOpacity(0.14)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w900, color: kText),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onApply(_sort, _category, _city);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kText,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                        ),
                        child: Text(
                          'Apply',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownString extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final List<String> items;
  final String allValue;
  final String allLabel;
  final ValueChanged<String> onChanged;

  const _DropdownString({
    required this.icon,
    required this.title,
    required this.value,
    required this.items,
    required this.allValue,
    required this.allLabel,
    required this.onChanged,
  });

  String _display(String v) => v == allValue ? allLabel : v;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kPrimary.withOpacity(0.18)),
            ),
            child: Icon(icon, color: kPrimary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                items: items
                    .map((e) => DropdownMenuItem<String>(
                          value: e,
                          child: Text(
                            _display(e),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w800),
                          ),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  onChanged(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownGeneric<T> extends StatelessWidget {
  final IconData icon;
  final String title;
  final T value;
  final List<T> items;
  final String Function(T v) labelBuilder;
  final ValueChanged<T?> onChanged;

  const _DropdownGeneric({
    required this.icon,
    required this.title,
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kPrimary.withOpacity(0.18)),
            ),
            child: Icon(icon, color: kPrimary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                items: items
                    .map((e) => DropdownMenuItem<T>(
                          value: e,
                          child: Text(
                            labelBuilder(e),
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w800),
                          ),
                        ))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Empty state
// =============================================================================
class _EmptyState extends StatelessWidget {
  final VoidCallback onClear;
  final VoidCallback onOpenFilters;

  const _EmptyState({
    required this.onClear,
    required this.onOpenFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
          Icon(Icons.search_off_rounded, color: kPrimary, size: 30),
          const SizedBox(height: 10),
          Text(
            'No results found',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: kText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different keyword, or choose a category/city.',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: kMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onOpenFilters,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.black.withOpacity(0.14)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                  child: Text(
                    'Open filters',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w900, color: kText),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onClear,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kText,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                  child: Text(
                    'Clear all',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Cart Badge (top-right small) - now opens CartScreen
// =============================================================================
class _CartMiniBadge extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _CartMiniBadge({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
        decoration: BoxDecoration(
          color: kText,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: kPrimary.withOpacity(0.30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_bag_rounded, color: kPrimary, size: 16),
            const SizedBox(width: 8),
            Text(
              '$count',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}