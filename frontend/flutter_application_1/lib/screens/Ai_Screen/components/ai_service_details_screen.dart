// lib/screens/Ai_Screen/components/ai_service_details_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;

import '../../../services/auth_service.dart';
import '../../user/chat/chat_inside_search.dart';

const Color kPrimary = Color.fromARGB(215, 20, 20, 215);
const Color kBg = Color(0xFFF6F7FB);
const Color kText = Color(0xFF0B1220);
const Color kMuted = Color(0xFF6B7280);
const Color kDanger = Color(0xFFEF4444);

/// Service details screen opened from AI search results
/// This screen only shows "Chat with Owner" button (no Add to Cart)
/// Add to Cart is handled from the AI service card directly
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

  @override
  void initState() {
    super.initState();
    _loadServiceDetails();
  }

  Future<void> _loadServiceDetails() async {
    try {
      final serviceDetails = await _fetchServiceDetails(widget.serviceId);
      setState(() {
        _serviceData = serviceDetails;
        _bookingType = serviceDetails['bookingType']?.toString() ?? 'daily';
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading service details: $e');
      setState(() {
        _isLoading = false;
        _bookingType = 'daily';
        // Use fallback data from widget
        _serviceData = {
          'serviceName': widget.serviceName ?? 'Service',
          'imageUrl': widget.imageUrl ?? '',
          'companyName': widget.providerName ?? 'Unknown',
          'category': widget.category ?? 'Other',
          'city': widget.city ?? '',
          'price': widget.price ?? 0,
          'bookingType': widget.payType ?? 'daily',
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

  /// Safely convert any value to double
  double _toDouble(dynamic value, [double fallback = 0]) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  String _money(double v) => '₪${v.toStringAsFixed(0)}';

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

  @override
  Widget build(BuildContext context) {
    final heroTag = 'ai_service_${widget.serviceId}';

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
                // Hero Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    children: [
                      Hero(
                        tag: heroTag,
                        child: CachedNetworkImage(
                          imageUrl: _getImageUrl(),
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
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  _getRating().toStringAsFixed(1),
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
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
                
                const SizedBox(height: 16),
                
                // Service Info Card
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
                              _getCategory(),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: kPrimary,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Rating
                          if (_getRating() > 0) ...[
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  _getRating().toStringAsFixed(1),
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w900,
                                    color: kText,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Service Name
                      Text(
                        _getServiceName(),
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: kText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Company Name
                      Text(
                        _getCompanyName(),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: kMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Price Section
                      _buildPriceSection(),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Description - only show if has content
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
                
                // Company Info - only show if has data
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
                
                // Note about booking
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber.shade700, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'To add this service to your cart, go back and use the "Add to Cart" button on the service card.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 100), // Space for bottom bar
              ],
            ),

      // BOTTOM: Chat with Owner Button Only
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.black.withOpacity(0.06))),
          ),
          child: ElevatedButton.icon(
            onPressed: () => _openChat(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            icon: const Icon(Icons.chat_bubble_rounded, size: 20),
            label: Text(
              'Chat with Owner',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Build Price Section
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

  // Helper methods
  String _getImageUrl() {
    return _serviceData?['imageUrl']?.toString() ?? 
           _serviceData?['images']?[0]?.toString() ?? 
           widget.imageUrl ?? '';
  }

  String _getServiceName() {
    return _serviceData?['serviceName']?.toString() ?? widget.serviceName ?? 'Service';
  }

  String _getCompanyName() {
    return _serviceData?['companyName']?.toString() ?? widget.providerName ?? 'Unknown';
  }

  String _getCategory() {
    return _serviceData?['category']?.toString() ?? widget.category ?? 'Other';
  }

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
    final apiDesc = _serviceData?['description']?.toString().trim() ?? '';
    if (apiDesc.isNotEmpty) return apiDesc;
    return 'No description yet.';
  }

  bool _hasAnyCompanyInfo() {
    final companyName = _getCompanyName();
    final email = _serviceData?['companyInfo']?['email']?.toString().trim() ?? '';
    final phone = _serviceData?['companyInfo']?['phone']?.toString().trim() ?? '';
    final city = _serviceData?['city']?.toString().trim() ?? widget.city ?? '';
    
    return (companyName.isNotEmpty && companyName != 'Unknown' && companyName != 'N/A') ||
           (city.isNotEmpty && city != 'N/A') ||
           (email.isNotEmpty && email != 'N/A') ||
           (phone.isNotEmpty && phone != 'N/A');
  }

  List<Widget> _buildCompanyInfoLines() {
    final lines = <Widget>[];
    
    final companyName = _getCompanyName();
    if (companyName.isNotEmpty && companyName != 'Unknown' && companyName != 'N/A') {
      lines.add(_InfoRow(icon: Icons.business_rounded, text: companyName));
    }
    
    final city = _serviceData?['city']?.toString().trim() ?? widget.city ?? '';
    if (city.isNotEmpty && city != 'N/A') {
      if (lines.isNotEmpty) lines.add(const SizedBox(height: 8));
      lines.add(_InfoRow(icon: Icons.location_on_rounded, text: city));
    }
    
    final email = _serviceData?['companyInfo']?['email']?.toString().trim() ?? '';
    if (email.isNotEmpty && email != 'N/A') {
      if (lines.isNotEmpty) lines.add(const SizedBox(height: 8));
      lines.add(_InfoRow(icon: Icons.email_rounded, text: email));
    }
    
    final phone = _serviceData?['companyInfo']?['phone']?.toString().trim() ?? '';
    if (phone.isNotEmpty && phone != 'N/A') {
      if (lines.isNotEmpty) lines.add(const SizedBox(height: 8));
      lines.add(_InfoRow(icon: Icons.phone_rounded, text: phone));
    }
    
    return lines;
  }

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
}

// Info Row Widget
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
