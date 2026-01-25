// lib/screens/showMore_provider.dart
// Modern Service Details Page for Provider - Redesigned

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'full_image_viewer_provider.dart';
import 'service_reviews_provider.dart';
import '../services/user_service/review_service.dart';
import '../models/review_model.dart' as ReviewModel;

// =====================
// 🎨 Colors - Same as project
// =====================
const Color kPrimaryColor = Color.fromARGB(215, 20, 20, 215);
const Color kBackgroundColor = Color(0xFFF7F8FC);
const Color kTextColor = Color(0xFF0B1220);
const Color kMutedColor = Color(0xFF6B7280);
const Color kSuccessColor = Color(0xFF10B981);
const Color kWarningColor = Color(0xFFF59E0B);

class ShowMoreProviderScreen extends StatefulWidget {
  final Map<String, dynamic> service;
  final Function(Map<String, dynamic>)? onEdit;

  const ShowMoreProviderScreen({
    Key? key,
    required this.service,
    this.onEdit,
  }) : super(key: key);

  @override
  State<ShowMoreProviderScreen> createState() => _ShowMoreProviderScreenState();
}

class _ShowMoreProviderScreenState extends State<ShowMoreProviderScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  Timer? _autoSlideTimer;
  
  // Reviews state
  List<ServiceReview> _reviews = [];
  double _avgRating = 0.0;
  int _totalReviews = 0;
  bool _isLoadingReviews = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    
    // Fetch reviews from API
    _fetchReviews();
    
    // Start auto-slide timer for images
    _startAutoSlide();
  }

  void _startAutoSlide() {
    final images = List<dynamic>.from(widget.service['images'] ?? []);
    if (images.length > 1) {
      _autoSlideTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (_pageController.hasClients) {
          int nextPage = (_currentImageIndex + 1) % images.length;
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  Future<void> _fetchReviews() async {
    try {
      final serviceId = widget.service['_id']?.toString() ?? widget.service['serviceId']?.toString() ?? '';
      if (serviceId.isEmpty) {
        setState(() => _isLoadingReviews = false);
        return;
      }

      final result = await ReviewService.getServiceReviews(
        serviceId: serviceId,
        page: 1,
        limit: 20,
      );

      final List<ReviewModel.Review> apiReviews = List<ReviewModel.Review>.from(result['reviews'] ?? []);
      
      setState(() {
        _reviews = apiReviews.map((r) => ServiceReview(
          id: r.id,
          visitorId: r.userId,
          customerName: r.userName,
          rating: r.rating,
          comment: r.comment ?? '',
          createdAt: r.reviewDate,
        )).toList();
        
        _avgRating = (result['averageRating'] ?? 0.0).toDouble();
        _totalReviews = result['totalReviews'] ?? _reviews.length;
        _isLoadingReviews = false;
      });
    } catch (e) {
      print('❌ Error fetching reviews: $e');
      setState(() => _isLoadingReviews = false);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _pageController.dispose();
    _autoSlideTimer?.cancel();
    super.dispose();
  }

  List<ServiceReview> _extractReviews() {
    final raw = widget.service['reviews'];
    if (raw is! List) return [];

    return raw
        .map<ServiceReview?>((item) {
          if (item is! Map) return null;
          final map = Map<String, dynamic>.from(item as Map);

          int rating = int.tryParse(map['rating']?.toString() ?? '') ?? 0;
          if (rating < 1) rating = 1;
          if (rating > 5) rating = 5;

          DateTime createdAt;
          final rawDate = map['createdAt'];
          if (rawDate is DateTime) {
            createdAt = rawDate;
          } else {
            createdAt = DateTime.tryParse(rawDate?.toString() ?? '') ?? DateTime.now();
          }

          return ServiceReview(
            id: map['id']?.toString() ?? '',
            visitorId: map['userId']?.toString() ?? map['visitorId']?.toString() ?? '',
            customerName: map['customerName']?.toString() ?? map['userName']?.toString() ?? 'Customer',
            rating: rating,
            comment: map['comment']?.toString() ?? '',
            createdAt: createdAt,
          );
        })
        .whereType<ServiceReview>()
        .toList();
  }

  Widget _buildDisplayImage(dynamic imageSource, {BoxFit fit = BoxFit.cover}) {
    if (imageSource is Uint8List) {
      return Image.memory(imageSource, fit: fit);
    } else if (imageSource is String) {
      if (imageSource.startsWith('http') || imageSource.startsWith('https')) {
        return Image.network(
          imageSource,
          fit: fit,
          errorBuilder: (_, __, ___) => Container(
            color: kPrimaryColor.withOpacity(0.1),
            child: const Icon(Icons.broken_image, color: kMutedColor, size: 48),
          ),
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                color: kPrimaryColor,
                strokeWidth: 2.5,
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                    : null,
              ),
            );
          },
        );
      } else if (!kIsWeb) {
        return Image.file(File(imageSource), fit: fit,
          errorBuilder: (_, __, ___) => Container(
            color: kPrimaryColor.withOpacity(0.1),
            child: const Icon(Icons.broken_image, color: kMutedColor, size: 48),
          ),
        );
      }
    }
    return Container(
      color: kPrimaryColor.withOpacity(0.1),
      child: const Icon(Icons.image_rounded, color: kMutedColor, size: 48),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.service;
    final images = List<dynamic>.from(s['images'] ?? []);
    final highlights = List<String>.from(s['highlights'] ?? []);
    final packages = List<Map<String, dynamic>>.from(
      (s['packages'] ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList()
    );

    // Price calculation
    final double oldPrice = double.tryParse(s['price']?.toString() ?? '0') ?? 0;
    final bool hasDiscount = s["discount"] != null && s["discount"].toString().trim().isNotEmpty;
    double finalPrice = oldPrice;
    if (hasDiscount) {
      final d = double.tryParse(s['discount'].toString()) ?? 0;
      finalPrice = oldPrice - (oldPrice * (d / 100));
    }

    // Location
    final double? lat = double.tryParse(s['latitude']?.toString() ?? '');
    final double? lng = double.tryParse(s['longitude']?.toString() ?? '');
    final bool hasLocation = lat != null && lng != null;

    // Use reviews from state (fetched from API)
    final reviews = _reviews;
    final avgRating = _avgRating;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Modern Sliver App Bar with Hero Image
            _buildSliverAppBar(s, images, hasDiscount),
            
            // Content
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Service Info Card
                  _buildServiceInfoCard(s, avgRating, _totalReviews),
                  
                  const SizedBox(height: 16),
                  
                  // Price Card
                  _buildPriceCard(oldPrice, finalPrice, hasDiscount, s),
                  
                  // Description
                  if (_hasDescription(s)) ...[
                    const SizedBox(height: 16),
                    _buildDescriptionCard(s),
                  ],
                  
                  // Service Information
                  const SizedBox(height: 16),
                  _buildServiceInformationCard(s),
                  
                  // Location Map
                  if (hasLocation) ...[
                    const SizedBox(height: 16),
                    _buildLocationCard(lat!, lng!, s['city'] ?? '', s['address'] ?? ''),
                  ],
                  
                  // Highlights
                  if (highlights.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildHighlightsCard(highlights),
                  ],
                  
                  // Packages
                  if (packages.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildPackagesSection(packages),
                  ],
                  
                  // Reviews Section
                  const SizedBox(height: 16),
                  _buildReviewsSection(s, reviews, avgRating),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(s),
    );
  }

  Widget _buildSliverAppBar(Map<String, dynamic> s, List<dynamic> images, bool hasDiscount) {
    return SliverAppBar(
      expandedHeight: 220, // Reduced from 300
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: _buildCircleButton(
        icon: LucideIcons.arrowLeft,
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        // Reviews Button
        _buildCircleButton(
          icon: LucideIcons.messageSquare,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ServiceReviewsProviderScreen(
                  service: widget.service,
                  reviews: _reviews,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Image Carousel - Landscape orientation
            if (images.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _autoSlideTimer?.cancel(); // Stop auto-slide when tapped
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullImageViewer(images: images.map((e) => e.toString()).toList()),
                    ),
                  ).then((_) => _startAutoSlide()); // Resume auto-slide
                },
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: images.length,
                  onPageChanged: (index) => setState(() => _currentImageIndex = index),
                  itemBuilder: (_, i) => _buildDisplayImage(images[i], fit: BoxFit.cover),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kPrimaryColor.withOpacity(0.2), kPrimaryColor.withOpacity(0.05)],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.image, size: 64, color: kPrimaryColor.withOpacity(0.4)),
                    const SizedBox(height: 12),
                    Text(
                      'No images added',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kMutedColor,
                      ),
                    ),
                  ],
                ),
              ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.15),
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
            // Discount Badge
            if (hasDiscount)
              Positioned(
                top: 100,
                left: 16,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (_, value, child) => Transform.scale(scale: value, child: child),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.percent, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          '-${s['discount']}% OFF',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Image indicators
            if (images.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(images.length, (i) {
                    final isActive = i == _currentImageIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: isActive ? [
                          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
                        ] : null,
                      ),
                    );
                  }),
                ),
              ),
            // Photo count badge
            if (images.length > 1)
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.image, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        '${_currentImageIndex + 1}/${images.length}',
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
    );
  }

  Widget _buildCircleButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: kTextColor, size: 20),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildServiceInfoCard(Map<String, dynamic> s, double avgRating, int reviewCount) {
    return Container(
      padding: const EdgeInsets.all(16), // Reduced from 22
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // Reduced from 24
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Reduced
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimaryColor.withOpacity(0.12), kPrimaryColor.withOpacity(0.06)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.tag, size: 12, color: kPrimaryColor), // Reduced
                const SizedBox(width: 6),
                Text(
                  s['category'] ?? 'Service',
                  style: GoogleFonts.poppins(
                    fontSize: 11, // Reduced from 12
                    fontWeight: FontWeight.w700,
                    color: kPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12), // Reduced from 16
          // Service Name
          Text(
            s['name'] ?? 'Service Name',
            style: GoogleFonts.poppins(
              fontSize: 20, // Reduced from 24
              fontWeight: FontWeight.w800,
              color: kTextColor,
              height: 1.2,
            ),
          ),
          if (s['brand'] != null && s['brand'].toString().trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: kBackgroundColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(LucideIcons.building2, size: 12, color: kMutedColor),
                ),
                const SizedBox(width: 8),
                Text(
                  s['brand'],
                  style: GoogleFonts.poppins(
                    fontSize: 12, // Reduced from 14
                    fontWeight: FontWeight.w600,
                    color: kMutedColor,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14), // Reduced from 20
          // Stats Row
          Row(
            children: [
              // Rating
              Expanded(
                child: _buildStatCard(
                  icon: Icons.star_rounded,
                  iconColor: Colors.amber,
                  bgColor: Colors.amber.withOpacity(0.1),
                  label: avgRating > 0 ? avgRating.toStringAsFixed(1) : 'New',
                  sublabel: '$reviewCount reviews',
                ),
              ),
              const SizedBox(width: 10),
              // City
              if (s['city'] != null && s['city'].toString().isNotEmpty)
                Expanded(
                  child: _buildStatCard(
                    icon: LucideIcons.mapPin,
                    iconColor: kPrimaryColor,
                    bgColor: kPrimaryColor.withOpacity(0.1),
                    label: s['city'],
                    sublabel: 'Location',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required String sublabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(10), // Reduced from 14
      decoration: BoxDecoration(
        color: kBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8), // Reduced from 10
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: iconColor), // Reduced from 18
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13, // Reduced from 15
                    fontWeight: FontWeight.w800,
                    color: kTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  sublabel,
                  style: GoogleFonts.poppins(
                    fontSize: 10, // Reduced from 11
                    fontWeight: FontWeight.w500,
                    color: kMutedColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(double oldPrice, double finalPrice, bool hasDiscount, Map<String, dynamic> s) {
    return Container(
      padding: const EdgeInsets.all(16), // Reduced from 22
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryColor.withOpacity(0.1), kPrimaryColor.withOpacity(0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20), // Reduced from 24
        border: Border.all(color: kPrimaryColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10), // Reduced from 12
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(LucideIcons.wallet, color: kPrimaryColor, size: 18), // Reduced
              ),
              const SizedBox(width: 12),
              Text(
                'Pricing',
                style: GoogleFonts.poppins(
                  fontSize: 16, // Reduced from 18
                  fontWeight: FontWeight.w800,
                  color: kTextColor,
                ),
              ),
              if (hasDiscount) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'SALE',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14), // Reduced from 20
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (hasDiscount) ...[
                Text(
                  '₪${oldPrice.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 16, // Reduced from 20
                    fontWeight: FontWeight.w600,
                    color: kMutedColor,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Colors.red.withOpacity(0.7),
                    decorationThickness: 2,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Text(
                '₪${finalPrice.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: 28, // Reduced from 36
                  fontWeight: FontWeight.w900,
                  color: hasDiscount ? const Color(0xFFFF4B2B) : kPrimaryColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
                  ],
                ),
                child: Text(
                  s['payType'] ?? 'per service',
                  style: GoogleFonts.poppins(
                    fontSize: 11, // Reduced from 12
                    fontWeight: FontWeight.w700,
                    color: kMutedColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(Map<String, dynamic> s) {
    final desc = s['fullDescription'] ?? s['shortDescription'] ?? s['description'] ?? '';
    
    return Container(
      padding: const EdgeInsets.all(16), // Reduced
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8)),
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
                child: Icon(LucideIcons.fileText, color: kPrimaryColor, size: 16),
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
          const SizedBox(height: 12),
          Text(
            desc,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: kMutedColor,
              height: 1.6,
            ),
          ),
          if (s['tagline'] != null && s['tagline'].toString().trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimaryColor.withOpacity(0.06), kPrimaryColor.withOpacity(0.02)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kPrimaryColor.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.quote, size: 16, color: kPrimaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s['tagline'],
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: kTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationCard(double lat, double lng, String city, String address) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 25, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kSuccessColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(LucideIcons.mapPin, color: kSuccessColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Service Location',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: kTextColor,
                        ),
                      ),
                      if (city.isNotEmpty || address.isNotEmpty)
                        Text(
                          address.isNotEmpty ? address : city,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: kMutedColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            child: SizedBox(
              height: 200,
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
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(lat, lng),
                        width: 60,
                        height: 60,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.elasticOut,
                          builder: (_, value, child) => Transform.scale(scale: value, child: child),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.8)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: kPrimaryColor.withOpacity(0.4),
                                  blurRadius: 16,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.location_on, color: Colors.white, size: 32),
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

  Widget _buildHighlightsCard(List<String> highlights) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 25, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kWarningColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(LucideIcons.sparkles, color: kWarningColor, size: 20),
              ),
              const SizedBox(width: 14),
              Text(
                'Key Highlights',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: kTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: highlights.asMap().entries.map((entry) {
              final index = entry.key;
              final h = entry.value;
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 400 + (index * 100)),
                curve: Curves.easeOut,
                builder: (_, value, child) => Transform.scale(
                  scale: value,
                  child: Opacity(opacity: value, child: child),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kPrimaryColor.withOpacity(0.1), kPrimaryColor.withOpacity(0.04)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kPrimaryColor.withOpacity(0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: kSuccessColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(LucideIcons.check, size: 12, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        h,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPackagesSection(List<Map<String, dynamic>> packages) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(LucideIcons.package, size: 20, color: Colors.purple),
              ),
              const SizedBox(width: 12),
              Text(
                'Available Packages',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: kTextColor,
                ),
              ),
            ],
          ),
        ),
        ...packages.asMap().entries.map((entry) {
          final index = entry.key;
          final p = entry.value;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 400 + (index * 150)),
            curve: Curves.easeOut,
            builder: (_, value, child) => Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            ),
            child: _buildPackageCard(p, index),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPackageCard(Map<String, dynamic> p, int index) {
    final colors = [
      [const Color(0xFF667eea), const Color(0xFF764ba2)],
      [const Color(0xFF11998e), const Color(0xFF38ef7d)],
      [const Color(0xFFf093fb), const Color(0xFFf5576c)],
    ];
    final gradientColors = colors[index % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          // Colored accent strip
          Container(
            width: 6,
            height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors, begin: Alignment.topCenter, end: Alignment.bottomCenter),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p['name'] ?? 'Package',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: kTextColor,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradientColors),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(color: gradientColors[0].withOpacity(0.3), blurRadius: 8),
                          ],
                        ),
                        child: Text(
                          '₪${p['price'] ?? 0}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (p['desc'] != null && p['desc'].toString().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      p['desc'],
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: kMutedColor,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(Map<String, dynamic> s, List<ServiceReview> reviews, double avgRating) {
    return Container(
      padding: const EdgeInsets.all(16), // Reduced from 22
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10), // Reduced
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.star_rounded, color: Colors.amber, size: 18), // Reduced
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer Reviews',
                      style: GoogleFonts.poppins(
                        fontSize: 16, // Reduced
                        fontWeight: FontWeight.w800,
                        color: kTextColor,
                      ),
                    ),
                    if (_isLoadingReviews)
                      Text(
                        'Loading reviews...',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: kMutedColor,
                        ),
                      )
                    else if (reviews.isNotEmpty)
                      Row(
                        children: [
                          Text(
                            avgRating.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                              fontSize: 13, // Reduced
                              fontWeight: FontWeight.w800,
                              color: Colors.amber[700],
                            ),
                          ),
                          const SizedBox(width: 6),
                          ...List.generate(5, (i) => Icon(
                            i < avgRating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 14,
                            color: Colors.amber,
                          )),
                          const SizedBox(width: 8),
                          Text(
                            '($_totalReviews)',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: kMutedColor,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Material(
                color: kPrimaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ServiceReviewsProviderScreen(
                          service: s,
                          reviews: reviews,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: kPrimaryColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(LucideIcons.arrowRight, size: 16, color: kPrimaryColor),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isLoadingReviews)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  color: kPrimaryColor,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (reviews.isEmpty)
            _buildEmptyReviews()
          else
            ...reviews.take(2).toList().asMap().entries.map((entry) {
              final int index = entry.key;
              final r = entry.value;
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 400 + (index * 150)),
                curve: Curves.easeOut,
                builder: (_, value, child) => Transform.translate(
                  offset: Offset(0, 15 * (1 - value)),
                  child: Opacity(opacity: value, child: child),
                ),
                child: _buildReviewCard(r),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildEmptyReviews() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kBackgroundColor, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.messageSquare, color: Colors.amber[600], size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'No reviews yet',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Once customers leave feedback, you\'ll see it here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: kMutedColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ServiceReview review) {
    final isPositive = review.rating >= 4;
    final gradientColors = isPositive
        ? [kSuccessColor.withOpacity(0.8), kSuccessColor]
        : review.rating >= 3
            ? [kWarningColor.withOpacity(0.8), kWarningColor]
            : [Colors.red.withOpacity(0.8), Colors.red];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kBackgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: gradientColors[1].withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: Center(
                  child: Text(
                    review.customerName.isNotEmpty ? review.customerName[0].toUpperCase() : 'U',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.customerName,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        color: kTextColor,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      _formatDate(review.createdAt),
                      style: GoogleFonts.poppins(fontSize: 12, color: kMutedColor),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '${review.rating}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        color: kTextColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                review.comment,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: kMutedColor,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar(Map<String, dynamic> s) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -6)),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pop(context, {"edit": true, "service": s}),
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(LucideIcons.pencil, size: 18),
        ),
        label: Text(
          'Edit This Service',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 📋 SERVICE INFORMATION SECTION
  // ══════════════════════════════════════════════════════════════════════════
  
  Widget _buildServiceInformationCard(Map<String, dynamic> s) {
    final venueType = s['venueType']?.toString();
    final maxCapacity = s['maxCapacity'];
    final minHours = s['minBookingHours'];
    final maxHours = s['maxBookingHours'];
    final workingDays = s['workingDays'] as List?;
    final availableHours = s['availableHours'] as List?;
    final payType = s['payType']?.toString();
    final bookingType = s['bookingType']?.toString() ?? 'hourly';
    final additionalInfo = s['additionalInfo'] as Map<String, dynamic>?;
    
    // Filter out description from additionalInfo
    final customInfo = <String, dynamic>{};
    if (additionalInfo != null) {
      additionalInfo.forEach((key, value) {
        if (key != 'description' && value != null && value.toString().isNotEmpty) {
          customInfo[key] = value;
        }
      });
    }

    // Format working hours
    String? workingHoursStr;
    if (availableHours != null && availableHours.isNotEmpty) {
      final hours = availableHours.map((e) => e as int).toList()..sort();
      if (hours.isNotEmpty) {
        workingHoursStr = '${hours.first.toString().padLeft(2, '0')}:00 - ${hours.last.toString().padLeft(2, '0')}:00';
      }
    }

    // Format working days
    String? workingDaysStr;
    if (workingDays != null && workingDays.isNotEmpty && workingDays.length < 7) {
      final dayNames = workingDays.map((d) {
        final day = d.toString().toLowerCase();
        return day.substring(0, 1).toUpperCase() + day.substring(1, day.length > 3 ? 3 : day.length);
      }).toList();
      workingDaysStr = dayNames.join(', ');
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimaryColor.withOpacity(0.15), kPrimaryColor.withOpacity(0.05)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.info, color: kPrimaryColor, size: 18),
              ),
              const SizedBox(width: 12),
              Text('Service Information', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: kTextColor)),
            ],
          ),
          const SizedBox(height: 16),
          
          // Booking Type
          if (bookingType.isNotEmpty)
            _buildInfoRow(
              icon: _getBookingTypeIcon(bookingType),
              label: 'Booking Type',
              value: _formatBookingType(bookingType),
              color: const Color(0xFF6366F1),
            ),
          
          // Pay Type
          if (payType != null && payType.isNotEmpty && payType != 'display')
            _buildInfoRow(
              icon: LucideIcons.wallet,
              label: 'Payment',
              value: _formatPayType(payType),
              color: const Color(0xFF059669),
            ),
          
          // Venue Type
          if (venueType != null && venueType.isNotEmpty)
            _buildInfoRow(
              icon: venueType == 'indoor' ? LucideIcons.building : LucideIcons.trees,
              label: 'Venue Type',
              value: venueType == 'indoor' ? 'Indoor' : 'Outdoor',
              color: venueType == 'indoor' ? const Color(0xFF3B82F6) : const Color(0xFF10B981),
            ),
          
          // Max Capacity
          if (maxCapacity != null && maxCapacity > 0)
            _buildInfoRow(
              icon: LucideIcons.users,
              label: 'Maximum Capacity',
              value: '$maxCapacity guests',
              color: const Color(0xFFF59E0B),
            ),
          
          // Min Booking Hours
          if (minHours != null && minHours > 0)
            _buildInfoRow(
              icon: LucideIcons.clock,
              label: 'Minimum Booking',
              value: '$minHours ${minHours == 1 ? 'hour' : 'hours'}',
              color: const Color(0xFF8B5CF6),
            ),
          
          // Max Booking Hours
          if (maxHours != null && maxHours > 0)
            _buildInfoRow(
              icon: LucideIcons.timer,
              label: 'Maximum Booking',
              value: '$maxHours hours',
              color: const Color(0xFFEC4899),
            ),
          
          // Working Hours
          if (workingHoursStr != null)
            _buildInfoRow(
              icon: LucideIcons.clock4,
              label: 'Working Hours',
              value: workingHoursStr,
              color: const Color(0xFF0891B2),
            ),
          
          // Working Days
          if (workingDaysStr != null)
            _buildInfoRow(
              icon: LucideIcons.calendar,
              label: 'Available Days',
              value: workingDaysStr,
              color: const Color(0xFFDC2626),
            ),
          
          // Additional Info
          if (customInfo.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kBackgroundColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Additional Details',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: kMutedColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...customInfo.entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 6, right: 10),
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${entry.key}: ',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: kTextColor,
                                  ),
                                ),
                                TextSpan(
                                  text: entry.value.toString(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: kMutedColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: kMutedColor,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getBookingTypeIcon(String bookingType) {
    switch (bookingType.toLowerCase()) {
      case 'hourly': return LucideIcons.clock;
      case 'daily': return LucideIcons.sun;
      case 'capacity': return LucideIcons.users;
      case 'mixed': return LucideIcons.layers;
      case 'display': return LucideIcons.eye;
      default: return LucideIcons.calendar;
    }
  }

  String _formatBookingType(String bookingType) {
    switch (bookingType.toLowerCase()) {
      case 'hourly': return 'Per Hour';
      case 'daily': return 'Per Day';
      case 'capacity': return 'Per Person';
      case 'mixed': return 'Flexible';
      case 'display': return 'Display Only';
      default: return bookingType;
    }
  }

  String _formatPayType(String payType) {
    switch (payType.toLowerCase()) {
      case 'per hour': return 'Per Hour';
      case 'per day': return 'Per Day';
      case 'per person': return 'Per Person';
      case 'display': return 'Display Only';
      default: return payType;
    }
  }

  bool _hasDescription(Map<String, dynamic> s) {
    final desc = s['fullDescription'] ?? s['shortDescription'] ?? s['description'] ?? '';
    return desc.toString().trim().isNotEmpty;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} months ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
