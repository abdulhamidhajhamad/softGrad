// lib/screens/offers.dart
//
// ✅ Modern Offers (Discounts) Page
// - Category + City horizontal filters
// - Discounted services grid (responsive)
// - Favorite goes to favorites.dart (FavoritesStore) + persisted
// - Smooth animations on filter + favorite
//
// Dependencies:
//   google_fonts: ^6.x
//   shared_preferences: ^2.x   (used inside favorites.dart store)
//
// Notes:
// - This file includes mock data for easy integration/testing.
// - Replace `_mockOffers` with your API/services layer.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'favorites.dart'; // ✅ use FavoritesStore + FavoriteService

class OffersPage extends StatefulWidget {
  const OffersPage({super.key});

  @override
  State<OffersPage> createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  // 🎨 Brand palette (as requested)
  static const Color kBlue = Color.fromRGBO(20, 20, 215, 1);
  static const Color kWhite = Colors.white;
  static const Color kBlack = Colors.black;
  static const Color kBg = Color(0xFFF7F8FC);
  static const Color kMuted = Color(0xFF6B7280);
  static const Color kBorder = Color(0xFFE5E7EB);

  // Filters
  String? _selectedCategory; // null => All
  String? _selectedCity; // null => All

  @override
  void initState() {
    super.initState();
    _bootFavs();
  }

  Future<void> _bootFavs() async {
    await FavoritesStore.init(); // ✅ load persisted favorites
    if (mounted) setState(() {});
  }

void _toggleFavFromOffer(OfferService o) {
  final fav = FavoriteService(
    id: o.id,
    name: o.serviceName,
    category: o.category,
    company: o.companyName,
    city: o.city,
    oldPrice: o.oldPrice,   // ✅ السعر القديم قبل الخصم (عدّلي الاسم حسب موديلك)
    price: o.newPrice,      // ✅ السعر الجديد بعد الخصم
    rating: o.rating,
    image: o.imageUrl,
  );

  setState(() {
    FavoritesStore.toggleService(fav);
  });
}

  List<OfferService> get _filteredOffers {
    final discountedOnly = _mockOffers.where((o) => o.newPrice < o.oldPrice);
    return discountedOnly.where((o) {
      final okCat =
          _selectedCategory == null || o.category == _selectedCategory;
      final okCity = _selectedCity == null || o.city == _selectedCity;
      return okCat && okCity;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final offers = _filteredOffers;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          'Offers',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: kBlack,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // =========================
            // Filters
            // =========================
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(
                    label: 'Categories',
                    trailing: _FilterPill(
                      text: _selectedCategory == null ? 'All' : 'Clear',
                      icon: _selectedCategory == null
                          ? Icons.apps_rounded
                          : Icons.close_rounded,
                      onTap: () => setState(() => _selectedCategory = null),
                      blue: kBlue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: kCategories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final c = kCategories[i];
                        final selected = _selectedCategory == c.name;
                        return CategoryChip(
                          label: c.name,
                          icon: c.icon,
                          selected: selected,
                          blue: kBlue,
                          onTap: () {
                            setState(() {
                              _selectedCategory = selected ? null : c.name;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionLabel(
                    label: 'Cities',
                    trailing: _FilterPill(
                      text: _selectedCity == null ? 'All' : 'Clear',
                      icon: _selectedCity == null
                          ? Icons.place_rounded
                          : Icons.close_rounded,
                      onTap: () => setState(() => _selectedCity = null),
                      blue: kBlue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: kCities.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final city = kCities[i];
                        final selected = _selectedCity == city;
                        return CityChip(
                          label: city,
                          selected: selected,
                          blue: kBlue,
                          onTap: () {
                            setState(() {
                              _selectedCity = selected ? null : city;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // =========================
            // Offers Grid
            // =========================
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) {
                  return FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.98, end: 1).animate(anim),
                      child: child,
                    ),
                  );
                },
                child: offers.isEmpty
                    ? _EmptyState(
                        key: ValueKey(
                            'empty_${_selectedCategory}_${_selectedCity}'),
                        blue: kBlue,
                        muted: kMuted,
                      )
                    : LayoutBuilder(
                        key: ValueKey(
                            'grid_${offers.length}_${_selectedCategory}_${_selectedCity}'),
                        builder: (context, box) {
                          final w = box.maxWidth;
                          final crossAxisCount = w >= 720 ? 3 : 2;
                          final childAspectRatio = w >= 720 ? 0.85 : 0.78;

                          return GridView.builder(
                            padding: const EdgeInsets.fromLTRB(14, 6, 14, 16),
                            physics: const BouncingScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: childAspectRatio,
                            ),
                            itemCount: offers.length,
                            itemBuilder: (context, i) {
                              final o = offers[i];

                              final isFav =
                                  FavoritesStore.isServiceFavorite(o.id);

                              return OfferCard(
                                offer: o,
                                isFavorite: isFav,
                                blue: kBlue,
                                border: kBorder,
                                muted: kMuted,
                                onFavoriteTap: () => _toggleFavFromOffer(o),
                                onTap: () {
                                  // TODO: Navigate to service details
                                },
                              );
                            },
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================================
// UI Components (same as your file)
// ===================================

class OfferCard extends StatelessWidget {
  final OfferService offer;
  final bool isFavorite;
  final Color blue;
  final Color border;
  final Color muted;
  final VoidCallback onFavoriteTap;
  final VoidCallback onTap;

  const OfferCard({
    super.key,
    required this.offer,
    required this.isFavorite,
    required this.blue,
    required this.border,
    required this.muted,
    required this.onFavoriteTap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final oldP = _money(offer.oldPrice);
    final newP = _money(offer.newPrice);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
            boxShadow: const [
              BoxShadow(
                blurRadius: 14,
                spreadRadius: 0,
                offset: Offset(0, 8),
                color: Color(0x11000000),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(18)),
                      child: _NetImage(url: offer.imageUrl, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: _Badge(
                        text: '-${offer.discountPercent.round()}%',
                        blue: blue,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _FavButton(
                        isFav: isFavorite,
                        onTap: onFavoriteTap,
                        blue: blue,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.serviceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      offer.companyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.place_rounded, size: 16, color: muted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            offer.city,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: muted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _RatingStars(
                            rating: offer.rating, muted: muted, blue: blue),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          oldP,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: muted,
                            decoration: TextDecoration.lineThrough,
                            decorationThickness: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            newP,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: blue,
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
        ),
      ),
    );
  }
}

class CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color blue;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.blue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? blue : Colors.white;
    final fg = selected ? Colors.white : Colors.black;
    final bd = selected ? blue : const Color(0xFFE5E7EB);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: bd),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    blurRadius: 14,
                    offset: Offset(0, 6),
                    color: Color(0x22000000),
                  )
                ]
              : const [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CityChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color blue;
  final VoidCallback onTap;

  const CityChip({
    super.key,
    required this.label,
    required this.selected,
    required this.blue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? blue : Colors.white;
    final fg = selected ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? blue : const Color(0xFFE5E7EB)),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

class _RatingStars extends StatelessWidget {
  final double rating;
  final Color muted;
  final Color blue;

  const _RatingStars({
    required this.rating,
    required this.muted,
    required this.blue,
  });

  @override
  Widget build(BuildContext context) {
    final full = rating.floor().clamp(0, 5);
    final hasHalf = (rating - full) >= 0.5;
    final empty = 5 - full - (hasHalf ? 1 : 0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < full; i++)
          Icon(Icons.star_rounded, size: 16, color: blue),
        if (hasHalf) Icon(Icons.star_half_rounded, size: 16, color: blue),
        for (int i = 0; i < empty; i++)
          Icon(Icons.star_outline_rounded, size: 16, color: muted),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: muted,
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color blue;

  const _Badge({required this.text, required this.blue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.70),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _FavButton extends StatelessWidget {
  final bool isFav;
  final VoidCallback onTap;
  final Color blue;

  const _FavButton(
      {required this.isFav, required this.onTap, required this.blue});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.92),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 160),
            scale: isFav ? 1.06 : 1.0,
            child: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 18,
              color: isFav ? blue : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Widget trailing;

  const _SectionLabel({required this.label, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const Spacer(),
        trailing,
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final Color blue;

  const _FilterPill({
    required this.text,
    required this.icon,
    required this.onTap,
    required this.blue,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: blue),
            const SizedBox(width: 6),
            Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Color blue;
  final Color muted;

  const _EmptyState({super.key, required this.blue, required this.muted});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(Icons.local_offer_rounded, color: blue, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              'No discounted offers match your filters.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try clearing the category or city filter.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NetImage extends StatelessWidget {
  final String url;
  final BoxFit fit;

  const _NetImage({required this.url, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loading) {
        if (loading == null) return child;
        return Container(
          color: const Color(0xFFF1F5F9),
          child: const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (context, _, __) {
        return Container(
          color: const Color(0xFFF1F5F9),
          child: const Center(
            child: Icon(Icons.image_not_supported_rounded,
                size: 26, color: Color(0xFF94A3B8)),
          ),
        );
      },
    );
  }
}

// ===================================
// Data Model + Mock Data
// ===================================

class OfferService {
  final String id;
  final String serviceName;
  final String companyName;
  final String city;
  final String category;
  final double rating; // out of 5
  final double oldPrice;
  final double newPrice;
  final String imageUrl;

  const OfferService({
    required this.id,
    required this.serviceName,
    required this.companyName,
    required this.city,
    required this.category,
    required this.rating,
    required this.oldPrice,
    required this.newPrice,
    required this.imageUrl,
  });

  double get discountPercent {
    if (oldPrice <= 0) return 0;
    final d = ((oldPrice - newPrice) / oldPrice) * 100;
    return d.clamp(0, 95);
  }
}

String _money(double v) {
  final s = v.round().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final idxFromEnd = s.length - i;
    buf.write(s[i]);
    if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write(',');
  }
  return '₪${buf.toString()}';
}

class CategoryItem {
  final String name;
  final IconData icon;
  const CategoryItem(this.name, this.icon);
}

const List<CategoryItem> kCategories = [
  CategoryItem('Venues', Icons.location_city_rounded),
  CategoryItem('Photographers', Icons.photo_camera_rounded),
  CategoryItem('Catering', Icons.restaurant_rounded),
  CategoryItem('Cake', Icons.cake_rounded),
  CategoryItem('Flower Shops', Icons.local_florist_rounded),
  CategoryItem('Decor & Lighting', Icons.auto_awesome_rounded),
  CategoryItem('Music & Entertainment', Icons.music_note_rounded),
  CategoryItem('Wedding Planners & Coordinators', Icons.event_rounded),
  CategoryItem('Card Printing', Icons.mark_email_read_rounded),
  CategoryItem('Jewelry & Accessories', Icons.diamond_rounded),
  CategoryItem('Car Rental & Transportation', Icons.directions_car_rounded),
  CategoryItem('Gift & Souvenir', Icons.card_giftcard_rounded),
];

const List<String> kCities = [
  'Nablus',
  'Ramallah',
  'Jenin',
  'Tulkarm',
  'Qalqilya',
  'Salfit',
  'Tubas',
  'Hebron',
  'Bethlehem',
];

const List<OfferService> _mockOffers = [
  OfferService(
    id: 'o1',
    serviceName: 'Royal Garden Hall',
    companyName: 'Royal Venues Co.',
    city: 'Nablus',
    category: 'Venues',
    rating: 4.7,
    oldPrice: 12000,
    newPrice: 9800,
    imageUrl:
        'https://images.unsplash.com/photo-1520854221256-17451cc331bf?w=1200&q=80',
  ),
  OfferService(
    id: 'o2',
    serviceName: 'Cinematic Wedding Shoot',
    companyName: 'Lens & Love Studio',
    city: 'Ramallah',
    category: 'Photographers',
    rating: 4.8,
    oldPrice: 3500,
    newPrice: 2990,
    imageUrl:
        'https://images.unsplash.com/photo-1529636798458-92182e662485?w=1200&q=80',
  ),
  OfferService(
    id: 'o3',
    serviceName: 'Premium Catering Package',
    companyName: 'Taste of Joy',
    city: 'Jenin',
    category: 'Catering',
    rating: 4.5,
    oldPrice: 7000,
    newPrice: 6100,
    imageUrl:
        'https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?w=1200&q=80',
  ),
  OfferService(
    id: 'o4',
    serviceName: 'Luxury Cake (3 Tiers)',
    companyName: 'SugarCraft',
    city: 'Bethlehem',
    category: 'Cake',
    rating: 4.6,
    oldPrice: 900,
    newPrice: 720,
    imageUrl:
        'https://images.unsplash.com/photo-1542826438-7bcd78f9a555?w=1200&q=80',
  ),
  OfferService(
    id: 'o5',
    serviceName: 'Bridal Bouquet + Decor Set',
    companyName: 'Bloom & Bliss',
    city: 'Hebron',
    category: 'Flower Shops',
    rating: 4.4,
    oldPrice: 650,
    newPrice: 520,
    imageUrl:
        'https://images.unsplash.com/photo-1487537708572-3c850b5e856e?w=1200&q=80',
  ),
  OfferService(
    id: 'o6',
    serviceName: 'Modern Lighting & Stage',
    companyName: 'GlowUp Decor',
    city: 'Tulkarm',
    category: 'Decor & Lighting',
    rating: 4.3,
    oldPrice: 2500,
    newPrice: 1990,
    imageUrl:
        'https://images.unsplash.com/photo-1527529482837-4698179dc6ce?w=1200&q=80',
  ),
  OfferService(
    id: 'o7',
    serviceName: 'DJ + Dabke Night',
    companyName: 'Beats Avenue',
    city: 'Qalqilya',
    category: 'Music & Entertainment',
    rating: 4.2,
    oldPrice: 1800,
    newPrice: 1490,
    imageUrl:
        'https://images.unsplash.com/photo-1520170350707-b2da59970118?w=1200&q=80',
  ),
  OfferService(
    id: 'o8',
    serviceName: 'Full Wedding Planning',
    companyName: 'Perfect Day Team',
    city: 'Ramallah',
    category: 'Wedding Planners & Coordinators',
    rating: 4.9,
    oldPrice: 5000,
    newPrice: 4250,
    imageUrl:
        'https://images.unsplash.com/photo-1519225421980-715cb0215aed?w=1200&q=80',
  ),
  OfferService(
    id: 'o9',
    serviceName: 'Luxury Invitation Set',
    companyName: 'Ink & Gold',
    city: 'Nablus',
    category: 'Card Printing',
    rating: 4.5,
    oldPrice: 450,
    newPrice: 360,
    imageUrl:
        'https://images.unsplash.com/photo-1521737604893-d14cc237f11d?w=1200&q=80',
  ),
  OfferService(
    id: 'o10',
    serviceName: 'Bride Accessories Bundle',
    companyName: 'Shine Jewelry',
    city: 'Salfit',
    category: 'Jewelry & Accessories',
    rating: 4.1,
    oldPrice: 1200,
    newPrice: 990,
    imageUrl:
        'https://images.unsplash.com/photo-1522312346375-d1a52e2b99b3?w=1200&q=80',
  ),
  OfferService(
    id: 'o11',
    serviceName: 'Luxury Car (Day Rental)',
    companyName: 'Elite Cars',
    city: 'Tubas',
    category: 'Car Rental & Transportation',
    rating: 4.4,
    oldPrice: 900,
    newPrice: 750,
    imageUrl:
        'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=1200&q=80',
  ),
  OfferService(
    id: 'o12',
    serviceName: 'Guest Gift Boxes',
    companyName: 'Memories Studio',
    city: 'Hebron',
    category: 'Gift & Souvenir',
    rating: 4.0,
    oldPrice: 300,
    newPrice: 240,
    imageUrl:
        'https://images.unsplash.com/photo-1513151233558-d860c5398176?w=1200&q=80',
  ),
];
