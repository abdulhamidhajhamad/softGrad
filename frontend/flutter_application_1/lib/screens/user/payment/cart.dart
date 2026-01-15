import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'checkout.dart';
import 'package:flutter_application_1/services/payment_service/cart_service.dart';

// Theme (نفس الألوان الأصلية)
const Color kPrimary = Color.fromARGB(215, 20, 20, 215);
const Color kBg = Color(0xFFF6F7FB);
const Color kText = Color(0xFF0B1220);
const Color kMuted = Color(0xFF6B7280);
const Color kDanger = Color(0xFFEF4444);

// -----------------------------------------------------------------------------
// Cart Page
// -----------------------------------------------------------------------------
class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _loading = true;
  String? _error;
  CartResponse? _cartData;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final cart = await CartService.getCart();
      setState(() {
        _cartData = cart;
        _loading = false;
      });
      
      // ✅ Sync local CartStore with backend data
      if (cart != null) {
        CartStore.instance.updateFromBackend(cart.items);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _removeItem(String serviceId) async {
    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Removing item...',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
          ),
          duration: const Duration(milliseconds: 800),
          behavior: SnackBarBehavior.floating,
          backgroundColor: kText,
        ),
      );

      final updatedCart = await CartService.removeFromCart(serviceId);
      
      setState(() {
        _cartData = updatedCart;
      });

      // ✅ Update local CartStore so the service can be added again
      CartStore.instance.remove(serviceId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Item removed ✓',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green.shade700,
            duration: const Duration(milliseconds: 1100),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to remove: ${e.toString()}',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: kDanger,
          ),
        );
      }
    }
  }

  Future<void> _clearCart() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Clear Cart?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
        ),
        content: Text(
          'This will remove all items from your cart.',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kDanger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Clear',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await CartService.clearCart();
        setState(() {
          _cartData = CartResponse(userId: '', items: [], totalAmount: 0.0);
        });

        // ✅ Clear local CartStore so services can be added again
        CartStore.instance.clear();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Cart cleared',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: kText,
              duration: const Duration(milliseconds: 1100),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to clear: ${e.toString()}',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: kDanger,
            ),
          );
        }
      }
    }
  }

  String _money(double v) => '₪${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded, color: kText),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: kBg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Cart',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w900,
            color: kText,
          ),
        ),
        actions: [
          if (_cartData != null && _cartData!.items.isNotEmpty)
            TextButton(
              onPressed: _clearCart,
              child: Text(
                'Clear',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w900,
                  color: kPrimary,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: kPrimary),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: kDanger),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load cart',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: kText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: kMuted,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _loadCart,
                          icon: const Icon(Icons.refresh),
                          label: Text(
                            'Retry',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _cartData == null || _cartData!.items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 80,
                              color: Colors.black.withOpacity(0.15),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Your cart is empty.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                color: kMuted,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Stack(
                      children: [
                        ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
                          itemCount: _cartData!.items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final item = _cartData!.items[i];
                            return _CartCard(
                              item: item,
                              onRemove: () => _removeItem(item.serviceId),
                            );
                          },
                        ),

                        // Bottom summary
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: SafeArea(
                            top: false,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border(
                                  top: BorderSide(
                                      color: Colors.black.withOpacity(0.06)),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.12),
                                    blurRadius: 24,
                                    offset: const Offset(0, -12),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Total',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w800,
                                            color: kMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          _money(_cartData!.totalAmount),
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w900,
                                            color: kText,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => CheckoutPage(
                                              cartData: _cartData!,
                                              onPaymentSuccess: () {
                                                // Reload cart after successful payment
                                                _loadCart();
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: kText,
                                        elevation: 0,
                                        padding:
                                            const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                      ),
                                      icon: const Icon(Icons.lock_rounded,
                                          color: Color.fromARGB(
                                              165, 244, 255, 179)),
                                      label: Text(
                                        'Checkout',
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
                          ),
                        ),
                      ],
                    ),
    );
  }
}

class _CartCard extends StatelessWidget {
  final CartItemBackend item;
  final VoidCallback onRemove;

  const _CartCard({required this.item, required this.onRemove});

  String _money(double v) => '₪${v.toStringAsFixed(0)}';

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImg = item.imageUrl != null && item.imageUrl!.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 74,
                height: 74,
                child: hasImg
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _ImgPlaceholder(),
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: const Color(0xFFF1F5F9),
                            alignment: Alignment.center,
                            child: const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2.2),
                            ),
                          );
                        },
                      )
                    : _ImgPlaceholder(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.serviceName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w900,
                      color: kText,
                      fontSize: 13.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.companyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: kMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Tag(
                        text: item.bookingType,
                        icon: Icons.event_available_rounded,
                      ),
                      _Tag(
                        text: _formatDate(item.bookingDetails.date),
                        icon: Icons.calendar_month_rounded,
                      ),
                    ],
                  ),
                  if (item.packageName != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory_2_rounded,
                              size: 12, color: Colors.amber.shade800),
                          const SizedBox(width: 4),
                          Text(
                            item.packageName!,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _money(item.price),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900,
                    color: kText,
                    fontSize: 13.2,
                  ),
                ),
                const SizedBox(height: 10),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_rounded),
                  color: kDanger,
                  tooltip: 'Remove',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ImgPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F9),
      alignment: Alignment.center,
      child: Icon(Icons.image, color: Colors.black.withOpacity(0.35)),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final IconData icon;

  const _Tag({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: kPrimary),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w900,
              color: kText,
              fontSize: 11.6,
            ),
          ),
        ],
      ),
    );
  }
}

// أضف هذا الكود في نهاية ملف cart.dart

// -----------------------------------------------------------------------------
// CartStore - In-Memory Cart State Management
// -----------------------------------------------------------------------------
class CartItem {
  final String id;
  final String serviceName;
  final String companyName;
  final double price;
  final String? imageUrl;

  CartItem({
    required this.id,
    required this.serviceName,
    required this.companyName,
    required this.price,
    this.imageUrl,
  });
}

class CartStore {
  // Singleton pattern
  static final CartStore instance = CartStore._internal();
  
  factory CartStore() {
    return instance;
  }
  
  CartStore._internal();

  // State
  final ValueNotifier<int> count = ValueNotifier<int>(0);
  final ValueNotifier<List<CartItem>> itemsListenable = ValueNotifier<List<CartItem>>([]);

  // Getters
  List<CartItem> get items => itemsListenable.value;

  // Methods
  bool contains(String serviceId) {
    return items.any((item) => item.id == serviceId);
  }

  void add(CartItem item) {
    if (!contains(item.id)) {
      final newList = [...items, item];
      itemsListenable.value = newList;
      count.value = newList.length;
    }
  }

  void remove(String serviceId) {
    final newList = items.where((item) => item.id != serviceId).toList();
    itemsListenable.value = newList;
    count.value = newList.length;
  }

  void clear() {
    itemsListenable.value = [];
    count.value = 0;
  }

  void updateFromBackend(List<CartItemBackend> backendItems) {
    final newList = backendItems.map((item) => CartItem(
      id: item.serviceId,
      serviceName: item.serviceName,
      companyName: item.companyName,
      price: item.price,
      imageUrl: item.imageUrl,
    )).toList();
    
    itemsListenable.value = newList;
    count.value = newList.length;
  }
}