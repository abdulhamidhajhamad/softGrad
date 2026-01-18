// lib/screens/user/web/pages/web_cart_page.dart
//
// ✅ Web Cart Page
// ✅ Full cart view with checkout summary
// ✅ Edit/remove items

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../web_theme.dart';
import 'package:flutter_application_1/services/payment_service/cart_service.dart';
import 'package:flutter_application_1/screens/user/payment/cart.dart';
import 'package:flutter_application_1/screens/user/payment/checkout.dart';

class WebCartPage extends StatefulWidget {
  const WebCartPage({super.key});

  @override
  State<WebCartPage> createState() => _WebCartPageState();
}

class _WebCartPageState extends State<WebCartPage> {
  bool _isLoading = true;
  CartResponse? _cartData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final cart = await CartService.getCart();
      setState(() {
        _cartData = cart;
        _isLoading = false;
      });
      
      if (cart != null) {
        CartStore.instance.updateFromBackend(cart.items);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _removeItem(String serviceId) async {
    try {
      final updatedCart = await CartService.removeFromCart(serviceId);
      setState(() => _cartData = updatedCart);
      CartStore.instance.remove(serviceId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Item removed successfully'),
            backgroundColor: kWebSuccess,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: kWebError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kWebPrimary))
          : _error != null
              ? _buildErrorState()
              : _cartData == null || _cartData!.items.isEmpty
                  ? _buildEmptyState()
                  : _buildCartContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: kWebError),
          const SizedBox(height: 16),
          Text('Something went wrong', style: WebTypography.h5),
          const SizedBox(height: 8),
          Text(_error!, style: WebTypography.body.copyWith(color: kWebTextMuted)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadCart,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kWebPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: kWebPrimary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_cart_outlined, size: 56, color: kWebPrimary),
          ),
          const SizedBox(height: 32),
          Text('Your cart is empty', style: WebTypography.h4),
          const SizedBox(height: 12),
          Text(
            'Start exploring our services and add them to your cart',
            style: WebTypography.body.copyWith(color: kWebTextMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to search
            },
            icon: const Icon(Icons.explore_rounded),
            label: const Text('Explore Services'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kWebPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cart items
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text('Shopping Cart', style: WebTypography.h3),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: kWebPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_cartData!.items.length} items',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kWebPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Items list
              Expanded(
                child: ListView.separated(
                  itemCount: _cartData!.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return _CartItemCard(
                      item: _cartData!.items[index],
                      onRemove: () => _removeItem(_cartData!.items[index].serviceId),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(width: 32),
        
        // Summary sidebar
        SizedBox(
          width: 380,
          child: _buildSummaryCard(),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final subtotal = _cartData!.totalAmount;
    final serviceFee = subtotal * 0.05; // 5% service fee
    final total = subtotal + serviceFee;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: WebDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Order Summary', style: WebTypography.h5),
          
          const SizedBox(height: 24),
          
          _buildSummaryRow('Subtotal', '₪${subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 12),
          _buildSummaryRow('Service Fee (5%)', '₪${serviceFee.toStringAsFixed(2)}'),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: WebTypography.h5),
              Text(
                '₪${total.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: kWebPrimary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Promo code
          TextField(
            decoration: InputDecoration(
              hintText: 'Promo code',
              hintStyle: GoogleFonts.poppins(fontSize: 14, color: kWebTextMuted),
              suffixIcon: TextButton(
                onPressed: () {},
                child: Text(
                  'Apply',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: kWebPrimary,
                  ),
                ),
              ),
              filled: true,
              fillColor: kWebBgSecondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Checkout button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _cartData != null ? () {
                // Navigate to checkout
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CheckoutPage(cartData: _cartData!)),
                );
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: kWebPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Proceed to Checkout',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Continue shopping
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                // Navigate back to explore
              },
              child: Text(
                'Continue Shopping',
                style: GoogleFonts.poppins(
                  color: kWebPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Security badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_rounded, size: 16, color: kWebTextMuted),
              const SizedBox(width: 8),
              Text(
                'Secure Checkout',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: kWebTextMuted,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.verified_user_rounded, size: 16, color: kWebTextMuted),
              const SizedBox(width: 8),
              Text(
                'SSL Protected',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: kWebTextMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: WebTypography.body.copyWith(color: kWebTextMuted)),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CartItemCard extends StatefulWidget {
  final CartItemBackend item;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    required this.onRemove,
  });

  @override
  State<_CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends State<_CartItemCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kWebBgCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isHovered ? WebShadows.md : WebShadows.sm,
          border: Border.all(color: _isHovered ? kWebPrimary.withOpacity(0.2) : kWebBorder),
        ),
        child: Row(
          children: [
            // Image
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: kWebBgSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: item.imageUrl!,
                        fit: BoxFit.cover,
                      )
                    : Center(
                        child: Icon(Icons.image_rounded, size: 32, color: kWebTextMuted),
                      ),
              ),
            ),
            
            const SizedBox(width: 20),
            
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service name
                  Text(
                    item.serviceName,
                    style: WebTypography.h6,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // Company
                  Text(
                    item.companyName,
                    style: WebTypography.caption,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Booking details
                  Row(
                    children: [
                      _buildDetailChip(Icons.calendar_today_rounded, _formatDate(item.bookingDetails.date)),
                      const SizedBox(width: 8),
                      if (item.bookingDetails.startHour != null && item.bookingDetails.endHour != null)
                        _buildDetailChip(
                          Icons.access_time_rounded,
                          '${item.bookingDetails.startHour}:00 - ${item.bookingDetails.endHour}:00',
                        ),
                    ],
                  ),
                  
                  if (item.packageName != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: kWebPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.inventory_2_rounded, size: 12, color: kWebPrimary),
                          const SizedBox(width: 4),
                          Text(
                            'Part of: ${item.packageName}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: kWebPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(width: 20),
            
            // Price & Actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₪${item.price.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: kWebPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: kWebError,
                  tooltip: 'Remove item',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kWebBgSecondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: kWebTextMuted),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: kWebTextBody,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
