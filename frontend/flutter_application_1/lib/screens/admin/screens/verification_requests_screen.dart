// lib/screens/admin/screens/verification_requests_screen.dart
// شاشة طلبات التحقق للأدمن

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_application_1/screens/compliance_provider/compliance_provider_service.dart';
import 'package:flutter_application_1/services/admin_service/admin_service.dart';
import '../theme/app_theme.dart';

// ============================================================================
// 📋 VERIFICATION REQUESTS SCREEN
// ============================================================================
class VerificationRequestsScreen extends StatefulWidget {
  const VerificationRequestsScreen({Key? key}) : super(key: key);

  @override
  State<VerificationRequestsScreen> createState() => _VerificationRequestsScreenState();
}

class _VerificationRequestsScreenState extends State<VerificationRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // State
  bool _isLoading = true;
  String? _error;
  VerificationStats? _stats;
  List<ProviderForReview> _pendingProviders = [];
  List<ProviderForReview> _rejectedProviders = [];
  List<ProviderForReview> _expiredProviders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final results = await Future.wait([
        ComplianceProviderService.getVerificationStats(),
        ComplianceProviderService.getPendingReviewProviders(limit: 50),
        ComplianceProviderService.getProvidersByStatus(status: VerificationStatus.rejected, limit: 50),
        ComplianceProviderService.getExpiredProviders(limit: 50),
      ]);

      if (mounted) {
        setState(() {
          _stats = results[0] as VerificationStats;
          _pendingProviders = results[1] as List<ProviderForReview>;
          _rejectedProviders = results[2] as List<ProviderForReview>;
          _expiredProviders = results[3] as List<ProviderForReview>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleVerification(ProviderForReview provider, bool approved, {String? notes}) async {
    try {
      await ComplianceProviderService.adminVerification(
        providerId: provider.id,
        approved: approved,
        notes: notes,
        rejectionReason: approved ? null : notes,
      );

      // If rejected, start a chat with the provider and send the rejection reason
      if (!approved && notes != null && notes.isNotEmpty) {
        try {
          // Use userId for chat (the actual user account), fallback to provider.id if not available
          final chatUserId = provider.userId ?? provider.id;
          print('🔵 Starting chat with user: $chatUserId (userId: ${provider.userId}, providerId: ${provider.id})');
          
          final rejectionMessage = '❌ Your verification request has been rejected.\n\n📋 Reason: $notes\n\nIf you have any questions or want to appeal this decision, please reply to this message.';
          await AdminService.startChatWithUser(chatUserId, rejectionMessage);
          print('✅ Chat message sent successfully');
        } catch (chatError) {
          print('⚠️ Could not start chat: $chatError');
          // Don't fail the whole operation if chat fails
        }
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approved ? 'Provider verified successfully!' : 'Provider rejected and notified via chat'),
            backgroundColor: approved ? kSuccessColor : kErrorColor,
          ),
        );
        _loadData(); // Refresh data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: kErrorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.alertCircle, size: 48, color: kErrorColor),
          const SizedBox(height: 16),
          Text(
            'Failed to load data',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: GoogleFonts.poppins(color: kTextSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            label: Text('Retry', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
        if (isMobile) {
          return _buildMobileContent();
        } else {
          return _buildWebContent();
        }
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 📱 MOBILE CONTENT - Clean & Modern Layout
  // ═══════════════════════════════════════════════════════════════
  Widget _buildMobileContent() {
    return Column(
      children: [
        // ═══ COMPACT STATS ROW ═══
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildMiniStat(_stats?.total ?? 0, 'Total', kPrimaryColor),
              _buildStatDivider(),
              _buildMiniStat(_stats?.verified ?? 0, 'Verified', kSuccessColor),
              _buildStatDivider(),
              _buildMiniStat(_stats?.adminReview ?? 0, 'Pending', kWarningColor),
              _buildStatDivider(),
              _buildMiniStat(_stats?.rejected ?? 0, 'Rejected', kErrorColor),
            ],
          ),
        ),
        
        // ═══ TAB BAR - Simplified for Mobile ═══
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: kTextSecondary,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
            unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13),
            indicator: BoxDecoration(
              color: kPrimaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: const EdgeInsets.all(4),
            dividerColor: Colors.transparent,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.clock, size: 16),
                    const SizedBox(width: 6),
                    Text('Pending${_pendingProviders.isNotEmpty ? ' (${_pendingProviders.length})' : ''}'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.xCircle, size: 16),
                    const SizedBox(width: 6),
                    Text('Rejected${_rejectedProviders.isNotEmpty ? ' (${_rejectedProviders.length})' : ''}'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.alertTriangle, size: 16),
                    const SizedBox(width: 6),
                    Text('Expired${_expiredProviders.isNotEmpty ? ' (${_expiredProviders.length})' : ''}'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // ═══ TAB CONTENT ═══
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMobileProvidersList(_pendingProviders, showActions: true),
              _buildMobileProvidersList(_rejectedProviders, showActions: false),
              _buildMobileProvidersList(_expiredProviders, showActions: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(int value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              value.toString(),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: kTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.grey.shade200,
    );
  }

  Widget _buildMobileProvidersList(List<ProviderForReview> providers, {required bool showActions}) {
    if (providers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.inbox, size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Text(
              'No requests found',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kTextSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Check back later',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: kPrimaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: providers.length,
        itemBuilder: (context, index) {
          return _buildMobileProviderCard(providers[index], showActions: showActions);
        },
      ),
    );
  }

  Widget _buildMobileProviderCard(ProviderForReview provider, {required bool showActions}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showProviderDetails(provider),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // ═══ HEADER ROW ═══
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          provider.companyName.isNotEmpty 
                              ? provider.companyName[0].toUpperCase() 
                              : '?',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.companyName,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: kTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: provider.providerType == ProviderType.business 
                                      ? Colors.blue.withOpacity(0.1) 
                                      : Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  provider.providerType == ProviderType.business ? 'Business' : 'Individual',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: provider.providerType == ProviderType.business 
                                        ? Colors.blue 
                                        : Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Status Badge
                    _buildMobileStatusBadge(provider.verificationStatus),
                  ],
                ),
                
                // ═══ ACTION BUTTONS (only for pending) ═══
                if (showActions) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showRejectDialog(provider),
                          icon: const Icon(LucideIcons.x, size: 16),
                          label: Text('Reject', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kErrorColor,
                            side: BorderSide(color: kErrorColor.withOpacity(0.5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleVerification(provider, true),
                          icon: const Icon(LucideIcons.check, size: 16),
                          label: Text('Approve', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kSuccessColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileStatusBadge(VerificationStatus status) {
    Color color;
    IconData icon;

    switch (status) {
      case VerificationStatus.verified:
        color = kSuccessColor;
        icon = LucideIcons.checkCircle;
        break;
      case VerificationStatus.adminReview:
        color = kWarningColor;
        icon = LucideIcons.clock;
        break;
      case VerificationStatus.rejected:
        color = kErrorColor;
        icon = LucideIcons.xCircle;
        break;
      case VerificationStatus.expired:
        color = Colors.orange;
        icon = LucideIcons.alertTriangle;
        break;
      default:
        color = kTextSecondary;
        icon = LucideIcons.helpCircle;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 🖥️ WEB CONTENT - Original Layout
  // ═══════════════════════════════════════════════════════════════
  Widget _buildWebContent() {
    return Column(
      children: [
        // Stats Cards
        Padding(
          padding: const EdgeInsets.all(20),
          child: _buildStatsSection(),
        ),
        // Tab Bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: kPrimaryColor,
            unselectedLabelColor: kTextSecondary,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
            unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
            indicator: BoxDecoration(
              color: kPrimaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorPadding: const EdgeInsets.all(4),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.clock, size: 18),
                    const SizedBox(width: 8),
                    const Text('Pending'),
                    if (_pendingProviders.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      _buildBadge(_pendingProviders.length),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.xCircle, size: 18),
                    const SizedBox(width: 8),
                    const Text('Rejected'),
                    if (_rejectedProviders.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      _buildBadge(_rejectedProviders.length, color: kErrorColor),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.alertTriangle, size: 18),
                    const SizedBox(width: 8),
                    const Text('Expired'),
                    if (_expiredProviders.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      _buildBadge(_expiredProviders.length, color: kWarningColor),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildProvidersList(_pendingProviders, showActions: true),
              _buildProvidersList(_rejectedProviders, showActions: false),
              _buildProvidersList(_expiredProviders, showActions: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(int count, {Color color = kPrimaryColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count.toString(),
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    if (_stats == null) return const SizedBox();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildStatCard(
              'Total Providers',
              _stats!.total.toString(),
              LucideIcons.users,
              kPrimaryColor,
              width: isWide ? (constraints.maxWidth - 64) / 5 : (constraints.maxWidth - 16) / 2,
            ),
            _buildStatCard(
              'Verified',
              _stats!.verified.toString(),
              LucideIcons.checkCircle,
              kSuccessColor,
              width: isWide ? (constraints.maxWidth - 64) / 5 : (constraints.maxWidth - 16) / 2,
            ),
            _buildStatCard(
              'Pending Review',
              _stats!.adminReview.toString(),
              LucideIcons.clock,
              kWarningColor,
              width: isWide ? (constraints.maxWidth - 64) / 5 : (constraints.maxWidth - 16) / 2,
            ),
            _buildStatCard(
              'Rejected',
              _stats!.rejected.toString(),
              LucideIcons.xCircle,
              kErrorColor,
              width: isWide ? (constraints.maxWidth - 64) / 5 : (constraints.maxWidth - 16) / 2,
            ),
            _buildStatCard(
              'Expiring Soon',
              _stats!.expiringWithin30Days.toString(),
              LucideIcons.alertTriangle,
              Colors.orange,
              width: isWide ? (constraints.maxWidth - 64) / 5 : (constraints.maxWidth - 16) / 2,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, {double? width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const Spacer(),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: kTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProvidersList(List<ProviderForReview> providers, {required bool showActions}) {
    if (providers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.inbox, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No requests found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: kPrimaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: providers.length,
        itemBuilder: (context, index) {
          return _buildProviderCard(providers[index], showActions: showActions);
        },
      ),
    );
  }

  Widget _buildProviderCard(ProviderForReview provider, {required bool showActions}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showProviderDetails(provider),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                        color: kPrimaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          provider.companyName.isNotEmpty 
                              ? provider.companyName[0].toUpperCase() 
                              : '?',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.companyName,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: kTextPrimary,
                            ),
                          ),
                          Text(
                            provider.email,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: kTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status Badge
                    _buildStatusBadge(provider.verificationStatus),
                  ],
                ),
                const SizedBox(height: 12),
                // Type Badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: provider.providerType == ProviderType.business 
                            ? Colors.blue.withOpacity(0.1) 
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            provider.providerType == ProviderType.business 
                                ? LucideIcons.building2 
                                : LucideIcons.user,
                            size: 14,
                            color: provider.providerType == ProviderType.business 
                                ? Colors.blue 
                                : Colors.green,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            provider.providerType == ProviderType.business 
                                ? 'Organization' 
                                : 'Individual',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: provider.providerType == ProviderType.business 
                                  ? Colors.blue 
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (provider.lastUpdated != null) ...[
                      const Spacer(),
                      Text(
                        _formatDate(provider.lastUpdated!),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: kTextSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
                // Actions (only for pending)
                if (showActions) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showRejectDialog(provider),
                          icon: const Icon(LucideIcons.x, size: 18),
                          label: Text('Reject', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kErrorColor,
                            side: const BorderSide(color: kErrorColor),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleVerification(provider, true),
                          icon: const Icon(LucideIcons.check, size: 18),
                          label: Text('Approve', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kSuccessColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(VerificationStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case VerificationStatus.verified:
        color = kSuccessColor;
        text = 'Verified';
        icon = LucideIcons.checkCircle;
        break;
      case VerificationStatus.adminReview:
        color = kWarningColor;
        text = 'Pending';
        icon = LucideIcons.clock;
        break;
      case VerificationStatus.rejected:
        color = kErrorColor;
        text = 'Rejected';
        icon = LucideIcons.xCircle;
        break;
      case VerificationStatus.expired:
        color = Colors.orange;
        text = 'Expired';
        icon = LucideIcons.alertTriangle;
        break;
      default:
        color = kTextSecondary;
        text = getVerificationStatusText(status);
        icon = LucideIcons.helpCircle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showProviderDetails(ProviderForReview provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProviderDetailsSheet(
        provider: provider,
        onApprove: () {
          Navigator.pop(context);
          _handleVerification(provider, true);
        },
        onReject: () {
          Navigator.pop(context);
          _showRejectDialog(provider);
        },
      ),
    );
  }

  void _showRejectDialog(ProviderForReview provider) {
    final notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kErrorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.xCircle, color: kErrorColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Reject Verification',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to reject ${provider.companyName}\'s verification?',
              style: GoogleFonts.poppins(fontSize: 14, color: kTextSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add rejection reason (optional)',
                hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade500),
                filled: true,
                fillColor: kBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: kTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleVerification(provider, false, notes: notesController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kErrorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Reject', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    }
    return 'Just now';
  }
}

// ============================================================================
// 📋 PROVIDER DETAILS SHEET
// ============================================================================
class _ProviderDetailsSheet extends StatelessWidget {
  final ProviderForReview provider;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ProviderDetailsSheet({
    required this.provider,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 48,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: kPrimaryLight,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              provider.companyName.isNotEmpty 
                                  ? provider.companyName[0].toUpperCase() 
                                  : '?',
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: kPrimaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider.companyName,
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: kTextPrimary,
                                ),
                              ),
                              Text(
                                provider.providerType == ProviderType.business 
                                    ? 'Organization' 
                                    : 'Individual',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: kTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Contact Info
                    _buildSection('Contact Information', [
                      _buildInfoRow(LucideIcons.mail, 'Email', provider.email),
                      if (provider.phone != null)
                        _buildInfoRow(LucideIcons.phone, 'Phone', provider.phone!),
                    ]),
                    const SizedBox(height: 24),
                    // Document Preview
                    if (provider.documentUrl != null) ...[
                      _buildSection('Uploaded Document', [
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: kBackgroundColor,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CachedNetworkImage(
                              imageUrl: provider.documentUrl!,
                              fit: BoxFit.contain,
                              placeholder: (_, __) => const Center(
                                child: CircularProgressIndicator(color: kPrimaryColor),
                              ),
                              errorWidget: (_, __, ___) => Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(LucideIcons.imageOff, size: 48, color: kTextSecondary),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Failed to load image',
                                    style: GoogleFonts.poppins(color: kTextSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 24),
                    ],
                    // Extracted Text
                    if (provider.extractedText != null && provider.extractedText!.isNotEmpty) ...[
                      _buildSection('Extracted Text (OCR)', [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kBackgroundColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            provider.extractedText!,
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: kTextPrimary,
                              height: 1.6,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 24),
                    ],
                    // Notes
                    if (provider.notes != null && provider.notes!.isNotEmpty) ...[
                      _buildSection('Notes', [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kWarningColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kWarningColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(LucideIcons.info, size: 20, color: kWarningColor),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  provider.notes!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: kTextPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
            // Action Buttons
            if (provider.verificationStatus == VerificationStatus.adminReview)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(LucideIcons.x, size: 18),
                        label: Text('Reject', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kErrorColor,
                          side: const BorderSide(color: kErrorColor),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onApprove,
                        icon: const Icon(LucideIcons.check, size: 18),
                        label: Text('Approve', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kSuccessColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: kTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kPrimaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: kPrimaryColor),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: kTextSecondary,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: kTextPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
