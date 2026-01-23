// lib/widgets/package_services_view.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/services/package_service/package_service.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/screens/user/chat/chat_inside_search.dart';
import 'package:flutter_application_1/screens/user/packages/packages.dart';
import 'package:flutter_application_1/screens/user/payment/cart.dart';
import 'package:flutter_application_1/widgets/package_booking_modal.dart';
import 'package:flutter_application_1/services/package_service/add_to_cart_packages.dart';

const Color kBrandBlue = Color.fromARGB(215, 20, 20, 215);
const Color kBg = Color(0xFFF6F7FB);
const Color kCard = Colors.white;
const Color kText = Color(0xFF0B1220);
const Color kMuted = Color(0xFF6B7280);
const Color kBorder = Color(0xFFE5E7EB);
const Color kDanger = Color(0xFFEF4444);
const Color kSuccess = Color(0xFF10B981);

/// 📦 Package Services View Page (What's Inside)
class PackageServicesViewPage extends StatefulWidget {
  final PackageModel package;

  const PackageServicesViewPage({super.key, required this.package});

  @override
  State<PackageServicesViewPage> createState() => _PackageServicesViewPageState();
}

class _PackageServicesViewPageState extends State<PackageServicesViewPage> {
  bool _isAddingToCart = false;

  String _money(double v) => '₪${v.toStringAsFixed(0)}';

  void _openServiceDetails(BuildContext context, PackageServiceItem service) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PackageServiceDetailsPage(
          service: service,
          packageName: widget.package.packageName,
        ),
      ),
    );
  }

  Future<void> _handleAddToCart() async {
    final package = widget.package;
    
    // 1. Show booking modal to collect service details
    final bookings = await showPackageBookingModal(
      context: context,
      package: package,
    );

    if (bookings == null || bookings.isEmpty) {
      // User cancelled
      return;
    }

    setState(() => _isAddingToCart = true);

    try {
      // 2. Call API to add package to cart
      final dto = AddPackageToCartDto(
        packageId: package.id,
        serviceBookings: bookings,
      );

      final cartResponse = await PackageCartService.addPackageToCart(dto);

      // 3. Update cart store
      CartStore.instance.updateFromBackend(cartResponse.items);

      setState(() => _isAddingToCart = false);

      // 4. Show success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Package added to cart ✅', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            backgroundColor: kSuccess,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      setState(() => _isAddingToCart = false);
      
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            backgroundColor: kDanger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final package = widget.package;
    
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: kText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "What's Inside",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: kText,
          ),
        ),
        centerTitle: true,
      ),
      // ✅ Bottom Add to Cart button
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.black.withOpacity(0.06))),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                disabledBackgroundColor: Colors.grey.withOpacity(0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _isAddingToCart ? null : _handleAddToCart,
              icon: _isAddingToCart 
                  ? const SizedBox(
                      width: 18, 
                      height: 18, 
                      child: CircularProgressIndicator(
                        strokeWidth: 2, 
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add_shopping_cart_rounded, size: 20),
              label: Text(
                _isAddingToCart ? 'Adding...' : 'Add Package to Cart',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        children: [
          // Package Info Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kBrandBlue.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.inventory_2_rounded,
                        color: kBrandBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            package.packageName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: kText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${package.companyName} • ${package.city}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: kMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Price Summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _PriceColumn(
                          label: 'Original Total',
                          value: _money(package.totalOriginal),
                          strikethrough: true,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: kBorder,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PriceColumn(
                          label: 'Package Price',
                          value: _money(package.totalPackage),
                          highlight: true,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: kBorder,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PriceColumn(
                          label: 'You Save',
                          value: _money(package.totalOriginal - package.totalPackage),
                          success: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Services Header
          Text(
            'Included Services (${package.services.length})',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: kText,
            ),
          ),

          const SizedBox(height: 12),

          // Services List - Modern Style
          ...package.services.map((service) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ModernServiceCard(
              service: service,
              onTap: () => _openServiceDetails(context, service),
            ),
          )).toList(),

          const SizedBox(height: 20),

          // Package Info Footer
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Valid from ${DateFormat('MMM d').format(package.startDate)} to ${DateFormat('MMM d, yyyy').format(package.endDate)}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Colors.blue.shade800,
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

/// 🎴 Modern Service Card - Clean List Style
class _ModernServiceCard extends StatelessWidget {
  final PackageServiceItem service;
  final VoidCallback onTap;

  const _ModernServiceCard({
    required this.service,
    required this.onTap,
  });

  String _money(double v) => '₪${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    final hasDiscount = service.originalPrice > service.newPrice;
    final discountPercent = hasDiscount
        ? ((service.originalPrice - service.newPrice) / service.originalPrice * 100).round()
        : 0;

    return Material(
      color: kCard,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: kBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Service Image/Icon
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: kBrandBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: service.imageUrl != null && service.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: CachedNetworkImage(
                          imageUrl: service.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Center(
                            child: Icon(
                              _getCategoryIcon(service.category),
                              color: kBrandBlue,
                              size: 28,
                            ),
                          ),
                          errorWidget: (_, __, ___) => Icon(
                            _getCategoryIcon(service.category),
                            color: kBrandBlue,
                            size: 28,
                          ),
                        ),
                      )
                    : Icon(
                        _getCategoryIcon(service.category),
                        color: kBrandBlue,
                        size: 28,
                      ),
              ),
              const SizedBox(width: 14),
              
              // Service Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service Name
                    Text(
                      service.serviceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: kText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Category
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: kBrandBlue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        service.category,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: kBrandBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Price Row
                    Row(
                      children: [
                        if (hasDiscount) ...[
                          Text(
                            _money(service.originalPrice),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: kMuted,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          _money(service.newPrice),
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: kBrandBlue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Discount Badge & Arrow
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (hasDiscount)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: kSuccess.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kSuccess.withOpacity(0.3)),
                      ),
                      child: Text(
                        '-$discountPercent%',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: kSuccess,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: kBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: kMuted,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'venues':
        return Icons.location_city_rounded;
      case 'photographers':
        return Icons.camera_alt_rounded;
      case 'catering':
        return Icons.restaurant_rounded;
      case 'cake':
        return Icons.cake_rounded;
      case 'flower shops':
        return Icons.local_florist_rounded;
      case 'decor & lighting':
        return Icons.lightbulb_rounded;
      case 'music & entertainment':
        return Icons.music_note_rounded;
      case 'event planners':
      case 'event planners & coordinators':
        return Icons.event_rounded;
      case 'card printing':
        return Icons.mail_rounded;
      case 'jewelry & accessories':
        return Icons.diamond_rounded;
      case 'car rental & transportation':
      case 'car rental and transportation':
        return Icons.directions_car_rounded;
      case 'gift & souvenir':
        return Icons.card_giftcard_rounded;
      default:
        return Icons.star_rounded;
    }
  }
}

// =============================================================================
// 📱 Package Service Details Page (with Chat instead of Add to Cart)
// =============================================================================
class _PackageServiceDetailsPage extends StatefulWidget {
  final PackageServiceItem service;
  final String packageName;

  const _PackageServiceDetailsPage({
    required this.service,
    required this.packageName,
  });

  @override
  State<_PackageServiceDetailsPage> createState() => _PackageServiceDetailsPageState();
}

class _PackageServiceDetailsPageState extends State<_PackageServiceDetailsPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _serviceData;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadServiceDetails();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadServiceDetails() async {
    try {
      final baseUrl = AuthService.baseUrl;
      final url = '$baseUrl/services/${widget.service.serviceId}';
      print('🔗 Fetching service from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print('📡 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📦 Service data loaded: ${data['serviceName'] ?? data['name']}');
        print('📷 mediaItems: ${data['mediaItems']}');
        print('📷 images: ${data['images']}');
        print('📷 images type: ${data['images']?.runtimeType}');
        setState(() {
          _serviceData = data;
          _isLoading = false;
        });
      } else {
        print('❌ Response body: ${response.body}');
        throw Exception('Failed to load');
      }
    } catch (e) {
      print('❌ Error loading service: $e');
      setState(() {
        _isLoading = false;
        _serviceData = null;
      });
    }
  }

  String _money(double v) => '₪${v.toStringAsFixed(0)}';

  void _openChat() {
    final providerName = _serviceData?['companyName']?.toString() ?? 'Provider';
    final providerEmail = _serviceData?['provider']?['email']?.toString() ?? '';
    final providerPhone = _serviceData?['provider']?['phoneNumber']?.toString() ?? '';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatInsideSearchScreen(
          providerName: providerName,
          providerEmail: providerEmail,
          providerPhone: providerPhone,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final hasDiscount = service.originalPrice > service.newPrice;
    final discountPercent = hasDiscount
        ? ((service.originalPrice - service.newPrice) / service.originalPrice * 100).round()
        : 0;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.6,
        centerTitle: true,
        iconTheme: const IconThemeData(color: kText),
        title: Text(
          'Service Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: kText),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kBrandBlue))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Package Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: kBrandBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBrandBlue.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.inventory_2_rounded, size: 16, color: kBrandBlue),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Part of "${widget.packageName}"',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: kBrandBlue,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),

                // Service Image Slider
                _buildImageSlider(service, hasDiscount, discountPercent),

                const SizedBox(height: 16),

                // Service Info Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: kBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category & Rating Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: kBrandBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              service.category,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: kBrandBlue,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (_serviceData?['rating'] != null)
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  _serviceData!['rating'].toString(),
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w900,
                                    color: kText,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 14),

                      // Service Name
                      Text(
                        service.serviceName,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: kText,
                        ),
                      ),
                      
                      const SizedBox(height: 6),

                      // Company Name
                      Text(
                        _serviceData?['companyName']?.toString() ?? 'Provider',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: kMuted,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Price Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: kBorder),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Package Price',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    color: kMuted,
                                  ),
                                ),
                                Text(
                                  _money(service.newPrice),
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: kBrandBlue,
                                  ),
                                ),
                              ],
                            ),
                            if (hasDiscount) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Original Price',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: kMuted,
                                    ),
                                  ),
                                  Text(
                                    _money(service.originalPrice),
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: kMuted,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: kSuccess.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    'You save ${_money(service.originalPrice - service.newPrice)} with this package!',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: kSuccess,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Max Hours / Capacity
                      if (service.maxHours != null || service.maxCapacity != null) ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            if (service.maxHours != null)
                              _InfoChip(
                                icon: Icons.access_time_rounded,
                                label: 'Max ${service.maxHours} hours',
                              ),
                            if (service.maxCapacity != null)
                              _InfoChip(
                                icon: Icons.people_rounded,
                                label: 'Max ${service.maxCapacity} people',
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Description
                if (_serviceData?['description'] != null && 
                    _serviceData!['description'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: kBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.description_rounded, size: 18, color: kBrandBlue),
                            const SizedBox(width: 8),
                            Text(
                              'Description',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w800,
                                color: kText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _serviceData!['description'].toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: kMuted,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 100), // Space for bottom button
              ],
            ),
      
      // Bottom Chat Button
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: kBorder)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _openChat,
            style: ElevatedButton.styleFrom(
              backgroundColor: kBrandBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.chat_bubble_rounded, size: 20),
            label: Text(
              'Chat with Provider',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Image Slider Widget
  Widget _buildImageSlider(PackageServiceItem service, bool hasDiscount, int discountPercent) {
    // ✅ Check both 'mediaItems' and 'images' fields
    List mediaItems = _serviceData?['mediaItems'] as List? ?? [];
    if (mediaItems.isEmpty) {
      mediaItems = _serviceData?['images'] as List? ?? [];
    }
    
    print('📷 Found ${mediaItems.length} images');
    
    if (mediaItems.isEmpty) {
      // No images - show placeholder
      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Container(
              height: 220,
              width: double.infinity,
              color: kBrandBlue.withOpacity(0.08),
              child: Center(
                child: Icon(
                  _getCategoryIcon(service.category),
                  size: 64,
                  color: kBrandBlue.withOpacity(0.5),
                ),
              ),
            ),
            if (hasDiscount)
              Positioned(
                top: 12,
                left: 12,
                child: _buildDiscountBadge(discountPercent),
              ),
          ],
        ),
      );
    }

    // Has images - show slider
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              SizedBox(
                height: 220,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: mediaItems.length,
                  onPageChanged: (index) {
                    setState(() => _currentImageIndex = index);
                  },
                  itemBuilder: (context, index) {
                    final item = mediaItems[index];
                    // ✅ Support both formats: {url: '...'} or just string URL
                    String url = '';
                    bool isVideo = false;
                    
                    if (item is String) {
                      url = item;
                    } else if (item is Map) {
                      url = item['url']?.toString() ?? '';
                      isVideo = item['type'] == 'video';
                    }
                    
                    print('📷 Image $index URL: $url');
                    
                    if (isVideo) {
                      // Video thumbnail with play icon
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            color: Colors.black,
                            child: const Center(
                              child: Icon(
                                Icons.play_circle_outline_rounded,
                                color: Colors.white,
                                size: 64,
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    
                    return CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: kBg,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: kBrandBlue,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: kBg,
                        child: Icon(
                          _getCategoryIcon(service.category),
                          size: 48,
                          color: kBrandBlue.withOpacity(0.3),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Discount Badge
              if (hasDiscount)
                Positioned(
                  top: 12,
                  left: 12,
                  child: _buildDiscountBadge(discountPercent),
                ),
              
              // Image Counter Badge
              if (mediaItems.length > 1)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_library_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          '${_currentImageIndex + 1}/${mediaItems.length}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Dots Indicator
        if (mediaItems.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              mediaItems.length,
              (index) => GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentImageIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentImageIndex == index
                        ? kBrandBlue
                        : kBrandBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDiscountBadge(int discountPercent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kDanger,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '-$discountPercent%',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w900,
          fontSize: 14,
          color: Colors.white,
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'venues':
        return Icons.location_city_rounded;
      case 'photographers':
        return Icons.camera_alt_rounded;
      case 'catering':
        return Icons.restaurant_rounded;
      case 'cake':
        return Icons.cake_rounded;
      case 'flower shops':
        return Icons.local_florist_rounded;
      case 'decor & lighting':
        return Icons.lightbulb_rounded;
      case 'music & entertainment':
        return Icons.music_note_rounded;
      default:
        return Icons.star_rounded;
    }
  }
}

/// 🏷️ Info Chip
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: kMuted),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: kText,
            ),
          ),
        ],
      ),
    );
  }
}

/// 💰 Price Column
class _PriceColumn extends StatelessWidget {
  final String label;
  final String value;
  final bool strikethrough;
  final bool highlight;
  final bool success;

  const _PriceColumn({
    required this.label,
    required this.value,
    this.strikethrough = false,
    this.highlight = false,
    this.success = false,
  });

  @override
  Widget build(BuildContext context) {
    Color valueColor = kText;
    if (highlight) valueColor = kBrandBlue;
    if (success) valueColor = Colors.green.shade700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: kMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: valueColor,
            decoration: strikethrough ? TextDecoration.lineThrough : null,
          ),
        ),
      ],
    );
  }
}