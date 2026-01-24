import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

import '../payment/cart.dart';
import '../chat/chat_customer_home_page.dart'; // ✅ Real chat
import '../../../widgets/booking_details_modal.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service/chat_user_service.dart'; // ✅ Chat service
import '../../../services/user_service/review_service.dart'; // ✅ Reviews
import '../../../services/service_locator.dart'; // ✅ For getIt
import '../home/home_customer.dart'; // ✅ For ServiceReviewsCustomerPage

const Color kPrimary = Color.fromARGB(215, 20, 20, 215);
const Color kBg = Color(0xFFF6F7FB);
const Color kText = Color(0xFF0B1220);
const Color kMuted = Color(0xFF6B7280);
const Color kDanger = Color(0xFFEF4444);

class ServiceDetailsData {
  final String id;
  final String serviceName;
  final String imageUrl;
  final String category;
  final String city;
  final double price;
  final double? oldPrice;
  final String description;

  final String companyName;
  final String contactEmail;
  final String contactPhone;

  const ServiceDetailsData({
    required this.id,
    required this.serviceName,
    required this.imageUrl,
    required this.category,
    required this.city,
    required this.price,
    required this.description,
    required this.companyName,
    required this.contactEmail,
    required this.contactPhone,
    this.oldPrice,
  });

  bool get hasDiscount =>
      oldPrice != null && oldPrice! > price && oldPrice! > 0;

  int get discountPercent {
    if (!hasDiscount) return 0;
    final p = ((oldPrice! - price) / oldPrice!) * 100;
    return p.round().clamp(1, 95);
  }
}

class ServiceInsideSearchScreen extends StatefulWidget {
  final ServiceDetailsData data;
  final String heroTag;

  const ServiceInsideSearchScreen({
    super.key,
    required this.data,
    required this.heroTag,
  });

  @override
  State<ServiceInsideSearchScreen> createState() => _ServiceInsideSearchScreenState();
}

class _ServiceInsideSearchScreenState extends State<ServiceInsideSearchScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _serviceData;
  String? _bookingType;
  
  // ✅ Media Slider State
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
  
  // ✅ Start auto-slide timer
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
  
  // ✅ Reset auto-slide timer on user interaction
  void _resetAutoSlide() {
    _autoSlideTimer?.cancel();
    _startAutoSlide();
  }
  
  // ✅ Check if URL is a video
  bool _isVideoUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') || 
           lower.endsWith('.mov') || 
           lower.endsWith('.avi') || 
           lower.endsWith('.webm') ||
           lower.contains('video');
  }
  
  // ✅ Open fullscreen gallery
  void _openFullScreenGallery(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenGallery(
          mediaUrls: _mediaUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
  
  // ✅ Get service icon by category
  IconData _getServiceIcon(String category) {
    final Map<String, IconData> categoryIcons = {
      'venues': Icons.apartment_rounded,
      'venue': Icons.apartment_rounded,
      'catering': Icons.restaurant_rounded,
      'photography': Icons.camera_alt_rounded,
      'music': Icons.music_note_rounded,
      'dj': Icons.headphones_rounded,
      'decoration': Icons.celebration_rounded,
      'flowers': Icons.local_florist_rounded,
      'makeup': Icons.face_rounded,
      'hair': Icons.content_cut_rounded,
      'transportation': Icons.directions_car_rounded,
      'cake': Icons.cake_rounded,
      'invitation': Icons.mail_rounded,
      'jewelry': Icons.diamond_rounded,
      'dress': Icons.checkroom_rounded,
      'other': Icons.category_rounded,
    };
    
    return categoryIcons[category.toLowerCase()] ?? Icons.category_rounded;
  }

  Future<void> _loadServiceDetails() async {
    try {
      final serviceDetails = await _fetchServiceDetails(widget.data.id);
      
      // 🔍 Debug: Print the response to see the structure
      print('📦 Service Details Response: $serviceDetails');
      print('📷 Images field: ${serviceDetails['images']}');
      print('📷 Images type: ${serviceDetails['images']?.runtimeType}');
      
      setState(() {
        _serviceData = serviceDetails;
        _bookingType = serviceDetails['bookingType']?.toString() ?? 'daily';
        
        // ✅ Extract media URLs from images array
        _mediaUrls = [];
        
        // Try 'images' field first
        final imagesField = serviceDetails['images'];
        if (imagesField != null && imagesField is List && imagesField.isNotEmpty) {
          for (var img in imagesField) {
            if (img != null) {
              String url = '';
              if (img is String && img.isNotEmpty) {
                url = img;
              } else if (img is Map) {
                // Handle {url: '...'} format
                url = (img['url'] ?? img['imageUrl'] ?? '').toString();
              }
              if (url.isNotEmpty) {
                _mediaUrls.add(url);
              }
            }
          }
        }
        
        // Try 'mediaItems' field (alternative format)
        if (_mediaUrls.isEmpty) {
          final mediaItems = serviceDetails['mediaItems'];
          if (mediaItems != null && mediaItems is List && mediaItems.isNotEmpty) {
            for (var item in mediaItems) {
              if (item != null) {
                String url = '';
                if (item is String && item.isNotEmpty) {
                  url = item;
                } else if (item is Map) {
                  url = (item['url'] ?? item['imageUrl'] ?? '').toString();
                }
                if (url.isNotEmpty) {
                  _mediaUrls.add(url);
                }
              }
            }
          }
        }
        
        // Try 'imageUrl' field (single image)
        if (_mediaUrls.isEmpty) {
          final singleImage = serviceDetails['imageUrl']?.toString() ?? '';
          if (singleImage.isNotEmpty) {
            _mediaUrls.add(singleImage);
          }
        }
        
        // Final fallback to widget data
        if (_mediaUrls.isEmpty && widget.data.imageUrl.isNotEmpty) {
          _mediaUrls.add(widget.data.imageUrl);
        }
        
        print('📷 Final _mediaUrls: $_mediaUrls');
        print('📷 _mediaUrls length: ${_mediaUrls.length}');
        
        _isLoading = false;
      });
      
      // Start auto-slide
      _startAutoSlide();
    } catch (e) {
      print('❌ Error loading service details: $e');
      setState(() {
        _isLoading = false;
        _bookingType = 'daily'; // Fallback to daily
        _serviceData = {
          'price': widget.data.price,
          'companyName': widget.data.companyName,
          'imageUrl': widget.data.imageUrl,
        };
        
        // Fallback image
        if (widget.data.imageUrl.isNotEmpty) {
          _mediaUrls = [widget.data.imageUrl];
        }
      });
    }
  }

  Future<Map<String, dynamic>> _fetchServiceDetails(String serviceId) async {
    final baseUrl = AuthService.baseUrl;
    final token = await AuthService.getToken();
    
    print('🔍 Fetching service details for: $serviceId');
    print('🔍 Token: ${token != null ? 'Present' : 'Missing'}');
    
    final response = await http.get(
      Uri.parse('$baseUrl/services/$serviceId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    print('🔍 Response status: ${response.statusCode}');
    print('🔍 Response body: ${response.body}');
    
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
        serviceId: widget.data.id,
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

  String _money(double v) => '₪${v.toStringAsFixed(0)}';

  // ✅ Open real chat with backend
  Future<void> _openChat(BuildContext context) async {
    // Get providerId from service data
    final providerId = _serviceData?['providerId']?.toString() ?? '';
    
    if (providerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot start chat: Provider not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: kPrimary),
      ),
    );

    try {
      // ✅ Use getIt to get the same ChatUserService instance
      final chatService = getIt<ChatUserService>();
      await chatService.initializeUserId();
      await chatService.initSocket();
      
      final chatId = await chatService.createChat(providerId);
      
      if (mounted) Navigator.pop(context); // Close loading
      
      if (chatId != null && mounted) {
        // Navigate to real chat
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatThreadPage(
              thread: ChatThreadModel(
                id: chatId,
                type: ThreadType.vendor,
                title: widget.data.companyName,
                lastMessage: '',
                lastTime: DateTime.now(),
                unreadCount: 0,
                online: false,
              ),
            ),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to start chat'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openBookingModal(BuildContext context) async {
    // Check if already in cart
    final inCart = CartStore.instance.contains(widget.data.id);
    if (inCart) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
          content: Text(
            'This service is already in your cart',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
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

    if (_serviceData == null || _bookingType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service details not loaded yet'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await showBookingModal(
      context: context,
      serviceId: widget.data.id,
      serviceName: widget.data.serviceName,
      bookingTypeString: _bookingType!,
      serviceData: _serviceData!,
      onSuccess: () {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            content: Text(
              'Added to cart successfully!',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = CartStore.instance;
    final data = widget.data;
    final heroTag = widget.heroTag;

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

      // ✅ BODY - Same design as home_customer.dart
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ✅ Media Slider
          _buildMediaSlider(data),
          
          const SizedBox(height: 16),
          
          // ✅ Service Info Card
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
                Row(
                  children: [
                    // Category Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        data.category,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: kPrimary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Rating
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          _serviceData?['rating']?.toString() ?? '0',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w900,
                            color: kText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Service Name
                Text(
                  data.serviceName,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: kText,
                  ),
                ),
                const SizedBox(height: 6),
                // Company Name
                Text(
                  _serviceData?['companyName']?.toString() ?? data.companyName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: kMuted,
                  ),
                ),
                const SizedBox(height: 16),
                
                // ✅ Price Section
                _buildPriceSection(),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // ✅ Description - only show if has content
          if (_hasDescription()) ...[
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
                  Text(
                    'Description',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w900,
                      color: kText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getDescription(),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: kMuted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // ✅ Service Information Section
          _buildServiceInformationSection(),
          
          // ✅ Company Info - only show if has data
          if (_hasAnyCompanyInfo())
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
                  Text(
                    'Company Info',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w900,
                      color: kText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._buildCompanyInfoLines(),
                ],
              ),
            ),

          // ✅ Customer Reviews Section
          _buildCustomerReviewsSection(),
          
          const SizedBox(height: 100), // Space for bottom bar
        ],
      ),

      // ✅ BOTTOM ACTIONS: Chat + Add to Cart
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.black.withOpacity(0.06))),
          ),
          child: ValueListenableBuilder<List<CartItem>>(
            valueListenable: store.itemsListenable,
            builder: (_, items, __) {
              final inCart = items.any((e) => e.id == data.id);
              final isDisplayOnly = _bookingType?.toLowerCase() == 'display';

              return Row(
                children: [
                  // ✅ Chat button (LEFT)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openChat(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.black.withOpacity(0.14)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: Icon(Icons.chat_bubble_rounded, color: kPrimary),
                      label: Text(
                        'Start Chat with Provider',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: kText),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // ✅ Add to Cart button (RIGHT)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (inCart || _isLoading || isDisplayOnly) ? null : () => _openBookingModal(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (inCart || isDisplayOnly) ? Colors.grey : kText,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.withOpacity(0.6),
                        disabledForegroundColor: Colors.white70,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: Icon(
                        inCart ? Icons.check_circle_rounded
                            : isDisplayOnly ? Icons.visibility_rounded
                            : Icons.add_shopping_cart_rounded,
                        color: (inCart || isDisplayOnly) ? Colors.white70 : kPrimary,
                      ),
                      label: Text(
                        inCart ? 'In Cart' 
                            : isDisplayOnly ? 'Display Only' 
                            : 'Add to Cart',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ✅ Build Media Slider Widget
  Widget _buildMediaSlider(ServiceDetailsData data) {
    // If no media, show placeholder
    if (_mediaUrls.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 220,
          color: kPrimary.withOpacity(0.1),
          child: Center(
            child: Icon(
              _getServiceIcon(data.category),
              size: 64,
              color: kPrimary.withOpacity(0.4),
            ),
          ),
        ),
      );
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          // Media PageView
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
                      ? _VideoThumbnail(url: url)
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
                              _getServiceIcon(data.category),
                              size: 64,
                              color: kPrimary.withOpacity(0.4),
                            ),
                          ),
                        ),
                );
              },
            ),
          ),
          
          // Discount Badge
          if (data.hasDiscount)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: kDanger.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '-${data.discountPercent}%',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          
          // Media counter badge
          if (_mediaUrls.length > 1)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_library_rounded, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '${_currentMediaIndex + 1}/${_mediaUrls.length}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Dot indicators (optimized for up to 10 items)
          if (_mediaUrls.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_mediaUrls.length, (index) {
                  final isActive = index == _currentMediaIndex;
                  // Smaller dots for many items (7+)
                  final bool manyItems = _mediaUrls.length >= 7;
                  final double activeWidth = manyItems ? 16 : 24;
                  final double inactiveWidth = manyItems ? 6 : 8;
                  final double height = manyItems ? 6 : 8;
                  final double margin = manyItems ? 2 : 3;
                  
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: EdgeInsets.symmetric(horizontal: margin),
                    width: isActive ? activeWidth : inactiveWidth,
                    height: height,
                    decoration: BoxDecoration(
                      color: isActive ? kPrimary : Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(height / 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  // ✅ Build Price Section (like home_customer.dart)
  Widget _buildPriceSection() {
    final allPrices = _serviceData?['allPrices'] as Map<String, dynamic>?;
    final bookingType = _bookingType?.toLowerCase() ?? 'daily';
    
    String priceLabel;
    double displayPrice = widget.data.price;
    IconData priceIcon;
    
    switch (bookingType) {
      case 'hourly':
        priceLabel = 'per hour';
        priceIcon = Icons.schedule_rounded;
        displayPrice = (allPrices?['perHour'] as num?)?.toDouble() ?? widget.data.price;
        break;
      case 'capacity':
        priceLabel = 'per person';
        priceIcon = Icons.person_rounded;
        displayPrice = (allPrices?['perPerson'] as num?)?.toDouble() ?? widget.data.price;
        break;
      case 'daily':
        priceLabel = 'per day';
        priceIcon = Icons.calendar_today_rounded;
        displayPrice = (allPrices?['perDay'] as num?)?.toDouble() ?? widget.data.price;
        break;
      case 'mixed':
        priceLabel = 'per event';
        priceIcon = Icons.event_rounded;
        displayPrice = (allPrices?['perEvent'] as num?)?.toDouble() ?? widget.data.price;
        break;
      case 'display':
        priceLabel = 'display only';
        priceIcon = Icons.visibility_rounded;
        displayPrice = (allPrices?['displayPrice'] as num?)?.toDouble() ?? widget.data.price;
        break;
      default:
        priceLabel = 'per service';
        priceIcon = Icons.payments_rounded;
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
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: kPrimary,
                  ),
                ),
                Text(
                  priceLabel,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: kMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 📋 SERVICE INFORMATION SECTION - Modern Design
  // ══════════════════════════════════════════════════════════════════════════
  
  Widget _buildServiceInformationSection() {
    final venueType = _serviceData?['venueType']?.toString();
    final maxCapacity = _serviceData?['maxCapacity'];
    final minHours = _serviceData?['minBookingHours'];
    final maxHours = _serviceData?['maxBookingHours'];
    final workingDays = _serviceData?['workingDays'] as List?;
    final availableHours = _serviceData?['availableHours'] as List?;
    final bookingType = _bookingType ?? 'hourly';
    final additionalInfo = _serviceData?['additionalInfo'] as Map<String, dynamic>?;
    
    // Check if we have any info to show
    final hasVenueInfo = venueType != null && venueType.isNotEmpty;
    final hasCapacity = maxCapacity != null && maxCapacity > 0;
    final hasBookingHours = (minHours != null && minHours > 0) || (maxHours != null && maxHours > 0);
    final hasWorkingHours = availableHours != null && availableHours.isNotEmpty;
    final hasWorkingDays = workingDays != null && workingDays.isNotEmpty;
    
    // Filter additional info
    final customInfo = <String, dynamic>{};
    if (additionalInfo != null) {
      additionalInfo.forEach((key, value) {
        if (key != 'description' && value != null && value.toString().isNotEmpty) {
          customInfo[key] = value;
        }
      });
    }
    
    final hasCustomInfo = customInfo.isNotEmpty;
    
    // If no info at all, don't show the section
    if (!hasVenueInfo && !hasCapacity && !hasBookingHours && !hasWorkingHours && !hasWorkingDays && !hasCustomInfo) {
      return const SizedBox.shrink();
    }

    // Format working hours (e.g., "9:00 AM - 8:00 PM")
    String? workingHoursStr;
    if (availableHours != null && availableHours.isNotEmpty) {
      final hours = availableHours.map((e) => e as int).toList()..sort();
      if (hours.isNotEmpty) {
        final startHour = hours.first;
        final endHour = hours.last;
        workingHoursStr = '${_formatHour(startHour)} - ${_formatHour(endHour + 1)}';
      }
    }

    // Format working days (e.g., "Sunday - Saturday")
    String? workingDaysStr;
    if (workingDays != null && workingDays.isNotEmpty) {
      if (workingDays.length == 7) {
        workingDaysStr = 'Every Day';
      } else {
        final dayOrder = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
        final sortedDays = workingDays.map((d) => d.toString().toLowerCase()).toList()
          ..sort((a, b) => dayOrder.indexOf(a).compareTo(dayOrder.indexOf(b)));
        
        // Check if consecutive days
        bool isConsecutive = true;
        for (int i = 1; i < sortedDays.length; i++) {
          if (dayOrder.indexOf(sortedDays[i]) - dayOrder.indexOf(sortedDays[i-1]) != 1) {
            isConsecutive = false;
            break;
          }
        }
        
        if (isConsecutive && sortedDays.length > 2) {
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
            // Header with icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kPrimary.withOpacity(0.15), kPrimary.withOpacity(0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.info_outline_rounded, color: kPrimary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Service Information',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: kText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // ═══════════════════════════════════════════
            // SECTION 1: Basic Service Info (Grid Layout)
            // ═══════════════════════════════════════════
            if (hasVenueInfo || hasCapacity || hasBookingHours) ...[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  // Venue Type
                  if (hasVenueInfo)
                    _buildInfoChip(
                      icon: venueType == 'indoor' ? Icons.home_rounded : Icons.park_rounded,
                      label: venueType == 'indoor' ? 'Indoor Venue' : 'Outdoor Venue',
                      color: venueType == 'indoor' ? const Color(0xFF3B82F6) : const Color(0xFF10B981),
                    ),
                  
                  // Max Capacity
                  if (hasCapacity)
                    _buildInfoChip(
                      icon: Icons.groups_rounded,
                      label: '$maxCapacity Guests Max',
                      color: const Color(0xFFF59E0B),
                    ),
                  
                  // Booking Type
                  _buildInfoChip(
                    icon: _getBookingIcon(bookingType),
                    label: _getBookingLabel(bookingType),
                    color: const Color(0xFF6366F1),
                  ),
                  
                  // Min Booking
                  if (minHours != null && minHours > 0)
                    _buildInfoChip(
                      icon: Icons.timer_outlined,
                      label: 'Min $minHours ${minHours == 1 ? 'Hour' : 'Hours'}',
                      color: const Color(0xFF8B5CF6),
                    ),
                  
                  // Max Booking
                  if (maxHours != null && maxHours > 0)
                    _buildInfoChip(
                      icon: Icons.timelapse_rounded,
                      label: 'Max $maxHours Hours',
                      color: const Color(0xFFEC4899),
                    ),
                ],
              ),
            ],
            
            // ═══════════════════════════════════════════
            // SECTION 2: Additional Info
            // ═══════════════════════════════════════════
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
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...customInfo.entries.map((entry) => _buildAdditionalInfoRow(entry.key, entry.value.toString())),
                  ],
                ),
              ),
            ],
            
            // ═══════════════════════════════════════════
            // SECTION 3: Working Hours & Days
            // ═══════════════════════════════════════════
            if (hasWorkingHours || hasWorkingDays) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0891B2).withOpacity(0.08),
                      const Color(0xFF06B6D4).withOpacity(0.04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF0891B2).withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    // Working Hours
                    if (workingHoursStr != null)
                      _buildScheduleRow(
                        icon: Icons.access_time_rounded,
                        title: 'Working Hours',
                        value: workingHoursStr,
                        iconColor: const Color(0xFF0891B2),
                      ),
                    
                    if (workingHoursStr != null && workingDaysStr != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: const Color(0xFF0891B2).withOpacity(0.15)),
                      ),
                    
                    // Working Days
                    if (workingDaysStr != null)
                      _buildScheduleRow(
                        icon: Icons.calendar_month_rounded,
                        title: 'Available Days',
                        value: workingDaysStr,
                        iconColor: const Color(0xFF0891B2),
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

  // Modern Info Chip Widget
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
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
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  // Additional Info Row Widget
  Widget _buildAdditionalInfoRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 7, right: 12),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$key: ',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: kMuted,
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

  // Schedule Row Widget (for working hours & days)
  Widget _buildScheduleRow({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: kMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: kText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper: Format hour to AM/PM
  String _formatHour(int hour) {
    if (hour == 0 || hour == 24) return '12:00 AM';
    if (hour == 12) return '12:00 PM';
    if (hour < 12) return '$hour:00 AM';
    return '${hour - 12}:00 PM';
  }

  // Helper: Capitalize day name
  String _capitalizeDay(String day) {
    if (day.isEmpty) return day;
    return day[0].toUpperCase() + day.substring(1);
  }

  // Helper: Get booking type icon
  IconData _getBookingIcon(String bookingType) {
    switch (bookingType.toLowerCase()) {
      case 'hourly': return Icons.schedule_rounded;
      case 'daily': return Icons.today_rounded;
      case 'capacity': return Icons.people_rounded;
      case 'mixed': return Icons.layers_rounded;
      case 'display': return Icons.visibility_rounded;
      default: return Icons.event_rounded;
    }
  }

  // Helper: Get booking type label
  String _getBookingLabel(String bookingType) {
    switch (bookingType.toLowerCase()) {
      case 'hourly': return 'Hourly Booking';
      case 'daily': return 'Daily Booking';
      case 'capacity': return 'Per Person';
      case 'mixed': return 'Flexible Booking';
      case 'display': return 'Display Only';
      default: return 'Standard Booking';
    }
  }

  // ✅ Helper: Check if has description
  bool _hasDescription() {
    final desc = _serviceData?['description']?.toString().trim() ?? 
                 widget.data.description.trim();
    return desc.isNotEmpty && desc != 'No description yet.';
  }

  // ✅ Helper: Get description text
  String _getDescription() {
    final apiDesc = _serviceData?['description']?.toString().trim() ?? '';
    if (apiDesc.isNotEmpty) return apiDesc;
    return widget.data.description.isNotEmpty ? widget.data.description : 'No description yet.';
  }

  // ✅ Helper methods
  bool _hasAnyCompanyInfo() {
    final companyName = _serviceData?['companyName']?.toString().trim() ?? 
                        widget.data.companyName.trim();
    final email = _serviceData?['companyInfo']?['email']?.toString().trim() ?? 
                  widget.data.contactEmail.trim();
    final phone = _serviceData?['companyInfo']?['phone']?.toString().trim() ?? 
                  widget.data.contactPhone.trim();
    final city = _serviceData?['city']?.toString().trim() ?? '';
    
    return (companyName.isNotEmpty && companyName != 'Unknown' && companyName != 'N/A') ||
           (city.isNotEmpty && city != 'N/A') ||
           (email.isNotEmpty && email != 'N/A') ||
           (phone.isNotEmpty && phone != 'N/A');
  }

  List<Widget> _buildCompanyInfoLines() {
    final lines = <Widget>[];
    
    final companyName = _serviceData?['companyName']?.toString().trim() ?? 
                        widget.data.companyName.trim();
    if (companyName.isNotEmpty && companyName != 'Unknown' && companyName != 'N/A') {
      lines.add(_InfoRow(icon: Icons.business_rounded, text: companyName));
    }
    
    final city = _serviceData?['city']?.toString().trim() ?? '';
    if (city.isNotEmpty && city != 'N/A') {
      if (lines.isNotEmpty) lines.add(const SizedBox(height: 8));
      lines.add(_InfoRow(icon: Icons.location_on_rounded, text: city));
    }
    
    final email = _serviceData?['companyInfo']?['email']?.toString().trim() ?? 
                  widget.data.contactEmail.trim();
    if (email.isNotEmpty && email != 'N/A') {
      if (lines.isNotEmpty) lines.add(const SizedBox(height: 8));
      lines.add(_InfoRow(icon: Icons.email_rounded, text: email));
    }
    
    final phone = _serviceData?['companyInfo']?['phone']?.toString().trim() ?? 
                  widget.data.contactPhone.trim();
    if (phone.isNotEmpty && phone != 'N/A') {
      if (lines.isNotEmpty) lines.add(const SizedBox(height: 8));
      lines.add(_InfoRow(icon: Icons.phone_rounded, text: phone));
    }
    
    return lines;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ⭐ CUSTOMER REVIEWS SECTION
  // ══════════════════════════════════════════════════════════════════════════
  
  Widget _buildCustomerReviewsSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
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
                          serviceId: widget.data.id,
                          serviceName: widget.data.serviceName,
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

// ✅ Info Row Widget (matches home_customer.dart)
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
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: kText,
            ),
          ),
        ),
      ],
    );
  }
}

// ============ Video Thumbnail Widget ============
class _VideoThumbnail extends StatefulWidget {
  final String url;
  const _VideoThumbnail({required this.url});

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

  Future<void> _initVideo() async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() => _initialized = true);
      }
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
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
        // Video play icon overlay
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
        // Video badge
        Positioned(
          bottom: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam_rounded, size: 12, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  'Video',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============ Full Screen Gallery ============
class _FullScreenGallery extends StatefulWidget {
  final List<String> mediaUrls;
  final int initialIndex;

  const _FullScreenGallery({
    required this.mediaUrls,
    required this.initialIndex,
  });

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
    _initVideoIfNeeded();
  }

  bool _isVideoUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') || 
           lower.endsWith('.mov') || 
           lower.endsWith('.avi') || 
           lower.endsWith('.webm') ||
           lower.contains('video');
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
        title: Text(
          '${_currentIndex + 1} / ${widget.mediaUrls.length}',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        centerTitle: true,
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
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 50,
                              ),
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
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (_, __, ___) => const Icon(
                  Icons.broken_image_rounded,
                  color: Colors.white54,
                  size: 64,
                ),
              ),
            ),
          );
        },
      ),
      // Bottom indicator
      bottomNavigationBar: widget.mediaUrls.length > 1
          ? Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.mediaUrls.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == index 
                          ? Colors.white 
                          : Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}