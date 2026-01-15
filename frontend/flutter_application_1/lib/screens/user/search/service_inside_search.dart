import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;

import '../payment/cart.dart';
import '../chat/chat_inside_search.dart';
import '../../../widgets/booking_details_modal.dart';
import '../../../services/auth_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadServiceDetails();
  }

  Future<void> _loadServiceDetails() async {
    try {
      final serviceDetails = await _fetchServiceDetails(widget.data.id);
      setState(() {
        _serviceData = serviceDetails;
        _bookingType = serviceDetails['bookingType']?.toString() ?? 'daily';
        _isLoading = false;
      });
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

  String _money(double v) => '₪${v.toStringAsFixed(0)}';

  void _openChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatInsideSearchScreen(
          providerName: widget.data.companyName,
          providerEmail: widget.data.contactEmail,
          providerPhone: widget.data.contactPhone,
        ),
      ),
    );
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
          // ✅ Hero Image
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                Hero(
                  tag: heroTag,
                  child: CachedNetworkImage(
                    imageUrl: data.imageUrl,
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
                      color: const Color(0xFFF1F5F9),
                      child: const Icon(Icons.image, size: 48),
                    ),
                  ),
                ),
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
              ],
            ),
          ),
          
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
                        'Start Chat',
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