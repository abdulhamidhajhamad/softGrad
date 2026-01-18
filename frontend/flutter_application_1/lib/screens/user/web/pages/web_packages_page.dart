// lib/screens/user/web/pages/web_packages_page.dart
//
// ✅ Web Packages Page
// ✅ Grid with package cards showing multiple services
// ✅ Discount calculations and service breakdown

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../web_theme.dart';
import 'package:flutter_application_1/services/package_service/package_service.dart';

class WebPackagesPage extends StatefulWidget {
  const WebPackagesPage({super.key});

  @override
  State<WebPackagesPage> createState() => _WebPackagesPageState();
}

class _WebPackagesPageState extends State<WebPackagesPage> {
  List<PackageModel> _packages = [];
  bool _isLoading = true;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    try {
      final packages = await PackageService.getActivePackages();
      setState(() {
        _packages = packages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<PackageModel> get _filteredPackages {
    if (_selectedCity == null) return _packages;
    return _packages.where((p) => p.city == _selectedCity).toList();
  }

  Set<String> get _allCities {
    return _packages.map((p) => p.city).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          
          const SizedBox(height: 24),
          
          // Filters
          _buildFilters(),
          
          const SizedBox(height: 24),
          
          // Packages grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: kWebPrimary))
                : _filteredPackages.isEmpty
                    ? _buildEmptyState()
                    : _buildPackagesGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Event Packages', style: WebTypography.h2),
              const SizedBox(height: 8),
              Text(
                'Complete packages with multiple services at discounted prices',
                style: WebTypography.body.copyWith(color: kWebTextMuted),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: kWebPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.inventory_2_rounded, color: kWebPrimary),
              const SizedBox(width: 12),
              Text(
                '${_packages.length} Packages Available',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kWebPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: WebDecorations.card,
      child: Row(
        children: [
          // City filter
          Text('Filter by City:', style: WebTypography.body),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: kWebBgSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<String>(
              value: _selectedCity,
              hint: Text('All Cities', style: GoogleFonts.poppins(fontSize: 14, color: kWebTextMuted)),
              underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text('All Cities', style: GoogleFonts.poppins(fontSize: 14)),
                ),
                ..._allCities.map((city) => DropdownMenuItem<String>(
                  value: city,
                  child: Text(city, style: GoogleFonts.poppins(fontSize: 14)),
                )),
              ],
              onChanged: (value) => setState(() => _selectedCity = value),
            ),
          ),
          
          const Spacer(),
          
          // Total savings info
          if (_packages.isNotEmpty) ...[
            Icon(Icons.savings_rounded, color: kWebSuccess, size: 20),
            const SizedBox(width: 8),
            Text(
              'Save up to ${_packages.map((p) => p.discountPercent).reduce((a, b) => a > b ? a : b).toStringAsFixed(0)}% on packages',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kWebSuccess,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: kWebTextMuted),
          const SizedBox(height: 16),
          Text('No Packages Available', style: WebTypography.h5),
          const SizedBox(height: 8),
          Text(
            'Check back later for bundled deals',
            style: WebTypography.body.copyWith(color: kWebTextMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildPackagesGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
      itemCount: _filteredPackages.length,
      itemBuilder: (context, index) {
        return _PackageCard(package: _filteredPackages[index]);
      },
    );
  }
}

class _PackageCard extends StatefulWidget {
  final PackageModel package;

  const _PackageCard({required this.package});

  @override
  State<_PackageCard> createState() => _PackageCardState();
}

class _PackageCardState extends State<_PackageCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.package;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: kWebBgCard,
          borderRadius: BorderRadius.circular(24),
          boxShadow: _isHovered ? WebShadows.lg : WebShadows.sm,
          border: Border.all(
            color: _isHovered ? kWebPrimary.withOpacity(0.3) : kWebBorder,
          ),
        ),
        child: Row(
          children: [
            // Image section
            Container(
              width: 280,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
                color: kWebBgSecondary,
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
                    child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: p.imageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          )
                        : Center(
                            child: Icon(Icons.inventory_2_rounded, size: 64, color: kWebTextMuted),
                          ),
                  ),
                  // Discount badge
                  if (p.discountPercent > 0)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: kWebError,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-${p.discountPercent.toStringAsFixed(0)}%',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  // City badge
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_rounded, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            p.city,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company & Name
                    Text(
                      p.companyName,
                      style: WebTypography.caption,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.packageName,
                      style: WebTypography.h5,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Categories
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: p.categories.take(4).map((cat) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: kWebPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          cat,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: kWebPrimary,
                          ),
                        ),
                      )).toList(),
                    ),
                    
                    const Spacer(),
                    
                    // Services count
                    Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: kWebSuccess, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${p.services.length} services included',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: kWebSuccess,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Prices
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₪${p.totalOriginal.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                decoration: TextDecoration.lineThrough,
                                color: kWebTextMuted,
                              ),
                            ),
                            Text(
                              '₪${p.totalPackage.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: kWebPrimary,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {
                            // TODO: Navigate to package details
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kWebPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'View Details',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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
    );
  }
}
