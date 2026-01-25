// lib/screens/user/profile/favorites.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/user_service/favorites_service.dart';
import 'package:flutter_application_1/services/user_service/offers_service.dart';
import 'package:flutter_application_1/services/package_service/package_service.dart';
import 'package:flutter_application_1/widgets/package_services_view.dart';
import '../home/home_customer.dart';
import '../home/offers.dart';

// ══════════════════════════════════════════════════════════════════════════
// 🎨 Design Tokens
// ══════════════════════════════════════════════════════════════════════════
const Color kNavBlue = Color.fromARGB(215, 20, 20, 215);
const Color kPrimaryBlue = Color.fromARGB(215, 20, 20, 215);
const Color kPageBg = Color(0xFFF6F7FB);
const Color kTextDark = Color(0xFF0B1220);
const Color kTextMuted = Color(0xFF64748B);
const Color kAccentPurple = Color(0xFF8B5CF6);

// Helper function to safely parse numbers from String or num
double _parseDouble(dynamic value, [double defaultValue = 0.0]) {
  if (value == null) return defaultValue;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

int _parseInt(dynamic value, [int defaultValue = 0]) {
  if (value == null) return defaultValue;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

// ══════════════════════════════════════════════════════════════════════════
// 📄 FAVORITES PAGE
// ══════════════════════════════════════════════════════════════════════════
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Data
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _packages = [];
  List<Map<String, dynamic>> _offers = [];
  
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFavorites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        setState(() {
          _isLoading = false;
          _error = 'Please login to view favorites';
        });
        return;
      }

      // Initialize FavoritesService to get latest data from backend
      await FavoritesService.instance.init();
      
      final serviceIds = FavoritesService.instance.favoriteServiceIds;
      final packageIds = FavoritesService.instance.favoritePackageIds;
      final offerIds = FavoritesService.instance.favoriteOfferIds;

      // Fetch details in parallel
      final results = await Future.wait([
        _fetchServicesDetails(serviceIds, token),
        _fetchPackagesDetails(packageIds, token),
        _fetchOffersDetails(offerIds, token),
      ]);

      setState(() {
        _services = results[0];
        _packages = results[1];
        _offers = results[2];
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading favorites: $e');
      setState(() {
        _isLoading = false;
        _error = 'Failed to load favorites';
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchServicesDetails(List<String> ids, String token) async {
    if (ids.isEmpty) return [];
    
    final List<Map<String, dynamic>> services = [];
    for (final id in ids) {
      try {
        final response = await http.get(
          Uri.parse('${AuthService.baseUrl}/services/$id'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data is Map<String, dynamic>) {
            // Add the ID to the service data
            data['_id'] = id;
            services.add(data);
          }
        }
      } catch (e) {
        print('❌ Error fetching service $id: $e');
      }
    }
    return services;
  }

  Future<List<Map<String, dynamic>>> _fetchPackagesDetails(List<String> ids, String token) async {
    if (ids.isEmpty) return [];
    
    final List<Map<String, dynamic>> packages = [];
    for (final id in ids) {
      try {
        final response = await http.get(
          Uri.parse('${AuthService.baseUrl}/packages/$id'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data is Map<String, dynamic>) {
            // Ensure ID is present
            if (data['_id'] == null) data['_id'] = id;
            packages.add(data);
          }
        }
      } catch (e) {
        print('❌ Error fetching package $id: $e');
      }
    }
    return packages;
  }

  Future<List<Map<String, dynamic>>> _fetchOffersDetails(List<String> ids, String token) async {
    if (ids.isEmpty) return [];
    
    final List<Map<String, dynamic>> offers = [];
    for (final id in ids) {
      try {
        final response = await http.get(
          Uri.parse('${AuthService.baseUrl}/services/$id'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data is Map<String, dynamic>) {
            // Add the ID to the offer data
            data['_id'] = id;
            offers.add(data);
          }
        }
      } catch (e) {
        print('❌ Error fetching offer $id: $e');
      }
    }
    return offers;
  }

  Future<void> _removeService(String id) async {
    final success = await FavoritesService.instance.toggleServiceFavorite(id);
    if (success) {
      setState(() {
        _services.removeWhere((s) => s['_id']?.toString() == id || s['id']?.toString() == id);
      });
      _showSnackBar('Removed from favorites');
    }
  }

  Future<void> _removePackage(String id) async {
    final success = await FavoritesService.instance.togglePackageFavorite(id);
    if (success) {
      setState(() {
        _packages.removeWhere((p) => p['_id']?.toString() == id || p['id']?.toString() == id);
      });
      _showSnackBar('Removed from favorites');
    }
  }

  Future<void> _removeOffer(String id) async {
    final success = await FavoritesService.instance.toggleOfferFavorite(id);
    if (success) {
      setState(() {
        _offers.removeWhere((o) => o['_id']?.toString() == id || o['id']?.toString() == id);
      });
      _showSnackBar('Removed from favorites');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: kNavBlue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.6,
        iconTheme: const IconThemeData(color: kTextDark),
        title: Text(
          'My Favorites',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w900,
            color: kTextDark,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: kNavBlue,
          unselectedLabelColor: kTextMuted,
          indicatorColor: kNavBlue,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.home_repair_service_rounded, size: 16),
                  const SizedBox(width: 4),
                  Text('Services (${_services.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.inventory_2_rounded, size: 16),
                  const SizedBox(width: 4),
                  Text('Packages (${_packages.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_offer_rounded, size: 16, color: _tabController.index == 2 ? kAccentPurple : kTextMuted),
                  const SizedBox(width: 4),
                  Text('Offers (${_offers.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kNavBlue))
          : _error != null
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildServicesList(),
                    _buildPackagesList(),
                    _buildOffersList(),
                  ],
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.withOpacity(0.6)),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Something went wrong',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: kTextMuted,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadFavorites,
            icon: const Icon(Icons.refresh_rounded),
            label: Text('Retry', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kNavBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 📋 SERVICES LIST
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildServicesList() {
    if (_services.isEmpty) {
      return _buildEmptyState(
        icon: Icons.home_repair_service_rounded,
        title: 'No favorite services',
        subtitle: 'Browse services and tap the heart to add favorites',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      color: kNavBlue,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _services.length,
        itemBuilder: (context, index) {
          final service = _services[index];
          return _ServiceCard(
            service: service,
            onRemove: () => _removeService(service['_id']?.toString() ?? service['id']?.toString() ?? ''),
            onTap: () => _openServiceDetails(service),
          );
        },
      ),
    );
  }

  void _openServiceDetails(Map<String, dynamic> service) {
    // Get coordinates - use null if not available
    double? lat;
    double? lng;
    if (service['latitude'] != null) {
      lat = _parseDouble(service['latitude']);
      if (lat == 0.0) lat = null;
    }
    if (service['longitude'] != null) {
      lng = _parseDouble(service['longitude']);
      if (lng == 0.0) lng = null;
    }
    
    final trendingService = HomeTrendingService(
      id: service['_id']?.toString() ?? service['id']?.toString() ?? '',
      name: service['serviceName']?.toString() ?? service['name']?.toString() ?? 'Unknown',
      company: service['companyName']?.toString() ?? 'Unknown',
      providerId: service['providerId']?.toString() ?? '',
      category: service['category']?.toString() ?? 'General',
      price: _parseDouble(service['price']),
      imageUrl: _getImageUrl(service),
      desc: service['description']?.toString() ?? '',
      latitude: lat,
      longitude: lng,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceDetailsPage(service: trendingService),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 📦 PACKAGES LIST
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPackagesList() {
    if (_packages.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inventory_2_rounded,
        title: 'No favorite packages',
        subtitle: 'Browse packages and tap the heart to add favorites',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      color: kNavBlue,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _packages.length,
        itemBuilder: (context, index) {
          final pkg = _packages[index];
          return _PackageCard(
            package: pkg,
            onRemove: () => _removePackage(pkg['_id']?.toString() ?? pkg['id']?.toString() ?? ''),
            onTap: () => _openPackageDetails(pkg),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 🎁 OFFERS LIST
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildOffersList() {
    if (_offers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.local_offer_rounded,
        title: 'No favorite offers',
        subtitle: 'Browse offers and tap the heart to add favorites',
        iconColor: kAccentPurple,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      color: kAccentPurple,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _offers.length,
        itemBuilder: (context, index) {
          final offer = _offers[index];
          return _OfferCard(
            offer: offer,
            onRemove: () => _removeOffer(offer['_id']?.toString() ?? offer['id']?.toString() ?? ''),
            onTap: () => _openOfferDetails(offer),
          );
        },
      ),
    );
  }

  void _openOfferDetails(Map<String, dynamic> offer) {
    // Parse numeric values safely (API may return strings)
    final originalPrice = _parseDouble(offer['originalPrice'], _parseDouble(offer['price']));
    final discountedPrice = _parseDouble(offer['discountedPrice'], originalPrice);
    
    final offerService = OfferService.fromJson({
      'id': offer['_id']?.toString() ?? offer['id']?.toString() ?? '',
      'name': offer['serviceName']?.toString() ?? offer['name']?.toString() ?? 'Unknown',
      'company': offer['companyName']?.toString(),
      'providerId': offer['providerId']?.toString(),
      'category': offer['category']?.toString(),
      'description': offer['description']?.toString(),
      'bookingType': offer['bookingType']?.toString(),
      'payType': offer['payType']?.toString(),
      'hasFixedLocation': offer['hasFixedLocation'],
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      'discountPercentage': _parseInt(offer['discountPercentage']),
      'offerStartDate': offer['offerStartDate'],
      'offerEndDate': offer['offerEndDate'],
      'offerDescription': offer['offerDescription']?.toString(),
      'imageUrl': _getImageUrl(offer),
      'images': offer['images'],
      'latitude': _parseDouble(offer['latitude']),
      'longitude': _parseDouble(offer['longitude']),
      'city': offer['city']?.toString(),
      'rating': _parseDouble(offer['rating']),
      'totalReviews': _parseInt(offer['totalReviews']),
      'workingDays': offer['workingDays'],
      'availableHours': offer['availableHours'],
      'minBookingHours': _parseInt(offer['minBookingHours']),
      'maxBookingHours': _parseInt(offer['maxBookingHours']),
      'maxCapacity': _parseInt(offer['maxCapacity']),
      'cleanupTimeMinutes': _parseInt(offer['cleanupTimeMinutes']),
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OfferDetailsPage(offer: offerService),
      ),
    );
  }

  void _openPackageDetails(Map<String, dynamic> pkg) {
    final packageModel = PackageModel.fromJson(pkg);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PackageServicesViewPage(package: packageModel),
      ),
    );
  }

  String _getImageUrl(Map<String, dynamic> item) {
    if (item['images'] != null && item['images'] is List && (item['images'] as List).isNotEmpty) {
      return item['images'][0].toString();
    }
    return item['imageUrl']?.toString() ?? '';
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Color iconColor = kNavBlue,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 56, color: iconColor),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: kTextDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: kTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 🎴 SERVICE CARD
// ══════════════════════════════════════════════════════════════════════════
class _ServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.service,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = service['serviceName']?.toString() ?? service['name']?.toString() ?? 'Unknown Service';
    final company = service['companyName']?.toString() ?? 'Unknown';
    final category = service['category']?.toString() ?? 'General';
    final price = _parseDouble(service['price']);
    final rating = _parseDouble(service['rating']);
    final imageUrl = _getImageUrl();

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
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
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: 110,
                height: 110,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: kPageBg,
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: kPageBg,
                  child: const Icon(Icons.image_not_supported_rounded, color: kTextMuted),
                ),
              ),
            ),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: kNavBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            category,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: kNavBlue,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              rating.toStringAsFixed(1),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: kTextDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: kTextDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      company,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kTextMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '₪${price.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: kNavBlue,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: onRemove,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.favorite_rounded, size: 18, color: Colors.red),
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
    );
  }

  String _getImageUrl() {
    if (service['images'] != null && service['images'] is List && (service['images'] as List).isNotEmpty) {
      return service['images'][0].toString();
    }
    return service['imageUrl']?.toString() ?? '';
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 📦 PACKAGE CARD
// ══════════════════════════════════════════════════════════════════════════
class _PackageCard extends StatelessWidget {
  final Map<String, dynamic> package;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _PackageCard({
    required this.package,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = package['packageName']?.toString() ?? package['name']?.toString() ?? 'Unknown Package';
    final company = package['companyName']?.toString() ?? 'Unknown';
    final price = _parseDouble(package['newPrice'], _parseDouble(package['price']));
    final originalPrice = _parseDouble(package['originalTotalPrice'], _parseDouble(package['originalPrice'], price));
    final imageUrl = _getImageUrl();
    final servicesCount = _parseInt(package['servicesCount'], (package['services'] as List?)?.length ?? 0);

    final discount = originalPrice > price
        ? ((1 - price / originalPrice) * 100).round()
        : 0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
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
        child: Row(
          children: [
          // Image with discount badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 110,
                  height: 110,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: kPageBg,
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: kPageBg,
                    child: const Icon(Icons.image_not_supported_rounded, color: kTextMuted),
                  ),
                ),
              ),
              if (discount > 0)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '-$discount%',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$servicesCount Services',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: kTextDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    company,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kTextMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '₪${price.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: kNavBlue,
                        ),
                      ),
                      if (discount > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          '₪${originalPrice.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kTextMuted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                      const Spacer(),
                      InkWell(
                        onTap: onRemove,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.favorite_rounded, size: 18, color: Colors.red),
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
    );
  }

  String _getImageUrl() {
    if (package['packageImageUrl'] != null && package['packageImageUrl'].toString().isNotEmpty) {
      return package['packageImageUrl'].toString();
    }
    if (package['images'] != null && package['images'] is List && (package['images'] as List).isNotEmpty) {
      return package['images'][0].toString();
    }
    return package['imageUrl']?.toString() ?? '';
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 🎁 OFFER CARD
// ══════════════════════════════════════════════════════════════════════════
class _OfferCard extends StatelessWidget {
  final Map<String, dynamic> offer;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _OfferCard({
    required this.offer,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = offer['serviceName']?.toString() ?? offer['name']?.toString() ?? 'Unknown Offer';
    final company = offer['companyName']?.toString() ?? 'Unknown';
    final category = offer['category']?.toString() ?? 'General';
    final originalPrice = _parseDouble(offer['originalPrice'], _parseDouble(offer['price']));
    final discountedPrice = _parseDouble(offer['discountedPrice'], originalPrice);
    final discount = _parseInt(offer['discountPercentage']);
    final imageUrl = _getImageUrl();
    
    // Offer end date
    final endDateStr = offer['offerEndDate']?.toString();
    String? daysLeft;
    if (endDateStr != null) {
      final endDate = DateTime.tryParse(endDateStr);
      if (endDate != null) {
        final diff = endDate.difference(DateTime.now()).inDays;
        if (diff > 0) {
          daysLeft = '$diff days left';
        } else if (diff == 0) {
          daysLeft = 'Ends today!';
        }
      }
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kAccentPurple.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: kAccentPurple.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image with discount badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 110,
                    height: 120,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: kPageBg,
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: kAccentPurple)),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: kPageBg,
                      child: const Icon(Icons.local_offer_rounded, color: kAccentPurple),
                    ),
                  ),
                ),
                if (discount > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFFF3B30)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Text(
                        '-$discount%',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: kAccentPurple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            category,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: kAccentPurple,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (daysLeft != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.timer_outlined, size: 10, color: Colors.orange),
                                const SizedBox(width: 3),
                                Text(
                                  daysLeft,
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: kTextDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      company,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kTextMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '₪${discountedPrice.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: kAccentPurple,
                          ),
                        ),
                        if (discount > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '₪${originalPrice.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: kTextMuted,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                        const Spacer(),
                        InkWell(
                          onTap: onRemove,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: kAccentPurple.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.favorite_rounded, size: 18, color: kAccentPurple),
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
    );
  }

  String _getImageUrl() {
    if (offer['images'] != null && offer['images'] is List && (offer['images'] as List).isNotEmpty) {
      return offer['images'][0].toString();
    }
    return offer['imageUrl']?.toString() ?? '';
  }
}
