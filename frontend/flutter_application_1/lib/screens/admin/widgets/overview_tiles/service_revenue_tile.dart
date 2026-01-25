import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../../../services/admin_service/admin_service.dart';

class ServiceRevenueTile extends StatefulWidget {
  final VoidCallback? onTap;

  const ServiceRevenueTile({super.key, this.onTap});

  @override
  State<ServiceRevenueTile> createState() => _ServiceRevenueTileState();
}

class _ServiceRevenueTileState extends State<ServiceRevenueTile> {
  double _revenue = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRevenue();
  }

  Future<void> _fetchRevenue() async {
    try {
      final services = await AdminService.getServiceSales();
      final total = services.fold<double>(
        0,
        (sum, item) => sum + (item['totalRevenue'] ?? 0).toDouble(),
      );
      if (mounted) {
        setState(() {
          _revenue = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching service revenue: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _OverviewTile(
      label: 'Service Revenue',
      value: _isLoading ? '...' : '₪${_revenue.toStringAsFixed(0)}',
      icon: LucideIcons.dollarSign,
      color: Colors.green,
      bgColor: Colors.green[50]!,
      onTap: widget.onTap,
    );
  }
}

class _OverviewTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback? onTap;

  const _OverviewTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // If width is constrained (typical mobile grid item), use vertical layout
            final isNarrow = constraints.maxWidth < 160;

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: color.withOpacity(0.12)),
                        ),
                        child: Icon(icon, size: 16, color: color),
                      ),
                      if (onTap != null)
                        Icon(LucideIcons.chevronRight, 
                            size: 16, color: Colors.grey[300]),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: kTextColor,
                          letterSpacing: -0.5,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              );
            }

            // Desktop / Wide Layout (Horizontal)
            return Row(
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withOpacity(0.12)),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    color: kTextColor,
                    letterSpacing: -0.2,
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 8),
                  Icon(LucideIcons.chevronRight,
                      size: 18, color: Colors.grey[400]),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
