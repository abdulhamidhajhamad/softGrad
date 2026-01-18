import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'service_sales_screen.dart';
import 'package_sales_screen.dart';
import 'verification_requests_screen.dart';
import '../widgets/overview_tiles/service_revenue_tile.dart';
import '../widgets/overview_tiles/package_revenue_tile.dart';
import '../widgets/overview_tiles/total_users_tile.dart';
import '../widgets/overview_tiles/providers_count_tile.dart';
import '../../../services/admin_service/admin_service.dart';
import '../../../services/socket_service.dart';
import '../../../screens/compliance_provider/compliance_provider_service.dart';
import 'dart:async';
import '../models/user.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class DiscountCode {
  final String id;
  final String code;
  final int percent;
  final String expires;
  const DiscountCode({
    required this.id,
    required this.code,
    required this.percent,
    required this.expires,
  });

  factory DiscountCode.fromJson(Map<String, dynamic> json) {
    // Handle discountValue as either int or double
    final discountValue = json['discountValue'];
    int percentValue = 0;
    if (discountValue is int) {
      percentValue = discountValue;
    } else if (discountValue is double) {
      percentValue = discountValue.toInt();
    } else if (discountValue is String) {
      percentValue = int.tryParse(discountValue) ?? 0;
    }
    
    return DiscountCode(
      id: json['_id'] ?? json['id'] ?? '',
      code: json['code'] ?? '',
      percent: percentValue,
      expires: json['expiryDate'] ?? '',
    );
  }
}

class ProviderSales {
  final String name;
  final double sales;
  const ProviderSales(this.name, this.sales);
}

class _HomeScreenState extends State<HomeScreen> {
  // Loading states
  bool _isLoadingDashboard = true;
  bool _isLoadingFinancial = true;
  bool _isLoadingTopProviders = true;
  bool _isLoadingCodes = true;
  bool _isLoadingVerification = true;

  // Data
  double _totalRevenue = 0.0;
  int _canceledBookings = 0;
  List<Map<String, dynamic>> _financialData = [];
  List<ProviderSales> _topSales = [];
  List<DiscountCode> _codes = [];
  List<User> _users = [];
  String _searchQuery = '';
  String _providerSearchQuery = '';
  int _pendingVerificationCount = 0;

  // Filtered lists - exclude admin
  List<User> get _regularUsers => _users.where((u) => u.role.toLowerCase() == 'user').toList();
  List<User> get _providers => _users.where((u) => u.role.toLowerCase() == 'vendor').toList();
  
  // Filtered for search (only regular users, by email)
  List<User> get _filteredUsers {
    final users = _regularUsers;
    if (_searchQuery.isEmpty) return users;
    return users.where((u) => 
      (u.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
      u.name.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }
  
  // Filtered for search (only providers, by email)
  List<User> get _filteredProviders {
    final providers = _providers;
    if (_providerSearchQuery.isEmpty) return providers;
    return providers.where((p) => 
      (p.email?.toLowerCase().contains(_providerSearchQuery.toLowerCase()) ?? false) ||
      p.name.toLowerCase().contains(_providerSearchQuery.toLowerCase())
    ).toList();
  }

  String _period = 'Last 30 Days';
  StreamSubscription? _dashboardSubscription;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _setupRealtimeUpdates();
  }

  @override
  void dispose() {
    _dashboardSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _fetchDashboardSummary(),
      _fetchFinancialGrowth(),
      _fetchTopProviders(),
      _fetchPromoCodes(),
      _fetchUsers(),
      _fetchPendingVerification(),
    ]);
  }

  void _setupRealtimeUpdates() {
    _dashboardSubscription = SocketService.dashboardStream.listen((data) {
      if (mounted) {
        // Refresh data when dashboard updates
        _fetchDashboardSummary();
        _fetchTopProviders();
        _fetchPendingVerification();
      }
    });
  }

  Future<void> _fetchPendingVerification() async {
    try {
      final stats = await ComplianceProviderService.getVerificationStats();
      if (mounted) {
        setState(() {
          _pendingVerificationCount = stats.adminReview;
          _isLoadingVerification = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching verification stats: $e');
      if (mounted) setState(() => _isLoadingVerification = false);
    }
  }

  Future<void> _fetchDashboardSummary() async {
    try {
      final summary = await AdminService.getDashboardSummary();
      if (mounted) {
        setState(() {
          _totalRevenue = (summary['totalRevenue'] ?? 0).toDouble();
          _canceledBookings = summary['canceledBookings'] ?? 0;
          _isLoadingDashboard = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching dashboard: $e');
      if (mounted) setState(() => _isLoadingDashboard = false);
    }
  }

  Future<void> _fetchFinancialGrowth() async {
    try {
      final growth = await AdminService.getFinancialGrowth();
      if (mounted) {
        setState(() {
          _financialData = growth;
          _isLoadingFinancial = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching financial growth: $e');
      if (mounted) setState(() => _isLoadingFinancial = false);
    }
  }

  Future<void> _fetchTopProviders() async {
    try {
      final response = await AdminService.getTopProviderSales(limit: 4);
      // Backend returns 'topProviders' array with 'companyName' and 'totalSales'
      final providers = response['topProviders'] ?? response['providers'] ?? response['data'] ?? [];
      
      print('📊 Top providers response: $response');
      
      final sales = (providers as List).map((p) {
        return ProviderSales(
          p['companyName'] ?? p['name'] ?? 'Unknown',
          (p['totalSales'] ?? p['revenue'] ?? 0).toDouble(),
        );
      }).toList();

      if (mounted) {
        setState(() {
          _topSales = sales;
          _isLoadingTopProviders = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching top providers: $e');
      if (mounted) setState(() => _isLoadingTopProviders = false);
    }
  }

  Future<void> _fetchPromoCodes() async {
    try {
      final codes = await AdminService.getPromoCodes();
      print('📦 Promo codes received: ${codes.length} codes');
      print('📦 Promo codes data: $codes');
      
      final codeList = codes.map((c) => DiscountCode.fromJson(c)).toList();
      
      if (mounted) {
        setState(() {
          _codes = codeList;
          _isLoadingCodes = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching promo codes: $e');
      if (mounted) setState(() => _isLoadingCodes = false);
    }
  }

  Future<void> _fetchUsers() async {
    try {
      final response = await AdminService.getAllUsers();
      final usersList = response['users'] ?? response['data'] ?? [];
      final users = (usersList as List).map((u) => User.fromJson(u)).toList();
      
      if (mounted) {
        setState(() => _users = users);
      }
    } catch (e) {
      print('❌ Error fetching users: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final poppinsTheme = baseTheme.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(baseTheme.textTheme),
      primaryTextTheme:
          GoogleFonts.poppinsTextTheme(baseTheme.primaryTextTheme),
    );

    return Theme(
      data: poppinsTheme,
      child: DefaultTextStyle(
        style: GoogleFonts.poppins(
            textStyle: const TextStyle(color: kTextColor, fontSize: 14)),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;
            final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;
            
            if (isDesktop) {
              return _buildDesktopLayout();
            } else if (isTablet) {
              return _buildTabletLayout();
            } else {
              return _buildMobileLayout();
            }
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 🖥️ DESKTOP LAYOUT - Modern Grid Dashboard
  // ═══════════════════════════════════════════════════════════════
  Widget _buildDesktopLayout() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ═══ WELCOME HEADER ═══
            _buildWebHeader(),
            const SizedBox(height: 20),
            
            // ═══ VERIFICATION ALERT ═══
            _buildVerificationAlertCard(),
            const SizedBox(height: 24),

            // ═══ ROW 1: 4 Stat Cards (Equal Width) ═══
            Row(
              children: [
                Expanded(
                  child: _buildWebStatCard(
                    title: 'Total Revenue',
                    value: _isLoadingDashboard ? '...' : '\$${(_totalRevenue / 1000).toStringAsFixed(1)}k',
                    icon: LucideIcons.dollarSign,
                    iconBgColor: kPrimaryColor,
                    trend: '+12.5%',
                    trendUp: true,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildWebStatCard(
                    title: 'Canceled Bookings',
                    value: _isLoadingDashboard ? '...' : '$_canceledBookings',
                    icon: LucideIcons.calendarX,
                    iconBgColor: Colors.red,
                    trend: 'this month',
                    trendUp: false,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildWebStatCard(
                    title: 'Total Users',
                    value: '${_regularUsers.length}',
                    icon: LucideIcons.users,
                    iconBgColor: Colors.amber,
                    trend: 'active',
                    trendUp: true,
                    onTap: () => _showUsersModal(context),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildWebStatCard(
                    title: 'Providers',
                    value: '${_providers.length}',
                    icon: LucideIcons.store,
                    iconBgColor: Colors.teal,
                    trend: 'registered',
                    trendUp: true,
                    onTap: () => _showProvidersModal(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // ═══ ROW 2: Chart (Large) + Top Providers (Small) ═══
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Financial Chart - Takes 65% width
                  Expanded(
                    flex: 65,
                    child: _buildWebChartCard(),
                  ),
                  const SizedBox(width: 20),
                  // Top Providers Donut - Takes 35% width
                  Expanded(
                    flex: 35,
                    child: _buildWebDonutCard(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // ═══ ROW 3: Revenue Tiles + Discount Codes ═══
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left: Service & Package Revenue
                  Expanded(
                    flex: 40,
                    child: Column(
                      children: [
                        Expanded(
                          child: _buildWebRevenueTile(
                            title: 'Service Revenue',
                            icon: LucideIcons.briefcase,
                            color: kPrimaryColor,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceSalesScreen())),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: _buildWebRevenueTile(
                            title: 'Package Revenue',
                            icon: LucideIcons.package,
                            color: Colors.purple,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PackageSalesScreen())),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Right: Discount Codes
                  Expanded(
                    flex: 60,
                    child: _buildWebDiscountCodesCard(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 🎨 WEB-SPECIFIC WIDGETS
  // ═══════════════════════════════════════════════════════════════
  
  Widget _buildWebHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
                  'Welcome back, Administrator! 👋',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Here\'s what\'s happening with your platform today.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              LucideIcons.layoutDashboard,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconBgColor,
    required String trend,
    required bool trendUp,
    VoidCallback? onTap,
  }) {
    return _HoverCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconBgColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 22, color: iconBgColor),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: trendUp ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trendUp ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                        size: 12,
                        color: trendUp ? Colors.green.shade600 : Colors.orange.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trend,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: trendUp ? Colors.green.shade600 : Colors.orange.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: kTextColor,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebChartCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(LucideIcons.lineChart, size: 20, color: kPrimaryColor),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Financial Growth',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: kTextColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: kBackgroundColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  'Last 7 Months',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: _isLoadingFinancial
                ? Center(child: CircularProgressIndicator(color: kPrimaryColor))
                : _financialData.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.barChart3, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              'No data available',
                              style: GoogleFonts.poppins(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    : LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 1,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: Colors.grey.shade100,
                              strokeWidth: 1,
                            ),
                          ),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: _financialData.asMap().entries.map((e) {
                                return FlSpot(
                                  e.key.toDouble(),
                                  ((e.value['value'] ?? 0) / 10000).toDouble(),
                                );
                              }).toList(),
                              isCurved: true,
                              gradient: LinearGradient(
                                colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.5)],
                              ),
                              barWidth: 3,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                                  radius: 4,
                                  color: Colors.white,
                                  strokeWidth: 2,
                                  strokeColor: kPrimaryColor,
                                ),
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    kPrimaryColor.withOpacity(0.2),
                                    kPrimaryColor.withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebDonutCard() {
    final items = _topSales;
    final total = items.fold<double>(0, (s, e) => s + e.sales);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(LucideIcons.pieChart, size: 20, color: Colors.purple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Top Providers',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: kTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoadingTopProviders
                ? Center(child: CircularProgressIndicator(color: kPrimaryColor))
                : items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.users, size: 40, color: Colors.grey.shade300),
                            const SizedBox(height: 8),
                            Text(
                              'No data available',
                              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 35,
                                sections: items.take(4).toList().asMap().entries.map((e) {
                                  final colors = [kPrimaryColor, Colors.teal, Colors.amber, Colors.pink];
                                  final percent = total > 0 ? (e.value.sales / total * 100) : 0;
                                  return PieChartSectionData(
                                    value: e.value.sales,
                                    color: colors[e.key % colors.length],
                                    radius: 25,
                                    title: '${percent.toStringAsFixed(0)}%',
                                    titleStyle: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...items.take(4).toList().asMap().entries.map((e) {
                            final colors = [kPrimaryColor, Colors.teal, Colors.amber, Colors.pink];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: colors[e.key % colors.length],
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      e.value.name,
                                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '\$${(e.value.sales / 1000).toStringAsFixed(1)}k',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: kTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebRevenueTile({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return _HoverCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: kTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'View details →',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildWebDiscountCodesCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(LucideIcons.tag, size: 20, color: Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Discount Codes',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: kTextColor,
                  ),
                ),
              ),
              _HoverCard(
                onTap: _openAddCodeDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: kPrimaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.plus, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'Add Code',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoadingCodes
                ? const Center(child: CircularProgressIndicator())
                : _codes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.ticket, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              'No discount codes yet',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Click "Add Code" to create one',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _codes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final code = _codes[index];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: kBackgroundColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: kPrimaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    code.code,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      color: kPrimaryColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${code.percent}% off',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        'Expires: ${code.expires.split('T')[0]}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    try {
                                      await AdminService.deletePromoCode(code.id);
                                      setState(() => _codes.removeWhere((c) => c.id == code.id));
                                    } catch (e) {
                                      print('Error deleting code: $e');
                                    }
                                  },
                                  icon: Icon(LucideIcons.trash2, size: 18, color: Colors.red.shade400),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 📱 TABLET LAYOUT - 2 Column Grid
  // ═══════════════════════════════════════════════════════════════
  Widget _buildTabletLayout() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ═══ VERIFICATION ALERT ═══
            _buildVerificationAlertCard(),
            const SizedBox(height: 16),
            
            // ═══ TOP: 2 Stat Cards ═══
            Row(
              children: [
                Expanded(child: _buildStatCard(
                  title: 'Total Revenue',
                  value: _isLoadingDashboard ? '...' : '\$${(_totalRevenue / 1000).toStringAsFixed(1)}k',
                  icon: LucideIcons.dollarSign,
                  color: kPrimaryColor,
                  trend: '+12.5%',
                  isPositive: true,
                )),
                const SizedBox(width: 14),
                Expanded(child: _buildStatCard(
                  title: 'Canceled',
                  value: _isLoadingDashboard ? '...' : '$_canceledBookings',
                  icon: LucideIcons.calendarX,
                  color: Colors.red,
                  trend: 'this month',
                  isPositive: false,
                )),
              ],
            ),
            const SizedBox(height: 16),
            
            // ═══ Overview Tiles ═══
            Row(
              children: [
                Expanded(child: ServiceRevenueTile(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceSalesScreen())),
                )),
                const SizedBox(width: 14),
                Expanded(child: PackageRevenueTile(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PackageSalesScreen())),
                )),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TotalUsersTile(onTap: () => _showUsersModal(context))),
                const SizedBox(width: 14),
                const Expanded(child: ProvidersCountTile()),
              ],
            ),
            const SizedBox(height: 16),
            
            // ═══ Chart ═══
            _buildChartCard(),
            const SizedBox(height: 16),
            
            // ═══ 2 Column: Discount + Donut ═══
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildTopProvidersDonutCard()),
                const SizedBox(width: 14),
                Expanded(child: _buildDiscountCodesCard()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 📱 MOBILE LAYOUT - Original Single Column
  // ═══════════════════════════════════════════════════════════════
  Widget _buildMobileLayout() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModernHeader(context),
            const SizedBox(height: 18),
            
            // ═══ QUICK STATS ROW ═══
            Row(
              children: [
                Expanded(child: _buildPrimaryMetricCard()),
                const SizedBox(width: 14),
                Expanded(child: _buildSecondaryMetricCard()),
              ],
            ),
            const SizedBox(height: 14),
            
            // ═══ VERIFICATION ALERT CARD ═══
            _buildVerificationAlertCard(),
            const SizedBox(height: 18),
            
            // ═══ OVERVIEW SECTION ═══
            Text(
              'Overview',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: kTextColor,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ServiceRevenueTile(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ServiceSalesScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PackageRevenueTile(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PackageSalesScreen()),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TotalUsersTile(onTap: () => _showUsersModal(context))),
                const SizedBox(width: 12),
                const Expanded(child: ProvidersCountTile()),
              ],
            ),
            const SizedBox(height: 18),
            
            // ═══ FINANCIAL GROWTH ═══
            _buildChartCard(),
            const SizedBox(height: 14),
            
            // ═══ TOP PROVIDERS ═══
            _buildTopProvidersDonutCard(),
            const SizedBox(height: 14),
            
            // ═══ DISCOUNT CODES ═══
            _buildDiscountCodesCard(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 🎨 MODERN STAT CARD (for Desktop/Tablet)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
    required bool isPositive,
  }) {
    return _HoverCard(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? LucideIcons.arrowUpRight : LucideIcons.arrowDownRight,
                        size: 12,
                        color: isPositive ? Colors.green.shade600 : Colors.red.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trend,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isPositive ? Colors.green.shade600 : Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 🔔 VERIFICATION ALERT CARD
  // ═══════════════════════════════════════════════════════════════
  Widget _buildVerificationAlertCard() {
    if (_isLoadingVerification) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const SizedBox(width: 22, height: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 10,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final hasPending = _pendingVerificationCount > 0;
    
    return GestureDetector(
      onTap: () {
        // Navigate to verification tab (index 6) via parent
        final parentState = context.findAncestorStateOfType<State>();
        if (parentState != null && parentState.mounted) {
          // Try to find AdminMainScreen and call _onNavTap
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const VerificationRequestsScreen(),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: hasPending
              ? LinearGradient(
                  colors: [
                    Colors.orange.shade400,
                    Colors.orange.shade600,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: hasPending ? null : Colors.green.shade50,
          borderRadius: BorderRadius.circular(16),
          boxShadow: hasPending
              ? [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasPending 
                    ? Colors.white.withOpacity(0.2)
                    : Colors.green.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                hasPending ? LucideIcons.shieldAlert : LucideIcons.shieldCheck,
                size: 24,
                color: hasPending ? Colors.white : Colors.green.shade600,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasPending 
                        ? 'Pending Verifications'
                        : 'All Verified',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: hasPending ? Colors.white : Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasPending
                        ? '$_pendingVerificationCount provider${_pendingVerificationCount > 1 ? 's' : ''} awaiting review'
                        : 'No pending requests',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: hasPending 
                          ? Colors.white.withOpacity(0.9)
                          : Colors.green.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: hasPending 
                    ? Colors.white.withOpacity(0.2)
                    : Colors.green.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: hasPending ? Colors.white : Colors.green.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Header ----------------
  Widget _buildModernHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 26,
              offset: const Offset(0, 14))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'Dashboard',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: kTextColor,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Welcome back, Administrator!',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600),
              ),
            ]),
          ),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: kPrimaryColor.withOpacity(0.25))),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: kPrimaryColor.withOpacity(0.12),
              child: Text(
                'AD',
                style: GoogleFonts.poppins(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Metric Cards ----------------
  Widget _buildPrimaryMetricCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: kPrimaryColor.withOpacity(0.22),
              blurRadius: 28,
              offset: const Offset(0, 16))
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            top: -12,
            child: Icon(LucideIcons.dollarSign,
                size: 84, color: Colors.white.withOpacity(0.10)),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'TOTAL REVENUE',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.85),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _isLoadingDashboard 
                  ? 'Loading...' 
                  : '\$${(_totalRevenue / 1000).toStringAsFixed(1)}k',
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(LucideIcons.arrowUpRight,
                    color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text('+12.5%',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSecondaryMetricCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 22,
              offset: const Offset(0, 12))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          'CANCELED',
          style: GoogleFonts.poppins(
              color: Colors.grey[500],
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6),
        ),
        const SizedBox(height: 6),
        Text(
            _isLoadingDashboard ? '...' : '$_canceledBookings',
            style: GoogleFonts.poppins(
                color: kTextColor, fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.red.shade100)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(LucideIcons.arrowDownRight, color: Colors.red, size: 14),
            const SizedBox(width: 6),
            Text('this month',
                style: GoogleFonts.poppins(
                    color: Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
      ]),
    );
  }

  // ---------------- Line Chart ----------------
  Widget _buildChartCard() {
    return Container(
      height: 260,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 24,
              offset: const Offset(0, 14))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('Financial Growth',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      color: kTextColor,
                      fontSize: 14)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: kBackgroundColor,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.grey.shade200)),
                child: Text('Last 7 Months',
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoadingFinancial
                ? Center(
                    child: CircularProgressIndicator(color: kPrimaryColor),
                  )
                : _financialData.isEmpty
                    ? Center(
                        child: Text(
                          'No data available',
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                        ),
                      )
                    : LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: _financialData.asMap().entries.map((e) {
                                return FlSpot(
                                  e.key.toDouble(),
                                  ((e.value['value'] ?? 0) / 10000).toDouble(),
                                );
                              }).toList(),
                              isCurved: true,
                              color: kPrimaryColor,
                              barWidth: 3.2,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                  show: true,
                                  color: kPrimaryColor.withOpacity(0.12)),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ---------------- Discount Codes Card ----------------
  Widget _buildDiscountCodesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 12))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(LucideIcons.tag, size: 18, color: Colors.grey[800]),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Discount Codes',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w900, fontSize: 14)),
              ),
              TextButton.icon(
                onPressed: _openAddCodeDialog,
                icon: const Icon(LucideIcons.plus, size: 16),
                label: Text('Add',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w800)),
                style: TextButton.styleFrom(foregroundColor: kPrimaryColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_isLoadingCodes)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            )
          else if (_codes.isEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text('No codes yet',
                  style: GoogleFonts.poppins(
                      color: Colors.grey[600], fontWeight: FontWeight.w600)),
            )
          else
            Column(
              children: _codes.map((c) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Dismissible(
                    key: ValueKey(c.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(LucideIcons.trash2, color: Colors.white),
                    ),
                    confirmDismiss: (_) async {
                      try {
                        await AdminService.deletePromoCode(c.id);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Code deleted',
                                  style: GoogleFonts.poppins()),
                            ),
                          );
                        }
                        return true;
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e',
                                  style: GoogleFonts.poppins()),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return false;
                      }
                    },
                    onDismissed: (_) {
                      setState(() => _codes.removeWhere((code) => code.id == c.id));
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: kPrimaryColor.withOpacity(0.18)),
                          ),
                          child: Text(c.code,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w900,
                                  color: kPrimaryColor)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${c.percent}% off • expires ${c.expires.split('T')[0]}',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[700],
                                fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  void _openAddCodeDialog() async {
    final codeCtrl = TextEditingController();
    final percentCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final expCtrl = TextEditingController(
        text: DateTime.now().add(const Duration(days: 30)).toString().split(' ')[0]);

    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          width: MediaQuery.of(ctx).size.width > 500 ? 450 : double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: kPrimaryColor.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ═══ HEADER ═══
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.85)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        LucideIcons.tag,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Discount Code',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add a new promotional code for users',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          LucideIcons.x,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // ═══ FORM CONTENT ═══
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Code Field
                    _buildModernTextField(
                      controller: codeCtrl,
                      label: 'Discount Code',
                      hint: 'e.g., SAVE20',
                      icon: LucideIcons.ticket,
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 18),
                    
                    // Description Field
                    _buildModernTextField(
                      controller: descCtrl,
                      label: 'Description',
                      hint: 'Brief description of the discount',
                      icon: LucideIcons.fileText,
                    ),
                    const SizedBox(height: 18),
                    
                    // Percent & Expiry Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildModernTextField(
                            controller: percentCtrl,
                            label: 'Discount %',
                            hint: 'e.g., 20',
                            icon: LucideIcons.percent,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildModernTextField(
                            controller: expCtrl,
                            label: 'Expires',
                            hint: 'YYYY-MM-DD',
                            icon: LucideIcons.calendar,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // ═══ ACTIONS ═══
              Container(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.plus, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Create Code',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (ok == true) {
      final code = codeCtrl.text.trim();
      final desc = descCtrl.text.trim();
      final percent = int.tryParse(percentCtrl.text.trim()) ?? 0;
      final exp = expCtrl.text.trim();

      if (code.isEmpty || percent <= 0 || desc.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fill all fields',
                style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        final result = await AdminService.createPromoCode(
          code: code,
          description: desc,
          discountValue: percent,
          expiryDate: exp,
        );

        if (mounted) {
          setState(() {
            _codes.insert(
              0,
              DiscountCode.fromJson(result),
            );
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Code created successfully', style: GoogleFonts.poppins()),
              backgroundColor: kSuccessColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating code: $e',
                  style: GoogleFonts.poppins()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // ---------------- Donut Chart ----------------
  Widget _buildTopProvidersDonutCard() {
    final items = _topSales;
    final total = items.fold<double>(0, (s, e) => s + e.sales);
    final top = items.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 12))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(LucideIcons.pieChart, size: 18, color: Colors.grey[800]),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Top Providers Sales',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: kBackgroundColor,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(_period,
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey[800])),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_isLoadingTopProviders)
            const Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(),
            )
          else if (top.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: Text(
                'No data available',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            )
          else
            Row(
              children: [
                SizedBox(
                  height: 140,
                  width: 140,
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: 48,
                      sectionsSpace: 2,
                      sections: List.generate(top.length, (i) {
                        final p = top[i];
                        final percent = total == 0 ? 0 : (p.sales / total) * 100;
                        final color = kPrimaryColor
                            .withOpacity(0.25 + (i * 0.15))
                            .withOpacity(1.0);

                        return PieChartSectionData(
                          value: p.sales,
                          radius: 28,
                          color: color,
                          title: '${percent.toStringAsFixed(0)}%',
                          titleStyle: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.white),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    children: top.map((p) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              height: 10,
                              width: 10,
                              decoration: BoxDecoration(
                                color: kPrimaryColor.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(p.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.grey[800],
                                      fontSize: 12.5)),
                            ),
                            Text(
                              '\$${p.sales.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w900,
                                  color: kTextColor,
                                  fontSize: 12.5),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                )
              ],
            ),
        ],
      ),
    );
  }

  // ---------------- Users Modal (كما هو عندك) ----------------
  void _showUsersModal(BuildContext context) async {
    // Fetch users if not already loaded
    if (_users.isEmpty) {
      await _fetchUsers();
    }

    if (!context.mounted) return;
    
    // Reset search query
    _searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ═══ HEADER ═══
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.85)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(LucideIcons.users, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manage Users',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${_regularUsers.length} users registered',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.85),
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
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.x, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              
              // ═══ SEARCH BAR ═══
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: kBackgroundColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    style: GoogleFonts.poppins(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Search by email or name...',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 14),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(LucideIcons.search, size: 18, color: kPrimaryColor),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    onChanged: (value) {
                      setModalState(() {
                        _searchQuery = value;
                      });
                      setState(() {}); // Update parent state too
                    },
                  ),
                ),
              ),
              
              // ═══ USERS LIST ═══
              Expanded(
                child: _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.userX, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isEmpty ? 'No users found' : 'No matching users',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[500],
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Try a different search term',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _filteredUsers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Avatar
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.7)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Center(
                                    child: Text(
                                      user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                
                                // User Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.name,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: kTextColor,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Icon(LucideIcons.mail, size: 13, color: Colors.grey[500]),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              user.email ?? 'No email',
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Delete Button
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => _showDeleteUserConfirmation(context, user, setModalState),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        LucideIcons.trash2,
                                        size: 18,
                                        color: Colors.red.shade600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 🗑️ DELETE USER CONFIRMATION DIALOG
  // ═══════════════════════════════════════════════════════════════
  void _showDeleteUserConfirmation(BuildContext context, User user, StateSetter setModalState) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ═══ HEADER ═══
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade600, Colors.red.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        LucideIcons.alertTriangle,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Delete User?',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // ═══ CONTENT ═══
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'You are about to delete:',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kBackgroundColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                                style: GoogleFonts.poppins(
                                  color: Colors.red.shade600,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: kTextColor,
                                  ),
                                ),
                                Text(
                                  user.email ?? 'No email',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'This action cannot be undone.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // ═══ ACTIONS ═══
              Container(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          if (user.email == null) return;
                          
                          try {
                            await AdminService.deleteUserByEmail(user.email!);
                            if (mounted) {
                              setState(() {
                                _users.removeWhere((u) => u.id == user.id);
                              });
                              setModalState(() {}); // Refresh modal
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(LucideIcons.checkCircle, color: Colors.white, size: 18),
                                      const SizedBox(width: 10),
                                      Text('User deleted successfully', style: GoogleFonts.poppins()),
                                    ],
                                  ),
                                  backgroundColor: kSuccessColor,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(LucideIcons.alertCircle, color: Colors.white, size: 18),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text('Error: $e', style: GoogleFonts.poppins())),
                                    ],
                                  ),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.trash2, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // � PROVIDERS MODAL - Manage Providers
  // ═══════════════════════════════════════════════════════════════
  void _showProvidersModal(BuildContext context) async {
    // Fetch users if not already loaded
    if (_users.isEmpty) {
      await _fetchUsers();
    }

    if (!context.mounted) return;
    
    // Reset search query
    _providerSearchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ═══ HEADER ═══
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.85)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(LucideIcons.store, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manage Providers',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${_providers.length} providers registered',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.85),
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
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.x, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              
              // ═══ SEARCH BAR ═══
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: kBackgroundColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    style: GoogleFonts.poppins(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Search by email or name...',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 14),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(LucideIcons.search, size: 18, color: kPrimaryColor),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    onChanged: (value) {
                      setModalState(() {
                        _providerSearchQuery = value;
                      });
                      setState(() {}); // Update parent state too
                    },
                  ),
                ),
              ),
              
              // ═══ PROVIDERS LIST ═══
              Expanded(
                child: _filteredProviders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.store, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              _providerSearchQuery.isEmpty ? 'No providers found' : 'No matching providers',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[500],
                              ),
                            ),
                            if (_providerSearchQuery.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Try a different search term',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _filteredProviders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final provider = _filteredProviders[index];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Avatar
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.7)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Center(
                                    child: Text(
                                      provider.name.isEmpty ? '?' : provider.name[0].toUpperCase(),
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                
                                // Provider Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        provider.name,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: kTextColor,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Icon(LucideIcons.mail, size: 13, color: Colors.grey[500]),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              provider.email ?? 'No email',
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Provider Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: kPrimaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Provider',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: kPrimaryColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                
                                // Delete Button
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => _showDeleteProviderConfirmation(context, provider, setModalState),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        LucideIcons.trash2,
                                        size: 18,
                                        color: Colors.red.shade600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 🗑️ DELETE PROVIDER CONFIRMATION DIALOG
  // ═══════════════════════════════════════════════════════════════
  void _showDeleteProviderConfirmation(BuildContext context, User provider, StateSetter setModalState) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ═══ HEADER ═══
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade600, Colors.red.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        LucideIcons.alertTriangle,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Delete Provider?',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // ═══ CONTENT ═══
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'You are about to delete:',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kBackgroundColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: kPrimaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                provider.name.isEmpty ? '?' : provider.name[0].toUpperCase(),
                                style: GoogleFonts.poppins(
                                  color: kPrimaryColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  provider.name,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: kTextColor,
                                  ),
                                ),
                                Text(
                                  provider.email ?? 'No email',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.alertCircle, size: 18, color: Colors.orange.shade700),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'All services and packages by this provider will also be affected.',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This action cannot be undone.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // ═══ ACTIONS ═══
              Container(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          if (provider.email == null) return;
                          
                          try {
                            await AdminService.deleteUserByEmail(provider.email!);
                            if (mounted) {
                              setState(() {
                                _users.removeWhere((u) => u.id == provider.id);
                              });
                              setModalState(() {}); // Refresh modal
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(LucideIcons.checkCircle, color: Colors.white, size: 18),
                                      const SizedBox(width: 10),
                                      Text('Provider deleted successfully', style: GoogleFonts.poppins()),
                                    ],
                                  ),
                                  backgroundColor: kSuccessColor,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(LucideIcons.alertCircle, color: Colors.white, size: 18),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text('Error: $e', style: GoogleFonts.poppins())),
                                    ],
                                  ),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.trash2, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // �🎨 MODERN TEXT FIELD WIDGET - For Add Discount Dialog
  // ═══════════════════════════════════════════════════════════════
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kBackgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: kPrimaryColor,
          ),
          hintStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade400,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: kPrimaryColor),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 🎨 HOVER CARD WIDGET - Adds hover effect for web
// ═══════════════════════════════════════════════════════════════
class _HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  
  const _HoverCard({required this.child, this.onTap});
  
  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _isHovered = false;
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()
            ..translate(0.0, _isHovered ? -4.0 : 0.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: kPrimaryColor.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : [],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
