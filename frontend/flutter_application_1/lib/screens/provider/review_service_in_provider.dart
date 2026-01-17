// lib/screens/provider/review_service_in_provider.dart
// Service Reviews Page for Provider - with Reply functionality

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:async';

import 'package:flutter_application_1/services/user_service/review_service.dart';
import 'package:flutter_application_1/services/chat_provider_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 🎨 Design Tokens - Modern Purple Theme
// ═══════════════════════════════════════════════════════════════════════════
const Color kPrimaryColor = Color(0xFF6C63FF);
const Color kPrimaryLight = Color(0xFFE8E6FF);
const Color kBackgroundColor = Color(0xFFF8F9FC);
const Color kTextColor = Color(0xFF1A1D29);
const Color kTextSecondary = Color(0xFF6B7280);
const Color kMutedColor = Color(0xFF6B7280);
const Color kSuccessColor = Color(0xFF10B981);
const Color kWarningColor = Color(0xFFF59E0B);
const Color kErrorColor = Color(0xFFEF4444);

/// =====================
/// Service Reviews Provider Page
/// =====================
class ServiceReviewsProviderPage extends StatefulWidget {
  final String serviceId;
  final String serviceName;

  const ServiceReviewsProviderPage({
    super.key,
    required this.serviceId,
    required this.serviceName,
  });

  @override
  State<ServiceReviewsProviderPage> createState() => _ServiceReviewsProviderPageState();
}

class _ServiceReviewsProviderPageState extends State<ServiceReviewsProviderPage> {
  bool _isLoading = true;
  List<dynamic> _reviews = [];
  double _averageRating = 0.0;
  int _totalReviews = 0;
  String _filterOption = 'all'; // all, positive, negative
  String _sortOption = 'newest'; // newest, oldest, highest, lowest
  
  // Track which reviews have been replied to
  final Set<String> _repliedReviewIds = {};

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      setState(() => _isLoading = true);
      
      final result = await ReviewService.getServiceReviews(
        serviceId: widget.serviceId,
        limit: 100, // Get all reviews
      );
      
      if (mounted) {
        setState(() {
          _reviews = result['reviews'] ?? [];
          _averageRating = (result['averageRating'] ?? 0).toDouble();
          _totalReviews = result['totalReviews'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading reviews: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<dynamic> get _filteredReviews {
    List<dynamic> filtered = List.from(_reviews);
    
    // Apply filter
    if (_filterOption == 'positive') {
      filtered = filtered.where((r) => (r.rating ?? 0) >= 4).toList();
    } else if (_filterOption == 'negative') {
      filtered = filtered.where((r) => (r.rating ?? 0) < 4).toList();
    }
    
    // Apply sort
    filtered.sort((a, b) {
      switch (_sortOption) {
        case 'oldest':
          return (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now());
        case 'highest':
          return (b.rating ?? 0).compareTo(a.rating ?? 0);
        case 'lowest':
          return (a.rating ?? 0).compareTo(b.rating ?? 0);
        default: // newest
          return (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now());
      }
    });
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1100;
        final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1100;

        if (isDesktop || isTablet) {
          return _buildWebLayout(isDesktop);
        }
        return _buildMobileLayout();
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 🌐 WEB LAYOUT - Modern Dashboard Style
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildWebLayout(bool isDesktop) {
    final filtered = _filteredReviews;
    final positiveCount = _reviews.where((r) => (r.rating ?? 0) >= 4).length;
    final negativeCount = _reviews.where((r) => (r.rating ?? 0) < 4).length;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Column(
        children: [
          // Modern Top Bar
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: kBackgroundColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.arrowLeft, size: 18, color: kTextSecondary),
                          const SizedBox(width: 8),
                          Text('Back', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: kTextSecondary)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.star_rounded, size: 20, color: Colors.amber),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Service Reviews', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: kTextColor)),
                      Text(widget.serviceName, style: GoogleFonts.poppins(fontSize: 13, color: kTextSecondary), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                // Average Rating Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.amber.shade600, Colors.amber.shade500]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 18, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(_averageRating.toStringAsFixed(1), style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                      Text(' ($_totalReviews)', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                : _reviews.isEmpty
                    ? _buildEmptyState()
                    : SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 24, vertical: 32),
                        child: Center(
                          child: Container(
                            constraints: BoxConstraints(maxWidth: isDesktop ? 1100 : double.infinity),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left - Stats & Filters
                                SizedBox(
                                  width: isDesktop ? 320 : 280,
                                  child: Column(
                                    children: [
                                      // Stats Card
                                      Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                                                  child: const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                                                ),
                                                const SizedBox(width: 12),
                                                Text('Rating Overview', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: kTextColor)),
                                              ],
                                            ),
                                            const SizedBox(height: 24),
                                            Text(_averageRating.toStringAsFixed(1), style: GoogleFonts.poppins(fontSize: 48, fontWeight: FontWeight.w800, color: Colors.amber.shade700)),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: List.generate(5, (i) => Icon(Icons.star_rounded, size: 20, color: i < _averageRating.round() ? Colors.amber : Colors.grey.shade300)),
                                            ),
                                            const SizedBox(height: 8),
                                            Text('$_totalReviews reviews', style: GoogleFonts.poppins(fontSize: 13, color: kTextSecondary)),
                                            const SizedBox(height: 24),
                                            const Divider(),
                                            const SizedBox(height: 16),
                                            _buildWebStatRow('Positive', positiveCount, kSuccessColor),
                                            const SizedBox(height: 12),
                                            _buildWebStatRow('Negative', negativeCount, kErrorColor),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      // Filter Card
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Filters', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: kTextColor)),
                                            const SizedBox(height: 16),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: [
                                                _buildWebFilterChip('All', 'all'),
                                                _buildWebFilterChip('Positive', 'positive'),
                                                _buildWebFilterChip('Negative', 'negative'),
                                              ],
                                            ),
                                            const SizedBox(height: 20),
                                            Text('Sort by', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: kTextColor)),
                                            const SizedBox(height: 12),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: [
                                                _buildWebSortChip('Newest', 'newest'),
                                                _buildWebSortChip('Oldest', 'oldest'),
                                                _buildWebSortChip('Highest', 'highest'),
                                                _buildWebSortChip('Lowest', 'lowest'),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                // Right - Reviews List
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 16),
                                        child: Text('${filtered.length} Reviews', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: kTextSecondary)),
                                      ),
                                      if (filtered.isEmpty)
                                        _buildNoFilterResults()
                                      else
                                        ...filtered.map((review) => _buildReviewCard(review)).toList(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebStatRow(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 10),
        Text(label, style: GoogleFonts.poppins(fontSize: 13, color: kTextSecondary)),
        const Spacer(),
        Text('$count', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: kTextColor)),
      ],
    );
  }

  Widget _buildWebFilterChip(String label, String value) {
    final isSelected = _filterOption == value;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _filterOption = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? kPrimaryColor : kBackgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : kTextSecondary)),
        ),
      ),
    );
  }

  Widget _buildWebSortChip(String label, String value) {
    final isSelected = _sortOption == value;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _sortOption = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? kPrimaryLight : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? kPrimaryColor : Colors.grey.shade300),
          ),
          child: Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? kPrimaryColor : kTextSecondary)),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 📱 MOBILE LAYOUT
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout() {
    final filtered = _filteredReviews;
    final positiveCount = _reviews.where((r) => (r.rating ?? 0) >= 4).length;
    final negativeCount = _reviews.where((r) => (r.rating ?? 0) < 4).length;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          _buildSliverAppBar(),
          
          // Content
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: kPrimaryColor),
              ),
            )
          else if (_reviews.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Summary Card
                  _buildSummaryCard(positiveCount, negativeCount),
                  
                  const SizedBox(height: 16),
                  
                  // Filter & Sort Row
                  _buildFilterSortRow(),
                  
                  const SizedBox(height: 16),
                  
                  // Reviews List
                  if (filtered.isEmpty)
                    _buildNoFilterResults()
                  else
                    ...filtered.map((review) => _buildReviewCard(review)).toList(),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: kBackgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: kTextColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, kBackgroundColor],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(60, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Service Reviews',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: kTextColor,
                              ),
                            ),
                            Text(
                              widget.serviceName,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: kMutedColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(int positiveCount, int negativeCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rating Circle
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimaryColor.withOpacity(0.1), kPrimaryColor.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: kPrimaryColor.withOpacity(0.2), width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _averageRating.toStringAsFixed(1),
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: kPrimaryColor,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    return Icon(
                      i < _averageRating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 10,
                      color: Colors.amber,
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_totalReviews Reviews',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: kTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildMiniStat(
                      icon: LucideIcons.thumbsUp,
                      color: kSuccessColor,
                      count: positiveCount,
                      label: 'Positive',
                    ),
                    const SizedBox(width: 16),
                    _buildMiniStat(
                      icon: LucideIcons.thumbsDown,
                      color: kErrorColor,
                      count: negativeCount,
                      label: 'Negative',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required Color color,
    required int count,
    required String label,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$count',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: kTextColor,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: kMutedColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterSortRow() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Filter Chips
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all', LucideIcons.list),
                  const SizedBox(width: 8),
                  _buildFilterChip('Positive', 'positive', LucideIcons.thumbsUp),
                  const SizedBox(width: 8),
                  _buildFilterChip('Negative', 'negative', LucideIcons.thumbsDown),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Sort Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: kBackgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sortOption,
                isDense: true,
                icon: Icon(LucideIcons.chevronDown, size: 16, color: kMutedColor),
                items: [
                  DropdownMenuItem(value: 'newest', child: Text('Newest', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600))),
                  DropdownMenuItem(value: 'oldest', child: Text('Oldest', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600))),
                  DropdownMenuItem(value: 'highest', child: Text('Highest', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600))),
                  DropdownMenuItem(value: 'lowest', child: Text('Lowest', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600))),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _sortOption = value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _filterOption == value;
    
    return GestureDetector(
      onTap: () => setState(() => _filterOption = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor : kBackgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? kPrimaryColor : Colors.grey.shade200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : kMutedColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : kMutedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(dynamic review) {
    final userName = review.userName ?? 'Anonymous';
    final rating = (review.rating ?? 0).toDouble();
    final comment = review.comment ?? '';
    final date = review.createdAt ?? DateTime.now();
    final userId = review.userId?.toString() ?? '';
    final reviewId = review.id?.toString() ?? '';
    final isPositive = rating >= 4;
    final hasReplied = _repliedReviewIds.contains(reviewId);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isPositive 
                              ? [kSuccessColor.withOpacity(0.7), kSuccessColor]
                              : [kWarningColor.withOpacity(0.7), kWarningColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: (isPositive ? kSuccessColor : kWarningColor).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Name & Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              color: kTextColor,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _formatDate(date),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: kMutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Rating Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isPositive 
                            ? kSuccessColor.withOpacity(0.1) 
                            : kWarningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isPositive 
                              ? kSuccessColor.withOpacity(0.3) 
                              : kWarningColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: isPositive ? kSuccessColor : kWarningColor,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            rating.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800,
                              color: isPositive ? kSuccessColor : kWarningColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Comment
                if (comment.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(LucideIcons.quote, size: 16, color: kMutedColor.withOpacity(0.5)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            comment,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: kTextColor,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Action Buttons
          Container(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                // Reply Button - Changes to "Already Replied" after sending
                Expanded(
                  child: hasReplied 
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: kSuccessColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kSuccessColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.checkCircle, size: 16, color: kSuccessColor),
                            const SizedBox(width: 8),
                            Text(
                              'Already Replied',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: kSuccessColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    : OutlinedButton.icon(
                        onPressed: () => _showReplyDialog(review, userName, userId, reviewId),
                        icon: Icon(LucideIcons.messageCircle, size: 16, color: kPrimaryColor),
                        label: Text(
                          'Reply to Customer',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: kPrimaryColor,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: kPrimaryColor.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  void _showReplyDialog(dynamic review, String userName, String userId, String reviewId) {
    final controller = TextEditingController();
    bool isSending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(LucideIcons.messageCircle, color: kPrimaryColor, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reply to Review',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: kTextColor,
                                ),
                              ),
                              Text(
                                'Send a message to $userName',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: kMutedColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: kBackgroundColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(LucideIcons.x, size: 18, color: kMutedColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Review Quote
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: kBackgroundColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.quote, size: 14, color: kMutedColor),
                              const SizedBox(width: 8),
                              Text(
                                'Original Review',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: kMutedColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            review.comment ?? 'No comment',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: kTextColor,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                '${(review.rating ?? 0).toStringAsFixed(1)} rating',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: kMutedColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Message Input
                    Text(
                      'Your Message',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: kTextColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: controller,
                      maxLines: 4,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Thank you for your feedback! We appreciate...',
                        hintStyle: GoogleFonts.poppins(color: kMutedColor, fontSize: 13),
                        filled: true,
                        fillColor: kBackgroundColor,
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: kPrimaryColor, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                color: kMutedColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: isSending ? null : () async {
                              if (controller.text.trim().isEmpty) {
                                _showPopupMessage(
                                  context,
                                  'Please write a message',
                                  LucideIcons.alertCircle,
                                  kWarningColor,
                                  isError: true,
                                );
                                return;
                              }

                              if (userId.isEmpty) {
                                _showPopupMessage(
                                  context,
                                  'Cannot send message: User information not available',
                                  LucideIcons.userX,
                                  kErrorColor,
                                  isError: true,
                                );
                                return;
                              }

                              setModalState(() => isSending = true);

                              try {
                                final result = await ChatProviderService.startChatWithUser(
                                  userId,
                                  controller.text.trim(),
                                );

                                if (mounted) {
                                  Navigator.pop(context);
                                  
                                  // Mark this review as replied
                                  if (result['success'] == true) {
                                    setState(() {
                                      _repliedReviewIds.add(reviewId);
                                    });
                                  }
                                  
                                  _showPopupMessage(
                                    context,
                                    'Message sent successfully to $userName!',
                                    LucideIcons.checkCircle,
                                    kSuccessColor,
                                    isError: false,
                                  );
                                }
                              } catch (e) {
                                print('Error sending message: $e');
                                setModalState(() => isSending = false);
                                _showPopupMessage(
                                  context,
                                  'Failed to send message. Please try again.',
                                  LucideIcons.alertCircle,
                                  kErrorColor,
                                  isError: true,
                                );
                              }
                            },
                            icon: isSending 
                                ? const SizedBox(
                                    width: 16, 
                                    height: 16, 
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2, 
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(LucideIcons.send, size: 18),
                            label: Text(
                              isSending ? 'Sending...' : 'Send Message',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: kPrimaryColor.withOpacity(0.6),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPopupMessage(
    BuildContext context,
    String message,
    IconData icon,
    Color color, {
    required bool isError,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                isError ? 'Oops!' : 'Success!',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: kTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: kMutedColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isError ? kErrorColor : kSuccessColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'OK',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.messageSquare, size: 48, color: Colors.amber),
            ),
            const SizedBox(height: 20),
            Text(
              'No Reviews Yet',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This service hasn\'t received any reviews yet.\nCheck back later!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: kMutedColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadReviews,
              icon: Icon(LucideIcons.refreshCw, size: 18),
              label: Text(
                'Refresh',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoFilterResults() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.searchX, size: 40, color: kMutedColor),
          const SizedBox(height: 12),
          Text(
            'No reviews match this filter',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try selecting a different filter option',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: kMutedColor,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => setState(() => _filterOption = 'all'),
            child: Text(
              'Show All Reviews',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: kPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} months ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
