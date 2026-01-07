import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';
import 'service_sales_screen.dart';
import 'package_sales_screen.dart';
import '../widgets/overview_tiles/service_revenue_tile.dart';
import '../widgets/overview_tiles/package_revenue_tile.dart';
import '../widgets/overview_tiles/total_users_tile.dart';
import '../widgets/overview_tiles/providers_count_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class DiscountCode {
  final String code;
  final int percent;
  final String expires; // keep simple as String
  const DiscountCode(
      {required this.code, required this.percent, required this.expires});
}

class ProviderSales {
  final String name;
  final double sales;
  const ProviderSales(this.name, this.sales);
}

class _HomeScreenState extends State<HomeScreen> {
  final List<DiscountCode> _codes = [
    const DiscountCode(code: 'WED10', percent: 10, expires: '2026-02-01'),
    const DiscountCode(code: 'VIP15', percent: 15, expires: '2026-03-10'),
  ];

  String _period = 'Last 30 Days';

  // mock top providers sales (غيرهم براحتك)
  List<ProviderSales> get _topSales {
    if (_period == 'Last 7 Days') {
      return const [
        ProviderSales('Sophie Turner', 12000),
        ProviderSales('Robert Wilson', 8600),
        ProviderSales('Jessica Brown', 5400),
        ProviderSales('Amanda White', 4200),
      ];
    }
    return const [
      ProviderSales('Sophie Turner', 48000),
      ProviderSales('Robert Wilson', 33600),
      ProviderSales('Jessica Brown', 21500),
      ProviderSales('Amanda White', 16800),
    ];
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildModernHeader(context),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: _buildPrimaryMetricCard()),
                    const SizedBox(width: 14),
                    Expanded(child: _buildSecondaryMetricCard()),
                  ],
                ),
                const SizedBox(height: 18),
                _buildChartCard(),
                const SizedBox(height: 14),

                // ✅ Discount Codes (Admin adds here)
                _buildDiscountCodesCard(),
                const SizedBox(height: 14),

                // ✅ Donut Chart (Top providers by sales)
                _buildTopProvidersDonutCard(),
                const SizedBox(height: 18),

                Text(
                  'Overview',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: kTextColor,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 12),

                ServiceRevenueTile(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ServiceSalesScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                PackageRevenueTile(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PackageSalesScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                TotalUsersTile(onTap: () => _showUsersModal(context)),
                const SizedBox(height: 12),
                const ProvidersCountTile(),
              ],
            ),
          ),
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
              '\$142.5k',
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
        Text('4',
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
            Text('2 this week',
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
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 1),
                      FlSpot(1, 1.5),
                      FlSpot(2, 1.4),
                      FlSpot(3, 2.2),
                      FlSpot(4, 2.8),
                      FlSpot(5, 2.6),
                      FlSpot(6, 3.2),
                    ],
                    isCurved: true,
                    color: kPrimaryColor,
                    barWidth: 3.2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                        show: true, color: kPrimaryColor.withOpacity(0.12)),
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
          if (_codes.isEmpty)
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
                          '${c.percent}% off • expires ${c.expires}',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[700],
                              fontSize: 12.5),
                        ),
                      ),
                    ],
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
    final expCtrl = TextEditingController(text: '2026-12-31');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: Text('Add Discount Code',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w900)),
        content: Column(
          children: [
            TextField(
              controller: codeCtrl,
              style: GoogleFonts.poppins(),
              decoration: InputDecoration(
                  labelText: 'Code',
                  labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: percentCtrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.poppins(),
              decoration: InputDecoration(
                  labelText: 'Percent (e.g. 10)',
                  labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: expCtrl,
              style: GoogleFonts.poppins(),
              decoration: InputDecoration(
                  labelText: 'Expires (YYYY-MM-DD)',
                  labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: GoogleFonts.poppins())),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: kPrimaryColor, foregroundColor: Colors.white),
            child: Text('Add',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );

    if (ok == true) {
      final code = codeCtrl.text.trim();
      final percent = int.tryParse(percentCtrl.text.trim()) ?? 0;
      final exp = expCtrl.text.trim();

      if (code.isEmpty || percent <= 0) return;

      setState(() {
        _codes.insert(
            0,
            DiscountCode(
                code: code,
                percent: percent,
                expires: exp.isEmpty ? '—' : exp));
      });
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
              PopupMenuButton<String>(
                onSelected: (v) => setState(() => _period = v),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                      value: 'Last 7 Days', child: Text('Last 7 Days')),
                  PopupMenuItem(
                      value: 'Last 30 Days', child: Text('Last 30 Days')),
                ],
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: kBackgroundColor,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Text(_period,
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.grey[800])),
                      const SizedBox(width: 6),
                      Icon(LucideIcons.chevronDown,
                          size: 16, color: Colors.grey[700]),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                height: 140,
                width: 140,
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: 48, // donut
                    sectionsSpace: 2,
                    sections: List.generate(top.length, (i) {
                      final p = top[i];
                      final percent = total == 0 ? 0 : (p.sales / total) * 100;
                      // بدون ألوان محددة؟ هنا بنستخدم درجات بسيطة من primary عبر opacity
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
  void _showUsersModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Manage Users',
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.w900)),
                  IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                style: GoogleFonts.poppins(),
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                  prefixIcon: const Icon(LucideIcons.search),
                  filled: true,
                  fillColor: kSecondaryColor.withOpacity(0.25),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: mockUsers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final user = mockUsers[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 18,
                            offset: const Offset(0, 10))
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: kPrimaryColor.withOpacity(0.12),
                          child: Text(
                            user.name[0],
                            style: GoogleFonts.poppins(
                                color: kPrimaryColor,
                                fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.name,
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w900)),
                                const SizedBox(height: 2),
                                Text(user.role,
                                    style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w600)),
                              ]),
                        ),
                        Icon(LucideIcons.chevronRight, color: Colors.grey[400]),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
