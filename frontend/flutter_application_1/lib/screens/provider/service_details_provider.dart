// lib/screens/provider/service_details_provider.dart
// Modern Service Details Page for Provider

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../user/profile/favorites.dart';
import '../user/payment/cart.dart' as cart;
import '../user/chat/chat_inside_search.dart' as chat;
import 'review_service_in_provider.dart';
import '../user/home/services_customer_home.dart';
import 'package:flutter_application_1/services/user_service/user_service_service.dart';
import 'package:flutter_application_1/services/user_service/review_service.dart';
import 'package:flutter_application_1/widgets/booking_details_modal.dart';

// =====================
// 🎨 Colors - Same as project
// =====================
const Color kPrimaryColor = Color.fromARGB(215, 20, 20, 215);
const Color kBackgroundColor = Color(0xFFF7F8FC);
const Color kTextColor = Color(0xFF0B1220);
const Color kMutedColor = Color(0xFF6B7280);
const Color kSuccessColor = Color(0xFF10B981);
const Color kWarningColor = Color(0xFFF59E0B);

/// =====================
/// Modern Service Details Page
/// =====================
class ServiceDetailsProviderPage extends StatefulWidget {
  final String serviceId;
  final List<ServiceItem> companyServices;

  const ServiceDetailsProviderPage({
    super.key,
    required this.serviceId,
    required this.companyServices,
  });

  @override
  State<ServiceDetailsProviderPage> createState() => _ServiceDetailsProviderPageState();
}

class _ServiceDetailsProviderPageState extends State<ServiceDetailsProviderPage> 
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  ServiceItem? _service;
  Map<String, dynamic>? _serviceData;
  
  // Location
  double? _lat;
  double? _lng;
  String? _bookingType;
  
  // Reviews
  List<dynamic> _reviews = [];
  double _averageRating = 0.0;
  int _totalReviews = 0;
  
  // Animation
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _service = widget.companyServices.firstWhere(
      (s) => s.id == widget.serviceId,
      orElse: () => widget.companyServices.first,
    );
    
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    
    _loadServiceDetails();
    _loadReviews();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadServiceDetails() async {
    try {
      setState(() => _isLoading = true);
      final data = await UserServiceService.getServiceDetails(widget.serviceId);

      setState(() {
        _serviceData = data;

        if (data['latitude'] != null) {
          _lat = double.tryParse(data['latitude'].toString());
        }
        if (data['longitude'] != null) {
          _lng = double.tryParse(data['longitude'].toString());
        }

        _bookingType = data['bookingType']?.toString().toLowerCase();
        _isLoading = false;
      });
      
      _animController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showErrorSnackBar('Failed to load service details');
      }
    }
  }

  Future<void> _loadReviews() async {
    try {
      final result = await ReviewService.getServiceReviews(
        serviceId: widget.serviceId,
        limit: 5,
      );
      
      if (mounted) {
        setState(() {
          _reviews = result['reviews'] ?? [];
          _averageRating = (result['averageRating'] ?? 0).toDouble();
          _totalReviews = result['totalReviews'] ?? 0;
        });
      }
    } catch (e) {
      print('Error loading reviews: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _money(double v) => '₪${v.toStringAsFixed(0)}';

  void _openBookingModal(BuildContext context, ServiceItem s) async {
    final inCart = cart.CartStore.instance.contains(s.id);
    
    if (inCart) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: kWarningColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            'This service is already in your cart',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
          action: SnackBarAction(
            label: 'View Cart',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const cart.CartPage()));
            },
          ),
        ),
      );
      return;
    }

    if (_serviceData == null || _bookingType == null) {
      _showErrorSnackBar('Service details not loaded yet');
      return;
    }

    await showBookingModal(
      context: context,
      serviceId: s.id,
      serviceName: s.serviceName,
      bookingTypeString: _bookingType!,
      serviceData: _serviceData!,
      onSuccess: () {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: kSuccessColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text(
              'Added to cart successfully!',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _service == null) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: _buildAppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: kPrimaryColor),
              const SizedBox(height: 16),
              Text(
                'Loading service...',
                style: GoogleFonts.poppins(color: kMutedColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    final s = _service!;
    final companyName = _serviceData?['companyInfo']?['name']?.toString().trim() ?? 
                        _serviceData?['companyName']?.toString().trim() ?? 
                        s.companyName;
    final companyEmail = _serviceData?['companyInfo']?['email']?.toString().trim() ?? s.companyEmail;
    final companyPhone = _serviceData?['companyInfo']?['phone']?.toString().trim() ?? s.companyPhone;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // ✅ Modern Sliver AppBar with Hero Image
            _buildSliverAppBar(s),
            
            // ✅ Content
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Service Info Card
                  _buildServiceInfoCard(s, companyName),
                  
                  const SizedBox(height: 16),
                  
                  // Price Section
                  if (s.price > 0 || _bookingType?.toLowerCase() != 'display')
                    _buildPriceCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Description
                  if (_hasDescription())
                    _buildDescriptionCard(),
                  
                  // Location Map
                  if (_lat != null && _lng != null) ...[
                    const SizedBox(height: 16),
                    _buildLocationCard(),
                  ],
                  
                  // Company Info
                  if (_hasCompanyInfo(companyName, companyEmail, companyPhone)) ...[
                    const SizedBox(height: 16),
                    _buildCompanyInfoCard(companyName, companyEmail, companyPhone),
                  ],
                  
                  // Reviews Section
                  const SizedBox(height: 16),
                  _buildReviewsSection(s),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(s, companyEmail, companyPhone),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        'Service Details',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w800, color: kTextColor),
      ),
      iconTheme: const IconThemeData(color: kTextColor),
    );
  }

  Widget _buildSliverAppBar(ServiceItem s) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0.5,
      iconTheme: const IconThemeData(color: kTextColor),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: kTextColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        // Favorite Button
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ValueListenableBuilder<int>(
            valueListenable: ServiceFavoritesStore.listenable,
            builder: (_, __, ___) {
              final fav = ServiceFavoritesStore.isFavorite(s.id);
              return IconButton(
                tooltip: 'Favorite',
                onPressed: () => toggleServiceFavorite(s),
                icon: Icon(
                  fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: fav ? Colors.red : kTextColor,
                ),
              );
            },
          ),
        ),
        // Cart Button
        Container(
          margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _CartIconButton(),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            if (s.imageUrl != null && s.imageUrl!.isNotEmpty)
              Image.network(
                s.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: kPrimaryColor.withOpacity(0.1),
                  child: const Icon(Icons.image_rounded, size: 64, color: kMutedColor),
                ),
              )
            else
              Container(
                color: kPrimaryColor.withOpacity(0.1),
                child: const Icon(Icons.image_rounded, size: 64, color: kMutedColor),
              ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
            ),
            // Category Badge
            Positioned(
              left: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.tag, size: 14, color: kPrimaryColor),
                    const SizedBox(width: 6),
                    Text(
                      s.category,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: kPrimaryColor,
                      ),
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

  Widget _buildServiceInfoCard(ServiceItem s, String companyName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Name
          Text(
            s.serviceName,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: kTextColor,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          // Company Name
          Row(
            children: [
              Icon(LucideIcons.building2, size: 16, color: kMutedColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  companyName,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kMutedColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats Row
          Row(
            children: [
              // Rating
              _buildStatChip(
                icon: Icons.star_rounded,
                iconColor: Colors.amber,
                label: _averageRating > 0 ? _averageRating.toStringAsFixed(1) : 'New',
                sublabel: '$_totalReviews reviews',
              ),
              const SizedBox(width: 12),
              // City
              if (s.city.isNotEmpty && s.city != 'N/A')
                _buildStatChip(
                  icon: LucideIcons.mapPin,
                  iconColor: kPrimaryColor,
                  label: s.city,
                  sublabel: 'Location',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String sublabel,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kBackgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withOpacity(0.04)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: kTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    sublabel,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: kMutedColor,
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

  Widget _buildPriceCard() {
    final allPrices = _serviceData?['allPrices'] as Map<String, dynamic>?;
    final bookingType = _bookingType?.toLowerCase() ?? 'daily';
    
    List<_PriceItem> prices = [];
    
    if (allPrices != null) {
      if (allPrices['perEvent'] != null && (allPrices['perEvent'] as num) > 0) {
        prices.add(_PriceItem('Per Event', (allPrices['perEvent'] as num).toDouble(), LucideIcons.calendar));
      }
      if (allPrices['perHour'] != null && (allPrices['perHour'] as num) > 0) {
        prices.add(_PriceItem('Per Hour', (allPrices['perHour'] as num).toDouble(), LucideIcons.clock));
      }
      if (allPrices['perPerson'] != null && (allPrices['perPerson'] as num) > 0) {
        prices.add(_PriceItem('Per Person', (allPrices['perPerson'] as num).toDouble(), LucideIcons.user));
      }
      if (allPrices['perDay'] != null && (allPrices['perDay'] as num) > 0) {
        prices.add(_PriceItem('Per Day', (allPrices['perDay'] as num).toDouble(), LucideIcons.sun));
      }
    }
    
    if (prices.isEmpty && _service != null) {
      IconData icon;
      String label;
      switch (bookingType) {
        case 'hourly':
          icon = LucideIcons.clock;
          label = 'Per Hour';
          break;
        case 'capacity':
          icon = LucideIcons.user;
          label = 'Per Person';
          break;
        case 'daily':
          icon = LucideIcons.sun;
          label = 'Per Day';
          break;
        default:
          icon = LucideIcons.calendar;
          label = 'Per Event';
      }
      prices.add(_PriceItem(label, _service!.price, icon));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryColor.withOpacity(0.08), kPrimaryColor.withOpacity(0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kPrimaryColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(LucideIcons.wallet, color: kPrimaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Pricing',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: kTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (prices.length == 1)
            _buildSinglePrice(prices.first)
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: prices.map((p) => _buildPriceChip(p)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSinglePrice(_PriceItem price) {
    return Row(
      children: [
        Icon(price.icon, color: kPrimaryColor, size: 20),
        const SizedBox(width: 10),
        Text(
          price.label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: kMutedColor,
          ),
        ),
        const Spacer(),
        Text(
          _money(price.value),
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: kPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceChip(_PriceItem price) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kPrimaryColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(price.icon, color: kPrimaryColor, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                price.label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: kMutedColor,
                ),
              ),
              Text(
                _money(price.value),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: kPrimaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                  color: kPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(LucideIcons.fileText, color: kPrimaryColor, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                'Description',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: kTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _getDescription(),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: kMutedColor,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kSuccessColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(LucideIcons.mapPin, color: kSuccessColor, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  'Service Location',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: kTextColor,
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            child: SizedBox(
              height: 200,
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
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'com.example.flutter_application_1',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(_lat!, _lng!),
                        width: 50,
                        height: 50,
                        child: Container(
                          decoration: BoxDecoration(
                            color: kPrimaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: kPrimaryColor.withOpacity(0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 30,
                          ),
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
    );
  }

  Widget _buildCompanyInfoCard(String name, String email, String phone) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                  color: kPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(LucideIcons.building, color: kPrimaryColor, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                'Company Info',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: kTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (name.isNotEmpty && name != 'Unknown' && name != 'N/A')
            _buildInfoRow(LucideIcons.building2, name),
          if (_service?.city != null && _service!.city.isNotEmpty && _service!.city != 'N/A')
            _buildInfoRow(LucideIcons.mapPin, _service!.city),
          if (email.isNotEmpty && email != 'N/A')
            _buildInfoRow(LucideIcons.mail, email),
          if (phone.isNotEmpty && phone != 'N/A')
            _buildInfoRow(LucideIcons.phone, phone),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: kPrimaryColor, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(ServiceItem s) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reviews',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: kTextColor,
                      ),
                    ),
                    if (_totalReviews > 0)
                      Text(
                        '${_averageRating.toStringAsFixed(1)} • $_totalReviews reviews',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kMutedColor,
                        ),
                      ),
                  ],
                ),
              ),
              // View All Button
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ServiceReviewsProviderPage(
                        serviceId: widget.serviceId,
                        serviceName: s.serviceName,
                      ),
                    ),
                  );
                },
                icon: Icon(LucideIcons.arrowRight, size: 16, color: kPrimaryColor),
                label: Text(
                  'View All',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: kPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_reviews.isEmpty)
            _buildEmptyReviews()
          else
            ..._reviews.take(2).map((review) => _buildReviewCard(review)).toList(),
        ],
      ),
    );
  }

  Widget _buildEmptyReviews() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kBackgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.messageSquare, color: kMutedColor, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'No reviews yet. Be the first to share your experience!',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kMutedColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(dynamic review) {
    final userName = review.userName ?? 'Anonymous';
    final rating = (review.rating ?? 0).toDouble();
    final comment = review.comment ?? '';
    final date = review.createdAt ?? DateTime.now();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBackgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimaryColor.withOpacity(0.8), kPrimaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        color: kTextColor,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _formatDate(date),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: kMutedColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Rating Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        color: kTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              comment,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: kMutedColor,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildBottomBar(ServiceItem s, String companyEmail, String companyPhone) {
    final isDisplayOnly = _bookingType?.toLowerCase() == 'display';
    
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Chat Button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => chat.ChatInsideSearchScreen(
                      providerName: s.companyName,
                      providerEmail: companyEmail,
                      providerPhone: companyPhone,
                    ),
                  ),
                );
              },
              icon: Icon(LucideIcons.messageCircle, color: kPrimaryColor, size: 20),
              label: Text(
                'Chat',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: kTextColor,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Add to Cart / Display Only Button
          Expanded(
            flex: 2,
            child: ValueListenableBuilder<List<cart.CartItem>>(
              valueListenable: cart.CartStore.instance.itemsListenable,
              builder: (_, items, ___) {
                final inCart = items.any((item) => item.id == s.id);
                
                return ElevatedButton.icon(
                  onPressed: (inCart || _isLoading || isDisplayOnly) 
                      ? null 
                      : () => _openBookingModal(context, s),
                  icon: Icon(
                    inCart ? Icons.check_circle_rounded 
                        : isDisplayOnly ? LucideIcons.eye 
                        : LucideIcons.shoppingCart,
                    size: 20,
                  ),
                  label: Text(
                    inCart ? 'In Cart' 
                        : isDisplayOnly ? 'Display Only' 
                        : 'Add to Cart',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (inCart || isDisplayOnly) ? Colors.grey : kTextColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.withOpacity(0.5),
                    disabledForegroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helpers
  bool _hasDescription() {
    final desc = _serviceData?['description']?.toString().trim() ?? '';
    return desc.isNotEmpty && desc != 'No description yet.';
  }

  String _getDescription() {
    return _serviceData?['description']?.toString().trim() ?? 'No description yet.';
  }

  bool _hasCompanyInfo(String name, String email, String phone) {
    return (name.isNotEmpty && name != 'Unknown' && name != 'N/A') ||
           (email.isNotEmpty && email != 'N/A') ||
           (phone.isNotEmpty && phone != 'N/A');
  }
}

// =====================
// Price Item Helper
// =====================
class _PriceItem {
  final String label;
  final double value;
  final IconData icon;
  
  _PriceItem(this.label, this.value, this.icon);
}

// =====================
// Cart Icon Button
// =====================
class _CartIconButton extends StatelessWidget {
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
              icon: const Icon(LucideIcons.shoppingBag, color: kTextColor, size: 22),
            ),
            if (c > 0)
              Positioned(
                right: 6,
                top: 6,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: kPrimaryColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      '$c',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
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
