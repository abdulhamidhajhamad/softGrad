// lib/screens/user/web/pages/web_home_page.dart
//
// ✅ Modern Web Home Page
// ✅ Hero section, Quick Actions, Trending Services, Packages
// ✅ Clean, minimalist design with light purple accents

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../web_theme.dart';
import 'package:flutter_application_1/services/user_service/home_user_service.dart';
import 'web_service_detail_dialog.dart';

class WebHomePage extends StatefulWidget {
  final String userName;
  final Function(int) onNavigate;

  const WebHomePage({
    super.key,
    required this.userName,
    required this.onNavigate,
  });

  @override
  State<WebHomePage> createState() => _WebHomePageState();
}

class _WebHomePageState extends State<WebHomePage> {
  List<HomePackageModel> _packages = [];
  List<HomeTrendingModel> _trending = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final packages = await HomeUserService.getHomePackages();
      final trending = await HomeUserService.getHomeTrendingServices();
      
      setState(() {
        _packages = packages;
        _trending = trending;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final firstName = widget.userName.split(' ').first;
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: kWebPrimary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Hero Section
            _buildHeroSection(greeting, firstName),
            
            const SizedBox(height: 40),
            
            // ✅ Quick Actions
            _buildQuickActions(),
            
            const SizedBox(height: 40),
            
            if (_isLoading)
              _buildLoadingState()
            else ...[
              // ✅ Packages Section
              if (_packages.isNotEmpty) ...[
                _buildSectionHeader(
                  'Featured Packages',
                  'Curated deals for your perfect event',
                  Icons.auto_awesome_rounded,
                  onViewAll: () => widget.onNavigate(3),
                ),
                const SizedBox(height: 20),
                _buildPackagesGrid(),
                const SizedBox(height: 40),
              ],
              
              // ✅ Trending Section
              if (_trending.isNotEmpty) ...[
                _buildSectionHeader(
                  'Trending Services',
                  'Popular vendors in your area',
                  Icons.trending_up_rounded,
                  onViewAll: () => widget.onNavigate(1),
                ),
                const SizedBox(height: 20),
                _buildTrendingGrid(),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(String greeting, String firstName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: kWebHeroGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: kWebPrimary.withOpacity(0.3),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, $firstName! 👋',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Ready to plan your next amazing event?\nExplore services, packages, and exclusive offers.',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.85),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => widget.onNavigate(1),
                      icon: const Icon(Icons.search_rounded),
                      label: const Text('Explore Services'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: kWebPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: () => widget.onNavigate(4),
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text('AI Assistant'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54, width: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Icon(
              Icons.celebration_rounded,
              size: 100,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        _QuickActionCard(
          icon: Icons.search_rounded,
          label: 'Browse Services',
          color: const Color(0xFF6366F1),
          onTap: () => widget.onNavigate(1),
        ),
        const SizedBox(width: 16),
        _QuickActionCard(
          icon: Icons.local_offer_rounded,
          label: 'Hot Offers',
          color: const Color(0xFFEF4444),
          onTap: () => widget.onNavigate(2),
        ),
        const SizedBox(width: 16),
        _QuickActionCard(
          icon: Icons.inventory_2_rounded,
          label: 'Packages',
          color: const Color(0xFF10B981),
          onTap: () => widget.onNavigate(3),
        ),
        const SizedBox(width: 16),
        _QuickActionCard(
          icon: Icons.auto_awesome_rounded,
          label: 'AI Assistant',
          color: kWebPrimary,
          onTap: () => widget.onNavigate(4),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onViewAll,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kWebPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: kWebPrimary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: WebTypography.h4),
              Text(
                subtitle,
                style: WebTypography.body.copyWith(color: kWebTextMuted),
              ),
            ],
          ),
        ),
        if (onViewAll != null)
          TextButton.icon(
            onPressed: onViewAll,
            icon: const Text('View All'),
            label: const Icon(Icons.arrow_forward_rounded, size: 16),
            style: TextButton.styleFrom(foregroundColor: kWebPrimary),
          ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(60),
        child: Column(
          children: [
            const CircularProgressIndicator(color: kWebPrimary),
            const SizedBox(height: 16),
            Text(
              'Loading your dashboard...',
              style: WebTypography.body.copyWith(color: kWebTextMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackagesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: _packages.take(4).length,
      itemBuilder: (context, index) {
        return _PackageCard(package: _packages[index]);
      },
    );
  }

  Widget _buildTrendingGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: _trending.take(6).length,
      itemBuilder: (context, index) {
        return _TrendingCard(service: _trending[index]);
      },
    );
  }
}

// =====================================================
// 🧩 HELPER WIDGETS
// =====================================================

class _QuickActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _isHovered ? widget.color.withOpacity(0.1) : kWebBgCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _isHovered ? widget.color.withOpacity(0.3) : kWebBorder,
              ),
              boxShadow: _isHovered ? WebShadows.md : WebShadows.sm,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  widget.label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kWebTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PackageCard extends StatefulWidget {
  final HomePackageModel package;

  const _PackageCard({required this.package});

  @override
  State<_PackageCard> createState() => _PackageCardState();
}

class _PackageCardState extends State<_PackageCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.package;
    final discount = p.originalPrice > 0
        ? (((p.originalPrice - p.price) / p.originalPrice) * 100).round()
        : 0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
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
        child: Row(
          children: [
            // Image
            Container(
              width: 160,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                color: kWebBgSecondary,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                child: p.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: p.imageUrl,
                        fit: BoxFit.cover,
                        height: double.infinity,
                      )
                    : Center(
                        child: Icon(Icons.inventory_2_rounded, size: 48, color: kWebTextMuted),
                      ),
              ),
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.title,
                            style: WebTypography.h5,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (discount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: kWebDiscount,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '-$discount%',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.company,
                      style: WebTypography.caption,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: p.services.take(3).map((s) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: kWebPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            s,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: kWebPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          '₪${p.price.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: kWebPrimary,
                          ),
                        ),
                        if (p.originalPrice > p.price) ...[
                          const SizedBox(width: 8),
                          Text(
                            '₪${p.originalPrice.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: kWebTextMuted,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
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

class _TrendingCard extends StatefulWidget {
  final HomeTrendingModel service;

  const _TrendingCard({required this.service});

  @override
  State<_TrendingCard> createState() => _TrendingCardState();
}

class _TrendingCardState extends State<_TrendingCard> {
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
            // Image
            Expanded(
              flex: 3,
              child: Container(
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
                          width: double.infinity,
                        )
                      : Center(
                          child: Icon(Icons.store_rounded, size: 48, color: kWebTextMuted),
                        ),
                ),
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
                            fontSize: 14,
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
