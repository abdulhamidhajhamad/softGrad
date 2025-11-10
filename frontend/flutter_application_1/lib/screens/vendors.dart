// lib/screens/vendors.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'vendor_profile.dart';

class VendorsListPage extends StatefulWidget {
  const VendorsListPage({Key? key}) : super(key: key);

  // Vendor data model
  static final List<Map<String, dynamic>> vendorData = [
    {
      'type': 'Wedding halls and Outdoor Gardens',
      'name': 'Venues',
      'icon': Icons.location_city,
    },
    {
      'type': 'Photo and Video Coverage',
      'name': 'Photographers',
      'icon': Icons.camera_alt,
    },
    {
      'type': 'Food and Beverages',
      'name': 'Catering',
      'icon': Icons.restaurant_menu,
    },
    {
      'type': 'Wedding Cakes and Special Sweets',
      'name': 'Cake',
      'icon': Icons.cake,
    },
    {
      'type': 'Bouquets',
      'name': 'Flower Shops',
      'icon': Icons.local_florist,
    },
    {
      'type': 'Decorations and Lighting',
      'name': 'Decor & Lighting',
      'icon': Icons.lightbulb_outline,
    },
    {
      'type': 'DJs and Live Bands',
      'name': 'Music & Entertainment',
      'icon': Icons.music_note,
    },
    {
      'type': 'Full Wedding Management and Coordination',
      'name': 'Wedding Planners & Coordinators',
      'icon': Icons.event,
    },
    {
      'type': 'Printed and Digital Wedding Invitations',
      'name': 'Card Printing',
      'icon': Icons.mail_outline,
    },
    {
      'type': 'Rings, Crowns and Accessories',
      'name': 'Jewelry & Accessories',
      'icon': Icons.diamond,
    },
    {
      'type': 'Bridal Car and Guest Transportation',
      'name': 'Car Rental & Transportation',
      'icon': Icons.directions_car,
    },
    {
      'type': 'Customized Favors and Gifts',
      'name': 'Gift & Souvenir',
      'icon': Icons.card_giftcard,
    },
  ];

  @override
  State<VendorsListPage> createState() => _VendorsListPageState();
}

class _VendorsListPageState extends State<VendorsListPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Color get brandBlue => const Color.fromARGB(185, 255, 106, 0);

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // Case-insensitive matching on both `name` and `type`.
  List<Map<String, dynamic>> _filterVendors(String query) {
    final base = VendorsListPage.vendorData
        .where((v) => v['type'] != 'Equipment Rentals')
        .toList();

    if (query.trim().isEmpty) return base;

    final q = query.toLowerCase();
    return base.where((v) {
      final name = (v['name'] as String).toLowerCase();
      final type = (v['type'] as String).toLowerCase();
      return name.contains(q) || type.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text;
    final filteredVendors = _filterVendors(query);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'All Vendors',
          style: GoogleFonts.poppins(
            fontSize: 23,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 4, 50, 143),
        elevation: 0.5,
        foregroundColor: const Color.fromARGB(255, 239, 239, 248),
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Search bar with clear UX affordances
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Semantics(
              label: 'Search vendors',
              textField: true,
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                style: GoogleFonts.poppins(fontSize: 14.5),
                decoration: InputDecoration(
                  hintText: 'Search Vendors...',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                            _searchFocusNode.requestFocus();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: brandBlue, width: 1.4),
                  ),
                ),
              ),
            ),
          ),

          // Results count (optional subtle helper)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                query.trim().isEmpty
                    ? 'Showing ${filteredVendors.length} categories'
                    : 'Found ${filteredVendors.length} for "$query"',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),

          // Animated results area
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: filteredVendors.isEmpty
                  ? _EmptyStateMessage(
                      key: const ValueKey('empty'),
                      query: query,
                    )
                  : ListView.builder(
                      key: ValueKey('list-$query'),
                      itemCount: filteredVendors.length,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemBuilder: (context, index) {
                        final vendor = filteredVendors[index];
                        return _AnimatedVendorTile(
                          delay: Duration(milliseconds: 30 * (index % 10)),
                          child: _VendorTile(
                            vendor: vendor,
                            brandBlue: brandBlue,
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Subtle entrance animation for list items without third-party packages.
class _AnimatedVendorTile extends StatelessWidget {
  final Widget child;
  final Duration delay;

  const _AnimatedVendorTile({
    Key? key,
    required this.child,
    this.delay = Duration.zero,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TweenAnimationBuilder gives a smooth fade + slide on build.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      // Add a small delayed start for cascading effect.
      onEnd: () {},
      builder: (context, value, _) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 8),
            child: child,
          ),
        );
      },
      // Wrap with a delayed FutureBuilder for the stagger effect
      child: FutureBuilder<void>(
        future: Future<void>.delayed(delay),
        builder: (context, snap) {
          // Once delay completes, return the actual tile to animate
          return child;
        },
      ),
    );
  }
}

/// The existing tile layout and navigation behavior kept as-is.
class _VendorTile extends StatelessWidget {
  final Map<String, dynamic> vendor;
  final Color brandBlue;

  const _VendorTile({
    Key? key,
    required this.vendor,
    required this.brandBlue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        elevation: 1,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    VendorProfilePage(title: vendor['name'] as String),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  vendor['icon'] as IconData,
                  size: 28,
                  color: brandBlue,
                  semanticLabel: '${vendor['name']} icon',
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendor['name'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        vendor['type'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyStateMessage extends StatelessWidget {
  final String query;

  const _EmptyStateMessage({Key? key, required this.query}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final styleTitle = GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Colors.black,
    );
    final styleBody = GoogleFonts.poppins(
      fontSize: 13.5,
      color: Colors.grey.shade700,
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          key: const ValueKey('no-results'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text('No vendors found for your search.',
                style: styleTitle, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Try a different keyword or clear the search.',
              style: styleBody,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
