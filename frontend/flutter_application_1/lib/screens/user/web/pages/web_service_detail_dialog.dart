// lib/screens/user/web/pages/web_service_detail_dialog.dart
//
// ✅ Modern Web Service Detail Dialog
// ✅ Shows service details with add to cart and chat options
// ✅ Beautiful design with smooth animations

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import '../web_theme.dart';
import '../../payment/cart.dart';
import '../../chat/chat_customer_home_page.dart';
import 'web_booking_dialog.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/user_service/chat_user_service.dart';
import '../../../../services/service_locator.dart';

/// Data model for service details
class WebServiceData {
  final String id;
  final String name;
  final String company;
  final String providerId;
  final String category;
  final String description;
  final String imageUrl;
  final String city;
  final double price;
  final double? oldPrice;
  final double rating;
  final String? email;
  final String? phone;

  const WebServiceData({
    required this.id,
    required this.name,
    required this.company,
    required this.providerId,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.city,
    required this.price,
    this.oldPrice,
    required this.rating,
    this.email,
    this.phone,
  });

  bool get hasDiscount =>
      oldPrice != null && oldPrice! > price && oldPrice! > 0;

  int get discountPercent {
    if (!hasDiscount) return 0;
    final p = ((oldPrice! - price) / oldPrice!) * 100;
    return p.round().clamp(1, 95);
  }
}

/// Show the service detail dialog
Future<void> showWebServiceDetail({
  required BuildContext context,
  required WebServiceData data,
}) async {
  await showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (ctx) => _WebServiceDetailDialog(data: data),
  );
}

class _WebServiceDetailDialog extends StatefulWidget {
  final WebServiceData data;

  const _WebServiceDetailDialog({required this.data});

  @override
  State<_WebServiceDetailDialog> createState() => _WebServiceDetailDialogState();
}

class _WebServiceDetailDialogState extends State<_WebServiceDetailDialog>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _serviceData;
  String? _bookingType;
  List<String> _mediaUrls = [];
  int _currentMediaIndex = 0;
  late PageController _pageController;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
    _loadServiceDetails();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadServiceDetails() async {
    try {
      final baseUrl = AuthService.baseUrl;
      final token = await AuthService.getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/services/${widget.data.id}'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _serviceData = data;
          _bookingType = data['bookingType']?.toString() ?? 'daily';
          _extractMediaUrls(data);
          _isLoading = false;
        });
      } else {
        _setFallbackData();
      }
    } catch (e) {
      _setFallbackData();
    }
  }

  void _setFallbackData() {
    setState(() {
      _isLoading = false;
      _bookingType = 'daily';
      _serviceData = {'price': widget.data.price};
      if (widget.data.imageUrl.isNotEmpty) {
        _mediaUrls = [widget.data.imageUrl];
      }
    });
  }

  void _extractMediaUrls(Map<String, dynamic> data) {
    _mediaUrls = [];

    final imagesField = data['images'];
    if (imagesField != null && imagesField is List && imagesField.isNotEmpty) {
      for (var img in imagesField) {
        if (img != null) {
          String url = '';
          if (img is String && img.isNotEmpty) {
            url = img;
          } else if (img is Map) {
            url = (img['url'] ?? img['imageUrl'] ?? '').toString();
          }
          if (url.isNotEmpty) {
            _mediaUrls.add(url);
          }
        }
      }
    }

    if (_mediaUrls.isEmpty) {
      final singleImage = data['imageUrl']?.toString() ?? '';
      if (singleImage.isNotEmpty) {
        _mediaUrls.add(singleImage);
      }
    }

    if (_mediaUrls.isEmpty && widget.data.imageUrl.isNotEmpty) {
      _mediaUrls.add(widget.data.imageUrl);
    }
  }

  IconData _getCategoryIcon(String category) {
    final icons = {
      'venues': Icons.apartment_rounded,
      'venue': Icons.apartment_rounded,
      'catering': Icons.restaurant_rounded,
      'photography': Icons.camera_alt_rounded,
      'photographers': Icons.camera_alt_rounded,
      'music': Icons.music_note_rounded,
      'dj': Icons.headphones_rounded,
      'decoration': Icons.celebration_rounded,
      'flowers': Icons.local_florist_rounded,
      'flower shops': Icons.local_florist_rounded,
      'makeup': Icons.face_rounded,
      'cake': Icons.cake_rounded,
      'event planners': Icons.event_rounded,
    };
    return icons[category.toLowerCase()] ?? Icons.category_rounded;
  }

  Future<void> _startChat() async {
    final providerId = _serviceData?['providerId']?.toString() ?? widget.data.providerId;

    if (providerId.isEmpty) {
      _showSnackBar('Cannot start chat: Provider not available', isError: true);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: kWebPrimary),
      ),
    );

    try {
      final chatService = getIt<ChatUserService>();
      await chatService.initializeUserId();
      await chatService.initSocket();

      final chatId = await chatService.createChat(providerId);

      if (mounted) Navigator.pop(context); // Close loading

      if (chatId != null && mounted) {
        Navigator.pop(context); // Close detail dialog
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatThreadPage(
              thread: ChatThreadModel(
                id: chatId,
                type: ThreadType.vendor,
                title: widget.data.company,
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
      _showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _addToCart() async {
    final inCart = CartStore.instance.contains(widget.data.id);
    if (inCart) {
      _showSnackBar('This service is already in your cart', isWarning: true);
      return;
    }

    if (_serviceData == null || _bookingType == null) {
      _showSnackBar('Service details not loaded yet', isError: true);
      return;
    }

    Navigator.pop(context); // Close dialog first

    await showWebBookingDialog(
      context: context,
      serviceId: widget.data.id,
      serviceName: widget.data.name,
      bookingTypeString: _bookingType!,
      serviceData: _serviceData!,
      onSuccess: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added to cart successfully!',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            backgroundColor: kWebSuccess,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false, bool isWarning = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? kWebError : isWarning ? Colors.orange : kWebSuccess,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(40),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
            decoration: BoxDecoration(
              color: kWebBgCard,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: _isLoading ? _buildLoadingState() : _buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(60),
        child: CircularProgressIndicator(color: kWebPrimary),
      ),
    );
  }

  Widget _buildContent() {
    final data = widget.data;
    final isDisplayOnly = _bookingType?.toLowerCase() == 'display';
    final inCart = CartStore.instance.contains(data.id);

    return Row(
      children: [
        // Left: Media Gallery
        Expanded(
          flex: 5,
          child: _buildMediaSection(data),
        ),

        // Right: Details
        Expanded(
          flex: 5,
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                // Header with close button
                _buildHeader(),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category badge
                        _buildCategoryBadge(data),
                        const SizedBox(height: 16),

                        // Service name
                        Text(
                          data.name,
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: kWebTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Company name
                        Text(
                          _serviceData?['companyName']?.toString() ?? data.company,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: kWebTextMuted,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Rating & Location row
                        _buildInfoRow(data),
                        const SizedBox(height: 24),

                        // Price card
                        _buildPriceCard(),
                        const SizedBox(height: 24),

                        // Description
                        if (_hasDescription()) ...[
                          _buildSectionTitle('Description', Icons.description_rounded),
                          const SizedBox(height: 12),
                          Text(
                            _getDescription(),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              height: 1.6,
                              color: kWebTextBody,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Company info
                        if (_hasCompanyInfo()) ...[
                          _buildSectionTitle('Contact Info', Icons.business_rounded),
                          const SizedBox(height: 12),
                          _buildCompanyInfo(),
                        ],
                      ],
                    ),
                  ),
                ),

                // Bottom actions
                _buildBottomActions(isDisplayOnly, inCart),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaSection(WebServiceData data) {
    return Stack(
      children: [
        // Background gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                kWebPrimary.withValues(alpha: 0.1),
                kWebPrimaryDark.withValues(alpha: 0.1),
              ],
            ),
          ),
        ),

        // Media content
        if (_mediaUrls.isEmpty)
          Center(
            child: Icon(
              _getCategoryIcon(data.category),
              size: 100,
              color: kWebPrimary.withValues(alpha: 0.4),
            ),
          )
        else
          PageView.builder(
            controller: _pageController,
            itemCount: _mediaUrls.length,
            onPageChanged: (index) => setState(() => _currentMediaIndex = index),
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: _mediaUrls[index],
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: kWebBgSecondary,
                  child: const Center(child: CircularProgressIndicator(color: kWebPrimary)),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: kWebBgSecondary,
                  child: Icon(
                    _getCategoryIcon(data.category),
                    size: 80,
                    color: kWebPrimary.withValues(alpha: 0.4),
                  ),
                ),
              );
            },
          ),

        // Discount badge
        if (data.hasDiscount)
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: kWebError,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: kWebError.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                '-${data.discountPercent}% OFF',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),

        // Media indicators
        if (_mediaUrls.length > 1)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_mediaUrls.length, (index) {
                final isActive = index == _currentMediaIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 28 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isActive ? kWebPrimary : Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),

        // Media counter
        if (_mediaUrls.length > 1)
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.photo_library_rounded, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    '${_currentMediaIndex + 1}/${_mediaUrls.length}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: kWebBorder)),
      ),
      child: Row(
        children: [
          Text(
            'Service Details',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: kWebTextMuted,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: kWebBgSecondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.close_rounded, color: kWebTextMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge(WebServiceData data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kWebPrimary.withValues(alpha: 0.15), kWebPrimaryDark.withValues(alpha: 0.1)],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getCategoryIcon(data.category), size: 16, color: kWebPrimary),
          const SizedBox(width: 8),
          Text(
            data.category,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kWebPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(WebServiceData data) {
    final city = _serviceData?['city']?.toString() ?? data.city;
    final rating = _serviceData?['rating']?.toString() ?? data.rating.toStringAsFixed(1);

    return Row(
      children: [
        // Rating
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: kWebWarning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.star_rounded, size: 18, color: kWebWarning),
              const SizedBox(width: 6),
              Text(
                rating,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: kWebTextPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Location
        if (city.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: kWebBgSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on_rounded, size: 18, color: kWebPrimary),
                const SizedBox(width: 6),
                Text(
                  city,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: kWebTextBody,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPriceCard() {
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kWebPrimary.withValues(alpha: 0.08), kWebPrimaryDark.withValues(alpha: 0.04)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kWebPrimary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kWebPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(priceIcon, color: kWebPrimary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₪${displayPrice.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: kWebPrimary,
                      ),
                    ),
                    if (widget.data.hasDiscount) ...[
                      const SizedBox(width: 10),
                      Text(
                        '₪${widget.data.oldPrice!.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: kWebTextMuted,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  priceLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: kWebTextMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: kWebPrimary),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: kWebTextPrimary,
          ),
        ),
      ],
    );
  }

  bool _hasDescription() {
    final desc = _serviceData?['description']?.toString().trim() ?? widget.data.description.trim();
    return desc.isNotEmpty && desc != 'No description yet.';
  }

  String _getDescription() {
    final apiDesc = _serviceData?['description']?.toString().trim() ?? '';
    if (apiDesc.isNotEmpty) return apiDesc;
    return widget.data.description.isNotEmpty ? widget.data.description : 'No description yet.';
  }

  bool _hasCompanyInfo() {
    final city = _serviceData?['city']?.toString().trim() ?? '';
    final email = _serviceData?['companyInfo']?['email']?.toString().trim() ?? widget.data.email ?? '';
    final phone = _serviceData?['companyInfo']?['phone']?.toString().trim() ?? widget.data.phone ?? '';
    return city.isNotEmpty || email.isNotEmpty || phone.isNotEmpty;
  }

  Widget _buildCompanyInfo() {
    final List<Widget> items = [];

    final city = _serviceData?['city']?.toString().trim() ?? '';
    if (city.isNotEmpty) {
      items.add(_buildInfoItem(Icons.location_on_rounded, city));
    }

    final email = _serviceData?['companyInfo']?['email']?.toString().trim() ?? widget.data.email ?? '';
    if (email.isNotEmpty && email != 'N/A') {
      items.add(_buildInfoItem(Icons.email_rounded, email));
    }

    final phone = _serviceData?['companyInfo']?['phone']?.toString().trim() ?? widget.data.phone ?? '';
    if (phone.isNotEmpty && phone != 'N/A') {
      items.add(_buildInfoItem(Icons.phone_rounded, phone));
    }

    return Column(
      children: items,
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kWebBgSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: kWebPrimary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: kWebTextBody,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(bool isDisplayOnly, bool inCart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: kWebBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Chat button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _startChat,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: kWebPrimary.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: Icon(Icons.chat_bubble_rounded, color: kWebPrimary),
              label: Text(
                'Start Chat',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kWebPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Add to Cart button
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: (inCart || isDisplayOnly) ? null : _addToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: (inCart || isDisplayOnly) ? kWebTextMuted : kWebPrimary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: kWebTextMuted.withValues(alpha: 0.6),
                disabledForegroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: Icon(
                inCart
                    ? Icons.check_circle_rounded
                    : isDisplayOnly
                        ? Icons.visibility_rounded
                        : Icons.add_shopping_cart_rounded,
              ),
              label: Text(
                inCart
                    ? 'In Cart'
                    : isDisplayOnly
                        ? 'Display Only'
                        : 'Add to Cart',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
