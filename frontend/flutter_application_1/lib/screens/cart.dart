import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'checkout.dart';

// -----------------------------------------------------------------------------
// Theme (keep same feel as your app)
// -----------------------------------------------------------------------------
const Color kPrimary = Color.fromARGB(215, 20, 20, 215);
const Color kBg = Color(0xFFF6F7FB);
const Color kText = Color(0xFF0B1220);
const Color kMuted = Color(0xFF6B7280);
const Color kDanger = Color(0xFFEF4444);

// -----------------------------------------------------------------------------
// ✅ Booking type resolver (based on Category) + Order-only counter
// -----------------------------------------------------------------------------
String _bookingTypeForCategory(String category) {
  switch (category) {
    case 'Venues':
    case 'Photographers':
    case 'Music & Entertainment':
    case 'Wedding Planners & Coordinators':
      return 'hourly';

    case 'Decor & Lighting':
    case 'Car Rental & Transportation':
      return 'full-day';

    case 'Catering':
    case 'Cake':
      return 'capacity';

    case 'Flower Shops':
    case 'Card Printing':
    case 'Jewelry & Accessories':
    case 'Gift & Souvenir':
      return 'order';

    default:
      return 'order';
  }
}

int _orderOnlyCount(List<CartItem> items) {
  int c = 0;
  for (final it in items) {
    if (_bookingTypeForCategory(it.category) == 'order') c++;
  }
  return c;
}

// -----------------------------------------------------------------------------
// Cart Model
// -----------------------------------------------------------------------------
class CartItem {
  final String id;
  final String title;
  final String providerName;
  final double price;
  final String imageUrl;
  final String category;
  final String city;

  const CartItem({
    required this.id,
    required this.title,
    required this.providerName,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.city,
  });
}

// -----------------------------------------------------------------------------
// Cart Store (singleton)
// -----------------------------------------------------------------------------
class CartStore {
  CartStore._();
  static final CartStore instance = CartStore._();

  final ValueNotifier<List<CartItem>> _items =
      ValueNotifier<List<CartItem>>([]);
  final ValueNotifier<int> count = ValueNotifier<int>(0);

  ValueListenable<List<CartItem>> get itemsListenable => _items;
  List<CartItem> get items => List.unmodifiable(_items.value);

  bool contains(String id) => _items.value.any((e) => e.id == id);

  void add(CartItem item) {
    final list = [..._items.value];

    // ✅ prevent duplicates (UX)
    final exists = list.any((e) => e.id == item.id);
    if (!exists) list.add(item);

    _items.value = list;

    // ✅ Badge count: ONLY "order" items
    count.value = _orderOnlyCount(list);
  }

  void removeAt(int index) {
    final list = [..._items.value];
    if (index < 0 || index >= list.length) return;
    list.removeAt(index);
    _items.value = list;

    // ✅ Badge count: ONLY "order" items
    count.value = _orderOnlyCount(list);
  }

  void removeById(String id) {
    final list = [..._items.value]..removeWhere((e) => e.id == id);
    _items.value = list;

    // ✅ Badge count: ONLY "order" items
    count.value = _orderOnlyCount(list);
  }

  void clear() {
    _items.value = [];

    // ✅ Badge count: ONLY "order" items
    count.value = 0;
  }

  double total() {
    double s = 0;
    for (final i in _items.value) {
      s += i.price;
    }
    return s;
  }
}

// -----------------------------------------------------------------------------
// Cart Page
// -----------------------------------------------------------------------------
class CartPage extends StatelessWidget {
  const CartPage({super.key});

  String _money(double v) => '₪${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        automaticallyImplyLeading: false, // ✅ kept as-is
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded, color: kText),
          onPressed: () => Navigator.pop(context), // ✅ يرجع للصفحة السابقة
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
          TextButton(
            onPressed: () {
              CartStore.instance.clear();
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
            },
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
      body: ValueListenableBuilder<List<CartItem>>(
        valueListenable: CartStore.instance.itemsListenable,
        builder: (_, items, __) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  'Your cart is empty.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: kMuted,
                    height: 1.4,
                  ),
                ),
              ),
            );
          }

          return Stack(
            children: [
              ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final it = items[i];
                  return _CartCard(
                    item: it,
                    onRemove: () =>
                        CartStore.instance.removeAt(i), // ✅ cancel/remove
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
                        top: BorderSide(color: Colors.black.withOpacity(0.06)),
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
                                _money(CartStore.instance.total()),
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
                              final snapshot =
                                  List<CartItem>.from(CartStore.instance.items);

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CheckoutPage(
                                    items: snapshot,
                                    amount: CartStore.instance.total(),
                                    currency: '₪',
                                    onPaymentSuccess: () =>
                                        CartStore.instance.clear(),
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kText,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            icon: Icon(Icons.lock_rounded,
                                color:
                                    const Color.fromARGB(165, 244, 255, 179)),
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
          );
        },
      ),
    );
  }
}

class _CartCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;

  const _CartCard({required this.item, required this.onRemove});

  String _money(double v) => '₪${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    final hasImg = item.imageUrl.trim().isNotEmpty;

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
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 74,
                height: 74,
                child: hasImg
                    ? Image.network(
                        item.imageUrl,
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
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.2),
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
                    item.title,
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
                    item.providerName,
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
                      _Tag(text: item.category, icon: Icons.grid_view_rounded),
                      _Tag(text: item.city, icon: Icons.location_on_rounded),
                    ],
                  ),
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
                  onPressed: onRemove, // ✅ cancel item
                  icon: const Icon(Icons.delete_rounded),
                  color: kDanger,
                  tooltip: 'Remove',
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
