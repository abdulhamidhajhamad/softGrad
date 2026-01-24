// lib/screens/Ai_Screen/components/ai_service_details_screen.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../services/auth_service.dart';
import '../../../widgets/booking_details_modal.dart';
import '../../../services/payment_service/cart_service.dart';
import '../../../services/user_service/review_service.dart';
import '../../user/chat/chat_inside_search.dart';
import '../../user/payment/cart.dart';
import '../../user/home/home_customer.dart'; // For ServiceReviewsCustomerPage

const Color kPrimary = Color.fromARGB(215, 20, 20, 215);
const Color kBg = Color(0xFFF6F7FB);
const Color kText = Color(0xFF0B1220);
const Color kMuted = Color(0xFF6B7280);
const Color kDanger = Color(0xFFEF4444);

/// Service details screen opened from AI search results
/// Now with full features like Home: Service Info, Company Info, Add to Cart
class AiServiceDetailsScreen extends StatefulWidget {
  final String serviceId;
  final String? serviceName;
  final String? imageUrl;
  final String? providerName;
  final String? category;
  final String? city;
  final double? price;
  final String? payType;

  const AiServiceDetailsScreen({
    super.key,
    required this.serviceId,
    this.serviceName,
    this.imageUrl,
    this.providerName,
    this.category,
    this.city,
    this.price,
    this.payType,
  });

  @override
  State<AiServiceDetailsScreen> createState() => _AiServiceDetailsScreenState();
}

class _AiServiceDetailsScreenState extends State<AiServiceDetailsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _serviceData;
  String? _bookingType;
  
  // Media Slider State
  List<String> _mediaUrls = [];
  int _currentMediaIndex = 0;
  late PageController _mediaPageController;
  Timer? _autoSlideTimer;

  // ✅ Reviews State
  List<dynamic> _reviews = [];
  double _averageRating = 0.0;
  int _totalReviews = 0;

  @override
  void initState() {
    super.initState();
    _mediaPageController = PageController();
    _loadServiceDetails();
    _loadReviews(); // ✅ Load reviews
  }
  
  @override
  void dispose() {
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
    _autoSlideTimer?.cancel();
    _startAutoSlide();
  }
  
  bool _isVideoUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') || 
           lower.endsWith('.mov') || 
           lower.endsWith('.avi') || 
           lower.endsWith('.webm') ||
           lower.contains('video');
  }
  
  void _openFullScreenGallery(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AiFullScreenGallery(
          mediaUrls: _mediaUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Future<void> _loadServiceDetails() async {
    try {
      final serviceDetails = await _fetchServiceDetails(widget.serviceId);
      setState(() {
        _serviceData = serviceDetails;
        _bookingType = serviceDetails['bookingType']?.toString() ?? 'daily';
        
        // Extract media URLs
        _mediaUrls = [];
        if (serviceDetails['images'] != null && serviceDetails['images'] is List) {
          for (var img in serviceDetails['images']) {
            if (img != null && img.toString().isNotEmpty) {
              _mediaUrls.add(img.toString());
            }
          }
        }
        if (_mediaUrls.isEmpty && widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
          _mediaUrls.add(widget.imageUrl!);
        }
        
        _isLoading = false;
      });
      
      _startAutoSlide();
    } catch (e) {
      print('Error loading service details: $e');
      setState(() {
        _isLoading = false;
        _bookingType = 'daily';
        _serviceData = {
          'serviceName': widget.serviceName ?? 'Service',
          'imageUrl': widget.imageUrl ?? '',
          'companyName': widget.providerName ?? 'Unknown',
          'category': widget.category ?? 'Other',
          'city': widget.city ?? '',
          'price': widget.price ?? 0,
          'bookingType': widget.payType ?? 'daily',
        };
        
        if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
          _mediaUrls = [widget.imageUrl!];
        }
      });
    }
  }

  Future<Map<String, dynamic>> _fetchServiceDetails(String serviceId) async {
    final baseUrl = AuthService.baseUrl;
    final response = await http.get(
      Uri.parse('$baseUrl/services/$serviceId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load service details');
    }
  }

  // ✅ Load Reviews for this service
  Future<void> _loadReviews() async {
    try {
      final result = await ReviewService.getServiceReviews(
        serviceId: widget.serviceId,
        limit: 10,
      );
      
      if (mounted) {
        setState(() {
          _reviews = result['reviews'] ?? [];
          _averageRating = (result['averageRating'] ?? 0).toDouble();
          _totalReviews = result['totalReviews'] ?? 0;
        });
      }
    } catch (e) {
      print('❌ Error loading reviews: $e');
    }
  }

  double _toDouble(dynamic value, [double fallback = 0]) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  String _money(double v) => '₪${v.toStringAsFixed(0)}';

  // ═══════════════════════════════════════════════════════════════════
  // CHAT WITH OWNER
  // ═══════════════════════════════════════════════════════════════════
  void _openChat(BuildContext context) {
    final companyName = _serviceData?['companyName']?.toString() ?? widget.providerName ?? 'Provider';
    final email = _serviceData?['companyInfo']?['email']?.toString() ?? 'N/A';
    final phone = _serviceData?['companyInfo']?['phone']?.toString() ?? 'N/A';
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatInsideSearchScreen(
          providerName: companyName,
          providerEmail: email,
          providerPhone: phone,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // ADD TO CART
  // ═══════════════════════════════════════════════════════════════════
  void _handleAddToCart() async {
    if (_serviceData == null) return;
    
    final bookingType = _bookingType?.toLowerCase() ?? 'daily';
    
    // Skip display-only services
    if (bookingType == 'display') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This is a display-only service and cannot be booked',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Show booking modal
    await showBookingModal(
      context: context,
      serviceId: widget.serviceId,
      serviceName: _getServiceName(),
      bookingTypeString: bookingType,
      serviceData: _serviceData!,
      onSuccess: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Added to cart!',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: 'View Cart',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage()));
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Media Slider
                _buildMediaSlider(),
                
                const SizedBox(height: 16),
                
                // Service Info Card
                _buildServiceInfoCard(),
                
                const SizedBox(height: 12),
                
                // Description
                if (_hasDescription())
                  _buildDescriptionCard(),
                
                // Service Information Section (NEW!)
                _buildServiceInformationSection(),
                
                // Company Info
                if (_hasAnyCompanyInfo())
                  _buildCompanyInfoCard(),
                
                // Map Section (if has location)
                if (_hasLocation())
                  _buildMapSection(),

                // ✅ Customer Reviews Section
                _buildCustomerReviewsSection(),

                const SizedBox(height: 100), // Space for bottom bar
              ],
            ),

      // BOTTOM: Two Buttons - Chat + Add to Cart
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
              // Chat Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openChat(context),
                  icon: Icon(Icons.chat_bubble_rounded, color: kPrimary),
                  label: Text(
                    'Chat with Owner',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: kText),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.black.withOpacity(0.14)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Add to Cart Button
              Expanded(
                child: ValueListenableBuilder<List<CartItem>>(
                  valueListenable: CartStore.instance.itemsListenable,
                  builder: (_, items, ___) {
                    final inCart = items.any((item) => item.id == widget.serviceId);
                    final isDisplayOnly = _bookingType?.toLowerCase() == 'display';

                    return ElevatedButton.icon(
                      onPressed: (inCart || isDisplayOnly) ? null : _handleAddToCart,
                      icon: Icon(
                        inCart ? Icons.check_circle_rounded : 
                        isDisplayOnly ? Icons.visibility_rounded : 
                        Icons.add_shopping_cart_rounded,
                        size: 20,
                      ),
                      label: Text(
                        inCart ? 'In Cart' : 
                        isDisplayOnly ? 'Display Only' : 
                        'Add to Cart',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: inCart ? Colors.green : kPrimary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: inCart ? Colors.green.withOpacity(0.7) : Colors.grey.shade400,
                        disabledForegroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // MEDIA SLIDER
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildMediaSlider() {
    if (_mediaUrls.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 220,
          color: kPrimary.withOpacity(0.1),
          child: Icon(
            _getServiceIcon(_getCategory()),
            size: 64,
            color: kPrimary.withOpacity(0.4),
          ),
        ),
      );
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          SizedBox(
            height: 220,
            child: PageView.builder(
              controller: _mediaPageController,
              itemCount: _mediaUrls.length,
              onPageChanged: (index) {
                setState(() => _currentMediaIndex = index);
                _resetAutoSlide();
              },
              itemBuilder: (context, index) {
                final url = _mediaUrls[index];
                final isVideo = _isVideoUrl(url);
                
                return GestureDetector(
                  onTap: () => _openFullScreenGallery(index),
                  child: isVideo
                      ? _AiVideoThumbnail(url: url)
                      : CachedNetworkImage(
                          imageUrl: url,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            height: 220,
                            color: const Color(0xFFF1F5F9),
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            height: 220,
                            color: kPrimary.withOpacity(0.1),
                            child: Icon(
                              _getServiceIcon(_getCategory()),
                              size: 64,
                              color: kPrimary.withOpacity(0.4),
                            ),
                          ),
                        ),
                );
              },
            ),
          ),
          
          // Rating Badge
          if (_getRating() > 0)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      _getRating().toStringAsFixed(1),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 13, color: kText),
                    ),
                  ],
                ),
              ),
            ),
          
          // Media counter
          if (_mediaUrls.length > 1)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_library_rounded, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '${_currentMediaIndex + 1}/${_mediaUrls.length}',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          
          // Dots
          if (_mediaUrls.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_mediaUrls.length, (index) {
                  final isActive = index == _currentMediaIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive ? kPrimary : Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SERVICE INFO CARD
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildServiceInfoCard() {
    return Container(
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _getCategory(),
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w900, color: kPrimary),
                ),
              ),
              const Spacer(),
              if (_getRating() > 0)
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      _getRating().toStringAsFixed(1),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: kText),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getServiceName(),
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w900, color: kText),
          ),
          const SizedBox(height: 6),
          Text(
            _getCompanyName(),
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: kMuted),
          ),
          const SizedBox(height: 16),
          _buildPriceSection(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // PRICE SECTION
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildPriceSection() {
    final allPrices = _serviceData?['allPrices'] as Map<String, dynamic>?;
    final bookingType = _bookingType?.toLowerCase() ?? widget.payType?.toLowerCase() ?? 'daily';
    
    String priceLabel;
    double displayPrice = widget.price ?? 0;
    IconData priceIcon;
    
    switch (bookingType) {
      case 'hourly':
      case 'perhour':
      case 'per hour':
        priceLabel = 'per hour';
        priceIcon = Icons.schedule_rounded;
        displayPrice = _toDouble(allPrices?['perHour']) > 0 
            ? _toDouble(allPrices?['perHour'])
            : _toDouble(_serviceData?['price'], widget.price ?? 0);
        break;
      case 'capacity':
      case 'perperson':
      case 'per person':
        priceLabel = 'per person';
        priceIcon = Icons.person_rounded;
        displayPrice = _toDouble(allPrices?['perPerson']) > 0 
            ? _toDouble(allPrices?['perPerson'])
            : _toDouble(_serviceData?['price'], widget.price ?? 0);
        break;
      case 'daily':
      case 'perday':
      case 'per day':
        priceLabel = 'per day';
        priceIcon = Icons.calendar_today_rounded;
        displayPrice = _toDouble(allPrices?['perDay']) > 0 
            ? _toDouble(allPrices?['perDay'])
            : _toDouble(_serviceData?['price'], widget.price ?? 0);
        break;
      case 'mixed':
      case 'perevent':
      case 'per event':
        priceLabel = 'per event';
        priceIcon = Icons.event_rounded;
        displayPrice = _toDouble(allPrices?['perEvent']) > 0 
            ? _toDouble(allPrices?['perEvent'])
            : _toDouble(_serviceData?['price'], widget.price ?? 0);
        break;
      case 'display':
        priceLabel = 'display only';
        priceIcon = Icons.visibility_rounded;
        displayPrice = _toDouble(allPrices?['displayPrice']) > 0 
            ? _toDouble(allPrices?['displayPrice'])
            : _toDouble(_serviceData?['price'], widget.price ?? 0);
        break;
      default:
        priceLabel = 'per service';
        priceIcon = Icons.payments_rounded;
        displayPrice = _toDouble(_serviceData?['price'], widget.price ?? 0);
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimary.withOpacity(0.08), kPrimary.withOpacity(0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(priceIcon, color: kPrimary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _money(displayPrice),
                  style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w900, color: kPrimary),
                ),
                Text(
                  priceLabel,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: kMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // DESCRIPTION CARD
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildDescriptionCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
            Text('Description', style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: kText)),
            const SizedBox(height: 8),
            Text(
              _getDescription(),
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: kMuted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SERVICE INFORMATION SECTION (NEW - Like Home!)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildServiceInformationSection() {
    final venueType = _serviceData?['venueType']?.toString();
    final maxCapacity = _serviceData?['maxCapacity'];
    final minHours = _serviceData?['minBookingHours'];
    final maxHours = _serviceData?['maxBookingHours'];
    final workingDays = _serviceData?['workingDays'] as List?;
    final availableHours = _serviceData?['availableHours'] as List?;
    final bookingType = _bookingType ?? 'hourly';
    final additionalInfo = _serviceData?['additionalInfo'] as Map<String, dynamic>?;
    
    final hasVenueInfo = venueType != null && venueType.isNotEmpty;
    final hasCapacity = maxCapacity != null && maxCapacity > 0;
    final hasBookingHours = (minHours != null && minHours > 0) || (maxHours != null && maxHours > 0);
    final hasWorkingHours = availableHours != null && availableHours.isNotEmpty;
    final hasWorkingDays = workingDays != null && workingDays.isNotEmpty;
    
    final customInfo = <String, dynamic>{};
    if (additionalInfo != null) {
      additionalInfo.forEach((key, value) {
        if (key != 'description' && value != null && value.toString().isNotEmpty) {
          customInfo[key] = value;
        }
      });
    }
    
    final hasCustomInfo = customInfo.isNotEmpty;
    
    if (!hasVenueInfo && !hasCapacity && !hasBookingHours && !hasWorkingHours && !hasWorkingDays && !hasCustomInfo) {
      return const SizedBox.shrink();
    }

    String? workingHoursStr;
    if (availableHours != null && availableHours.isNotEmpty) {
      final hours = availableHours.map((e) => e as int).toList()..sort();
      if (hours.isNotEmpty) {
        workingHoursStr = '${_formatHour(hours.first)} - ${_formatHour(hours.last + 1)}';
      }
    }

    String? workingDaysStr;
    if (workingDays != null && workingDays.isNotEmpty) {
      if (workingDays.length == 7) {
        workingDaysStr = 'Every Day';
      } else {
        final dayOrder = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
        final sortedDays = workingDays.map((d) => d.toString().toLowerCase()).toList()
          ..sort((a, b) => dayOrder.indexOf(a).compareTo(dayOrder.indexOf(b)));
        
        if (sortedDays.length > 2) {
          workingDaysStr = '${_capitalizeDay(sortedDays.first)} - ${_capitalizeDay(sortedDays.last)}';
        } else {
          workingDaysStr = sortedDays.map((d) => _capitalizeDay(d)).join(', ');
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kPrimary.withOpacity(0.15), kPrimary.withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.info_outline_rounded, color: kPrimary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Service Information',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w900, color: kText),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Info Chips
            if (hasVenueInfo || hasCapacity || hasBookingHours)
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (hasVenueInfo)
                    _buildInfoChip(
                      icon: venueType == 'indoor' ? Icons.home_rounded : Icons.park_rounded,
                      label: venueType == 'indoor' ? 'Indoor Venue' : 'Outdoor Venue',
                      color: venueType == 'indoor' ? const Color(0xFF3B82F6) : const Color(0xFF10B981),
                    ),
                  if (hasCapacity)
                    _buildInfoChip(
                      icon: Icons.groups_rounded,
                      label: '$maxCapacity Guests Max',
                      color: const Color(0xFFF59E0B),
                    ),
                  _buildInfoChip(
                    icon: _getBookingIcon(bookingType),
                    label: _getBookingLabel(bookingType),
                    color: const Color(0xFF6366F1),
                  ),
                  if (minHours != null && minHours > 0)
                    _buildInfoChip(
                      icon: Icons.timer_outlined,
                      label: 'Min $minHours ${minHours == 1 ? 'Hour' : 'Hours'}',
                      color: const Color(0xFF8B5CF6),
                    ),
                  if (maxHours != null && maxHours > 0)
                    _buildInfoChip(
                      icon: Icons.timelapse_rounded,
                      label: 'Max $maxHours Hours',
                      color: const Color(0xFFEC4899),
                    ),
                ],
              ),
            
            // Additional Info
            if (hasCustomInfo) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.playlist_add_check_rounded, size: 18, color: kMuted),
                        const SizedBox(width: 8),
                        Text(
                          'Additional Details',
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF475569)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...customInfo.entries.map((entry) => _buildAdditionalInfoRow(entry.key, entry.value.toString())),
                  ],
                ),
              ),
            ],
            
            // Working Hours & Days
            if (hasWorkingHours || hasWorkingDays) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF0891B2).withOpacity(0.08), const Color(0xFF06B6D4).withOpacity(0.04)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF0891B2).withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    if (workingHoursStr != null)
                      _buildScheduleRow(
                        icon: Icons.access_time_rounded,
                        title: 'Working Hours',
                        value: workingHoursStr,
                      ),
                    if (workingHoursStr != null && workingDaysStr != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: const Color(0xFF0891B2).withOpacity(0.15)),
                      ),
                    if (workingDaysStr != null)
                      _buildScheduleRow(
                        icon: Icons.calendar_month_rounded,
                        title: 'Available Days',
                        value: workingDaysStr,
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: color.withOpacity(0.9))),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6, height: 6,
            margin: const EdgeInsets.only(top: 7, right: 12),
            decoration: BoxDecoration(color: kPrimary.withOpacity(0.6), shape: BoxShape.circle),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: '$key: ', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF334155))),
                  TextSpan(text: value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: kMuted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleRow({required IconData icon, required String title, required String value}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFF0891B2).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: const Color(0xFF0891B2)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: kMuted)),
              const SizedBox(height: 2),
              Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: kText)),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // COMPANY INFO CARD
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildCompanyInfoCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
            Text('Company Info', style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: kText)),
            const SizedBox(height: 12),
            ..._buildCompanyInfoLines(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // MAP SECTION
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildMapSection() {
    final lat = _toDouble(_serviceData?['latitude'] ?? _serviceData?['location']?['coordinates']?['latitude']);
    final lng = _toDouble(_serviceData?['longitude'] ?? _serviceData?['location']?['coordinates']?['longitude']);
    
    if (lat == 0 || lng == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Location', style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: kText)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 200,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(lat, lng),
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
                        point: LatLng(lat, lng),
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_pin, size: 40, color: Colors.red),
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

  // ═══════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════
  String _getServiceName() => _serviceData?['serviceName']?.toString() ?? widget.serviceName ?? 'Service';
  String _getCompanyName() => _serviceData?['companyName']?.toString() ?? widget.providerName ?? 'Unknown';
  String _getCategory() => _serviceData?['category']?.toString() ?? widget.category ?? 'Other';
  
  double _getRating() {
    return _toDouble(_serviceData?['rating']) > 0 
        ? _toDouble(_serviceData?['rating']) 
        : _toDouble(_serviceData?['averageRating']);
  }

  bool _hasDescription() {
    final desc = _serviceData?['description']?.toString().trim() ?? '';
    return desc.isNotEmpty && desc != 'No description yet.';
  }

  String _getDescription() {
    return _serviceData?['description']?.toString().trim() ?? 'No description yet.';
  }

  bool _hasAnyCompanyInfo() {
    final companyName = _getCompanyName();
    final email = _serviceData?['companyInfo']?['email']?.toString().trim() ?? '';
    final phone = _serviceData?['companyInfo']?['phone']?.toString().trim() ?? '';
    final city = _serviceData?['city']?.toString().trim() ?? widget.city ?? '';
    
    return (companyName.isNotEmpty && companyName != 'Unknown') ||
           city.isNotEmpty || email.isNotEmpty || phone.isNotEmpty;
  }

  bool _hasLocation() {
    final lat = _toDouble(_serviceData?['latitude'] ?? _serviceData?['location']?['coordinates']?['latitude']);
    final lng = _toDouble(_serviceData?['longitude'] ?? _serviceData?['location']?['coordinates']?['longitude']);
    return lat != 0 && lng != 0;
  }

  List<Widget> _buildCompanyInfoLines() {
    final lines = <Widget>[];
    
    final companyName = _getCompanyName();
    if (companyName.isNotEmpty && companyName != 'Unknown') {
      lines.add(_InfoRow(icon: Icons.business_rounded, text: companyName));
    }
    
    final city = _serviceData?['city']?.toString().trim() ?? widget.city ?? '';
    if (city.isNotEmpty) {
      if (lines.isNotEmpty) lines.add(const SizedBox(height: 8));
      lines.add(_InfoRow(icon: Icons.location_on_rounded, text: city));
    }
    
    final email = _serviceData?['companyInfo']?['email']?.toString().trim() ?? '';
    if (email.isNotEmpty) {
      if (lines.isNotEmpty) lines.add(const SizedBox(height: 8));
      lines.add(_InfoRow(icon: Icons.email_rounded, text: email));
    }
    
    final phone = _serviceData?['companyInfo']?['phone']?.toString().trim() ?? '';
    if (phone.isNotEmpty) {
      if (lines.isNotEmpty) lines.add(const SizedBox(height: 8));
      lines.add(_InfoRow(icon: Icons.phone_rounded, text: phone));
    }
    
    return lines;
  }

  String _formatHour(int hour) {
    if (hour == 0 || hour == 24) return '12:00 AM';
    if (hour == 12) return '12:00 PM';
    if (hour < 12) return '$hour:00 AM';
    return '${hour - 12}:00 PM';
  }

  String _capitalizeDay(String day) {
    if (day.isEmpty) return day;
    return day[0].toUpperCase() + day.substring(1);
  }

  IconData _getBookingIcon(String type) {
    switch (type.toLowerCase()) {
      case 'hourly': return Icons.schedule_rounded;
      case 'daily': return Icons.calendar_today_rounded;
      case 'capacity': return Icons.groups_rounded;
      case 'mixed': return Icons.event_rounded;
      case 'display': return Icons.visibility_rounded;
      default: return Icons.payments_rounded;
    }
  }

  String _getBookingLabel(String type) {
    switch (type.toLowerCase()) {
      case 'hourly': return 'Hourly Booking';
      case 'daily': return 'Daily Booking';
      case 'capacity': return 'Per Person';
      case 'mixed': return 'Per Event';
      case 'display': return 'Display Only';
      default: return 'Booking Available';
    }
  }

  IconData _getServiceIcon(String category) {
    final icons = {
      'venues': Icons.apartment_rounded,
      'venue': Icons.apartment_rounded,
      'catering': Icons.restaurant_rounded,
      'photography': Icons.camera_alt_rounded,
      'photographers': Icons.camera_alt_rounded,
      'music': Icons.music_note_rounded,
      'dj': Icons.headphones_rounded,
      'decoration': Icons.celebration_rounded,
      'decor': Icons.celebration_rounded,
      'flowers': Icons.local_florist_rounded,
      'makeup': Icons.face_rounded,
      'hair': Icons.content_cut_rounded,
      'transportation': Icons.directions_car_rounded,
      'car': Icons.directions_car_rounded,
      'cake': Icons.cake_rounded,
      'invitation': Icons.mail_rounded,
      'jewelry': Icons.diamond_rounded,
      'dress': Icons.checkroom_rounded,
    };
    return icons[category.toLowerCase()] ?? Icons.category_rounded;
  }

  // ═══════════════════════════════════════════════════════════════════
  // ⭐ CUSTOMER REVIEWS SECTION
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildCustomerReviewsSection() {
    return Padding(
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
            // Header Row
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
                        'Customer Reviews',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: kText,
                        ),
                      ),
                      if (_totalReviews > 0)
                        Text(
                          '${_averageRating.toStringAsFixed(1)} ⭐ • $_totalReviews ${_totalReviews == 1 ? 'review' : 'reviews'}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                // View All Button
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ServiceReviewsCustomerPage(
                          serviceId: widget.serviceId,
                          serviceName: _getServiceName(),
                        ),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: kPrimary.withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: kPrimary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 16, color: kPrimary),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Reviews List or Empty State
            if (_reviews.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black.withOpacity(0.04)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.rate_review_outlined, color: Color(0xFF64748B), size: 24),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'No reviews yet. Be the first to share your experience!',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._reviews.take(2).map((review) => _buildReviewCard(review)),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(dynamic review) {
    final userName = review.userName ?? 'Anonymous';
    final rating = (review.rating ?? 0).toDouble();
    final comment = review.comment ?? '';
    final date = review.reviewDate ?? DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // User Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimary.withOpacity(0.8), kPrimary],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontSize: 18,
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
                        color: kText,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _formatReviewDate(date),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: kMuted,
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
                        color: kText,
                        fontSize: 13,
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
                color: kMuted,
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

  String _formatReviewDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} months ago';
    return '${(diff.inDays / 365).floor()} years ago';
  }
}

// ═══════════════════════════════════════════════════════════════════
// INFO ROW WIDGET
// ═══════════════════════════════════════════════════════════════════
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: kPrimary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: kText)),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// VIDEO THUMBNAIL WIDGET
// ═══════════════════════════════════════════════════════════════════
class _AiVideoThumbnail extends StatefulWidget {
  final String url;
  const _AiVideoThumbnail({required this.url});

  @override
  State<_AiVideoThumbnail> createState() => _AiVideoThumbnailState();
}

class _AiVideoThumbnailState extends State<_AiVideoThumbnail> {
  VideoPlayerController? _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await _controller!.initialize();
      if (mounted) setState(() => _initialized = true);
    } catch (e) {
      debugPrint('Video init error: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_initialized && _controller != null)
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller!.value.size.width,
              height: _controller!.value.size.height,
              child: VideoPlayer(_controller!),
            ),
          )
        else
          Container(
            color: Colors.black87,
            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
          ),
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// FULL SCREEN GALLERY
// ═══════════════════════════════════════════════════════════════════
class _AiFullScreenGallery extends StatefulWidget {
  final List<String> mediaUrls;
  final int initialIndex;

  const _AiFullScreenGallery({required this.mediaUrls, required this.initialIndex});

  @override
  State<_AiFullScreenGallery> createState() => _AiFullScreenGalleryState();
}

class _AiFullScreenGalleryState extends State<_AiFullScreenGallery> {
  late PageController _pageController;
  late int _currentIndex;
  VideoPlayerController? _videoController;
  bool _isVideoPlaying = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _initVideoIfNeeded();
  }

  bool _isVideoUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.webm') || lower.contains('video');
  }

  Future<void> _initVideoIfNeeded() async {
    final url = widget.mediaUrls[_currentIndex];
    if (_isVideoUrl(url)) {
      _videoController?.dispose();
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoController!.initialize();
      if (mounted) setState(() {});
    }
  }

  void _toggleVideoPlay() {
    if (_videoController == null) return;
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _isVideoPlaying = false;
      } else {
        _videoController!.play();
        _isVideoPlaying = true;
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('${_currentIndex + 1} / ${widget.mediaUrls.length}', style: GoogleFonts.poppins(color: Colors.white)),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.mediaUrls.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
            _isVideoPlaying = false;
          });
          _videoController?.pause();
          _initVideoIfNeeded();
        },
        itemBuilder: (context, index) {
          final url = widget.mediaUrls[index];
          final isVideo = _isVideoUrl(url);

          if (isVideo && index == _currentIndex) {
            return GestureDetector(
              onTap: _toggleVideoPlay,
              child: Center(
                child: _videoController?.value.isInitialized == true
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          ),
                          if (!_isVideoPlaying)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 50),
                            ),
                        ],
                      )
                    : const CircularProgressIndicator(color: Colors.white),
              ),
            );
          }

          return InteractiveViewer(
            child: Center(
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                errorWidget: (_, __, ___) => const Icon(Icons.broken_image_rounded, color: Colors.white54, size: 64),
              ),
            ),
          );
        },
      ),
    );
  }
}
