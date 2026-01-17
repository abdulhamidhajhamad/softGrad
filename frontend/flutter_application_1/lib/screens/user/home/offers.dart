// lib/screens/user/home/offers.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_application_1/services/user_service/offers_service.dart';
import 'package:flutter_application_1/services/user_service/chat_user_service.dart';
import 'package:flutter_application_1/services/service_locator.dart';
import 'package:flutter_application_1/widgets/booking_details_modal.dart';
import 'package:flutter_application_1/screens/user/payment/cart.dart' show CartStore, CartItem, CartPage;
import 'package:flutter_application_1/screens/user/chat/chat_customer_home_page.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// =====================
// 🎨 Design Tokens (Same as Search page)
// =====================
const Color kPrimaryBlue = Color.fromARGB(215, 20, 20, 215);
const Color kPageBg = Color(0xFFF6F7FB);
const Color kTextDark = Color(0xFF0B1220);
const Color kTextMuted = Color(0xFF64748B);
const Color kDiscountRed = Color(0xFFFF3B30);
// ✅ Using light purple/violet instead of green
const Color kAccentPurple = Color(0xFF8B5CF6);

// ✅ All Palestinian cities
const List<String> kPalestinianCities = [
  'Nablus',
  'Ramallah',
  'Hebron',
  'Bethlehem',
  'Jenin',
  'Tulkarm',
  'Qalqilya',
  'Salfit',
  'Jericho',
  'Tubas',
  'Jerusalem',
  'Gaza',
  'Khan Yunis',
  'Rafah',
  'Deir al-Balah',
  'Beit Lahia',
  'Jabalya',
];

// ✅ All categories in the system
const List<String> kOfferCategories = [
  'Venues',
  'Photographers',
  'Catering',
  'Cake',
  'Music & Entertainment',
  'Event Planners',
  'Decor & Lighting',
  'Car Rental and Transportation',
  'Flower Shops',
  'Card Printing',
  'Jewelry & Accessories',
  'Gift & Souvenir',
];

// =====================
// 🔍 Filter Tabs
// =====================
enum OfferTab { all, categories, city }

class OffersPage extends StatefulWidget {
  const OffersPage({super.key});

  @override
  State<OffersPage> createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> with TickerProviderStateMixin {
  static const String kAll = '__all__';
  
  final OffersRepository _repo = OffersRepository();
  final _queryCtrl = TextEditingController();
  Timer? _debounce;
  
  // Data state
  List<OfferService> _allOffers = [];
  List<OfferService> _visible = [];
  bool _isLoading = true;
  String? _error;
  
  // Filter state
  OfferTab _tab = OfferTab.all;
  String _category = '__all__';
  String _city = '__all__';

  @override
  void initState() {
    super.initState();
    _loadOffers();
    _queryCtrl.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryCtrl.removeListener(_onQueryChanged);
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOffers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final offers = await _repo.fetchActiveOffers();
      _allOffers = offers;
      _visible = offers;
      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Error loading offers: $e');
      setState(() {
        _isLoading = false;
        _error = 'Failed to load offers';
      });
    }
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 170), _applyFilters);
  }

  void _applyFilters() {
    final q = _queryCtrl.text.trim().toLowerCase();
    
    List<OfferService> res = [..._allOffers];
    
    // Category filter
    if (_category != kAll) {
      res = res.where((e) => e.category.toLowerCase() == _category.toLowerCase()).toList();
    }
    
    // City filter
    if (_city != kAll) {
      res = res.where((e) => e.city.toLowerCase() == _city.toLowerCase()).toList();
    }
    
    // Search query
    if (q.isNotEmpty) {
      res = res.where((e) {
        final hay = '${e.name} ${e.company} ${e.city} ${e.category} ${e.description}'.toLowerCase();
        return hay.contains(q);
      }).toList();
    }
    
    if (!mounted) return;
    setState(() => _visible = res);
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
      backgroundColor: kPageBg,
      appBar: _OffersAppBar(onBack: () => Navigator.pop(context)),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: kPrimaryBlue))
            : _error != null
                ? _buildErrorState()
                : _buildContent(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: kPrimaryBlue, size: 48),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: kTextDark),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadOffers,
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryBlue),
            child: Text(
              'Retry',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ✅ Search Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: _OffersSearchHeader(
              controller: _queryCtrl,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
            ),
          ),
        ),
        
        // ✅ Filter Tabs (All / Categories / City)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: _OfferTypeTabs(
              value: _tab,
              onChanged: (t) => setState(() => _tab = t),
            ),
          ),
        ),
        
        // ✅ Category Chips (when Categories tab selected)
        if (_tab == OfferTab.categories)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: _QuickChipsBar(
                title: 'Pick a category',
                icon: Icons.grid_view_rounded,
                selected: _category,
                allValue: kAll,
                allLabel: 'All',
                items: kOfferCategories,
                onChanged: (v) {
                  setState(() => _category = v);
                  _applyFilters();
                },
              ),
            ),
          ),
        
        // ✅ City Chips (when City tab selected)
        if (_tab == OfferTab.city)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: _QuickChipsBar(
                title: 'Pick a city',
                icon: Icons.location_city_rounded,
                selected: _city,
                allValue: kAll,
                allLabel: 'All',
                items: kPalestinianCities,
                onChanged: (v) {
                  setState(() => _city = v);
                  _applyFilters();
                },
              ),
            ),
          ),
        
        // ✅ Results count & Cart button
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Text(
                  '${_visible.length} results',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    color: kTextMuted,
                    fontSize: 12.8,
                  ),
                ),
                const Spacer(),
                ValueListenableBuilder<int>(
                  valueListenable: CartStore.instance.count,
                  builder: (_, count, __) {
                    return _CartMiniBadge(count: count, onTap: _openCart);
                  },
                ),
              ],
            ),
          ),
        ),
        
        // ✅ Offers List or Empty State
        if (_visible.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              child: _buildEmptyState(),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final offer = _visible[i];
                  return Padding(
                    padding: EdgeInsets.only(bottom: i == _visible.length - 1 ? 0 : 12),
                    child: _OfferCard(
                      offer: offer,
                      onTap: () => _openOfferDetails(offer),
                    ),
                  );
                },
                childCount: _visible.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: kPrimaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_offer_outlined,
              size: 60,
              color: kPrimaryBlue.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _allOffers.isEmpty ? 'No Active Offers' : 'No Matching Offers',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: kTextDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _allOffers.isEmpty 
                ? 'Check back later for amazing deals!'
                : 'Try adjusting your filters',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: kTextMuted,
            ),
          ),
          const SizedBox(height: 24),
          if (_allOffers.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _queryCtrl.clear();
                  _tab = OfferTab.all;
                  _category = kAll;
                  _city = kAll;
                });
                _applyFilters();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text('Clear Filters', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
              style: TextButton.styleFrom(foregroundColor: kPrimaryBlue),
            ),
        ],
      ),
    );
  }

  void _openOfferDetails(OfferService offer) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OfferDetailsPage(offer: offer)),
    );
  }
}

// =============================================================================
// ✅ App Bar
// =============================================================================
class _OffersAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onBack;
  const _OffersAppBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: kPageBg,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back_rounded),
        color: kTextDark,
        tooltip: 'Back',
      ),
      title: Text(
        'Special Offers',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: kTextDark),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// =============================================================================
// ✅ Search Header (Same design as Search page)
// =============================================================================
class _OffersSearchHeader extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  const _OffersSearchHeader({
    required this.controller,
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
              color: kPrimaryBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kPrimaryBlue.withOpacity(0.18)),
            ),
            child: Icon(Icons.search_rounded, color: kPrimaryBlue, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              style: GoogleFonts.poppins(
                fontSize: 13.8,
                fontWeight: FontWeight.w700,
                color: kTextDark,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search offers, categories, cities..',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13.2,
                  fontWeight: FontWeight.w600,
                  color: kTextMuted,
                ),
              ),
              onSubmitted: onSubmitted,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// ✅ Tabs: All / Categories / City
// =============================================================================
class _OfferTypeTabs extends StatelessWidget {
  final OfferTab value;
  final ValueChanged<OfferTab> onChanged;

  const _OfferTypeTabs({required this.value, required this.onChanged});

  String _label(OfferTab t) {
    switch (t) {
      case OfferTab.all: return 'All';
      case OfferTab.categories: return 'Categories';
      case OfferTab.city: return 'City';
    }
  }

  IconData _icon(OfferTab t) {
    switch (t) {
      case OfferTab.all: return Icons.manage_search_rounded;
      case OfferTab.categories: return Icons.grid_view_rounded;
      case OfferTab.city: return Icons.location_city_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = OfferTab.values;

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
          color: selected ? kPrimaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? Colors.transparent : Colors.black.withOpacity(0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: selected ? kPrimaryBlue.withOpacity(0.18) : Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : kTextDark),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 12.2,
                color: selected ? Colors.white : kTextDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// ✅ Quick Chips Bar (Same design as Search page)
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
      padding: const EdgeInsets.all(12),
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
                  color: kPrimaryBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kPrimaryBlue.withOpacity(0.18)),
                ),
                child: Icon(icon, color: kPrimaryBlue, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900,
                    fontSize: 13.2,
                    color: kTextDark,
                  ),
                ),
              ),
              if (selected != allValue)
                TextButton(
                  onPressed: () => onChanged(allValue),
                  child: Text(
                    'Reset',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: kPrimaryBlue),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: allLabel,
                selected: selected == allValue,
                onTap: () => onChanged(allValue),
              ),
              for (final item in items)
                _FilterChip(
                  label: item,
                  selected: selected == item,
                  onTap: () => onChanged(item),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kPrimaryBlue : kPageBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? kPrimaryBlue : Colors.black.withOpacity(0.08),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : kTextDark,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// ✅ Cart Mini Badge
// =============================================================================
class _CartMiniBadge extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _CartMiniBadge({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: kTextDark,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================
// 📦 Offer Card Widget
// =====================
class _OfferCard extends StatelessWidget {
  final OfferService offer;
  final VoidCallback onTap;

  const _OfferCard({
    required this.offer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: kPrimaryBlue.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // ✅ Image Section
            Stack(
              children: [
                // Image
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: offer.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: offer.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: kPrimaryBlue,
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey.shade200,
                              child: Icon(
                                Icons.image_not_supported_rounded,
                                size: 50,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: Icon(
                              Icons.local_offer_rounded,
                              size: 60,
                              color: kPrimaryBlue.withOpacity(0.3),
                            ),
                          ),
                  ),
                ),
                
                // ✅ Discount Badge (TOP LEFT)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kDiscountRed, kDiscountRed.withOpacity(0.85)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: kDiscountRed.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '-${offer.discountPercentage}%',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // ✅ Time Remaining Badge (TOP RIGHT)
                Positioned(
                  top: 12,
                  right: 12,
                  child: _CountdownBadge(offer: offer),
                ),
                
                // ✅ Category Badge (BOTTOM LEFT)
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      offer.category,
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
            
            // ✅ Content Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Name
                  Text(
                    offer.name,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: kTextDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Company Name
                  Text(
                    offer.company,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kTextMuted,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // ✅ Price Row
                  Row(
                    children: [
                      // Discounted Price
                      Text(
                        '₪${offer.discountedPrice.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: kAccentPurple,
                        ),
                      ),
                      
                      const SizedBox(width: 10),
                      
                      // Original Price (strikethrough)
                      Text(
                        '₪${offer.originalPrice.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: kTextMuted,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: kTextMuted,
                          decorationThickness: 2,
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Savings
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: kAccentPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Save ₪${offer.savingsAmount.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: kAccentPurple,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // ✅ Rating & Location Row
                  if (offer.rating > 0 || offer.city.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          if (offer.rating > 0) ...[
                            const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              offer.rating.toStringAsFixed(1),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: kTextDark,
                              ),
                            ),
                            if (offer.totalReviews > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(${offer.totalReviews})',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: kTextMuted,
                                ),
                              ),
                            ],
                            const SizedBox(width: 16),
                          ],
                          if (offer.city.isNotEmpty && offer.city != 'Unknown') ...[
                            Icon(Icons.location_on_outlined, size: 16, color: kTextMuted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                offer.city,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: kTextMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================
// ⏰ Countdown Badge Widget
// =====================
class _CountdownBadge extends StatefulWidget {
  final OfferService offer;

  const _CountdownBadge({required this.offer});

  @override
  State<_CountdownBadge> createState() => _CountdownBadgeState();
}

class _CountdownBadgeState extends State<_CountdownBadge> {
  Timer? _timer;
  String _timeText = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _updateTime());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        _timeText = widget.offer.remainingTimeString;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.offer.remainingTime;
    final isUrgent = remaining != null && remaining.inHours < 24;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isUrgent 
            ? Colors.orange.withOpacity(0.95)
            : Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUrgent ? Icons.timer_rounded : Icons.schedule_rounded,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            _timeText,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// =====================
// 📄 Offer Details Page
// =====================
class OfferDetailsPage extends StatefulWidget {
  final OfferService offer;

  const OfferDetailsPage({super.key, required this.offer});

  @override
  State<OfferDetailsPage> createState() => _OfferDetailsPageState();
}

class _OfferDetailsPageState extends State<OfferDetailsPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _serviceData;
  List<String> _mediaUrls = [];
  int _currentMediaIndex = 0;
  PageController? _mediaPageController;
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();
    _loadServiceDetails();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _mediaPageController?.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    if (_mediaUrls.length > 1) {
      _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (_mediaPageController != null && _mediaPageController!.hasClients) {
          final nextPage = (_currentMediaIndex + 1) % _mediaUrls.length;
          _mediaPageController!.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  Future<void> _loadServiceDetails() async {
    try {
      final repo = OffersRepository();
      final response = await repo.fetchOfferDetails(widget.offer.id);

      setState(() {
        _serviceData = response;
        
        // Extract media URLs
        _mediaUrls = [];
        if (response['images'] != null && response['images'] is List) {
          for (var img in response['images']) {
            if (img != null && img.toString().isNotEmpty) {
              _mediaUrls.add(img.toString());
            }
          }
        }
        // Fallback
        if (_mediaUrls.isEmpty && widget.offer.imageUrl.isNotEmpty) {
          _mediaUrls.add(widget.offer.imageUrl);
        }
        
        _mediaPageController = PageController();
        _isLoading = false;
      });
      
      _startAutoSlide();
    } catch (e) {
      print('❌ Error loading offer details: $e');
      setState(() {
        _isLoading = false;
        // Use offer data as fallback
        if (widget.offer.images.isNotEmpty) {
          _mediaUrls = widget.offer.images;
        } else if (widget.offer.imageUrl.isNotEmpty) {
          _mediaUrls = [widget.offer.imageUrl];
        }
        _mediaPageController = PageController();
      });
    }
  }

  Future<void> _startChat() async {
    if (widget.offer.providerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot start chat: Provider not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: kPrimaryBlue),
      ),
    );

    try {
      final chatService = getIt<ChatUserService>();
      await chatService.initializeUserId();
      await chatService.initSocket();
      
      final chatId = await chatService.createChat(widget.offer.providerId);
      
      if (mounted) Navigator.pop(context);
      
      if (chatId != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatThreadPage(
              thread: ChatThreadModel(
                id: chatId,
                type: ThreadType.vendor,
                title: widget.offer.company,
                lastMessage: '',
                lastTime: DateTime.now(),
                unreadCount: 0,
                online: false,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _openBookingModal() async {
    final bookingType = _serviceData?['bookingType']?.toString().toLowerCase() 
        ?? widget.offer.bookingType.toLowerCase();
    
    if (bookingType == 'display') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
          content: Text(
            'This is a display-only service',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
      );
      return;
    }

    // Check if already in cart
    final inCart = CartStore.instance.contains(widget.offer.id);
    if (inCart) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
          content: Text(
            'This offer is already in your cart',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          action: SnackBarAction(
            label: 'View Cart',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartPage()),
              );
            },
          ),
        ),
      );
      return;
    }

    // ✅ Build service data with DISCOUNTED price
    final serviceData = _serviceData ?? {
      'bookingType': widget.offer.bookingType,
      'workingDays': widget.offer.workingDays,
      'availableHours': widget.offer.availableHours,
      'minBookingHours': widget.offer.minBookingHours,
      'maxBookingHours': widget.offer.maxBookingHours,
      'maxCapacity': widget.offer.maxCapacity,
      'hasFixedLocation': widget.offer.hasFixedLocation,
    };

    // ✅ IMPORTANT: Override price with discounted price for cart calculation
    serviceData['allPrices'] = {
      'perDay': widget.offer.discountedPrice,
      'perHour': widget.offer.discountedPrice,
      'perPerson': widget.offer.discountedPrice,
      'perEvent': widget.offer.discountedPrice,
      'displayPrice': widget.offer.discountedPrice,
    };

    await showBookingModal(
      context: context,
      serviceId: widget.offer.id,
      serviceName: widget.offer.name,
      bookingTypeString: bookingType,
      serviceData: serviceData,
      onSuccess: () {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: kAccentPurple,
            content: Text(
              'Added to cart with discount!',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;

    return Scaffold(
      backgroundColor: kPageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: kTextDark),
        title: Text(
          'Offer Details',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w900,
            color: kTextDark,
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryBlue))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ✅ Media Slider
                if (_mediaUrls.isNotEmpty) _buildMediaSlider(),
                
                const SizedBox(height: 16),
                
                // ✅ Offer Info Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.black.withOpacity(0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category & Rating Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: kPrimaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              offer.category,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: kPrimaryBlue,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (offer.rating > 0)
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  '${offer.rating.toStringAsFixed(1)} (${offer.totalReviews})',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    color: kTextDark,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Service Name
                      Text(
                        offer.name,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: kTextDark,
                        ),
                      ),
                      
                      const SizedBox(height: 6),
                      
                      // Company
                      Text(
                        offer.company,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: kTextMuted,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // ✅ Price Section with Countdown
                      _buildPriceSection(),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // ✅ Offer Details Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        kDiscountRed.withOpacity(0.05),
                        kAccentPurple.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: kDiscountRed.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.local_offer_rounded, color: kDiscountRed, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Offer Details',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w900,
                              color: kTextDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      
                      // Discount percentage
                      _buildOfferDetailRow(
                        Icons.percent_rounded,
                        'Discount',
                        '${offer.discountPercentage}% OFF',
                        kDiscountRed,
                      ),
                      const SizedBox(height: 10),
                      
                      // Savings
                      _buildOfferDetailRow(
                        Icons.savings_rounded,
                        'You Save',
                        '₪${offer.savingsAmount.toStringAsFixed(0)}',
                        kAccentPurple,
                      ),
                      const SizedBox(height: 10),
                      
                      // Time remaining
                      _buildOfferDetailRow(
                        Icons.timer_rounded,
                        'Ends In',
                        offer.remainingTimeString,
                        Colors.orange,
                      ),
                      
                      if (offer.offerDescription.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          offer.offerDescription,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: kTextMuted,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // ✅ Description
                if (offer.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.black.withOpacity(0.06)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w900,
                              color: kTextDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            offer.description,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              color: kTextMuted,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // ✅ Location Map
                if (offer.latitude != null && offer.longitude != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.black.withOpacity(0.06)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Location',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w900,
                                  color: kTextDark,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (offer.city.isNotEmpty && offer.city != 'Unknown')
                                Text(
                                  '• ${offer.city}',
                                  style: GoogleFonts.poppins(
                                    color: kTextMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              height: 200,
                              child: FlutterMap(
                                options: MapOptions(
                                  initialCenter: LatLng(
                                    offer.latitude!,
                                    offer.longitude!,
                                  ),
                                  initialZoom: 15.0,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.example.flutter_application_1',
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: LatLng(offer.latitude!, offer.longitude!),
                                        width: 40,
                                        height: 40,
                                        child: const Icon(
                                          Icons.location_pin,
                                          size: 40,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                const SizedBox(height: 100),
              ],
            ),
    );
  }

  Widget _buildPriceSection() {
    final offer = widget.offer;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kPageBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Discounted price
              Text(
                '₪${offer.discountedPrice.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: kAccentPurple,
                ),
              ),
              const SizedBox(height: 4),
              // Original price
              Row(
                children: [
                  Text(
                    'Was: ',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: kTextMuted,
                    ),
                  ),
                  Text(
                    '₪${offer.originalPrice.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kTextMuted,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: kTextMuted,
                      decorationThickness: 2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          // Discount badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kDiscountRed, kDiscountRed.withOpacity(0.85)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: kDiscountRed.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  '-${offer.discountPercentage}%',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'OFF',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferDetailRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: kTextMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMediaSlider() {
    if (_mediaUrls.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: PageView.builder(
              controller: _mediaPageController,
              itemCount: _mediaUrls.length,
              onPageChanged: (index) {
                setState(() => _currentMediaIndex = index);
              },
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: _mediaUrls[index],
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: kPrimaryBlue,
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    child: Icon(
                      Icons.image_not_supported_rounded,
                      size: 50,
                      color: Colors.grey.shade400,
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Page indicators
          if (_mediaUrls.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_mediaUrls.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentMediaIndex == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _currentMediaIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  );
                }),
              ),
            ),
          
          // Image counter
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentMediaIndex + 1}/${_mediaUrls.length}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final isDisplayOnly = (widget.offer.bookingType.toLowerCase() == 'display');
    
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black.withOpacity(0.06))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            // ✅ Start Chat Button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _startChat,
                icon: const Icon(Icons.chat_bubble_rounded, color: kPrimaryBlue),
                label: Text(
                  'Chat',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    color: kTextDark,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.black.withOpacity(0.14)),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // ✅ Add to Cart Button
            Expanded(
              flex: 2,
              child: ValueListenableBuilder<List<CartItem>>(
                valueListenable: CartStore.instance.itemsListenable,
                builder: (_, items, ___) {
                  final inCart = items.any((item) => item.id == widget.offer.id);

                  return ElevatedButton.icon(
                    onPressed: (inCart || _isLoading || isDisplayOnly) 
                        ? null 
                        : _openBookingModal,
                    icon: Icon(
                      inCart 
                          ? Icons.check_circle_rounded 
                          : isDisplayOnly 
                              ? Icons.visibility_rounded 
                              : Icons.add_shopping_cart_rounded,
                      color: (inCart || isDisplayOnly) ? Colors.white70 : Colors.white,
                    ),
                    label: Text(
                      inCart 
                          ? 'In Cart' 
                          : isDisplayOnly 
                              ? 'Display Only' 
                              : 'Add to Cart',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (inCart || isDisplayOnly) 
                          ? Colors.grey 
                          : kAccentPurple,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.withOpacity(0.6),
                      disabledForegroundColor: Colors.white70,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
