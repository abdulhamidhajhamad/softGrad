// lib/screens/Ai_Screen/components/ai_package_card.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../models/ai_data_models.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/booking_details_modal.dart';
import '../../../services/payment_service/cart_service.dart';
import '../../user/payment/cart.dart';

// ✅ Clean Modern Color Palette (matching project)
const Color kPrimary = Color.fromARGB(215, 20, 20, 215);
const Color kBg = Color(0xFFF6F7FB);
const Color kCard = Colors.white;
const Color kText = Color(0xFF0B1220);
const Color kMuted = Color(0xFF6B7280);
const Color kBorder = Color(0xFFE5E7EB);
const Color kSuccess = Color(0xFF22C55E);

class AiPackageCard extends StatefulWidget {
  final PackageResult package;
  final VoidCallback onAddToCart;
  final bool isStrictBudget; // ✅ NEW: Hide level labels for strict budget

  const AiPackageCard({
    Key? key,
    required this.package,
    required this.onAddToCart,
    this.isStrictBudget = false,
  }) : super(key: key);

  @override
  State<AiPackageCard> createState() => _AiPackageCardState();
}

class _AiPackageCardState extends State<AiPackageCard> {
  bool _isExpanded = false;
  bool _isProcessing = false;
  int _currentServiceIndex = 0;
  List<ServiceItem> _pendingServices = [];
  bool _serviceAddedSuccessfully = false; // ✅ Track if service was added
  int _addedServicesCount = 0; // ✅ Track how many services were added

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kBorder.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Header Section
          _buildHeader(),
          
          // ✅ Services Preview (always visible)
          _buildServicesPreview(),
          
          // ✅ Expanded Details
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedDetails(),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
          
          // ✅ Footer with Add to Cart
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return InkWell(
      onTap: _toggleExpanded,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // ✅ Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kPrimary, kPrimary.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                
                // ✅ Title & Badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ Only show level badge if NOT strict budget
                      if (!widget.isStrictBudget && widget.package.packageLevel.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getLevelColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _getLevelColor().withOpacity(0.3)),
                          ),
                          child: Text(
                            widget.package.packageLevel,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _getLevelColor(),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      Text(
                        widget.isStrictBudget 
                            ? 'AI Generated Package'
                            : widget.package.name,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: kText,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // ✅ Expand/Collapse
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: kMuted,
                    size: 22,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // ✅ Price Section
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kPrimary.withOpacity(0.1), kPrimary.withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kPrimary.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '₪${widget.package.price.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: kPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'total',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: kMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // ✅ Services count
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: kBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.grid_view_rounded, size: 16, color: kMuted),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.package.services.length} services',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: widget.package.services.take(3).map((service) {
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
                Icon(
                  _getCategoryIcon(service.category),
                  size: 14,
                  color: kPrimary,
                ),
                const SizedBox(width: 6),
                Text(
                  service.category,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: kText,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExpandedDetails() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Description
          if (widget.package.description.isNotEmpty) ...[
            Text(
              widget.package.description,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: kMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          // ✅ Services Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.list_alt_rounded, size: 16, color: kPrimary),
              ),
              const SizedBox(width: 10),
              Text(
                'Included Services',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          
          // ✅ Services List
          ...widget.package.services.map((service) => _buildServiceItem(service)),
          
          // ✅ Info Note
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.amber.shade700, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Prices are estimates. You\'ll set booking details for each service.',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.amber.shade800,
                      height: 1.4,
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

  Widget _buildServiceItem(ServiceItem service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          // ✅ Category Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kBorder),
            ),
            child: Icon(
              _getCategoryIcon(service.category),
              color: kPrimary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          
          // ✅ Service Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: kText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      service.category,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: kMuted,
                      ),
                    ),
                    if (service.providerName != null) ...[
                      Text(' • ', style: TextStyle(color: kMuted)),
                      Expanded(
                        child: Text(
                          service.providerName!,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: kMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // ✅ Price
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '₪${service.price.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: kPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _handleAddToCart,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: kPrimary.withOpacity(0.6),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: _isProcessing
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Processing...',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_shopping_cart_rounded, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Add Package to Cart',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ✅ Handle Add to Cart - Opens booking modal for each service
  void _handleAddToCart() async {
    final services = widget.package.services.where((s) => s.id.isNotEmpty).toList();
    
    if (services.isEmpty) {
      _showErrorSnackbar('No bookable services in this package');
      return;
    }

    setState(() {
      _isProcessing = true;
      _pendingServices = services;
      _currentServiceIndex = 0;
      _addedServicesCount = 0;
    });

    // Process services one by one
    await _processNextService();
  }

  Future<void> _processNextService() async {
    // ✅ Check if all services processed
    if (_currentServiceIndex >= _pendingServices.length) {
      setState(() => _isProcessing = false);
      
      // Show final success message
      if (_addedServicesCount > 0) {
        _showSuccessSnackbar('$_addedServicesCount service${_addedServicesCount > 1 ? 's' : ''} added to cart!');
      }
      return;
    }

    final service = _pendingServices[_currentServiceIndex];
    
    // Check if already in cart - skip silently
    if (CartStore.instance.contains(service.id)) {
      _currentServiceIndex++;
      await _processNextService();
      return;
    }

    try {
      // Fetch service details
      final baseUrl = AuthService.baseUrl;
      final response = await http.get(
        Uri.parse('$baseUrl/services/${service.id}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load service');
      }

      final serviceData = json.decode(response.body) as Map<String, dynamic>;
      final bookingType = serviceData['bookingType']?.toString() ?? 'daily';

      // Skip display-only services silently
      if (bookingType.toLowerCase() == 'display') {
        _currentServiceIndex++;
        await _processNextService();
        return;
      }

      // Show booking modal
      if (!mounted) return;
      
      // ✅ Reset flag before showing modal
      _serviceAddedSuccessfully = false;
      
      // ✅ AI packages: Don't pass packageName - book as individual services
      await showBookingModal(
        context: context,
        serviceId: service.id,
        serviceName: service.name,
        bookingTypeString: bookingType,
        serviceData: serviceData,
        onSuccess: () {
          // ✅ Mark as successfully added
          _serviceAddedSuccessfully = true;
          _addedServicesCount++;
        },
      );

      // ✅ After modal closes, check if it was successful
      if (!mounted) return;
      
      if (_serviceAddedSuccessfully) {
        // Service was added successfully - move to next
        _currentServiceIndex++;
        await _processNextService();
      } else {
        // User closed modal without adding (cancelled)
        // Ask if they want to skip this service and continue
        final shouldContinue = await _showSkipDialog(service.name);
        if (shouldContinue == true) {
          _currentServiceIndex++;
          await _processNextService();
        } else {
          // User wants to stop
          setState(() => _isProcessing = false);
          if (_addedServicesCount > 0) {
            _showSuccessSnackbar('$_addedServicesCount service${_addedServicesCount > 1 ? 's' : ''} added to cart!');
          }
        }
      }
    } catch (e) {
      print('❌ Error processing service ${service.name}: $e');
      // Skip failed service and continue
      _currentServiceIndex++;
      await _processNextService();
    }
  }

  Future<bool?> _showSkipDialog(String serviceName) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.skip_next_rounded, color: kPrimary, size: 24),
            const SizedBox(width: 10),
            Text(
              'Skip Service?',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You didn\'t book "$serviceName".',
              style: GoogleFonts.poppins(color: kText, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Do you want to skip it and continue with the remaining services?',
              style: GoogleFonts.poppins(color: kMuted, fontSize: 13),
            ),
            if (_currentServiceIndex < _pendingServices.length - 1) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: kMuted, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${_pendingServices.length - _currentServiceIndex - 1} more service(s) remaining',
                      style: GoogleFonts.poppins(color: kMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Stop Here',
              style: GoogleFonts.poppins(color: kMuted, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(
              'Skip & Continue',
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(message, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: kSuccess,
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
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Color _getLevelColor() {
    switch (widget.package.packageLevel.toLowerCase()) {
      case 'basic':
      case 'budget':
        return const Color(0xFF22C55E);
      case 'premium':
      case 'luxury':
        return const Color(0xFFEAB308);
      default:
        return kPrimary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'venues':
      case 'venue':
        return Icons.apartment_rounded;
      case 'photographers':
      case 'photography':
        return Icons.camera_alt_rounded;
      case 'catering':
        return Icons.restaurant_rounded;
      case 'cake':
        return Icons.cake_rounded;
      case 'flower shops':
      case 'flowers':
        return Icons.local_florist_rounded;
      case 'decor & lighting':
      case 'decoration':
        return Icons.lightbulb_rounded;
      case 'music & entertainment':
      case 'music':
        return Icons.music_note_rounded;
      case 'event planners & coordinators':
        return Icons.event_rounded;
      case 'card printing':
        return Icons.mail_rounded;
      case 'jewelry & accessories':
        return Icons.diamond_rounded;
      case 'car rental & transportation':
        return Icons.directions_car_rounded;
      case 'gift & souvenir':
        return Icons.card_giftcard_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }
}
