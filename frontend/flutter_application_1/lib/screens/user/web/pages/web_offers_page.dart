// lib/screens/user/web/pages/web_offers_page.dart
//
// ✅ Web Offers/Deals Page
// ✅ Grid with offer cards showing discount badges
// ✅ Timer countdown for limited offers

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../web_theme.dart';
import 'package:flutter_application_1/services/user_service/offers_service.dart';
import 'web_service_detail_dialog.dart';

class WebOffersPage extends StatefulWidget {
  const WebOffersPage({super.key});

  @override
  State<WebOffersPage> createState() => _WebOffersPageState();
}

class _WebOffersPageState extends State<WebOffersPage> {
  List<OfferService> _offers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    try {
      final repo = OffersRepository();
      final offers = await repo.fetchActiveOffers();
      setState(() {
        _offers = offers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with banner
          _buildHeaderBanner(),
          
          const SizedBox(height: 32),
          
          // Stats row
          _buildStatsRow(),
          
          const SizedBox(height: 24),
          
          // Offers grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: kWebPrimary))
                : _offers.isEmpty
                    ? _buildEmptyState()
                    : _buildOffersGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kWebPrimary, kWebPrimaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🔥 Hot Deals & Offers',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Exclusive discounts on premium services. Limited time offers - book now before they expire!',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  '${_offers.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Active Offers',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    // Calculate stats
    final totalSavings = _offers.fold<double>(
      0, (sum, o) => sum + o.savingsAmount,
    );
    final avgDiscount = _offers.isEmpty
        ? 0
        : _offers.fold<int>(0, (sum, o) => sum + o.discountPercentage) ~/ _offers.length;
    final expiringToday = _offers.where((o) {
      if (o.offerEndDate == null) return false;
      final today = DateTime.now();
      return o.offerEndDate!.day == today.day &&
             o.offerEndDate!.month == today.month &&
             o.offerEndDate!.year == today.year;
    }).length;

    return Row(
      children: [
        _buildStatCard(
          icon: Icons.savings_rounded,
          title: 'Total Savings',
          value: '₪${totalSavings.toStringAsFixed(0)}',
          color: kWebSuccess,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          icon: Icons.percent_rounded,
          title: 'Avg. Discount',
          value: '$avgDiscount%',
          color: kWebPrimary,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          icon: Icons.timer_rounded,
          title: 'Expiring Today',
          value: '$expiringToday',
          color: kWebError,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: WebDecorations.card.copyWith(
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: WebTypography.caption),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer_outlined, size: 64, color: kWebTextMuted),
          const SizedBox(height: 16),
          Text('No Active Offers', style: WebTypography.h5),
          const SizedBox(height: 8),
          Text(
            'Check back later for exclusive deals',
            style: WebTypography.body.copyWith(color: kWebTextMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildOffersGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
      itemCount: _offers.length,
      itemBuilder: (context, index) {
        return _OfferCard(offer: _offers[index]);
      },
    );
  }
}

class _OfferCard extends StatefulWidget {
  final OfferService offer;

  const _OfferCard({required this.offer});

  @override
  State<_OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<_OfferCard> {
  bool _isHovered = false;

  void _openOfferDetail() {
    final o = widget.offer;
    showWebServiceDetail(
      context: context,
      data: WebServiceData(
        id: o.id,
        name: o.name,
        company: o.company,
        providerId: o.providerId,
        category: o.category,
        description: o.description,
        imageUrl: o.imageUrl,
        city: o.city,
        price: o.discountedPrice,
        oldPrice: o.originalPrice,
        rating: o.rating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.offer;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _openOfferDetail,
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
              // Image with discount badge
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
                        child: o.imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: o.imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              )
                            : Center(
                                child: Icon(Icons.local_offer_rounded, size: 48, color: kWebTextMuted),
                              ),
                      ),
                    ),
                    // Discount badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: kWebError,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '-${o.discountPercentage}%',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Time remaining
                  if (o.remainingTimeString.isNotEmpty)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              o.remainingTimeString,
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
            
            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: kWebPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        o.category,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: kWebPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Name
                    Text(
                      o.name,
                      style: WebTypography.h6,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Company
                    Text(
                      o.company,
                      style: WebTypography.caption,
                      maxLines: 1,
                    ),
                    
                    const Spacer(),
                    
                    // Prices
                    Row(
                      children: [
                        Text(
                          '₪${o.originalPrice.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            decoration: TextDecoration.lineThrough,
                            color: kWebTextMuted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₪${o.discountedPrice.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: kWebPrimary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: kWebSuccess.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Save ₪${o.savingsAmount.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: kWebSuccess,
                            ),
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
