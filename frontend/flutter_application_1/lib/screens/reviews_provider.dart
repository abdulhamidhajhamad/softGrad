// lib/screens/reviews_provider.dart
// Modern Reviews Hub - Shows services and navigates to service-specific reviews

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter_application_1/services/service_service.dart';
import 'package:flutter_application_1/services/user_service/review_service.dart';
import 'provider/review_service_in_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 🎨 Design Tokens - Modern Purple Theme
// ═══════════════════════════════════════════════════════════════════════════
const Color kPrimaryColor = Color(0xFF6C63FF);
const Color kPrimaryLight = Color(0xFFE8E6FF);
const Color kBackgroundColor = Color(0xFFF8F9FC);
const Color kCardColor = Colors.white;
const Color kTextPrimary = Color(0xFF1A1D29);
const Color kTextSecondary = Color(0xFF6B7280);
const Color kSuccessColor = Color(0xFF10B981);
const Color kWarningColor = Color(0xFFF59E0B);
const Color kErrorColor = Color(0xFFEF4444);

// ═══════════════════════════════════════════════════════════════════════════
// 📱 Main Reviews Hub Screen
// ═══════════════════════════════════════════════════════════════════════════
class ReviewsProviderScreen extends StatefulWidget {
  final String? providerId;

  const ReviewsProviderScreen({Key? key, this.providerId}) : super(key: key);

  @override
  State<ReviewsProviderScreen> createState() => _ReviewsProviderScreenState();
}

class _ReviewsProviderScreenState extends State<ReviewsProviderScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _services = [];
  Map<String, _ServiceReviewStats> _reviewStats = {};
  String? _errorMessage;

  // Overall stats
  int _totalReviews = 0;
  double _overallRating = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load provider's services
      final services = await ServiceService.fetchMyServices();
      _services = List<Map<String, dynamic>>.from(services);

      // Load review stats for each service
      int totalReviews = 0;
      double totalRating = 0;
      int servicesWithRating = 0;

      for (var service in _services) {
        final serviceId = service['_id']?.toString() ?? service['id']?.toString() ?? '';
        if (serviceId.isNotEmpty) {
          try {
            final result = await ReviewService.getServiceReviews(
              serviceId: serviceId,
              limit: 1, // Just need stats
            );
            
            final avgRating = (result['averageRating'] ?? 0).toDouble();
            final reviewCount = (result['totalReviews'] ?? 0) as int;
            
            _reviewStats[serviceId] = _ServiceReviewStats(
              averageRating: avgRating,
              totalReviews: reviewCount,
            );
            
            totalReviews += reviewCount;
            if (avgRating > 0) {
              totalRating += avgRating;
              servicesWithRating++;
            }
          } catch (e) {
            _reviewStats[serviceId] = _ServiceReviewStats(
              averageRating: 0,
              totalReviews: 0,
            );
          }
        }
      }

      _totalReviews = totalReviews;
      _overallRating = servicesWithRating > 0 ? totalRating / servicesWithRating : 0;

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
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
  // 🌐 WEB LAYOUT
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildWebLayout(bool isDesktop) {
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
                Text('Reviews Hub', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: kTextPrimary)),
                const Spacer(),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _loadData,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: kPrimaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.refreshCw, size: 16, color: kPrimaryColor),
                          const SizedBox(width: 8),
                          Text('Refresh', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: kPrimaryColor)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                : _errorMessage != null
                    ? _buildErrorState()
                    : _services.isEmpty
                        ? _buildNoServicesState()
                        : SingleChildScrollView(
                            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 24, vertical: 32),
                            child: Center(
                              child: Container(
                                constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : double.infinity),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Overall Stats Row
                                    _buildWebOverallStats(),
                                    const SizedBox(height: 32),
                                    // Services Section Header
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(10)),
                                          child: const Icon(LucideIcons.layoutGrid, size: 18, color: kPrimaryColor),
                                        ),
                                        const SizedBox(width: 12),
                                        Text('Your Services', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: kTextPrimary)),
                                        const Spacer(),
                                        Text('${_services.length} services', style: GoogleFonts.poppins(fontSize: 14, color: kTextSecondary)),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    // Services Grid
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: isDesktop ? 3 : 2,
                                        crossAxisSpacing: 20,
                                        mainAxisSpacing: 20,
                                        childAspectRatio: 1.1,
                                      ),
                                      itemCount: _services.length,
                                      itemBuilder: (context, index) => _buildWebServiceCard(_services[index]),
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

  Widget _buildWebOverallStats() {
    return Row(
      children: [
        // Overall Rating Card
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade600, Colors.amber.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.star_rounded, size: 22, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Text('Overall Rating', style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _overallRating > 0 ? _overallRating.toStringAsFixed(1) : '—',
                      style: GoogleFonts.poppins(fontSize: 48, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    if (_overallRating > 0) ...[
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text('/ 5', style: GoogleFonts.poppins(fontSize: 20, color: Colors.white70)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (i) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.star_rounded,
                      size: 24,
                      color: i < _overallRating.round() ? Colors.white : Colors.white.withOpacity(0.3),
                    ),
                  )),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        // Total Reviews Card
        Expanded(
          child: _buildWebStatCard(
            'Total Reviews',
            _totalReviews.toString(),
            LucideIcons.messageSquare,
            kPrimaryColor,
            subtitle: 'across all services',
          ),
        ),
        const SizedBox(width: 20),
        // Services Card
        Expanded(
          child: _buildWebStatCard(
            'Active Services',
            _services.where((s) => s['isActive'] == true).length.toString(),
            LucideIcons.briefcase,
            kSuccessColor,
            subtitle: 'with reviews enabled',
          ),
        ),
      ],
    );
  }

  Widget _buildWebStatCard(String label, String value, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 16),
          Text(value, style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w700, color: kTextPrimary)),
          Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: kTextSecondary)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: kTextSecondary)),
          ],
        ],
      ),
    );
  }

  Widget _buildWebServiceCard(Map<String, dynamic> service) {
    final serviceId = service['_id']?.toString() ?? service['id']?.toString() ?? '';
    final serviceName = service['serviceName']?.toString() ?? service['name']?.toString() ?? 'Service';
    final category = service['category']?.toString() ?? '';
    final imageUrl = (service['images'] as List?)?.firstOrNull?.toString();
    final stats = _reviewStats[serviceId] ?? _ServiceReviewStats(averageRating: 0, totalReviews: 0);
    final isActive = service['isActive'] == true;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _openServiceReviews(serviceId, serviceName),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 100,
                      width: double.infinity,
                      child: imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(color: kBackgroundColor),
                              errorWidget: (_, __, ___) => Container(
                                color: kPrimaryLight,
                                child: const Icon(LucideIcons.image, color: kPrimaryColor, size: 32),
                              ),
                            )
                          : Container(
                              color: kPrimaryLight,
                              child: const Icon(LucideIcons.image, color: kPrimaryColor, size: 32),
                            ),
                    ),
                    // Rating Badge
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: stats.averageRating > 0 ? Colors.amber : Colors.grey.shade600,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              stats.averageRating > 0 ? stats.averageRating.toStringAsFixed(1) : 'New',
                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Status Badge
                    if (!isActive)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: kErrorColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Hidden', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                      ),
                  ],
                ),
              ),
              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName,
                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: kTextPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (category.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(category, style: GoogleFonts.poppins(fontSize: 12, color: kTextSecondary)),
                      ],
                      const Spacer(),
                      Row(
                        children: [
                          Icon(LucideIcons.messageSquare, size: 14, color: kTextSecondary),
                          const SizedBox(width: 6),
                          Text(
                            '${stats.totalReviews} ${stats.totalReviews == 1 ? 'review' : 'reviews'}',
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: kTextSecondary),
                          ),
                          const Spacer(),
                          Icon(LucideIcons.chevronRight, size: 18, color: kPrimaryColor),
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

  // ══════════════════════════════════════════════════════════════════════════
  // 📱 MOBILE LAYOUT
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 180,
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
                icon: const Icon(LucideIcons.arrowLeft, color: kTextPrimary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(LucideIcons.refreshCw, color: kPrimaryColor, size: 20),
                  onPressed: _loadData,
                ),
              ),
            ],
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
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            // Rating Circle
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.amber.shade600, Colors.amber.shade500],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _overallRating > 0 ? _overallRating.toStringAsFixed(1) : '—',
                                    style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(5, (i) => Icon(
                                      Icons.star_rounded,
                                      size: 10,
                                      color: i < _overallRating.round() ? Colors.white : Colors.white.withOpacity(0.4),
                                    )),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Title & Stats
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Reviews Hub', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: kTextPrimary)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$_totalReviews total reviews • ${_services.length} services',
                                    style: GoogleFonts.poppins(fontSize: 13, color: kTextSecondary),
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
          ),
          // Content
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
            )
          else if (_errorMessage != null)
            SliverFillRemaining(child: _buildErrorState())
          else if (_services.isEmpty)
            SliverFillRemaining(child: _buildNoServicesState())
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildMobileServiceCard(_services[index]),
                  childCount: _services.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileServiceCard(Map<String, dynamic> service) {
    final serviceId = service['_id']?.toString() ?? service['id']?.toString() ?? '';
    final serviceName = service['serviceName']?.toString() ?? service['name']?.toString() ?? 'Service';
    final category = service['category']?.toString() ?? '';
    final imageUrl = (service['images'] as List?)?.firstOrNull?.toString();
    final stats = _reviewStats[serviceId] ?? _ServiceReviewStats(averageRating: 0, totalReviews: 0);
    final isActive = service['isActive'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openServiceReviews(serviceId, serviceName),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(color: kBackgroundColor),
                                errorWidget: (_, __, ___) => Container(
                                  color: kPrimaryLight,
                                  child: const Icon(LucideIcons.image, color: kPrimaryColor, size: 24),
                                ),
                              )
                            : Container(
                                color: kPrimaryLight,
                                child: const Icon(LucideIcons.image, color: kPrimaryColor, size: 24),
                              ),
                      ),
                      if (!isActive)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text('Hidden', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName,
                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: kTextPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (category.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(category, style: GoogleFonts.poppins(fontSize: 12, color: kTextSecondary)),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Rating
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: stats.averageRating > 0 ? Colors.amber.withOpacity(0.15) : kBackgroundColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded, size: 14, color: stats.averageRating > 0 ? Colors.amber : kTextSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  stats.averageRating > 0 ? stats.averageRating.toStringAsFixed(1) : 'New',
                                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: stats.averageRating > 0 ? Colors.amber.shade700 : kTextSecondary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Reviews count
                          Icon(LucideIcons.messageSquare, size: 14, color: kTextSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${stats.totalReviews}',
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: kTextSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arrow
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: kPrimaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.chevronRight, size: 20, color: kPrimaryColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 🔧 Helper Methods
  // ══════════════════════════════════════════════════════════════════════════
  void _openServiceReviews(String serviceId, String serviceName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceReviewsProviderPage(
          serviceId: serviceId,
          serviceName: serviceName,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kErrorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(LucideIcons.alertCircle, size: 48, color: kErrorColor),
            ),
            const SizedBox(height: 20),
            Text('Something went wrong', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: kTextPrimary)),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t load your reviews.\nPlease try again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: kTextSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: Text('Try Again', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoServicesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kPrimaryLight,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(LucideIcons.briefcase, size: 56, color: kPrimaryColor),
            ),
            const SizedBox(height: 24),
            Text('No Services Yet', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: kTextPrimary)),
            const SizedBox(height: 10),
            Text(
              'Create your first service to start\nreceiving customer reviews.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: kTextSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 📊 Helper Classes
// ═══════════════════════════════════════════════════════════════════════════
class _ServiceReviewStats {
  final double averageRating;
  final int totalReviews;

  _ServiceReviewStats({
    required this.averageRating,
    required this.totalReviews,
  });
}
