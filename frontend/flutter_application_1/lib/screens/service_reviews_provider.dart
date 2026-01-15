// lib/screens/service_reviews_provider.dart
// Modern Service Reviews Page for Provider - with Reply Functionality

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_1/services/chat_provider_service.dart';
import 'chat_screen.dart';

// =====================
// 🎨 Colors - Same as project
// =====================
const Color kPrimaryColor = Color.fromARGB(215, 20, 20, 215);
const Color kBackgroundColor = Color(0xFFF7F8FC);
const Color kTextColor = Color(0xFF0B1220);
const Color kMutedColor = Color(0xFF6B7280);
const Color kSuccessColor = Color(0xFF10B981);
const Color kWarningColor = Color(0xFFF59E0B);
const Color kDangerColor = Color(0xFFEF4444);

/// Model for service review
class ServiceReview {
  final String id;
  final String visitorId; // User ID for chat functionality
  final String customerName;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final String? customerAvatarUrl;

  ServiceReview({
    required this.id,
    this.visitorId = '',
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.customerAvatarUrl,
  });
}

/// Modern Service Reviews Screen for Provider
class ServiceReviewsProviderScreen extends StatefulWidget {
  final Map<String, dynamic> service;
  final List<ServiceReview> reviews;

  const ServiceReviewsProviderScreen({
    Key? key,
    required this.service,
    this.reviews = const [],
  }) : super(key: key);

  @override
  State<ServiceReviewsProviderScreen> createState() => _ServiceReviewsProviderScreenState();
}

class _ServiceReviewsProviderScreenState extends State<ServiceReviewsProviderScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  
  String _filterOption = 'all'; // all, positive, negative
  String _sortOption = 'newest'; // newest, oldest, highest, lowest
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  double get _avgRating {
    if (widget.reviews.isEmpty) return 0;
    final sum = widget.reviews.fold<int>(0, (s, r) => s + r.rating);
    return sum / widget.reviews.length;
  }

  List<ServiceReview> get _filteredReviews {
    List<ServiceReview> filtered = List.from(widget.reviews);
    
    // Apply filter
    if (_filterOption == 'positive') {
      filtered = filtered.where((r) => r.rating >= 4).toList();
    } else if (_filterOption == 'negative') {
      filtered = filtered.where((r) => r.rating < 4).toList();
    }
    
    // Apply sort
    switch (_sortOption) {
      case 'oldest':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'highest':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'lowest':
        filtered.sort((a, b) => a.rating.compareTo(b.rating));
        break;
      default: // newest
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    
    return filtered;
  }

  Map<int, int> get _ratingDistribution {
    Map<int, int> dist = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (var r in widget.reviews) {
      if (r.rating >= 1 && r.rating <= 5) {
        dist[r.rating] = (dist[r.rating] ?? 0) + 1;
      }
    }
    return dist;
  }

  Widget _buildDisplayImage(String? imageSource) {
    if (imageSource == null || imageSource.isEmpty) {
      return const Icon(Icons.person, color: Colors.white, size: 22);
    }
    
    if (imageSource.startsWith('http')) {
      return ClipOval(
        child: Image.network(
          imageSource,
          fit: BoxFit.cover,
          width: 48,
          height: 48,
          errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 22),
        ),
      );
    }

    if (!kIsWeb) {
      return ClipOval(
        child: Image.file(
          File(imageSource),
          fit: BoxFit.cover,
          width: 48,
          height: 48,
          errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 22),
        ),
      );
    }

    return const Icon(Icons.person, color: Colors.white, size: 22);
  }

  @override
  Widget build(BuildContext context) {
    final filteredReviews = _filteredReviews;
    
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Modern App Bar
            _buildSliverAppBar(),
            
            // Content
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Rating Summary Card
                  _buildRatingSummaryCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Filter & Sort Row
                  _buildFilterSortRow(),
                  
                  const SizedBox(height: 16),
                  
                  // Reviews List
                  if (filteredReviews.isEmpty)
                    _buildEmptyState()
                  else
                    ...filteredReviews.asMap().entries.map((entry) {
                      final index = entry.key;
                      final review = entry.value;
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(milliseconds: 300 + (index * 100)),
                        curve: Curves.easeOut,
                        builder: (_, value, child) => Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(opacity: value, child: child),
                        ),
                        child: _buildReviewCard(review),
                      );
                    }).toList(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
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
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kPrimaryColor.withOpacity(0.08), Colors.white],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(60, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Customer Reviews',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: kTextColor,
                    ),
                  ),
                  Text(
                    widget.service['name'] ?? 'Service',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: kMutedColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingSummaryCard() {
    final dist = _ratingDistribution;
    final total = widget.reviews.length;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: widget.reviews.isEmpty
          ? _buildNoReviewsSummary()
          : Row(
              children: [
                // Rating Score
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: _avgRating),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOut,
                        builder: (_, value, __) => Text(
                          value.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: kTextColor,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Icon(
                            i < _avgRating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 20,
                            color: Colors.amber,
                          ),
                        )),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${widget.reviews.length} reviews',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: kPrimaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Vertical Divider
                Container(
                  width: 1,
                  height: 120,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.black.withOpacity(0.06),
                ),
                
                // Rating Distribution
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [5, 4, 3, 2, 1].map((star) {
                      final count = dist[star] ?? 0;
                      final percent = total > 0 ? count / total : 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Text(
                              '$star',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: kMutedColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: percent),
                                  duration: const Duration(milliseconds: 800),
                                  curve: Curves.easeOut,
                                  builder: (_, value, __) => LinearProgressIndicator(
                                    value: value,
                                    backgroundColor: kBackgroundColor,
                                    valueColor: AlwaysStoppedAnimation(_getRatingColor(star)),
                                    minHeight: 8,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 28,
                              child: Text(
                                '$count',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: kMutedColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildNoReviewsSummary() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(LucideIcons.star, color: Colors.amber[600], size: 40),
        ),
        const SizedBox(height: 16),
        Text(
          'No reviews yet',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: kTextColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Be patient, reviews will come soon!',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: kMutedColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSortRow() {
    return Row(
      children: [
        // Filter Dropdown
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _filterOption,
                isExpanded: true,
                icon: Icon(LucideIcons.chevronDown, size: 18, color: kMutedColor),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kTextColor,
                ),
                items: [
                  _buildDropdownItem('all', 'All Reviews', LucideIcons.layoutList),
                  _buildDropdownItem('positive', 'Positive (4-5)', LucideIcons.thumbsUp),
                  _buildDropdownItem('negative', 'Critical (1-3)', LucideIcons.thumbsDown),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _filterOption = value);
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Sort Dropdown
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sortOption,
                isExpanded: true,
                icon: Icon(LucideIcons.chevronDown, size: 18, color: kMutedColor),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kTextColor,
                ),
                items: [
                  _buildDropdownItem('newest', 'Newest', LucideIcons.arrowDown),
                  _buildDropdownItem('oldest', 'Oldest', LucideIcons.arrowUp),
                  _buildDropdownItem('highest', 'Highest', LucideIcons.trendingUp),
                  _buildDropdownItem('lowest', 'Lowest', LucideIcons.trendingDown),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _sortOption = value);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  DropdownMenuItem<String> _buildDropdownItem(String value, String label, IconData icon) {
    return DropdownMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16, color: kPrimaryColor),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String message = 'No reviews to display';
    if (_filterOption == 'positive') {
      message = 'No positive reviews yet';
    } else if (_filterOption == 'negative') {
      message = 'No critical reviews - great job!';
    }
    
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.messageSquare, size: 48, color: kMutedColor.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: kMutedColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ServiceReview review) {
    final isPositive = review.rating >= 4;
    final ratingColor = _getRatingColor(review.rating);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with avatar and rating
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [ratingColor.withOpacity(0.8), ratingColor],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: ratingColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Center(
                    child: review.customerAvatarUrl != null && review.customerAvatarUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _buildDisplayImage(review.customerAvatarUrl),
                          )
                        : Text(
                            review.customerName.isNotEmpty ? review.customerName[0].toUpperCase() : 'U',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontSize: 20,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                // Name and date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.customerName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: kTextColor,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(review.createdAt),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: kMutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // Rating Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: ratingColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: ratingColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 18, color: ratingColor),
                      const SizedBox(width: 4),
                      Text(
                        '${review.rating}.0',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w800,
                          color: ratingColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Comment
          if (review.comment.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kBackgroundColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.quote, size: 16, color: kPrimaryColor.withOpacity(0.5)),
                        const SizedBox(width: 8),
                        Text(
                          'Customer Feedback',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: kMutedColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      review.comment,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: kTextColor.withOpacity(0.8),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Reply Button
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openChatWithCustomer(review),
                icon: Icon(LucideIcons.messageCircle, size: 18, color: kPrimaryColor),
                label: Text(
                  'Reply to Customer',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: kPrimaryColor,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: kPrimaryColor.withOpacity(0.3)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Open chat directly with the customer without initial message
  Future<void> _openChatWithCustomer(ServiceReview review) async {
    if (review.visitorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot identify the customer', style: GoogleFonts.poppins()),
          backgroundColor: kWarningColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Start chat without sending initial message
      final result = await ChatProviderService.startChatWithUser(
        review.visitorId,
        '', // No initial message
      );

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        final chatId = result['chatId'] ?? result['data']?['chatId'];
        if (chatId != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                conversationId: chatId,
                customerName: review.customerName,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to open chat', style: GoogleFonts.poppins()),
              backgroundColor: kDangerColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}', style: GoogleFonts.poppins()),
            backgroundColor: kDangerColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Color _getRatingColor(int rating) {
    if (rating >= 4) return kSuccessColor;
    if (rating >= 3) return kWarningColor;
    return kDangerColor;
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
