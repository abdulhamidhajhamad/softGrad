// lib/screens/user/web/pages/web_search_page.dart
//
// ✅ Web Search/Explore Page
// ✅ Grid layout with filters and sorting
// ✅ Service cards with hover effects

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../web_theme.dart';
import 'package:flutter_application_1/services/user_service/home_user_service.dart';
import 'web_service_detail_dialog.dart';

class WebSearchPage extends StatefulWidget {
  const WebSearchPage({super.key});

  @override
  State<WebSearchPage> createState() => _WebSearchPageState();
}

class _WebSearchPageState extends State<WebSearchPage> {
  List<HomeTrendingModel> _allServices = [];
  List<HomeTrendingModel> _filtered = [];
  bool _isLoading = true;

  String _searchQuery = '';
  String? _selectedCategory;
  String _sortBy = 'rating';

  final List<String> _categories = [
    'Venues', 'Photographers', 'Catering', 'Cake',
    'Music', 'Decoration', 'Event Planners', 'Flower Shops',
  ];

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      final services = await HomeUserService.getHomeTrendingServices();
      setState(() {
        _allServices = services;
        _filtered = services;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    List<HomeTrendingModel> result = [..._allServices];

    // Category filter
    if (_selectedCategory != null) {
      result = result.where((s) =>
        s.category.toLowerCase() == _selectedCategory!.toLowerCase()
      ).toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      result = result.where((s) {
        final text = '${s.name} ${s.company} ${s.category}'.toLowerCase();
        return text.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Sorting
    switch (_sortBy) {
      case 'price_low':
        result.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        result.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating':
      default:
        result.sort((a, b) => b.rating.compareTo(a.rating));
    }

    setState(() => _filtered = result);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text('Explore Services', style: WebTypography.h2),
          const SizedBox(height: 8),
          Text(
            'Find the perfect vendors for your event',
            style: WebTypography.body.copyWith(color: kWebTextMuted),
          ),
          
          const SizedBox(height: 24),
          
          // Filters Row
          _buildFiltersRow(),
          
          const SizedBox(height: 24),
          
          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: kWebPrimary))
                : _filtered.isEmpty
                    ? _buildEmptyState()
                    : _buildResultsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersRow() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: WebDecorations.card,
      child: Row(
        children: [
          // Search
          Expanded(
            flex: 2,
            child: TextField(
              onChanged: (value) {
                _searchQuery = value;
                _applyFilters();
              },
              decoration: InputDecoration(
                hintText: 'Search services...',
                hintStyle: GoogleFonts.poppins(fontSize: 14, color: kWebTextMuted),
                prefixIcon: const Icon(Icons.search_rounded, color: kWebTextMuted),
                filled: true,
                fillColor: kWebBgSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Category Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: kWebBgSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<String>(
              value: _selectedCategory,
              hint: Text('Category', style: GoogleFonts.poppins(fontSize: 14, color: kWebTextMuted)),
              underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text('All Categories', style: GoogleFonts.poppins(fontSize: 14)),
                ),
                ..._categories.map((cat) => DropdownMenuItem<String>(
                  value: cat,
                  child: Text(cat, style: GoogleFonts.poppins(fontSize: 14)),
                )),
              ],
              onChanged: (value) {
                setState(() => _selectedCategory = value);
                _applyFilters();
              },
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Sort Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: kWebBgSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<String>(
              value: _sortBy,
              underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              items: [
                DropdownMenuItem(
                  value: 'rating',
                  child: Text('Top Rated', style: GoogleFonts.poppins(fontSize: 14)),
                ),
                DropdownMenuItem(
                  value: 'price_low',
                  child: Text('Price: Low to High', style: GoogleFonts.poppins(fontSize: 14)),
                ),
                DropdownMenuItem(
                  value: 'price_high',
                  child: Text('Price: High to Low', style: GoogleFonts.poppins(fontSize: 14)),
                ),
              ],
              onChanged: (value) {
                setState(() => _sortBy = value!);
                _applyFilters();
              },
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Result count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: kWebPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_filtered.length} results',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kWebPrimary,
              ),
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
          Icon(Icons.search_off_rounded, size: 64, color: kWebTextMuted),
          const SizedBox(height: 16),
          Text('No services found', style: WebTypography.h5),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search query',
            style: WebTypography.body.copyWith(color: kWebTextMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.8,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: _filtered.length,
      itemBuilder: (context, index) {
        return _ServiceCard(service: _filtered[index]);
      },
    );
  }
}

class _ServiceCard extends StatefulWidget {
  final HomeTrendingModel service;

  const _ServiceCard({required this.service});

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _isHovered = false;

  void _openServiceDetail() {
    final s = widget.service;
    showWebServiceDetail(
      context: context,
      data: WebServiceData(
        id: s.id,
        name: s.name,
        company: s.company,
        providerId: s.providerId,
        category: s.category,
        description: s.desc,
        imageUrl: s.imageUrl,
        city: '',
        price: s.price,
        rating: s.rating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.service;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _openServiceDetail,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: kWebBgCard,
            borderRadius: BorderRadius.circular(20),
            boxShadow: _isHovered ? WebShadows.lg : WebShadows.sm,
            border: Border.all(
              color: _isHovered ? kWebPrimary.withOpacity(0.3) : kWebBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with category badge
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        color: kWebBgSecondary,
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: s.imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                              imageUrl: s.imageUrl,
                              fit: BoxFit.cover,
                            )
                          : Center(
                              child: Icon(Icons.store_rounded, size: 48, color: kWebTextMuted),
                            ),
                    ),
                  ),
                  // Category badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: kWebPrimary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        s.category,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Favorite button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.favorite_border_rounded, size: 18),
                        color: kWebTextMuted,
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      style: WebTypography.h6,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.company,
                      style: WebTypography.caption,
                      maxLines: 1,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 16, color: kWebWarning),
                        const SizedBox(width: 4),
                        Text(
                          s.rating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '₪${s.price.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: kWebPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
