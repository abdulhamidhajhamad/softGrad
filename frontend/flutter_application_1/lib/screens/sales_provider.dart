// lib/screens/sales_provider.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// موجودين عندك وممكن تحتاجهم لاحقاً
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_1/screens/booking%20type/add_service_provider.dart';
import 'show more/showMore_provider.dart';
import 'edit_service_provider.dart';


class SalesProviderScreen extends StatefulWidget {
  const SalesProviderScreen({Key? key}) : super(key: key);

  @override
  State<SalesProviderScreen> createState() => _SalesProviderScreenState();
}

class _SalesProviderScreenState extends State<SalesProviderScreen> {
  static const Color kPrimaryColor = Color.fromARGB(215, 20, 20, 215);
  static const Color kTextColor = Colors.black;
  static const Color kBackgroundColor = Colors.white;

  String filter = "This Year";

  // ---------------------------------------------------------------------------
  // 👍 داتا فاضية — تجهز للبك اند
  final List<double> monthlySales = [];
  final List<int> yearlySales = [];
  final List<String> yearlyLabels = [];
  final List<Map<String, dynamic>> servicesSales = [];

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Sales Analytics",
          style: GoogleFonts.poppins(
            fontSize: 22,
            color: kTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilter(),
            const SizedBox(height: 10),
            _buildKPIs(),
            const SizedBox(height: 10),
            _buildMonthlyChart(),
            const SizedBox(height: 15),
            _buildYearlyChart(),
            const SizedBox(height: 15),
            _buildSalesTable(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Filter Dropdown
  Widget _buildFilter() {
    return Align(
      alignment: Alignment.centerRight,
      child: DropdownButton<String>(
        value: filter,
        style: GoogleFonts.poppins(color: kTextColor),
        items: ["Last 30 Days", "Last 90 Days", "This Year"]
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black,
                      height: 1,
                    ),
                  ),
                ))
            .toList(),
        onChanged: (val) => setState(() => filter = val!),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // KPI Cards
  Widget _buildKPIs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _kpiCard("Total Sales", "—"),
        _kpiCard("This Month", "—"),
      ],
    );
  }

  Widget _kpiCard(String title, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(24),
        decoration: _chartBoxDecoration(),
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                height: 1,
                fontSize: 14,
                color: kTextColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                height: 1,
                fontSize: 20,
                color: kPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Monthly Chart
  Widget _buildMonthlyChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _chartBoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Monthly Sales",
            style: GoogleFonts.poppins(
              height: 1,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(
            height: 200,
            child: monthlySales.isEmpty
                ? const Center(child: Text("No Data"))
                : const Text("Chart Coming Soon..."),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Yearly Chart
  Widget _buildYearlyChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _chartBoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Yearly Sales Trend",
            style: GoogleFonts.poppins(
              height: 1,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(
            height: 220,
            child: yearlySales.isEmpty
                ? const Center(child: Text("No Data"))
                : CustomPaint(
                    painter: MultiColorLinePainter(yearlySales),
                  ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sales Table
  Widget _buildSalesTable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _chartBoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Sales by Service",
            style: GoogleFonts.poppins(
              height: 1,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          servicesSales.isEmpty
              ? const Center(child: Text("No Services Sales Data"))
              : Table(
                  border: TableBorder.all(color: Colors.black12),
                  columnWidths: const {
                    0: FlexColumnWidth(1.8),
                    1: FlexColumnWidth(1.1),
                    2: FlexColumnWidth(1.4),
                    3: FlexColumnWidth(2.0),
                  },
                  children: [
                    _tableHeader(),
                    ...servicesSales.map((row) => _tableRow(row)),
                  ],
                ),
        ],
      ),
    );
  }

  TableRow _tableHeader() {
    return TableRow(
      decoration: const BoxDecoration(color: Color(0xFFEDEDED)),
      children: const [
        _tableHeaderCell("Service"),
        _tableHeaderCell("Orders"),
        _tableHeaderCell("Revenue"),
        _tableHeaderCell("Last Order"),
      ],
    );
  }

  TableRow _tableRow(Map<String, dynamic> row) {
    return TableRow(
      children: [
        _tableCell(row["service"]),
        _tableCell(row["orders"].toString()),
        _tableCell("₪${row["revenue"]}"),
        _tableCell(row["lastOrder"]),
      ],
    );
  }

  Widget _tableCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 6),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            height: 2.1,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Decoration
  BoxDecoration _chartBoxDecoration() {
    return BoxDecoration(
      color: kBackgroundColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 10,
          offset: Offset(1, 3),
        )
      ],
    );
  }
}

class _tableHeaderCell extends StatelessWidget {
  final String text;
  const _tableHeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// MULTI-COLOR Line Chart Painter
// ============================================================================
class MultiColorLinePainter extends CustomPainter {
  final List<int> points;

  MultiColorLinePainter(this.points);

  final List<Color> yearColors = [
    Colors.red,
    Colors.blue,
    Colors.amber,
    Colors.green,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    double maxVal = points.reduce((a, b) => a > b ? a : b).toDouble();

    for (int i = 0; i < points.length; i++) {
      double x = (size.width / (points.length - 1)) * i;
      double y = size.height - ((points[i] / maxVal) * size.height);

      Paint dot = Paint()
        ..color = yearColors[i]
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), 5, dot);
    }

    for (int i = 0; i < points.length - 1; i++) {
      double x1 = (size.width / (points.length - 1)) * i;
      double y1 = size.height - ((points[i] / maxVal) * size.height);

      double x2 = (size.width / (points.length - 1)) * (i + 1);
      double y2 = size.height - ((points[i + 1] / maxVal) * size.height);

      Paint line = Paint()
        ..color = yearColors[i + 1]
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
