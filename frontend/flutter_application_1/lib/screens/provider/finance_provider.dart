// lib/screens/provider/finance_provider.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/services/finance_provider_service.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

// ═══════════════════════════════════════════════════════════════════════════
// 🎨 Design Tokens - Modern Purple Theme
// ═══════════════════════════════════════════════════════════════════════════
const Color kPrimaryColor = Color(0xFF6C63FF);
const Color kPrimaryLight = Color(0xFFE8E6FF);
const Color kTextColor = Color(0xFF1A1D29);
const Color kTextSecondary = Color(0xFF6B7280);
const Color kBackgroundColor = Color(0xFFF8F9FC);
const Color kCardColor = Colors.white;
const Color kSuccessColor = Color(0xFF10B981);
const Color kWarningColor = Color(0xFFF59E0B);
const Color kDangerColor = Color(0xFFEF4444);

class FinanceProviderScreen extends StatefulWidget {
  const FinanceProviderScreen({Key? key}) : super(key: key);

  @override
  State<FinanceProviderScreen> createState() => _FinanceProviderScreenState();
}

class _FinanceProviderScreenState extends State<FinanceProviderScreen> {
  bool _isLoading = true;
  FinanceData? _financeData;
  String? _error;
  
  // 📅 Selected time period for Revenue Trend
  String _selectedPeriod = '1 Month';
  final List<String> _periodOptions = ['1 Month', '6 Months', '1 Year'];

  @override
  void initState() {
    super.initState();
    _loadFinanceData();
  }

  Future<void> _loadFinanceData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await FinanceProviderService.fetchFinanceStats();
      if (mounted) {
        setState(() {
          _financeData = data;
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        body: const Center(child: CircularProgressIndicator(color: kPrimaryColor)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        body: Center(child: _buildErrorState()),
      );
    }

    if (_financeData == null) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        body: Center(child: _buildEmptyState()),
      );
    }

    final summary = _financeData!.summary;
    final servicesSales = _financeData!.servicesSales;
    final recentBookings = _financeData!.recentBookings;

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
                    color: kPrimaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.trendingUp, size: 20, color: kPrimaryColor),
                ),
                const SizedBox(width: 14),
                Text(
                  'Finance Overview',
                  style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: kTextColor),
                ),
                const Spacer(),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _loadFinanceData,
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
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 24, vertical: 32),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 1400 : double.infinity),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main Stats Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Total Revenue Card
                          Expanded(
                            flex: 2,
                            child: _buildWebRevenueCard(summary),
                          ),
                          const SizedBox(width: 24),
                          // Stats Cards
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: _buildWebStatCard('Total Bookings', summary.totalBookings.toString(), LucideIcons.calendar, kPrimaryColor)),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildWebStatCard('This Month', '₪${_formatNumber(summary.currentMonthRevenue)}', LucideIcons.trendingUp, kSuccessColor)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(child: _buildWebStatCard('Cancelled', summary.cancelledCount.toString(), LucideIcons.xCircle, kDangerColor, subtitle: '₪${_formatNumber(summary.cancelledAmount)}')),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildWebStatCard('Growth Rate', '${summary.growthRate >= 0 ? '+' : ''}${summary.growthRate.toStringAsFixed(1)}%', summary.growthRate >= 0 ? LucideIcons.arrowUpRight : LucideIcons.arrowDownRight, summary.growthRate >= 0 ? kSuccessColor : kDangerColor)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Charts Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Revenue Trend Chart
                          Expanded(
                            flex: 3,
                            child: _buildWebChartSection(),
                          ),
                          const SizedBox(width: 24),
                          // Services Sales
                          Expanded(
                            flex: 2,
                            child: _buildWebServicesSalesSection(servicesSales),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Recent Bookings Table
                      if (recentBookings.isNotEmpty) _buildWebRecentBookings(recentBookings),
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

  Widget _buildWebRevenueCard(FinanceSummary summary) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: kPrimaryColor.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 8))],
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
                child: const Icon(LucideIcons.wallet, size: 22, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text('Total Revenue', style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '₪${_formatNumber(summary.totalRevenue)}',
            style: GoogleFonts.poppins(fontSize: 42, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: summary.growthRate >= 0 ? kSuccessColor.withOpacity(0.2) : kDangerColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  summary.growthRate >= 0 ? LucideIcons.arrowUpRight : LucideIcons.arrowDownRight,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  '${summary.growthRate >= 0 ? '+' : ''}${summary.growthRate.toStringAsFixed(1)}% vs last month',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebStatCard(String label, String value, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.poppins(fontSize: 13, color: kTextSecondary)),
                Text(value, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: kTextColor)),
                if (subtitle != null) Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: kTextSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebChartSection() {
    final filteredTrend = _getFilteredTrend();

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(10)),
                child: const Icon(LucideIcons.barChart3, size: 18, color: kPrimaryColor),
              ),
              const SizedBox(width: 12),
              Text('Revenue Trend', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: kTextColor)),
              const Spacer(),
              _buildPeriodDropdown(),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: filteredTrend.isEmpty
                ? Center(child: Text('No trend data', style: GoogleFonts.poppins(color: kTextSecondary)))
                : _SimpleBarChart(data: filteredTrend),
          ),
        ],
      ),
    );
  }

  Widget _buildWebServicesSalesSection(List<ServiceSalesData> servicesSales) {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(10)),
                child: const Icon(LucideIcons.pieChart, size: 18, color: kPrimaryColor),
              ),
              const SizedBox(width: 12),
              Text('Sales by Service', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: kTextColor)),
            ],
          ),
          const SizedBox(height: 20),
          if (servicesSales.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text('No sales data yet', style: GoogleFonts.poppins(color: kTextSecondary))),
            )
          else ...[
            SizedBox(height: 160, child: _ServicesPieChart(services: servicesSales)),
            const SizedBox(height: 16),
            const Divider(),
            ...servicesSales.map((s) => _ServiceSalesItem(service: s)),
          ],
        ],
      ),
    );
  }

  Widget _buildWebRecentBookings(List<RecentBooking> bookings) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(LucideIcons.clock, size: 18, color: kPrimaryColor),
                ),
                const SizedBox(width: 12),
                Text('Recent Bookings', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: kTextColor)),
              ],
            ),
          ),
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(color: kBackgroundColor),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text('Client', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: kTextSecondary))),
                Expanded(flex: 2, child: Text('Service', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: kTextSecondary))),
                Expanded(child: Text('Date', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: kTextSecondary))),
                Expanded(child: Text('Amount', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: kTextSecondary))),
                Expanded(child: Text('Status', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: kTextSecondary))),
              ],
            ),
          ),
          ...bookings.map((b) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text('Customer', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: kTextColor))),
                Expanded(flex: 2, child: Text(b.serviceName, style: GoogleFonts.poppins(fontSize: 14, color: kTextSecondary))),
                Expanded(child: Text(_formatBookingDate(b.bookingDate ?? b.createdAt), style: GoogleFonts.poppins(fontSize: 13, color: kTextSecondary))),
                Expanded(child: Text('₪${b.price.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: kSuccessColor))),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: b.status == 'confirmed' ? kSuccessColor.withOpacity(0.1) : kDangerColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      b.status.toUpperCase(),
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: b.status == 'confirmed' ? kSuccessColor : kDangerColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  String _formatBookingDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return "Today";
    if (diff.inDays == 1) return "Yesterday";
    if (diff.inDays < 7) return "${diff.inDays} days ago";
    return "${date.day}/${date.month}/${date.year}";
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 📱 MOBILE LAYOUT
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kCardColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: kTextColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Finance Overview",
          style: GoogleFonts.poppins(
            color: kTextColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: kPrimaryColor),
            onPressed: _loadFinanceData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: kPrimaryColor),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_financeData == null) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadFinanceData,
      color: kPrimaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCards(),
            const SizedBox(height: 20),
            _buildRevenueChart(),
            const SizedBox(height: 20),
            _buildServicesSalesSection(),
            const SizedBox(height: 20),
            _buildBookingStatusSection(),
            const SizedBox(height: 20),
            _buildRecentBookingsSection(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kDangerColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: kDangerColor,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Failed to load finance data",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? "Unknown error",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadFinanceData,
              icon: const Icon(Icons.refresh_rounded),
              label: Text("Try Again", style: GoogleFonts.poppins()),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.analytics_outlined,
                color: kPrimaryColor,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "No Finance Data Yet",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Start receiving bookings to see your financial overview",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final summary = _financeData!.summary;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Revenue Card
        _MainRevenueCard(
          totalRevenue: summary.totalRevenue,
          growthRate: summary.growthRate,
          currentMonthRevenue: summary.currentMonthRevenue,
        ),
        const SizedBox(height: 12),
        // Stats Row
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.calendar_today_rounded,
                label: "Total Bookings",
                value: summary.totalBookings.toString(),
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.trending_up_rounded,
                label: "This Month",
                value: "₪${_formatNumber(summary.currentMonthRevenue)}",
                color: kSuccessColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Only Cancelled card (removed Pending)
        _StatCard(
          icon: Icons.cancel_outlined,
          label: "Cancelled",
          value: summary.cancelledCount.toString(),
          subValue: "₪${_formatNumber(summary.cancelledAmount)}",
          color: kDangerColor,
        ),
      ],
    );
  }

  // 📅 Get filtered monthly trend based on selected period
  List<MonthlyTrendData> _getFilteredTrend() {
    final monthlyTrend = _financeData!.monthlyTrend;
    
    int monthsToShow;
    switch (_selectedPeriod) {
      case '1 Month':
        monthsToShow = 1;
        break;
      case '6 Months':
        monthsToShow = 6;
        break;
      case '1 Year':
        monthsToShow = 12;
        break;
      default:
        monthsToShow = 1;
    }
    
    if (monthlyTrend.length <= monthsToShow) {
      return monthlyTrend;
    }
    
    return monthlyTrend.take(monthsToShow).toList();
  }

  Widget _buildRevenueChart() {
    final filteredTrend = _getFilteredTrend();
    
    if (filteredTrend.isEmpty) {
      return const SizedBox.shrink();
    }

    return _SectionCard(
      title: "Revenue Trend",
      icon: Icons.show_chart_rounded,
      trailing: _buildPeriodDropdown(),
      child: SizedBox(
        height: 200,
        child: _SimpleBarChart(data: filteredTrend),
      ),
    );
  }

  Widget _buildPeriodDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: kPrimaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kPrimaryColor.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPeriod,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, 
            color: kPrimaryColor, size: 18),
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: kPrimaryColor,
          ),
          dropdownColor: kCardColor,
          borderRadius: BorderRadius.circular(12),
          items: _periodOptions.map((String period) {
            return DropdownMenuItem<String>(
              value: period,
              child: Text(period),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedPeriod = newValue;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildServicesSalesSection() {
    final servicesSales = _financeData!.servicesSales;
    
    if (servicesSales.isEmpty) {
      return _SectionCard(
        title: "Sales by Service",
        icon: Icons.pie_chart_rounded,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              "No sales data yet",
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }

    return _SectionCard(
      title: "Sales by Service",
      icon: Icons.pie_chart_rounded,
      child: Column(
        children: [
          // Pie Chart
          SizedBox(
            height: 200,
            child: _ServicesPieChart(services: servicesSales),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          // Services List
          ...servicesSales.map((service) => _ServiceSalesItem(service: service)),
        ],
      ),
    );
  }

  Widget _buildBookingStatusSection() {
    final summary = _financeData!.summary;
    final total = summary.totalBookings + summary.cancelledCount;
    
    if (total == 0) {
      return const SizedBox.shrink();
    }

    return _SectionCard(
      title: "Booking Status",
      icon: Icons.donut_large_rounded,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _StatusIndicator(
                label: "Confirmed",
                count: summary.totalBookings,
                total: total,
                color: kSuccessColor,
              ),
            ),
            Expanded(
              child: _StatusIndicator(
                label: "Cancelled",
                count: summary.cancelledCount,
                total: total,
                color: kDangerColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBookingsSection() {
    final recentBookings = _financeData!.recentBookings;
    
    if (recentBookings.isEmpty) {
      return const SizedBox.shrink();
    }

    return _SectionCard(
      title: "Recent Bookings",
      icon: Icons.history_rounded,
      child: Column(
        children: recentBookings
            .map((booking) => _RecentBookingItem(booking: booking))
            .toList(),
      ),
    );
  }

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return "${(number / 1000000).toStringAsFixed(1)}M";
    } else if (number >= 1000) {
      return "${(number / 1000).toStringAsFixed(1)}K";
    }
    return number.toStringAsFixed(0);
  }
}

// ===================== Widgets =====================

class _MainRevenueCard extends StatelessWidget {
  final double totalRevenue;
  final double growthRate;
  final double currentMonthRevenue;

  const _MainRevenueCard({
    required this.totalRevenue,
    required this.growthRate,
    required this.currentMonthRevenue,
  });

  @override
  Widget build(BuildContext context) {
    final isPositiveGrowth = growthRate >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kPrimaryColor,
            kPrimaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.3),
            blurRadius: 15,
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
              Text(
                "Total Revenue",
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositiveGrowth
                      ? kSuccessColor.withOpacity(0.2)
                      : kDangerColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositiveGrowth
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${isPositiveGrowth ? '+' : ''}${growthRate.toStringAsFixed(1)}%",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "₪${_formatCurrency(totalRevenue)}",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "All time earnings",
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return "${(value / 1000000).toStringAsFixed(2)}M";
    } else if (value >= 1000) {
      return "${(value / 1000).toStringAsFixed(2)}K";
    }
    return value.toStringAsFixed(2);
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subValue;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.subValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                ),
                if (subValue != null)
                  Text(
                    subValue!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: kPrimaryColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: kTextColor,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _SimpleBarChart extends StatelessWidget {
  final List<MonthlyTrendData> data;

  const _SimpleBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final maxRevenue = data.map((e) => e.revenue).reduce(math.max);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((item) {
          final heightRatio = maxRevenue > 0 ? item.revenue / maxRevenue : 0.0;
          
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "₪${_formatShort(item.revenue)}",
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: kPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    height: 120 * heightRatio,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          kPrimaryColor,
                          kPrimaryColor.withOpacity(0.7),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.month,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatShort(double value) {
    if (value >= 1000) {
      return "${(value / 1000).toStringAsFixed(1)}K";
    }
    return value.toStringAsFixed(0);
  }
}

class _ServicesPieChart extends StatelessWidget {
  final List<ServiceSalesData> services;

  const _ServicesPieChart({required this.services});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(200, 200),
      painter: _PieChartPainter(services: services),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<ServiceSalesData> services;

  _PieChartPainter({required this.services});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;
    
    final colors = [
      kPrimaryColor,
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
      const Color(0xFF06B6D4),
      const Color(0xFFEC4899),
      const Color(0xFF84CC16),
    ];

    double startAngle = -math.pi / 2;
    
    for (int i = 0; i < services.length; i++) {
      final sweepAngle = (services[i].percentage / 100) * 2 * math.pi;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      startAngle += sweepAngle;
    }

    // Center circle (donut effect)
    final centerPaint = Paint()
      ..color = kCardColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.6, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ServiceSalesItem extends StatelessWidget {
  final ServiceSalesData service;

  const _ServiceSalesItem({required this.service});

  static final _colors = [
    kPrimaryColor,
    const Color(0xFF10B981),
    const Color(0xFFF59E0B),
    const Color(0xFFEF4444),
    const Color(0xFF8B5CF6),
    const Color(0xFF06B6D4),
    const Color(0xFFEC4899),
    const Color(0xFF84CC16),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _colors[service.serviceName.hashCode % _colors.length],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.serviceName,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: kTextColor,
                  ),
                ),
                Text(
                  "${service.bookings} bookings",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "₪${service.revenue.toStringAsFixed(0)}",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kTextColor,
                ),
              ),
              Text(
                "${service.percentage.toStringAsFixed(1)}%",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: kPrimaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _StatusIndicator({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: percentage / 100,
                strokeWidth: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text(
              count.toString(),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _RecentBookingItem extends StatelessWidget {
  final RecentBooking booking;

  const _RecentBookingItem({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getStatusColor(booking.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getStatusIcon(booking.status),
              color: _getStatusColor(booking.status),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.serviceName,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: kTextColor,
                  ),
                ),
                Text(
                  _formatDate(booking.createdAt),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "₪${booking.price.toStringAsFixed(0)}",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kTextColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(booking.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _capitalizeStatus(booking.status),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: _getStatusColor(booking.status),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'completed':
        return kSuccessColor;
      case 'cancelled':
        return kDangerColor;
      case 'pending':
        return kWarningColor;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'completed':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      case 'pending':
        return Icons.hourglass_empty_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _capitalizeStatus(String status) {
    if (status.isEmpty) return status;
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return "Today";
    } else if (diff.inDays == 1) {
      return "Yesterday";
    } else if (diff.inDays < 7) {
      return "${diff.inDays} days ago";
    } else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }
}
