// lib/screens/vendors.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'favorites.dart';
import 'compnay_insider_provider.dart';
import 'cart.dart' as cart;
import 'package:flutter_application_1/services/user_service/user_service_service.dart';

// =====================
// 🎨 Black / White / Blue
// =====================
const Color kBlue = Color.fromARGB(215, 20, 20, 215);
const Color kBg = Color(0xFFF7F8FC);
const Color kText = Color(0xFF0B1220);
const Color kMuted = Color(0xFF6B7280);

// ✅ Cities (Fixed list as requested)
const List<String> kCities = [
  'Nablus',
  'Ramallah',
  'Jenin',
  'Tulkarm',
  'Qalqilya',
  'Hebron',
  'Salfit',
  'Tubas',
];

// =====================
// 🔽 Sort Options (Only Rating & Price) - kept (DO NOT DELETE)
// =====================
enum SortOption { ratingHighLow, priceLowHigh, priceHighLow }

// =====================
// ✅ Service Favorites (Global reactive store)
// =====================
class ServiceFavoritesStore {
  static final Set<String> _ids = <String>{};
  static final ValueNotifier<int> _tick = ValueNotifier<int>(0);

  static ValueListenable<int> get listenable => _tick;

  static bool isFavorite(String serviceId) => _ids.contains(serviceId);

  static void toggle(String serviceId) {
    if (_ids.contains(serviceId)) {
      _ids.remove(serviceId);
    } else {
      _ids.add(serviceId);
    }
    _tick.value++;
  }

  static void setFavorites(List<String> ids) {
    _ids.clear();
    _ids.addAll(ids);
    _tick.value++;
  }
}

// ✅ bridge: لما نعمل Favorite هون، ينضاف كمان على FavoritesPage
void toggleServiceFavorite(ServiceItem s) async {
  try {
    await UserServiceService.toggleServiceFavorite(s.id);
    ServiceFavoritesStore.toggle(s.id);

    final nowFav = ServiceFavoritesStore.isFavorite(s.id);
    final newPrice = (s.hasDiscount && s.discountPrice != null) 
        ? s.discountPrice! 
        : s.price;

    if (nowFav) {
      FavoritesStore.addService(
        FavoriteService(
          id: s.id,
          name: s.serviceName,
          category: s.category,
          company: s.companyName,
          city: s.city,
          oldPrice: s.price,
          price: newPrice,
          rating: s.rating,
          image: s.imageUrl,
        ),
      );
    } else {
      FavoritesStore.removeServiceById(s.id);
    }
  } catch (e) {
    print('Error toggling favorite: $e');
  }
}

// =====================
// ✅ Service Model
// =====================
class ServiceItem {
  final String id;
  final String category;
  final String serviceName;
  final String? payType; // 'per event', 'per hour', 'per person', 'per day'
  final String companyName;
  final String companyEmail;
  final String companyPhone;

  final String city;

  /// ✅ NEW: description
  final String description;

  /// original price
  final double price;

  /// discounted price (optional). If set and < price => show discount UI.
  final double? discountPrice;

  final double rating;
  final int reviewsCount;

  /// uploaded image url
  final String? imageUrl;
 final double? lat;
  final double? lng;

  const ServiceItem({
    required this.id,
    required this.category,
    required this.serviceName,
    required this.companyName,
    required this.companyEmail,
    required this.companyPhone,
    required this.city,
    required this.description,
    required this.price,
    this.discountPrice,
    required this.rating,
    required this.reviewsCount,
    this.imageUrl,
    this.payType,
    this.lat,
    this.lng,

  });

  bool get hasDiscount =>
      discountPrice != null && discountPrice! > 0 && discountPrice! < price;

  factory ServiceItem.fromJson(Map<String, dynamic> json, String category) {
    return ServiceItem(
      id: json['id'] ?? '',
      category: category,
      serviceName: json['serviceName'] ?? 'N/A',
      companyName: json['companyName'] ?? 'N/A',
      companyEmail: '',
      companyPhone: '',
      city: json['city'] ?? 'N/A',
      price: _parsePrice(json['price']),
      rating: (json['rating'] ?? 0).toDouble(),
      reviewsCount: 0,
      imageUrl: json['image'],
      description: json['description'] ?? '',
      payType: json['payType'],
    lat: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
    lng: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
    );
  }

  static double _parsePrice(dynamic price) {
    if (price == null || price == 'N/A') return 0.0;
    if (price is num) return price.toDouble();
    if (price is String) {
      final parsed = double.tryParse(price);
      return parsed ?? 0.0;
    }
    return 0.0;
  }
}

// =====================
// ✅ Review Model + Seed (NEW)
// =====================
class ReviewItem {
  final String id;
  final String userName;
  final double rating;
  final String comment;
  final DateTime date;
  final List<String> imageUrls;

  const ReviewItem({
    required this.id,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.date,
    this.imageUrls = const [],
  });
}

// ✅ Seed Reviews (Replace later with API)
final Map<String, List<ReviewItem>> kSeedReviewsByServiceId = {
  'v1': [
    ReviewItem(
      id: 'r1',
      userName: 'Ahmad',
      rating: 5.0,
      comment: 'Amazing service and super organized. Highly recommended!',
      date: DateTime(2025, 11, 20),
      imageUrls: [
        'https://picsum.photos/seed/rev1/900/700',
        'https://picsum.photos/seed/rev2/900/700',
      ],
    ),
    ReviewItem(
      id: 'r2',
      userName: 'Lina',
      rating: 4.5,
      comment: 'Everything was great, only small delay at the beginning.',
      date: DateTime(2025, 10, 02),
      imageUrls: [
        'https://picsum.photos/seed/rev3/900/700',
      ],
    ),
  ],
  'p1': [
    ReviewItem(
      id: 'r3',
      userName: 'Sara',
      rating: 4.8,
      comment: 'Photos came out cinematic 🔥 loved the editing!',
      date: DateTime(2025, 9, 12),
      imageUrls: [
        'https://picsum.photos/seed/rev4/900/700',
        'https://picsum.photos/seed/rev5/900/700',
        'https://picsum.photos/seed/rev6/900/700',
      ],
    ),
  ],
};

// =====================
// ✅ Service Map Section Widget
// =====================
class _ServiceMapSection extends StatelessWidget {
  final double lat;
  final double lng;
  final String serviceName;

  const _ServiceMapSection({
    required this.lat,
    required this.lng,
    required this.serviceName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(lat, lng),
          initialZoom: 15.0,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
          ),
        ),
        children: [
          TileLayer(
           urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.flutter_application_1', // ✅ غيّر هذا
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(lat, lng),
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class VendorsListPage extends StatefulWidget {
  const VendorsListPage({Key? key}) : super(key: key);

  static final List<Map<String, dynamic>> vendorData = [
    {
      'type': 'Wedding halls and Outdoor Gardens',
      'name': 'Venues',
      'icon': Icons.location_city
    },
    {
      'type': 'Photo and Video Coverage',
      'name': 'Photographers',
      'icon': Icons.camera_alt
    },
    {
      'type': 'Food and Beverages',
      'name': 'Catering',
      'icon': Icons.restaurant_menu
    },
    {
      'type': 'Wedding Cakes and Special Sweets',
      'name': 'Cake',
      'icon': Icons.cake
    },
    {'type': 'Bouquets', 'name': 'Flower Shops', 'icon': Icons.local_florist},
    {
      'type': 'Decorations and Lighting',
      'name': 'Decor & Lighting',
      'icon': Icons.lightbulb_outline
    },
    {
      'type': 'DJs and Live Bands',
      'name': 'Music & Entertainment',
      'icon': Icons.music_note
    },
    {
      'type': 'Full Wedding Management and Coordination',
      'name': 'Wedding Planners & Coordinators',
      'icon': Icons.event
    },
    {
      'type': 'Printed and Digital Wedding Invitations',
      'name': 'Card Printing',
      'icon': Icons.mail_outline
    },
    {
      'type': 'Rings, Crowns and Accessories',
      'name': 'Jewelry & Accessories',
      'icon': Icons.workspace_premium_rounded,
    },
    {
      'type': 'Bridal Car and Guest Transportation',
      'name': 'Car Rental & Transportation',
      'icon': Icons.directions_car
    },
    {
      'type': 'Customized Favors and Gifts',
      'name': 'Gift & Souvenir',
      'icon': Icons.card_giftcard
    },
  ];

  @override
  State<VendorsListPage> createState() => _VendorsListPageState();
}

class _VendorsListPageState extends State<VendorsListPage> {
  final TextEditingController _categorySearchCtrl = TextEditingController();

  // (OLD) kept - DO NOT DELETE
  SortOption _sortOption = SortOption.ratingHighLow;
  int _minRating = 0; // 0=all, 1..5

  // =========================
  // ✅ NEW FILTER STATE (multi-select)
  // =========================
  bool _sortCheapest = false;
  bool _sortMostExpensive = false;
  bool _sortTopRated = false;

  // multi select
  final Set<String> _selectedCategories = <String>{};
  final Set<String> _selectedCities = <String>{};

  // rating threshold (we choose)
  double _minRatingValue = 0.0; // 0 = any, 4.0, 4.5 ...

  final Map<String, bool> _expanded = {};

  // =====================
  // ✅ Load Services from API
  // =====================
  bool _isLoading = true;
  Map<String, List<ServiceItem>> _allServices = {};

  @override
  void initState() {
    super.initState();
    for (final c in VendorsListPage.vendorData) {
      _expanded[c['name'] as String] = false;
    }
    _loadHomeServices();
  }

  Future<void> _loadHomeServices() async {
    try {
      setState(() => _isLoading = true);
      
      final data = await UserServiceService.getHomeServices();
      final Map<String, List<ServiceItem>> services = {};
      
      data.forEach((category, items) {
        if (items is List) {
          services[category] = items.map((item) => 
            ServiceItem.fromJson(item, category)
          ).toList();
        }
      });

      setState(() {
        _allServices = services;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading services: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load services: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _categorySearchCtrl.dispose();
    super.dispose();
  }

  String _norm(String s) => s.trim().toLowerCase();

  String _sortLabel(SortOption v) {
    switch (v) {
      case SortOption.ratingHighLow:
        return 'Rating';
      case SortOption.priceLowHigh:
        return 'Price: Low to High';
      case SortOption.priceHighLow:
        return 'Price: High to Low';
    }
  }

  // =====================
  // ✅ NEW: Filter helpers
  // =====================
  bool get _hasAnyFilter =>
      _selectedCategories.isNotEmpty ||
      _selectedCities.isNotEmpty ||
      _minRatingValue > 0 ||
      _sortCheapest ||
      _sortMostExpensive ||
      _sortTopRated;

  void _clearAllFilters() {
    setState(() {
      _selectedCategories.clear();
      _selectedCities.clear();
      _minRatingValue = 0.0;
      _sortCheapest = false;
      _sortMostExpensive = false;
      _sortTopRated = false;
    });
  }

  // Applies: category selection, city selection, minRating, sorting (multi)
  List<ServiceItem> _applyFiltersToServices(List<ServiceItem> input) {
    List<ServiceItem> list = [...input];

    if (_selectedCities.isNotEmpty) {
      list = list.where((s) => _selectedCities.contains(s.city)).toList();
    }

    if (_minRatingValue > 0) {
      list = list.where((s) => s.rating >= _minRatingValue).toList();
    }

    final bool cheapest = _sortCheapest;
    final bool expensive = _sortMostExpensive;
    final bool top = _sortTopRated;

    int cmpPrice(ServiceItem a, ServiceItem b, {required bool asc}) {
      final ap = a.hasDiscount ? (a.discountPrice ?? a.price) : a.price;
      final bp = b.hasDiscount ? (b.discountPrice ?? b.price) : b.price;
      return asc ? ap.compareTo(bp) : bp.compareTo(ap);
    }

    list.sort((a, b) {
      if (top && cheapest && !expensive) {
        final r = b.rating.compareTo(a.rating);
        if (r != 0) return r;
        return cmpPrice(a, b, asc: true);
      }
      if (top && expensive && !cheapest) {
        final r = b.rating.compareTo(a.rating);
        if (r != 0) return r;
        return cmpPrice(a, b, asc: false);
      }
      if (top && !cheapest && !expensive) {
        final r = b.rating.compareTo(a.rating);
        if (r != 0) return r;
        return cmpPrice(a, b, asc: true);
      }
      if (cheapest && !top && !expensive) {
        final p = cmpPrice(a, b, asc: true);
        if (p != 0) return p;
        return b.rating.compareTo(a.rating);
      }
      if (expensive && !top && !cheapest) {
        final p = cmpPrice(a, b, asc: false);
        if (p != 0) return p;
        return b.rating.compareTo(a.rating);
      }

      // default
      final r = b.rating.compareTo(a.rating);
      if (r != 0) return r;
      return cmpPrice(a, b, asc: true);
    });

    return list;
  }

  List<ServiceItem> _servicesForCategory(String categoryName) {
    final list = _allServices[categoryName] ?? [];
    return _applyFiltersToServices(list);
  }

  List<ServiceItem> _servicesForCompany(String companyName) {
    final List<ServiceItem> all = [];
    _allServices.forEach((_, services) {
      all.addAll(services.where((s) => s.companyName == companyName));
    });
    return _applyFiltersToServices(all);
  }

  List<Map<String, dynamic>> _filteredCategories() {
    final q = _norm(_categorySearchCtrl.text);
    final base = VendorsListPage.vendorData.toList();

    List<Map<String, dynamic>> res = base;

    if (_selectedCategories.isNotEmpty) {
      res = res
          .where((cat) => _selectedCategories.contains(cat['name'] as String))
          .toList();
    }

    if (q.isNotEmpty) {
      res = res.where((cat) {
        final name = _norm(cat['name'] as String);
        final type = _norm(cat['type'] as String);
        return name.contains(q) || type.contains(q);
      }).toList();
    }

    return res;
  }

  void _openFiltersSheet() {
    final initialSortCheapest = _sortCheapest;
    final initialSortExpensive = _sortMostExpensive;
    final initialSortTop = _sortTopRated;

    final initialCategories = Set<String>.from(_selectedCategories);
    final initialCities = Set<String>.from(_selectedCities);
    final initialMinRating = _minRatingValue;

    final allCategories =
        VendorsListPage.vendorData.map((e) => e['name'] as String).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _MultiFilterBottomSheet(
          allCategories: allCategories,
          allCities: kCities,
          initCategories: initialCategories,
          initCities: initialCities,
          initMinRating: initialMinRating,
          initCheapest: initialSortCheapest,
          initExpensive: initialSortExpensive,
          initTopRated: initialSortTop,
          onClear: () {
            _clearAllFilters();
            Navigator.pop(context);
          },
          onApply: (result) {
            setState(() {
              _selectedCategories
                ..clear()
                ..addAll(result.categories);
              _selectedCities
                ..clear()
                ..addAll(result.cities);

              _minRatingValue = result.minRating;
              _sortCheapest = result.cheapest;
              _sortMostExpensive = result.expensive;
              _sortTopRated = result.topRated;
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Future<void> _openServiceDetails(ServiceItem service) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceDetailsPage(
          serviceId: service.id,
          companyServices: _servicesForCompany(service.companyName),
        ),
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final categories = _filteredCategories();
    final bool showDescription = _categorySearchCtrl.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.6,
        centerTitle: true,
        title: Text(
          'Services',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: kText,
          ),
        ),
        iconTheme: const IconThemeData(color: kText),
        actions: const [
          _CartIconButton(),
          SizedBox(width: 6),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.black.withOpacity(0.06)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _CategorySearchField(
                                  controller: _categorySearchCtrl,
                                  hint: 'Search categories...',
                                  onChanged: () => setState(() {}),
                                  onClear: () {
                                    _categorySearchCtrl.clear();
                                    setState(() {});
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              _FilterButton(
                                active: _hasAnyFilter,
                                onTap: _openFiltersSheet,
                              ),
                            ],
                          ),
                          if (_hasAnyFilter ||
                              _categorySearchCtrl.text.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: _ActiveFiltersBar(
                                categoriesCount: _selectedCategories.length,
                                citiesCount: _selectedCities.length,
                                minRating: _minRatingValue,
                                cheapest: _sortCheapest,
                                expensive: _sortMostExpensive,
                                topRated: _sortTopRated,
                                onRemove: (kind) {
                                  setState(() {
                                    if (kind == 'cheapest') _sortCheapest = false;
                                    if (kind == 'expensive')
                                      _sortMostExpensive = false;
                                    if (kind == 'topRated') _sortTopRated = false;
                                    if (kind == 'minRating') _minRatingValue = 0.0;
                                    if (kind == 'categories')
                                      _selectedCategories.clear();
                                    if (kind == 'cities') _selectedCities.clear();
                                  });
                                },
                                onClearAll: _clearAllFilters,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: categories.isEmpty
                        ? const _EmptyStateMessage()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final cat = categories[index];
                              final String catName = cat['name'] as String;
                              final String catType = cat['type'] as String;
                              final IconData icon = cat['icon'] as IconData;

                              final services = _servicesForCategory(catName);
                              final bool expanded = _expanded[catName] ?? false;
                              final bool isFav =
                                  FavoritesStore.isVendorFavorite(catName);

                              return _CategoryCard(
                                categoryName: catName,
                                categoryType: catType,
                                icon: icon,
                                services: services,
                                expanded: expanded,
                                showDescription: showDescription,
                                isFavorite: isFav,
                                onToggleFavorite: () {
                                  setState(() {
                                    if (isFav) {
                                      FavoritesStore.removeVendorByName(catName);
                                    } else {
                                      FavoritesStore.addVendor(
                                        FavoriteVendor(name: catName, type: catType),
                                      );
                                    }
                                  });
                                },
                                onToggleExpand: services.length <= 4
                                    ? null
                                    : () => setState(
                                        () => _expanded[catName] = !expanded),
                                onViewAll: services.isEmpty
                                    ? null
                                    : () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => CategoryServicesPage(
                                              categoryName: catName,
                                              categoryType: catType,
                                              categoryIcon: icon,
                                              services: services,
                                              allCompanyResolver: (companyName) =>
                                                  _servicesForCompany(companyName),
                                            ),
                                          ),
                                        );
                                        setState(() {});
                                      },
                                onTapService: (service) =>
                                    _openServiceDetails(service),
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

// =====================
// Category "View All" Page
// =====================
class CategoryServicesPage extends StatelessWidget {
  final String categoryName;
  final String categoryType;
  final IconData categoryIcon;
  final List<ServiceItem> services;

  final List<ServiceItem> Function(String companyName) allCompanyResolver;

  const CategoryServicesPage({
    super.key,
    required this.categoryName,
    required this.categoryType,
    required this.categoryIcon,
    required this.services,
    required this.allCompanyResolver,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.6,
        title: Text(
          categoryName,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: kText),
        ),
        iconTheme: const IconThemeData(color: kText),
        actions: const [
          _CartIconButton(),
          SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        children: [
          Container(
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
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: kBlue.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kBlue.withOpacity(0.16)),
                  ),
                  child: Icon(categoryIcon, color: kBlue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryType,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: kMuted,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${services.length} services',
                        style: GoogleFonts.poppins(
                          color: kText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final s in services) ...[
            _ServiceListTileCard(
              service: s,
              companyServices: allCompanyResolver(s.companyName),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ServiceListTileCard extends StatelessWidget {
  final ServiceItem service;
  final List<ServiceItem> companyServices;
  const _ServiceListTileCard(
      {required this.service, required this.companyServices});

  String _money(double v) => '₪${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceDetailsPage(
                serviceId: service.id, companyServices: companyServices),
          ),
        );
      },
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
          children: [
            _ThumbImage(url: service.imageUrl, size: 46),
            const SizedBox(width: 12),
            Expanded(
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
                  const SizedBox(height: 4),
                  Text(
                    '${service.companyName} • ${service.city}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: kMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (service.price <= 0)
                    Text(
                      'Ask for price',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w900,
                        color: kText,
                        fontSize: 12.5,
                      ),
                    )
                  else if (service.hasDiscount)
                    Row(
                      children: [
                        Text(
                          _money(service.price),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w900,
                            color: Colors.red,
                            fontSize: 12.3,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _money(service.discountPrice!),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w900,
                            color: kText,
                            fontSize: 12.8,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      _money(service.price),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w900,
                        color: kText,
                        fontSize: 12.5,
                      ),
                    ),
                ],
              ),
            ),
            Container(
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
                    service.rating.toStringAsFixed(1),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w900,
                      color: kText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            ValueListenableBuilder<int>(
              valueListenable: ServiceFavoritesStore.listenable,
              builder: (_, __, ___) {
                final isFav = ServiceFavoritesStore.isFavorite(service.id);
                return IconButton(
                  tooltip: 'Favorite',
                  onPressed: () => toggleServiceFavorite(service),
                  icon: Icon(
                    isFav
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isFav ? kBlue : kMuted,
                  ),
                );
              },
            ),
            const Icon(Icons.chevron_right_rounded, color: kMuted),
          ],
        ),
      ),
    );
  }
}

// =====================
// Service Details Page
// =====================
class ServiceDetailsPage extends StatefulWidget {
  final String serviceId;
  final List<ServiceItem> companyServices;

  const ServiceDetailsPage({
    super.key,
    required this.serviceId,
    required this.companyServices,
  });

  @override
  State<ServiceDetailsPage> createState() => _ServiceDetailsPageState();
}

// ✅ استبدل _ServiceDetailsPageState كاملة بهذا الكود

class _ServiceDetailsPageState extends State<ServiceDetailsPage> {
  bool _isLoading = true;
  ServiceItem? _service;
  Map<String, dynamic>? _serviceData;
  
  // ✅ إحداثيات الخريطة (من الـ API)
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    _service = widget.companyServices.firstWhere(
      (s) => s.id == widget.serviceId,
      orElse: () => widget.companyServices.first,
    );
    _loadServiceDetails();
  }

  Future<void> _loadServiceDetails() async {
    try {
      setState(() => _isLoading = true);
      final data = await UserServiceService.getServiceDetails(widget.serviceId);
      
      setState(() {
        _serviceData = data;
        
        // ✅ نجيب latitude و longitude من الـ API Response
        if (data['latitude'] != null) {
          _lat = double.tryParse(data['latitude'].toString());
        }
        if (data['longitude'] != null) {
          _lng = double.tryParse(data['longitude'].toString());
        }
        
        print('📍 Coordinates from API: lat=$_lat, lng=$_lng');
        
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading service details: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load service details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _money(double v) => '₪${v.toStringAsFixed(0)}';

  void _addToCart(BuildContext context, ServiceItem s) {
    double finalPrice = s.price;
    if (s.hasDiscount && s.discountPrice != null) {
      finalPrice = s.discountPrice!;
    }

    final item = cart.CartItem(
      id: s.id,
      title: s.serviceName,
      providerName: s.companyName,
      price: finalPrice,
      imageUrl: (s.imageUrl ?? '').trim(),
      category: s.category,
      city: s.city,
    );

    cart.CartStore.instance.add(item);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: kText,
        duration: const Duration(milliseconds: 1200),
        content: Text(
          'Added to cart: ${s.serviceName}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
        ),
        action: SnackBarAction(
          label: 'Open',
          textColor: kBlue,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const cart.CartPage()),
            );
          },
        ),
      ),
    );
  }

  String _getPayTypeLabel(String? payType) {
    if (payType == null) return '';
    switch (payType.toLowerCase()) {
      case 'per event':
        return 'Per Event';
      case 'per hour':
        return 'Per Hour';
      case 'per person':
        return 'Per Person';
      case 'per day':
        return 'Per Day';
      default:
        return payType;
    }
  }

  Widget _buildPriceSection(Map<String, dynamic>? serviceData) {
    final s = _service!;
    final allPrices = serviceData?['allPrices'] as Map<String, dynamic>?;
    
    final List<MapEntry<String, double>> pricesList = [];
    
    if (allPrices != null) {
      if (allPrices['perEvent'] != null && allPrices['perEvent'] > 0) {
        pricesList.add(MapEntry('per event', (allPrices['perEvent'] as num).toDouble()));
      }
      if (allPrices['perHour'] != null && allPrices['perHour'] > 0) {
        pricesList.add(MapEntry('per hour', (allPrices['perHour'] as num).toDouble()));
      }
      if (allPrices['perPerson'] != null && allPrices['perPerson'] > 0) {
        pricesList.add(MapEntry('per person', (allPrices['perPerson'] as num).toDouble()));
      }
      if (allPrices['perDay'] != null && allPrices['perDay'] > 0) {
        pricesList.add(MapEntry('per day', (allPrices['perDay'] as num).toDouble()));
      }
    }
    
    if (pricesList.isEmpty) {
      pricesList.add(MapEntry(s.payType ?? 'per event', s.price));
    }

    if (pricesList.length == 1) {
      final entry = pricesList.first;
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _getPayTypeLabel(entry.key),
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: kMuted,
            ),
          ),
          Text(
            _money(entry.value),
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: kBlue,
            ),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pricing Options:',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: kText,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: pricesList.map((entry) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: kBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBlue.withOpacity(0.20)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getPayTypeLabel(entry.key),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: kMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _money(entry.value),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: kBlue,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _service == null) {
      return Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.6,
          title: Text('Service Details', 
            style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: kText)),
          iconTheme: const IconThemeData(color: kText),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final s = _service!;
    final companyEmail = _serviceData?['companyInfo']?['email'] ?? s.companyEmail;
    final companyPhone = _serviceData?['companyInfo']?['phone'] ?? s.companyPhone;
    final reviews = kSeedReviewsByServiceId[s.id] ?? const <ReviewItem>[];

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.6,
        title: Text(
          'Service Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: kText),
        ),
        iconTheme: const IconThemeData(color: kText),
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: ServiceFavoritesStore.listenable,
            builder: (_, __, ___) {
              final fav = ServiceFavoritesStore.isFavorite(s.id);
              return IconButton(
                tooltip: 'Favorite',
                onPressed: () => toggleServiceFavorite(s),
                icon: Icon(
                  fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: fav ? kBlue : kMuted,
                ),
              );
            },
          ),
          const _CartIconButton(),
          const SizedBox(width: 6),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.black.withOpacity(0.06))),
          ),
          child: Row(
            children: [
              Expanded(
                child: ValueListenableBuilder<List<cart.CartItem>>(
                  valueListenable: cart.CartStore.instance.itemsListenable,
                  builder: (_, __, ___) {
                    final inCart = cart.CartStore.instance.contains(s.id);

                    return ElevatedButton.icon(
                      onPressed: inCart ? null : () => _addToCart(context, s),
                      icon: Icon(inCart ? Icons.check_rounded : Icons.add_shopping_cart_rounded),
                      label: Text(
                        inCart ? 'Added' : 'Add to cart',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kText,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.black.withOpacity(0.14),
                        disabledForegroundColor: kText,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CompanyInsiderProviderPage(
                          companyName: s.companyName,
                          companyEmail: companyEmail,
                          companyPhone: companyPhone,
                          city: s.city,
                          services: widget.companyServices,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kText,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Company profile',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        children: [
          _BigHeroImage(url: s.imageUrl),
          const SizedBox(height: 12),
          
          // ✅ Service Info Container
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 10, height: 48),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.serviceName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: kText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${s.category} • ${s.city}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: kMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.black.withOpacity(0.06)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 20, color: Color.fromARGB(255, 255, 128, 0)),
                            const SizedBox(width: 6),
                            Text(
                              '${s.rating.toStringAsFixed(1)} (${s.reviewsCount})',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w800,
                                color: kBlue,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (s.price <= 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Contact for pricing', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: kMuted)),
                        Text('Ask for price', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w900, color: kText)),
                      ],
                    )
                  else
                    _buildPriceSection(_serviceData),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // ✅ Description Container
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Description', style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: kText)),
                  const SizedBox(height: 8),
                  Text(
                    (_serviceData?['description']?.toString().trim().isEmpty ?? true)
                        ? 'No description yet.'
                        : _serviceData!['description'].toString(),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: kMuted, height: 1.35),
                  ),
                ],
              ),
            ),
          ),
          
          // ✅✅✅ MAP SECTION - بعد الـ Description وقبل الـ Reviews
          if (_lat != null && _lng != null) ...[
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.black.withOpacity(0.06)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: kBlue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Location',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: kText),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 220,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(_lat!, _lng!),
                            initialZoom: 15.0,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                            ),
                          ),
                          children: [
                                    TileLayer(
                                      urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
                                      subdomains: const ['a', 'b', 'c'],
                                      userAgentPackageName: 'com.example.flutter_application_1', // نفس الاسم
                                    ),  
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(_lat!, _lng!),
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 40,
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
          ],
          
          const SizedBox(height: 12),
          
          // ✅ Reviews Section
          _ReviewsSection(serviceName: s.serviceName, reviews: reviews),
          
          const SizedBox(height: 12),
          
          // ✅ Company Info
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Company info', style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: kText)),
                  const SizedBox(height: 15),
                  _InfoRow(icon: Icons.business_rounded, text: s.companyName),
                  const SizedBox(height: 8),
                  _InfoRow(icon: Icons.email_rounded, text: companyEmail),
                  const SizedBox(height: 8),
                  _InfoRow(icon: Icons.phone_rounded, text: companyPhone),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Rest of the widgets (Cart, Info, Search, Filter, etc.) remain exactly the same...
// I'll add them in the next update
// =====================
// Cart icon with badge
// =====================
class _CartIconButton extends StatelessWidget {
  const _CartIconButton();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: cart.CartStore.instance.count,
      builder: (_, c, __) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Cart',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const cart.CartPage()),
                );
              },
              icon: const Icon(Icons.shopping_bag_rounded, color: kText),
            ),
            if (c > 0)
              Positioned(
                right: 8,
                top: 8,
                child: IgnorePointer(
                  ignoring: true,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
              ),
          ],
        );
      },
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

// =====================
// UI Pieces
// =====================

class _CategorySearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onChanged;
  final VoidCallback onClear;

  const _CategorySearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final q = controller.text;

    return TextField(
      controller: controller,
      onChanged: (_) => onChanged(),
      style: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w700, color: kText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.poppins(color: kMuted, fontWeight: FontWeight.w600),
        prefixIcon: Icon(Icons.search_rounded, color: kText.withOpacity(0.75)),
        suffixIcon: q.isNotEmpty
            ? IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.close_rounded),
                onPressed: onClear,
              )
            : null,
        filled: true,
        fillColor: Colors.black.withOpacity(0.03),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const _FilterButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 48,
        width: 52,
        decoration: BoxDecoration(
          color: kText,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.tune_rounded, color: Colors.white),
            if (active)
              Positioned(
                top: 10,
                right: 12,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: kBlue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.6),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------
// (OLD) Sort + Rating widgets kept (DO NOT DELETE)
// ---------------------
class _SortSegment extends StatelessWidget {
  final SortOption value;
  final ValueChanged<SortOption> onChanged;

  const _SortSegment({required this.value, required this.onChanged});

  String _label(SortOption v) {
    switch (v) {
      case SortOption.ratingHighLow:
        return 'Rating';
      case SortOption.priceLowHigh:
        return 'Price: Low to High';
      case SortOption.priceHighLow:
        return 'Price: High to Low';
    }
  }

  IconData _icon(SortOption v) {
    switch (v) {
      case SortOption.ratingHighLow:
        return Icons.star_rounded;
      case SortOption.priceLowHigh:
        return Icons.payments_rounded;
      case SortOption.priceHighLow:
        return Icons.payments_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = SortOption.values;

    return Column(
      children: [
        for (final it in items) ...[
          _SegRow(
            active: it == value,
            icon: _icon(it),
            label: _label(it),
            onTap: () => onChanged(it),
          ),
          if (it != items.last) const SizedBox(height: 10),
        ]
      ],
    );
  }
}

class _SegRow extends StatelessWidget {
  final bool active;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SegRow({
    required this.active,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: active ? kText : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? Colors.transparent : Colors.black.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: active ? kBlue : kText),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                  color: active ? Colors.white : kText,
                ),
              ),
            ),
            if (active)
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}

class _RatingWrap extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _RatingWrap({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, int v) {
      final active = value == v;
      return InkWell(
        onTap: () => onChanged(v),
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: active ? kBlue : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color:
                  active ? Colors.transparent : Colors.black.withOpacity(0.08),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded,
                  size: 16, color: active ? Colors.white : kBlue),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: active ? Colors.white : kText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip('All', 0),
        for (int r = 1; r <= 5; r++) chip('$r+', r),
      ],
    );
  }
}

// =====================
// ✅ NEW Active Filters Bar
// =====================
class _ActiveFiltersBar extends StatelessWidget {
  final int categoriesCount;
  final int citiesCount;
  final double minRating;
  final bool cheapest;
  final bool expensive;
  final bool topRated;

  final ValueChanged<String> onRemove;
  final VoidCallback onClearAll;

  const _ActiveFiltersBar({
    required this.categoriesCount,
    required this.citiesCount,
    required this.minRating,
    required this.cheapest,
    required this.expensive,
    required this.topRated,
    required this.onRemove,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (cheapest) {
      chips.add(_MiniChip2(
        icon: Icons.south_rounded,
        label: 'Cheapest',
        onClear: () => onRemove('cheapest'),
      ));
    }
    if (expensive) {
      chips.add(_MiniChip2(
        icon: Icons.north_rounded,
        label: 'Most expensive',
        onClear: () => onRemove('expensive'),
      ));
    }
    if (topRated) {
      chips.add(_MiniChip2(
        icon: Icons.star_rounded,
        label: 'Top rated',
        onClear: () => onRemove('topRated'),
      ));
    }
    if (minRating > 0) {
      chips.add(_MiniChip2(
        icon: Icons.grade_rounded,
        label: '${minRating.toStringAsFixed(1)}+',
        onClear: () => onRemove('minRating'),
      ));
    }
    if (categoriesCount > 0) {
      chips.add(_MiniChip2(
        icon: Icons.grid_view_rounded,
        label: '$categoriesCount categories',
        onClear: () => onRemove('categories'),
      ));
    }
    if (citiesCount > 0) {
      chips.add(_MiniChip2(
        icon: Icons.location_city_rounded,
        label: '$citiesCount cities',
        onClear: () => onRemove('cities'),
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

class _MiniChip2 extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onClear;

  const _MiniChip2({
    required this.icon,
    required this.label,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
      decoration: BoxDecoration(
        color: kBlue.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kBlue.withOpacity(0.20)),
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

// =====================
// ✅ NEW Multi Filter Bottom Sheet
// =====================
class _FilterResult {
  final bool cheapest;
  final bool expensive;
  final bool topRated;
  final double minRating;
  final Set<String> categories;
  final Set<String> cities;

  const _FilterResult({
    required this.cheapest,
    required this.expensive,
    required this.topRated,
    required this.minRating,
    required this.categories,
    required this.cities,
  });
}

class _MultiFilterBottomSheet extends StatefulWidget {
  final List<String> allCategories;
  final List<String> allCities;

  final Set<String> initCategories;
  final Set<String> initCities;

  final double initMinRating;

  final bool initCheapest;
  final bool initExpensive;
  final bool initTopRated;

  final VoidCallback onClear;
  final ValueChanged<_FilterResult> onApply;

  const _MultiFilterBottomSheet({
    required this.allCategories,
    required this.allCities,
    required this.initCategories,
    required this.initCities,
    required this.initMinRating,
    required this.initCheapest,
    required this.initExpensive,
    required this.initTopRated,
    required this.onClear,
    required this.onApply,
  });

  @override
  State<_MultiFilterBottomSheet> createState() =>
      _MultiFilterBottomSheetState();
}

class _MultiFilterBottomSheetState extends State<_MultiFilterBottomSheet> {
  late bool _cheapest;
  late bool _expensive;
  late bool _topRated;

  late double _minRating;
  late Set<String> _categories;
  late Set<String> _cities;

  @override
  void initState() {
    super.initState();
    _cheapest = widget.initCheapest;
    _expensive = widget.initExpensive;
    _topRated = widget.initTopRated;
    _minRating = widget.initMinRating;
    _categories = Set<String>.from(widget.initCategories);
    _cities = Set<String>.from(widget.initCities);
  }

  void _toggleSet(Set<String> set, String value) {
    setState(() {
      if (set.contains(value)) {
        set.remove(value);
      } else {
        set.add(value);
      }
    });
  }

  Widget _chipGrid({
    required List<Widget> children,
    int phoneColumns = 2,
    int wideColumns = 3,
  }) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final cols = w >= 520 ? wideColumns : phoneColumns;
        const gap = 10.0;
        final itemW = (w - (gap * (cols - 1))) / cols;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final ch in children)
              SizedBox(
                width: itemW,
                child: ch,
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.92,
          minChildSize: 0.55,
          maxChildSize: 0.96,
          builder: (context, scrollController) {
            return Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
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
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 10),
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
                        onPressed: widget.onClear,
                        child: Text(
                          'Clear',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w900,
                            color: kBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // ✅ Scrollable content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 12),
                      children: [
                        _SheetSection(
                          title: 'Sort',
                          child: _chipGrid(
                            phoneColumns: 2,
                            wideColumns: 3,
                            children: [
                              _ToggleChip(
                                icon: Icons.south_rounded,
                                label: 'Cheapest',
                                active: _cheapest,
                                onTap: () =>
                                    setState(() => _cheapest = !_cheapest),
                              ),
                              _ToggleChip(
                                icon: Icons.north_rounded,
                                label: 'Most expensive',
                                active: _expensive,
                                onTap: () =>
                                    setState(() => _expensive = !_expensive),
                              ),
                              _ToggleChip(
                                icon: Icons.star_rounded,
                                label: 'Top rated',
                                active: _topRated,
                                onTap: () =>
                                    setState(() => _topRated = !_topRated),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _SheetSection(
                          title: 'Minimum rating',
                          child: _chipGrid(
                            phoneColumns: 3,
                            wideColumns: 4,
                            children: [
                              _ToggleChip(
                                icon: Icons.all_inclusive_rounded,
                                label: 'Any',
                                active: _minRating == 0.0,
                                onTap: () => setState(() => _minRating = 0.0),
                              ),
                              _ToggleChip(
                                icon: Icons.grade_rounded,
                                label: '4.0+',
                                active: _minRating == 4.0,
                                onTap: () => setState(() => _minRating = 4.0),
                              ),
                              _ToggleChip(
                                icon: Icons.grade_rounded,
                                label: '4.5+',
                                active: _minRating == 4.5,
                                onTap: () => setState(() => _minRating = 4.5),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ✅ Categories as LIST (fixed height + scroll)
                        _SheetSection(
                          title: 'Categories',
                          trailing: (_categories.isNotEmpty)
                              ? TextButton(
                                  onPressed: () =>
                                      setState(() => _categories.clear()),
                                  child: Text(
                                    'Reset',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w900,
                                      color: kBlue,
                                    ),
                                  ),
                                )
                              : null,
                          child: SizedBox(
                            height: 230,
                            child: ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              itemCount: widget.allCategories.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) {
                                final c = widget.allCategories[i];
                                final active = _categories.contains(c);
                                return _ListToggleRow(
                                  icon: Icons.grid_view_rounded,
                                  label: c,
                                  active: active,
                                  onTap: () => _toggleSet(_categories, c),
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ✅ Cities as LIST (fixed height + scroll)
                        _SheetSection(
                          title: 'Cities',
                          trailing: (_cities.isNotEmpty)
                              ? TextButton(
                                  onPressed: () =>
                                      setState(() => _cities.clear()),
                                  child: Text(
                                    'Reset',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w900,
                                      color: kBlue,
                                    ),
                                  ),
                                )
                              : null,
                          child: SizedBox(
                            height: 190,
                            child: ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              itemCount: widget.allCities.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) {
                                final c = widget.allCities[i];
                                final active = _cities.contains(c);
                                return _ListToggleRow(
                                  icon: Icons.location_city_rounded,
                                  label: c,
                                  active: active,
                                  onTap: () => _toggleSet(_cities, c),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ✅ Bottom buttons fixed
                  Container(
                    padding: const EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.black.withOpacity(0.08)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                  color: Colors.black.withOpacity(0.14)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w900,
                                color: kText,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              widget.onApply(
                                _FilterResult(
                                  cheapest: _cheapest,
                                  expensive: _expensive,
                                  topRated: _topRated,
                                  minRating: _minRating,
                                  categories: _categories,
                                  cities: _cities,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kText,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              'Apply',
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ✅ Section card
class _SheetSection extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SheetSection({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w900,
                  color: kText,
                  fontSize: 12.8,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.icon,
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
                ? kBlue.withOpacity(0.30)
                : Colors.black.withOpacity(0.08),
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: kBlue.withOpacity(0.20),
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
              Icon(Icons.check_rounded, size: 16, color: kBlue),
              const SizedBox(width: 6),
            ],
            Icon(icon, size: 16, color: active ? Colors.white : kBlue),
            const SizedBox(width: 8),
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

// ✅ LIST row (for Categories + Cities)
class _ListToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ListToggleRow({
    required this.icon,
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
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: active ? kText : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? Colors.transparent : Colors.black.withOpacity(0.08),
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: kBlue.withOpacity(0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: active ? Colors.white : kBlue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w900,
                  fontSize: 12.8,
                  color: active ? Colors.white : kText,
                ),
              ),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 170),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: active ? kBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: active
                      ? Colors.transparent
                      : Colors.black.withOpacity(0.18),
                ),
              ),
              child: active
                  ? const Icon(Icons.check_rounded,
                      size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// =====================
// Category Card + Service Cards
// =====================
class _CategoryCard extends StatelessWidget {
  final String categoryName;
  final String categoryType;
  final IconData icon;

  final List<ServiceItem> services;
  final bool expanded;

  final bool showDescription;

  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  final VoidCallback? onToggleExpand;
  final VoidCallback? onViewAll;
  final void Function(ServiceItem service) onTapService;

  const _CategoryCard({
    required this.categoryName,
    required this.categoryType,
    required this.icon,
    required this.services,
    required this.expanded,
    required this.showDescription,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onToggleExpand,
    required this.onViewAll,
    required this.onTapService,
  });

  @override
  Widget build(BuildContext context) {
    final showMore = services.length > 4;
    final visible = expanded ? services : services.take(4).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: kBlue.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kBlue.withOpacity(0.16)),
                    ),
                    child: Icon(icon, color: kBlue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryName,
                          style: GoogleFonts.poppins(
                            fontSize: 16.2,
                            fontWeight: FontWeight.w900,
                            color: kText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          categoryType,
                          style: GoogleFonts.poppins(
                            fontSize: 12.2,
                            fontWeight: FontWeight.w600,
                            color: kMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (onViewAll != null)
                    TextButton(
                      onPressed: onViewAll,
                      style: TextButton.styleFrom(
                        foregroundColor: kBlue,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      child: Text(
                        'View all',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  IconButton(
                    onPressed: onToggleFavorite,
                    icon: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFavorite ? kBlue : kMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (services.isEmpty)
                _NoServicesInCategory()
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final cross = w >= 520 ? 3 : 2;

                    final textScale =
                        MediaQuery.textScaleFactorOf(context).clamp(1.0, 1.25);
                    final baseH = cross == 3 ? 230.0 : 262.0;
                    final cardH = baseH + (textScale - 1.0) * 18.0;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: visible.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cross,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: cardH,
                      ),
                      itemBuilder: (context, i) {
                        final s = visible[i];
                        return _ServiceCard(
                          service: s,
                          onTap: () => onTapService(s),
                          showDescription: showDescription,
                        );
                      },
                    );
                  },
                ),
              if (showMore) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onToggleExpand,
                    icon: Icon(expanded ? Icons.expand_less : Icons.expand_more,
                        color: kBlue),
                    label: Text(
                      expanded ? 'Show less' : 'Show more',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w900, color: kBlue),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceItem service;
  final VoidCallback onTap;
  final bool showDescription;

  const _ServiceCard({
    required this.service,
    required this.onTap,
    required this.showDescription,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black.withOpacity(0.06)),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 82,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Positioned.fill(
                          child: _CoverImage(url: service.imageUrl)),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.00),
                                Colors.black.withOpacity(0.10),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 8,
                        top: 8,
                        child: ValueListenableBuilder<int>(
                          valueListenable: ServiceFavoritesStore.listenable,
                          builder: (_, __, ___) {
                            final isFavorite =
                                ServiceFavoritesStore.isFavorite(service.id);
                            return InkWell(
                              // ✅✅✅ FIX (ONLY CHANGE): use bridge so it goes to Favorites page
                              onTap: () => toggleServiceFavorite(service),
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.black.withOpacity(0.06)),
                                ),
                                child: Icon(
                                  isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  size: 18,
                                  color: isFavorite ? kBlue : kMuted,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color: Colors.black.withOpacity(0.06)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 14, color: kBlue),
                              const SizedBox(width: 4),
                              Text(
                                service.rating.toStringAsFixed(1),
                                style: GoogleFonts.poppins(
                                  fontSize: 11.4,
                                  fontWeight: FontWeight.w900,
                                  color: kText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.serviceName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 13.2,
                            fontWeight: FontWeight.w900,
                            color: kText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          service.companyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w600,
                            color: kMuted,
                          ),
                        ),
                        if (showDescription &&
                            service.description.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            service.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 11.6,
                              fontWeight: FontWeight.w600,
                              color: kMuted,
                              height: 1.25,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 16, color: kBlue),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                service.city,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600,
                                  color: kMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(child: _PriceBlock(service: service)),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: kText,
                                foregroundColor: Colors.white,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: const VisualDensity(
                                    horizontal: -2, vertical: -2),
                                minimumSize: const Size(0, 34),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 9),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: onTap,
                              child: Text(
                                'View',
                                style: GoogleFonts.poppins(
                                    fontSize: 11.8,
                                    fontWeight: FontWeight.w900),
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
      ),
    );
  }
}

class _PriceBlock extends StatelessWidget {
  final ServiceItem service;
  const _PriceBlock({required this.service});

  String _money(double v) => '₪${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    if (service.price <= 0) {
      return Text(
        'Ask for price',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
            fontSize: 12.6, fontWeight: FontWeight.w900, color: kText),
      );
    }

    if (service.hasDiscount) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _money(service.price),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 11.8,
              fontWeight: FontWeight.w900,
              color: Colors.red,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _money(service.discountPrice!),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
                fontSize: 12.8, fontWeight: FontWeight.w900, color: kText),
          ),
        ],
      );
    }

    return Text(
      _money(service.price),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.poppins(
          fontSize: 12.6, fontWeight: FontWeight.w900, color: kText),
    );
  }
}

class _NoServicesInCategory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: kMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No services match your filters in this category.',
              style: GoogleFonts.poppins(
                fontSize: 12.6,
                color: kMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateMessage extends StatelessWidget {
  const _EmptyStateMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 52, color: kMuted),
            const SizedBox(height: 12),
            Text(
              'No categories found.',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w900, color: kText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching a different category name or clear filters.',
              style: GoogleFonts.poppins(
                  fontSize: 13.5, color: kMuted, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// =====================
// Image helpers
// =====================
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
      alignment: Alignment.center,
      errorBuilder: (_, __, ___) => Container(
        color: kBlue.withOpacity(0.10),
        child: Icon(Icons.broken_image_rounded, color: kBlue.withOpacity(0.9)),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: Colors.black.withOpacity(0.04),
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                value: progress.expectedTotalBytes == null
                    ? null
                    : progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ThumbImage extends StatelessWidget {
  final String? url;
  final double size;
  const _ThumbImage({required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: size,
        height: size,
        child: _CoverImage(url: url),
      ),
    );
  }
}

class _BigHeroImage extends StatelessWidget {
  final String? url;
  const _BigHeroImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            Positioned.fill(child: _CoverImage(url: url)),
            Positioned(
              left: 14,
              bottom: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================
// ✅ Reviews UI
// =====================
class _ReviewsSection extends StatelessWidget {
  final String serviceName;
  final List<ReviewItem> reviews;

  const _ReviewsSection({
    required this.serviceName,
    required this.reviews,
  });

  String _fmtDate(DateTime d) {
    String two(int x) => x.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  double _avgRating() {
    if (reviews.isEmpty) return 0.0;
    final sum = reviews.fold<double>(0.0, (a, b) => a + b.rating);
    return sum / reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    final avg = _avgRating();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Reviews',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900,
                    color: kText,
                  ),
                ),
                const Spacer(),
                if (reviews.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: kBlue.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: kBlue.withOpacity(0.18)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 16, color: kBlue),
                        const SizedBox(width: 6),
                        Text(
                          '${avg.toStringAsFixed(1)} • ${reviews.length}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w900,
                            color: kText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ServiceReviewsPage(
                          serviceName: serviceName,
                          reviews: reviews,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'See all',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w900,
                      color: kBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            if (reviews.isEmpty)
              Text(
                'No reviews yet.',
                style: GoogleFonts.poppins(
                  color: kMuted,
                  fontWeight: FontWeight.w700,
                ),
              )
            else ...[
              for (final r in reviews.take(2)) ...[
                _ReviewCard(
                  review: r,
                  dateText: _fmtDate(r.date),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class ServiceReviewsPage extends StatelessWidget {
  final String serviceName;
  final List<ReviewItem> reviews;

  const ServiceReviewsPage({
    super.key,
    required this.serviceName,
    required this.reviews,
  });

  String _fmtDate(DateTime d) {
    String two(int x) => x.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.6,
        iconTheme: const IconThemeData(color: kText),
        title: Text(
          'Reviews',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w900,
            color: kText,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        children: [
          Text(
            serviceName,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w900,
              color: kText,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          if (reviews.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.black.withOpacity(0.06)),
              ),
              child: Text(
                'No reviews yet.',
                style: GoogleFonts.poppins(
                  color: kMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            for (final r in reviews) ...[
              _ReviewCard(review: r, dateText: _fmtDate(r.date)),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewItem review;
  final String dateText;

  const _ReviewCard({
    required this.review,
    required this.dateText,
  });

  @override
  Widget build(BuildContext context) {
    final initial = review.userName.trim().isEmpty
        ? 'U'
        : review.userName.trim()[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: kBlue.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kBlue.withOpacity(0.18)),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900,
                    color: kBlue,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w900,
                        color: kText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateText,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        color: kMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _RatingPill(rating: review.rating),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review.comment,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: kText,
              height: 1.35,
            ),
          ),
          if (review.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 10),
            _ReviewImagesStrip(urls: review.imageUrls),
          ],
        ],
      ),
    );
  }
}

class _RatingPill extends StatelessWidget {
  final double rating;
  const _RatingPill({required this.rating});

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
            rating.toStringAsFixed(1),
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

class _ReviewImagesStrip extends StatelessWidget {
  final List<String> urls;
  const _ReviewImagesStrip({required this.urls});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final u = urls[i];
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ReviewGalleryPage(urls: urls, initialIndex: i),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 92,
                height: 72,
                child: Image.network(
                  u,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.black.withOpacity(0.05),
                    child:
                        const Icon(Icons.broken_image_rounded, color: kMuted),
                  ),
                  loadingBuilder: (_, child, p) {
                    if (p == null) return child;
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
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ReviewGalleryPage extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;

  const ReviewGalleryPage({
    super.key,
    required this.urls,
    this.initialIndex = 0,
  });

  @override
  State<ReviewGalleryPage> createState() => _ReviewGalleryPageState();
}

class _ReviewGalleryPageState extends State<ReviewGalleryPage> {
  late final PageController _pc;

  @override
  void initState() {
    super.initState();
    _pc = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: PageView.builder(
        controller: _pc,
        itemCount: widget.urls.length,
        itemBuilder: (_, i) {
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                widget.urls[i],
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image_rounded,
                  color: Colors.white70,
                  size: 42,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}