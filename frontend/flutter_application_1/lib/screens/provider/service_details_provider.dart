// lib/screens/provider/service_details_provider.dart
// Modern Responsive Service Details Page for Provider

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:video_player/video_player.dart';

import '../user/profile/favorites.dart';
import '../user/payment/cart.dart' as cart;
import '../user/chat/chat_inside_search.dart' as chat;
import 'review_service_in_provider.dart';
import '../user/home/services_customer_home.dart';
import 'package:flutter_application_1/services/user_service/user_service_service.dart';
import 'package:flutter_application_1/services/user_service/review_service.dart';
import 'package:flutter_application_1/widgets/booking_details_modal.dart';

// ============================================================================
// 🎨 THEME COLORS
// ============================================================================
const Color kPrimaryColor = Color(0xFF6C63FF);
const Color kPrimaryLight = Color(0xFFE8E6FF);
const Color kBackgroundColor = Color(0xFFF8F9FC);
const Color kCardColor = Colors.white;
const Color kTextPrimary = Color(0xFF1A1D26);
const Color kTextSecondary = Color(0xFF6B7280);
const Color kSuccessColor = Color(0xFF10B981);
const Color kWarningColor = Color(0xFFF59E0B);

// ============================================================================
// 📄 SERVICE DETAILS PROVIDER PAGE
// ============================================================================
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

  // Media Slider State
  List<String> _mediaUrls = [];
  int _currentMediaIndex = 0;
  late PageController _mediaPageController;
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();
    _service = widget.companyServices.firstWhere(
      (s) => s.id == widget.serviceId,
      orElse: () => widget.companyServices.first,
    );

    _mediaPageController = PageController();

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
    _autoSlideTimer?.cancel();
    _mediaPageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    if (_mediaUrls.length <= 1) return;

    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final nextIndex = (_currentMediaIndex + 1) % _mediaUrls.length;
      _mediaPageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  void _resetAutoSlide() {
    _startAutoSlide();
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

        _mediaUrls = [];
        if (data['images'] != null && data['images'] is List) {
          for (var img in data['images']) {
            if (img != null && img.toString().isNotEmpty) {
              _mediaUrls.add(img.toString());
            }
          }
        }
        if (_mediaUrls.isEmpty && _service?.imageUrl != null && _service!.imageUrl!.isNotEmpty) {
          _mediaUrls.add(_service!.imageUrl!);
        }

        _isLoading = false;
      });

      _startAutoSlide();
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
          content: Text('This service is already in your cart', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
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
            content: Text('Added to cart successfully!', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1100;
        final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1100;

        if (isDesktop || isTablet) {
          return _buildWebLayout(isDesktop);
        }
        return _buildMobileLayout();
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 🌐 WEB LAYOUT - Modern & Clean Design
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildWebLayout(bool isDesktop) {
    if (_isLoading || _service == null) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kPrimaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const CircularProgressIndicator(color: kPrimaryColor, strokeWidth: 3),
              ),
              const SizedBox(height: 24),
              Text('Loading service details...', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: kTextSecondary)),
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
    final isDisplayOnly = _bookingType?.toLowerCase() == 'display';

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Column(
        children: [
          _buildModernWebTopBar(s),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Hero Section with Media
                    _buildWebHeroSection(s, isDesktop),
                    // Content Section
                    Container(
                      constraints: BoxConstraints(maxWidth: isDesktop ? 1400 : double.infinity),
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 48 : 24,
                        vertical: isDesktop ? 40 : 24,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // LEFT COLUMN - Main Content
                          Expanded(
                            flex: 6,
                            child: Column(
                              children: [
                                _buildModernServiceInfoCard(s, companyName),
                                if (_hasDescription()) ...[
                                  const SizedBox(height: 24),
                                  _buildModernDescriptionCard(),
                                ],
                                const SizedBox(height: 24),
                                _buildWebReviewsSection(s),
                              ],
                            ),
                          ),
                          SizedBox(width: isDesktop ? 32 : 20),
                          // RIGHT COLUMN - Sticky Sidebar
                          SizedBox(
                            width: isDesktop ? 380 : 320,
                            child: Column(
                              children: [
                                if (!isDisplayOnly && s.price > 0)
                                  _buildModernPriceCard(),
                                if (isDisplayOnly)
                                  _buildDisplayOnlyCard(),
                                const SizedBox(height: 20),
                                _buildModernActionButtons(s, companyEmail, companyPhone),
                                if (_lat != null && _lng != null) ...[
                                  const SizedBox(height: 20),
                                  _buildModernLocationCard(),
                                ],
                                if (_hasCompanyInfo(companyName, companyEmail, companyPhone)) ...[
                                  const SizedBox(height: 20),
                                  _buildModernCompanyCard(companyName, companyEmail, companyPhone),
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
            ),
          ),
        ],
      ),
    );
  }

  // Modern Top Bar
  Widget _buildModernWebTopBar(ServiceItem s) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          _HoverButton(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: kBackgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.arrowLeft, size: 18, color: kTextSecondary),
                  const SizedBox(width: 8),
                  Text('Back', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: kTextSecondary)),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Favorite
          ValueListenableBuilder<int>(
            valueListenable: ServiceFavoritesStore.listenable,
            builder: (_, __, ___) {
              final fav = ServiceFavoritesStore.isFavorite(s.id);
              return _HoverButton(
                onTap: () => toggleServiceFavorite(s),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: fav ? Colors.red.withOpacity(0.1) : kBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 20,
                    color: fav ? Colors.red : kTextSecondary,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          _CartIconButton(),
        ],
      ),
    );
  }

  // Hero Section with Media Gallery
  Widget _buildWebHeroSection(ServiceItem s, bool isDesktop) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 24,
        vertical: isDesktop ? 32 : 20,
      ),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isDesktop ? 1400 : double.infinity),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Image
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: _mediaUrls.isEmpty
                        ? Container(
                            color: kPrimaryLight,
                            child: const Center(child: Icon(LucideIcons.image, size: 48, color: kPrimaryColor)),
                          )
                        : GestureDetector(
                            onTap: () => _openFullScreenGallery(0),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  _mediaUrls[_currentMediaIndex],
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: Colors.grey.shade100,
                                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: kPrimaryColor)),
                                    );
                                  },
                                  errorBuilder: (_, __, ___) => Container(
                                    color: kPrimaryLight,
                                    child: const Icon(Icons.broken_image_rounded, size: 48, color: kTextSecondary),
                                  ),
                                ),
                                // Expand icon overlay
                                Positioned(
                                  bottom: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(LucideIcons.expand, size: 14, color: Colors.white),
                                        const SizedBox(width: 6),
                                        Text('View Gallery', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
              // Thumbnails Grid
              if (_mediaUrls.length > 1) ...[
                const SizedBox(width: 12),
                SizedBox(
                  width: isDesktop ? 200 : 150,
                  child: Column(
                    children: [
                      ...List.generate(
                        _mediaUrls.length > 4 ? 3 : (_mediaUrls.length - 1).clamp(0, 3),
                        (index) {
                          final realIndex = index + 1;
                          if (realIndex >= _mediaUrls.length) return const SizedBox.shrink();
                          return Padding(
                            padding: EdgeInsets.only(bottom: index < 2 ? 12 : 0),
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _currentMediaIndex = realIndex);
                                _resetAutoSlide();
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: AspectRatio(
                                  aspectRatio: 4 / 3,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.network(
                                        _mediaUrls[realIndex],
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
                                      ),
                                      if (_currentMediaIndex == realIndex)
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(color: kPrimaryColor, width: 3),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      if (_mediaUrls.length > 4)
                        GestureDetector(
                          onTap: () => _openFullScreenGallery(0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AspectRatio(
                              aspectRatio: 4 / 3,
                              child: Container(
                                color: Colors.black.withOpacity(0.7),
                                child: Center(
                                  child: Text(
                                    '+${_mediaUrls.length - 4}',
                                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Modern Service Info Card
  Widget _buildModernServiceInfoCard(ServiceItem s, String companyName) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Category
          Text(
            s.serviceName,
            style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: kTextPrimary, height: 1.2),
          ),
          const SizedBox(height: 16),
          // Meta Info Row
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _buildMetaChip(LucideIcons.tag, s.category, kPrimaryLight, kPrimaryColor),
              if (s.city.isNotEmpty && s.city != 'N/A')
                _buildMetaChip(LucideIcons.mapPin, s.city, kSuccessColor.withOpacity(0.1), kSuccessColor),
              _buildMetaChip(
                Icons.star_rounded,
                _averageRating > 0 ? '${_averageRating.toStringAsFixed(1)} ($_totalReviews)' : 'New',
                Colors.amber.withOpacity(0.15),
                Colors.amber.shade700,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Provider Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.7)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      companyName.isNotEmpty ? companyName[0].toUpperCase() : 'C',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Provided by', style: GoogleFonts.poppins(fontSize: 12, color: kTextSecondary)),
                      Text(companyName, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: kTextPrimary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: kSuccessColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: kSuccessColor, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('Verified', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: kSuccessColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label, Color bgColor, Color fgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fgColor),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: fgColor)),
        ],
      ),
    );
  }

  // Modern Description Card
  Widget _buildModernDescriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.fileText, size: 20, color: kPrimaryColor),
              const SizedBox(width: 10),
              Text('About This Service', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: kTextPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _getDescription(),
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: kTextSecondary, height: 1.8),
          ),
        ],
      ),
    );
  }

  // Modern Price Card
  Widget _buildModernPriceCard() {
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.85)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: kPrimaryColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                child: const Icon(LucideIcons.wallet, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Text('Pricing', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Text(bookingType.toUpperCase(), style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...prices.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                Icon(p.icon, color: Colors.white.withOpacity(0.8), size: 18),
                const SizedBox(width: 12),
                Text(p.label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.9))),
                const Spacer(),
                Text(_money(p.value), style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // Display Only Card
  Widget _buildDisplayOnlyCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(LucideIcons.eye, color: Colors.grey.shade600, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Display Only', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: kTextPrimary)),
                Text('Contact provider for pricing', style: GoogleFonts.poppins(fontSize: 13, color: kTextSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Modern Action Buttons
  Widget _buildModernActionButtons(ServiceItem s, String companyEmail, String companyPhone) {
    final isDisplayOnly = _bookingType?.toLowerCase() == 'display';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Add to Cart Button
          ValueListenableBuilder<List<cart.CartItem>>(
            valueListenable: cart.CartStore.instance.itemsListenable,
            builder: (_, items, ___) {
              final inCart = items.any((item) => item.id == s.id);

              return _HoverButton(
                onTap: (inCart || _isLoading || isDisplayOnly) ? () {} : () => _openBookingModal(context, s),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: (inCart || isDisplayOnly)
                        ? null
                        : LinearGradient(colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.85)]),
                    color: (inCart || isDisplayOnly) ? Colors.grey.shade200 : null,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: (inCart || isDisplayOnly)
                        ? null
                        : [BoxShadow(color: kPrimaryColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        inCart ? Icons.check_circle_rounded : isDisplayOnly ? LucideIcons.eye : LucideIcons.shoppingCart,
                        size: 20,
                        color: (inCart || isDisplayOnly) ? Colors.grey.shade600 : Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        inCart ? 'Already in Cart' : isDisplayOnly ? 'Display Only' : 'Add to Cart',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: (inCart || isDisplayOnly) ? Colors.grey.shade600 : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          // Chat Button
          _HoverButton(
            onTap: () {
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
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: kBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.messageCircle, size: 18, color: kPrimaryColor),
                  const SizedBox(width: 10),
                  Text('Chat with Provider', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: kPrimaryColor)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Modern Location Card
  Widget _buildModernLocationCard() {
    final locationAddress = _serviceData?['locationAddress']?.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(LucideIcons.mapPin, size: 18, color: kSuccessColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Location', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: kTextPrimary)),
                      if (locationAddress.isNotEmpty)
                        Text(locationAddress, style: GoogleFonts.poppins(fontSize: 12, color: kTextSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: SizedBox(
              height: 150,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(_lat!, _lng!),
                  initialZoom: 14.0,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag),
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
                        width: 32,
                        height: 32,
                        child: Container(
                          decoration: BoxDecoration(
                            color: kPrimaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [BoxShadow(color: kPrimaryColor.withOpacity(0.4), blurRadius: 8)],
                          ),
                          child: const Icon(Icons.location_on, color: Colors.white, size: 16),
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

  // Modern Company Card
  Widget _buildModernCompanyCard(String name, String email, String phone) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.building, size: 18, color: kPrimaryColor),
              const SizedBox(width: 10),
              Text('Contact Info', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: kTextPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          if (email.isNotEmpty && email != 'N/A')
            _buildCompactInfoRow(LucideIcons.mail, email),
          if (phone.isNotEmpty && phone != 'N/A')
            _buildCompactInfoRow(LucideIcons.phone, phone),
        ],
      ),
    );
  }

  Widget _buildCompactInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: kTextSecondary, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: kTextPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebTopBar(ServiceItem s) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: kCardColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          _HoverButton(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: kBackgroundColor, borderRadius: BorderRadius.circular(12)),
              child: const Icon(LucideIcons.arrowLeft, size: 20, color: kTextSecondary),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.serviceName, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: kTextPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.tag, size: 12, color: kPrimaryColor),
                          const SizedBox(width: 4),
                          Text(s.category, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: kPrimaryColor)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (s.city.isNotEmpty && s.city != 'N/A')
                      Row(
                        children: [
                          const Icon(LucideIcons.mapPin, size: 14, color: kTextSecondary),
                          const SizedBox(width: 4),
                          Text(s.city, style: GoogleFonts.poppins(fontSize: 13, color: kTextSecondary)),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Favorite
          ValueListenableBuilder<int>(
            valueListenable: ServiceFavoritesStore.listenable,
            builder: (_, __, ___) {
              final fav = ServiceFavoritesStore.isFavorite(s.id);
              return _HoverButton(
                onTap: () => toggleServiceFavorite(s),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: fav ? Colors.red.withOpacity(0.1) : kBackgroundColor, borderRadius: BorderRadius.circular(12)),
                  child: Icon(fav ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 22, color: fav ? Colors.red : kTextSecondary),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          // Cart
          _CartIconButton(),
        ],
      ),
    );
  }

  Widget _buildWebMediaSection(ServiceItem s) {
    return Container(
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          // Main Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: SizedBox(
              height: 400,
              width: double.infinity,
              child: _mediaUrls.isEmpty
                  ? Container(
                      color: kPrimaryLight,
                      child: const Center(child: Icon(LucideIcons.image, size: 64, color: kPrimaryColor)),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        PageView.builder(
                          controller: _mediaPageController,
                          onPageChanged: (index) {
                            setState(() => _currentMediaIndex = index);
                            _resetAutoSlide();
                          },
                          itemCount: _mediaUrls.length,
                          itemBuilder: (context, index) {
                            final url = _mediaUrls[index];
                            final isVideo = _isVideoUrl(url);

                            if (isVideo) {
                              return _VideoThumbnail(url: url, onTap: () => _openFullScreenGallery(index));
                            }

                            return GestureDetector(
                              onTap: () => _openFullScreenGallery(index),
                              child: Image.network(
                                url,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(color: Colors.grey.shade100, child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: kPrimaryColor)));
                                },
                                errorBuilder: (_, __, ___) => Container(color: kPrimaryLight, child: const Icon(Icons.broken_image_rounded, size: 64, color: kTextSecondary)),
                              ),
                            );
                          },
                        ),
                        // Counter Badge
                        if (_mediaUrls.length > 1)
                          Positioned(
                            top: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.image, size: 14, color: Colors.white),
                                  const SizedBox(width: 6),
                                  Text('${_currentMediaIndex + 1}/${_mediaUrls.length}', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
          // Thumbnails
          if (_mediaUrls.length > 1)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 70,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _mediaUrls.length,
                  itemBuilder: (context, index) {
                    final isSelected = index == _currentMediaIndex;
                    return GestureDetector(
                      onTap: () {
                        _mediaPageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 12),
                        width: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? kPrimaryColor : Colors.transparent, width: 3),
                          boxShadow: isSelected ? [BoxShadow(color: kPrimaryColor.withOpacity(0.3), blurRadius: 8)] : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Image.network(_mediaUrls[index], fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWebServiceInfoCard(ServiceItem s, String companyName) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating & Reviews
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                    const SizedBox(width: 6),
                    Text(_averageRating > 0 ? _averageRating.toStringAsFixed(1) : 'New', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, color: kTextPrimary)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text('$_totalReviews reviews', style: GoogleFonts.poppins(fontSize: 13, color: kTextSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          // Company
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.7)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: Text(companyName.isNotEmpty ? companyName[0].toUpperCase() : 'C', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Provided by', style: GoogleFonts.poppins(fontSize: 12, color: kTextSecondary)),
                    Text(companyName, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: kTextPrimary)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWebPriceCard() {
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [kPrimaryColor.withOpacity(0.08), kPrimaryColor.withOpacity(0.02)]),
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
                decoration: BoxDecoration(color: kPrimaryColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(LucideIcons.wallet, color: kPrimaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Pricing', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: kTextPrimary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(20)),
                child: Text(bookingType, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: kPrimaryColor)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...prices.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(p.icon, color: kPrimaryColor, size: 20),
                    const SizedBox(width: 12),
                    Text(p.label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: kTextSecondary)),
                    const Spacer(),
                    Text(_money(p.value), style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: kPrimaryColor)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildWebDescriptionCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(12)),
                child: const Icon(LucideIcons.fileText, color: kPrimaryColor, size: 18),
              ),
              const SizedBox(width: 12),
              Text('Description', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: kTextPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          Text(_getDescription(), style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: kTextSecondary, height: 1.7)),
        ],
      ),
    );
  }

  Widget _buildWebLocationCard() {
    final locationAddress = _serviceData?['locationAddress']?.toString() ?? '';
    
    return Container(
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: kSuccessColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(LucideIcons.mapPin, color: kSuccessColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Service Location', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: kTextPrimary)),
                      if (locationAddress.isNotEmpty)
                        Text(locationAddress, style: GoogleFonts.poppins(fontSize: 13, color: kTextSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Modern Map Container
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kSuccessColor.withOpacity(0.2), width: 2),
              boxShadow: [BoxShadow(color: kSuccessColor.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(_lat!, _lng!),
                      initialZoom: 15.0,
                      interactionOptions: const InteractionOptions(flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag),
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
                            width: 36,
                            height: 36,
                            child: Container(
                              decoration: BoxDecoration(
                                color: kPrimaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [BoxShadow(color: kPrimaryColor.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)],
                              ),
                              child: const Icon(Icons.location_on, color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Overlay gradient
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.white.withOpacity(0.9), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  // Open in Maps button
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: _HoverButton(
                      onTap: () {
                        // TODO: Open in external maps
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: kPrimaryColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: kPrimaryColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.externalLink, size: 14, color: Colors.white),
                            const SizedBox(width: 6),
                            Text('Open Map', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebCompanyInfoCard(String name, String email, String phone) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(12)),
                child: const Icon(LucideIcons.building, color: kPrimaryColor, size: 18),
              ),
              const SizedBox(width: 12),
              Text('Company Info', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: kTextPrimary)),
            ],
          ),
          const SizedBox(height: 20),
          if (name.isNotEmpty && name != 'Unknown' && name != 'N/A') _buildInfoRow(LucideIcons.building2, name),
          if (_service?.city != null && _service!.city.isNotEmpty && _service!.city != 'N/A') _buildInfoRow(LucideIcons.mapPin, _service!.city),
          if (email.isNotEmpty && email != 'N/A') _buildInfoRow(LucideIcons.mail, email),
          if (phone.isNotEmpty && phone != 'N/A') _buildInfoRow(LucideIcons.phone, phone),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: kBackgroundColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: kPrimaryColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: kTextPrimary))),
        ],
      ),
    );
  }

  Widget _buildWebActionButtons(ServiceItem s, String companyEmail, String companyPhone) {
    final isDisplayOnly = _bookingType?.toLowerCase() == 'display';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          // Chat Button
          _HoverButton(
            onTap: () {
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
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: kBackgroundColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kPrimaryColor.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.messageCircle, size: 20, color: kPrimaryColor),
                  const SizedBox(width: 10),
                  Text('Chat with Provider', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: kPrimaryColor)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Add to Cart Button
          ValueListenableBuilder<List<cart.CartItem>>(
            valueListenable: cart.CartStore.instance.itemsListenable,
            builder: (_, items, ___) {
              final inCart = items.any((item) => item.id == s.id);

              return _HoverButton(
                onTap: (inCart || _isLoading || isDisplayOnly) ? () {} : () => _openBookingModal(context, s),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: (inCart || isDisplayOnly) ? null : LinearGradient(colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.8)]),
                    color: (inCart || isDisplayOnly) ? Colors.grey.shade300 : null,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: (inCart || isDisplayOnly) ? null : [BoxShadow(color: kPrimaryColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(inCart ? Icons.check_circle_rounded : isDisplayOnly ? LucideIcons.eye : LucideIcons.shoppingCart, size: 20, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(inCart ? 'In Cart' : isDisplayOnly ? 'Display Only' : 'Add to Cart', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWebReviewsSection(ServiceItem s) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Customer Reviews', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: kTextPrimary)),
                    if (_totalReviews > 0)
                      Text('${_averageRating.toStringAsFixed(1)} • $_totalReviews reviews', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: kTextSecondary)),
                  ],
                ),
              ),
              _HoverButton(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceReviewsProviderPage(serviceId: widget.serviceId, serviceName: s.serviceName)));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(20)),
                  child: Text('View All', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: kPrimaryColor)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_reviews.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: kBackgroundColor, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  const Icon(LucideIcons.messageSquare, color: kTextSecondary, size: 24),
                  const SizedBox(width: 14),
                  Expanded(child: Text('No reviews yet. Be the first to share your experience!', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: kTextSecondary))),
                ],
              ),
            )
          else
            ..._reviews.take(3).map((review) => _buildReviewCard(review)),
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: kBackgroundColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black.withOpacity(0.04))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(gradient: LinearGradient(colors: [kPrimaryColor.withOpacity(0.8), kPrimaryColor]), borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : 'U', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 18))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: kTextPrimary, fontSize: 15)),
                    Text(_formatReviewDate(date), style: GoogleFonts.poppins(fontSize: 12, color: kTextSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(rating.toStringAsFixed(1), style: GoogleFonts.poppins(fontWeight: FontWeight.w800, color: kTextPrimary, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(comment, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: kTextSecondary, height: 1.6), maxLines: 3, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 📱 MOBILE LAYOUT
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout() {
    if (_isLoading || _service == null) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: _buildMobileAppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: kPrimaryColor),
              const SizedBox(height: 16),
              Text('Loading service...', style: GoogleFonts.poppins(color: kTextSecondary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    final s = _service!;
    final companyName = _serviceData?['companyInfo']?['name']?.toString().trim() ?? _serviceData?['companyName']?.toString().trim() ?? s.companyName;
    final companyEmail = _serviceData?['companyInfo']?['email']?.toString().trim() ?? s.companyEmail;
    final companyPhone = _serviceData?['companyInfo']?['phone']?.toString().trim() ?? s.companyPhone;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            _buildMobileSliverAppBar(s),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildMobileServiceInfoCard(s, companyName),
                  const SizedBox(height: 16),
                  if (s.price > 0 || _bookingType?.toLowerCase() != 'display') _buildMobilePriceCard(),
                  const SizedBox(height: 16),
                  if (_hasDescription()) _buildMobileDescriptionCard(),
                  if (_lat != null && _lng != null) ...[const SizedBox(height: 16), _buildMobileLocationCard()],
                  if (_hasCompanyInfo(companyName, companyEmail, companyPhone)) ...[const SizedBox(height: 16), _buildMobileCompanyInfoCard(companyName, companyEmail, companyPhone)],
                  const SizedBox(height: 16),
                  _buildMobileReviewsSection(s),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildMobileBottomBar(s, companyEmail, companyPhone),
    );
  }

  PreferredSizeWidget _buildMobileAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text('Service Details', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, color: kTextPrimary)),
      iconTheme: const IconThemeData(color: kTextPrimary),
    );
  }

  Widget _buildMobileSliverAppBar(ServiceItem s) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0.5,
      iconTheme: const IconThemeData(color: kTextPrimary),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))]),
        child: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: kTextPrimary), onPressed: () => Navigator.pop(context)),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))]),
          child: ValueListenableBuilder<int>(
            valueListenable: ServiceFavoritesStore.listenable,
            builder: (_, __, ___) {
              final fav = ServiceFavoritesStore.isFavorite(s.id);
              return IconButton(tooltip: 'Favorite', onPressed: () => toggleServiceFavorite(s), icon: Icon(fav ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: fav ? Colors.red : kTextPrimary));
            },
          ),
        ),
        Container(margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))]), child: _CartIconButton()),
      ],
      flexibleSpace: FlexibleSpaceBar(background: _buildMobileMediaSlider(s)),
    );
  }

  Widget _buildMobileMediaSlider(ServiceItem s) {
    if (_mediaUrls.isEmpty) {
      return Container(color: kPrimaryLight, child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.image_rounded, size: 64, color: kTextSecondary), const SizedBox(height: 8), Text('No images', style: GoogleFonts.poppins(color: kTextSecondary, fontSize: 14))])));
    }

    return GestureDetector(
      onTap: () => _openFullScreenGallery(0),
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _mediaPageController,
            onPageChanged: (index) {
              setState(() => _currentMediaIndex = index);
              _resetAutoSlide();
            },
            itemCount: _mediaUrls.length,
            itemBuilder: (context, index) {
              final url = _mediaUrls[index];
              final isVideo = _isVideoUrl(url);
              if (isVideo) return _VideoThumbnail(url: url, onTap: () => _openFullScreenGallery(index));
              return GestureDetector(
                onTap: () => _openFullScreenGallery(index),
                child: Image.network(url, fit: BoxFit.cover, loadingBuilder: (context, child, loadingProgress) => loadingProgress == null ? child : Container(color: Colors.grey.shade200, child: const Center(child: CircularProgressIndicator(color: kPrimaryColor, strokeWidth: 2))), errorBuilder: (_, __, ___) => Container(color: kPrimaryLight, child: const Icon(Icons.broken_image_rounded, size: 64, color: kTextSecondary))),
              );
            },
          ),
          Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.1), Colors.transparent, Colors.black.withOpacity(0.4)], stops: const [0.0, 0.4, 1.0])))),
          if (_mediaUrls.length > 1) Positioned(bottom: 60, left: 0, right: 0, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_mediaUrls.length, (index) => AnimatedContainer(duration: const Duration(milliseconds: 300), margin: const EdgeInsets.symmetric(horizontal: 3), width: _currentMediaIndex == index ? 24 : 8, height: 8, decoration: BoxDecoration(color: _currentMediaIndex == index ? Colors.white : Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(4), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)]))))),
          if (_mediaUrls.length > 1) Positioned(top: 100, right: 16, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.photo_library_rounded, size: 14, color: Colors.white), const SizedBox(width: 4), Text('${_currentMediaIndex + 1}/${_mediaUrls.length}', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white))]))),
          Positioned(left: 16, bottom: 16, child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))]), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(LucideIcons.tag, size: 14, color: kPrimaryColor), const SizedBox(width: 6), Text(s.category, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: kPrimaryColor))]))),
        ],
      ),
    );
  }

  Widget _buildMobileServiceInfoCard(ServiceItem s, String companyName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.serviceName, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: kTextPrimary, height: 1.2)),
          const SizedBox(height: 8),
          Row(children: [const Icon(LucideIcons.building2, size: 16, color: kTextSecondary), const SizedBox(width: 8), Expanded(child: Text(companyName, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: kTextSecondary)))]),
          const SizedBox(height: 16),
          Row(children: [
            _buildMobileStatChip(icon: Icons.star_rounded, iconColor: Colors.amber, label: _averageRating > 0 ? _averageRating.toStringAsFixed(1) : 'New', sublabel: '$_totalReviews reviews'),
            const SizedBox(width: 12),
            if (s.city.isNotEmpty && s.city != 'N/A') _buildMobileStatChip(icon: LucideIcons.mapPin, iconColor: kPrimaryColor, label: s.city, sublabel: 'Location'),
          ]),
        ],
      ),
    );
  }

  Widget _buildMobileStatChip({required IconData icon, required Color iconColor, required String label, required String sublabel}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: kBackgroundColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.black.withOpacity(0.04))),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: iconColor)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: kTextPrimary), maxLines: 1, overflow: TextOverflow.ellipsis), Text(sublabel, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: kTextSecondary))])),
        ]),
      ),
    );
  }

  Widget _buildMobilePriceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [kPrimaryColor.withOpacity(0.08), kPrimaryColor.withOpacity(0.02)]), borderRadius: BorderRadius.circular(20), border: Border.all(color: kPrimaryColor.withOpacity(0.15))),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: kPrimaryColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: const Icon(LucideIcons.wallet, color: kPrimaryColor, size: 20)),
        const SizedBox(width: 12),
        Text('Pricing', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: kTextPrimary)),
        const Spacer(),
        Text(_money(_service!.price), style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w900, color: kPrimaryColor)),
      ]),
    );
  }

  Widget _buildMobileDescriptionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(12)), child: const Icon(LucideIcons.fileText, color: kPrimaryColor, size: 18)), const SizedBox(width: 12), Text('Description', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: kTextPrimary))]),
        const SizedBox(height: 14),
        Text(_getDescription(), style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: kTextSecondary, height: 1.6)),
      ]),
    );
  }

  Widget _buildMobileLocationCard() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.all(20), child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: kSuccessColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(LucideIcons.mapPin, color: kSuccessColor, size: 18)), const SizedBox(width: 12), Text('Service Location', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: kTextPrimary))])),
        ClipRRect(borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)), child: SizedBox(height: 200, child: FlutterMap(options: MapOptions(initialCenter: LatLng(_lat!, _lng!), initialZoom: 15.0, interactionOptions: const InteractionOptions(flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag)), children: [TileLayer(urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', subdomains: const ['a', 'b', 'c'], userAgentPackageName: 'com.example.flutter_application_1'), MarkerLayer(markers: [Marker(point: LatLng(_lat!, _lng!), width: 50, height: 50, child: Container(decoration: BoxDecoration(color: kPrimaryColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: kPrimaryColor.withOpacity(0.4), blurRadius: 12, spreadRadius: 2)]), child: const Icon(Icons.location_on, color: Colors.white, size: 30)))])]))),
      ]),
    );
  }

  Widget _buildMobileCompanyInfoCard(String name, String email, String phone) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(12)), child: const Icon(LucideIcons.building, color: kPrimaryColor, size: 18)), const SizedBox(width: 12), Text('Company Info', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: kTextPrimary))]),
        const SizedBox(height: 16),
        if (name.isNotEmpty && name != 'Unknown' && name != 'N/A') _buildInfoRow(LucideIcons.building2, name),
        if (_service?.city != null && _service!.city.isNotEmpty && _service!.city != 'N/A') _buildInfoRow(LucideIcons.mapPin, _service!.city),
        if (email.isNotEmpty && email != 'N/A') _buildInfoRow(LucideIcons.mail, email),
        if (phone.isNotEmpty && phone != 'N/A') _buildInfoRow(LucideIcons.phone, phone),
      ]),
    );
  }

  Widget _buildMobileReviewsSection(ServiceItem s) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.star_rounded, color: Colors.amber, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Reviews', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: kTextPrimary)), if (_totalReviews > 0) Text('${_averageRating.toStringAsFixed(1)} • $_totalReviews reviews', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: kTextSecondary))])),
          TextButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceReviewsProviderPage(serviceId: widget.serviceId, serviceName: s.serviceName))), icon: const Icon(LucideIcons.arrowRight, size: 16, color: kPrimaryColor), label: Text('View All', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: kPrimaryColor))),
        ]),
        const SizedBox(height: 16),
        if (_reviews.isEmpty)
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: kBackgroundColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.black.withOpacity(0.04))), child: Row(children: [const Icon(LucideIcons.messageSquare, color: kTextSecondary, size: 24), const SizedBox(width: 14), Expanded(child: Text('No reviews yet.', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: kTextSecondary)))]))
        else
          ..._reviews.take(2).map((review) => _buildReviewCard(review)),
      ]),
    );
  }

  Widget _buildMobileBottomBar(ServiceItem s, String companyEmail, String companyPhone) {
    final isDisplayOnly = _bookingType?.toLowerCase() == 'display';

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -4))]),
      child: Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => chat.ChatInsideSearchScreen(providerName: s.companyName, providerEmail: companyEmail, providerPhone: companyPhone))),
            icon: const Icon(LucideIcons.messageCircle, color: kPrimaryColor, size: 20),
            label: Text('Chat', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: kTextPrimary)),
            style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey.shade300), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ValueListenableBuilder<List<cart.CartItem>>(
            valueListenable: cart.CartStore.instance.itemsListenable,
            builder: (_, items, ___) {
              final inCart = items.any((item) => item.id == s.id);
              return ElevatedButton.icon(
                onPressed: (inCart || _isLoading || isDisplayOnly) ? null : () => _openBookingModal(context, s),
                icon: Icon(inCart ? Icons.check_circle_rounded : isDisplayOnly ? LucideIcons.eye : LucideIcons.shoppingCart, size: 20),
                label: Text(inCart ? 'In Cart' : isDisplayOnly ? 'Display Only' : 'Add to Cart', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(backgroundColor: (inCart || isDisplayOnly) ? Colors.grey : kTextPrimary, foregroundColor: Colors.white, disabledBackgroundColor: Colors.grey.withOpacity(0.5), disabledForegroundColor: Colors.white70, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
              );
            },
          ),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 🔧 HELPERS
  // ══════════════════════════════════════════════════════════════════════════
  bool _isVideoUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.mp4') || lower.contains('.mov') || lower.contains('.avi') || lower.contains('.webm') || lower.contains('video');
  }

  void _openFullScreenGallery(int initialIndex) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _FullScreenGallery(mediaUrls: _mediaUrls, initialIndex: initialIndex)));
  }

  bool _hasDescription() {
    final desc = _serviceData?['description']?.toString().trim() ?? '';
    return desc.isNotEmpty && desc != 'No description yet.';
  }

  String _getDescription() => _serviceData?['description']?.toString().trim() ?? 'No description yet.';

  bool _hasCompanyInfo(String name, String email, String phone) {
    return (name.isNotEmpty && name != 'Unknown' && name != 'N/A') || (email.isNotEmpty && email != 'N/A') || (phone.isNotEmpty && phone != 'N/A');
  }

  String _formatReviewDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 🧩 WIDGETS
// ════════════════════════════════════════════════════════════════════════════

class _PriceItem {
  final String label;
  final double value;
  final IconData icon;
  _PriceItem(this.label, this.value, this.icon);
}

class _HoverButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _HoverButton({required this.child, required this.onTap});
  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: widget.onTap, child: AnimatedOpacity(duration: const Duration(milliseconds: 150), opacity: _isHovered ? 0.85 : 1.0, child: widget.child)),
    );
  }
}

class _CartIconButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: cart.CartStore.instance.count,
      builder: (_, c, __) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(tooltip: 'Cart', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const cart.CartPage())), icon: const Icon(LucideIcons.shoppingBag, color: kTextPrimary, size: 22)),
            if (c > 0) Positioned(right: 6, top: 6, child: IgnorePointer(child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: kPrimaryColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white, width: 1.5)), child: Text('$c', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 10, color: Colors.white))))),
          ],
        );
      },
    );
  }
}

class _VideoThumbnail extends StatefulWidget {
  final String url;
  final VoidCallback onTap;
  const _VideoThumbnail({required this.url, required this.onTap});
  @override
  State<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<_VideoThumbnail> {
  VideoPlayerController? _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  void _initVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await _controller?.initialize();
      if (mounted) setState(() => _initialized = true);
    } catch (e) {
      print('Video init error: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_initialized && _controller != null)
            FittedBox(fit: BoxFit.cover, child: SizedBox(width: _controller!.value.size.width, height: _controller!.value.size.height, child: VideoPlayer(_controller!)))
          else
            Container(color: Colors.grey.shade900, child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))),
          Center(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle), child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 48))),
          Positioned(top: 100, left: 16, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.red.withOpacity(0.9), borderRadius: BorderRadius.circular(8)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.videocam_rounded, size: 14, color: Colors.white), const SizedBox(width: 4), Text('Video', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white))]))),
        ],
      ),
    );
  }
}

class _FullScreenGallery extends StatefulWidget {
  final List<String> mediaUrls;
  final int initialIndex;
  const _FullScreenGallery({required this.mediaUrls, required this.initialIndex});
  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late PageController _pageController;
  late int _currentIndex;
  VideoPlayerController? _videoController;
  bool _isVideoPlaying = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _checkAndLoadVideo();
  }

  void _checkAndLoadVideo() {
    _disposeVideo();
    final url = widget.mediaUrls[_currentIndex];
    if (_isVideoUrl(url)) _initVideo(url);
  }

  void _initVideo(String url) async {
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoController?.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      print('Video error: $e');
    }
  }

  void _disposeVideo() {
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
    _isVideoPlaying = false;
  }

  bool _isVideoUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.mp4') || lower.contains('.mov') || lower.contains('.avi') || lower.contains('.webm') || lower.contains('video');
  }

  @override
  void dispose() {
    _disposeVideo();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, elevation: 0, iconTheme: const IconThemeData(color: Colors.white), title: Text('${_currentIndex + 1} / ${widget.mediaUrls.length}', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)), centerTitle: true),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
          _checkAndLoadVideo();
        },
        itemCount: widget.mediaUrls.length,
        itemBuilder: (context, index) {
          final url = widget.mediaUrls[index];
          final isVideo = _isVideoUrl(url);
          if (isVideo && index == _currentIndex && _videoController != null) return _buildVideoPlayer();
          if (isVideo) return _buildVideoPlaceholder(url);
          return InteractiveViewer(minScale: 0.5, maxScale: 4.0, child: Center(child: Image.network(url, fit: BoxFit.contain, loadingBuilder: (context, child, loadingProgress) => loadingProgress == null ? child : const Center(child: CircularProgressIndicator(color: Colors.white)), errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, size: 64, color: Colors.white54))));
        },
      ),
      bottomNavigationBar: widget.mediaUrls.length > 1
          ? Container(color: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(widget.mediaUrls.length, (index) => AnimatedContainer(duration: const Duration(milliseconds: 300), margin: const EdgeInsets.symmetric(horizontal: 4), width: _currentIndex == index ? 24 : 8, height: 8, decoration: BoxDecoration(color: _currentIndex == index ? Colors.white : Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(4))))))
          : null,
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoController == null || !_videoController!.value.isInitialized) return const Center(child: CircularProgressIndicator(color: Colors.white));
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_videoController!.value.isPlaying) {
            _videoController!.pause();
            _isVideoPlaying = false;
          } else {
            _videoController!.play();
            _isVideoPlaying = true;
          }
        });
      },
      child: Stack(alignment: Alignment.center, children: [
        Center(child: AspectRatio(aspectRatio: _videoController!.value.aspectRatio, child: VideoPlayer(_videoController!))),
        AnimatedOpacity(opacity: _isVideoPlaying ? 0.0 : 1.0, duration: const Duration(milliseconds: 200), child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle), child: Icon(_isVideoPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 48))),
      ]),
    );
  }

  Widget _buildVideoPlaceholder(String url) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 48)), const SizedBox(height: 16), Text('Swipe to view video', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14))]));
  }
}
