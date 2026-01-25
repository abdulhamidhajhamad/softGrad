import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../../../services/admin_service/admin_service.dart';

class PackageRevenueTile extends StatefulWidget {
  final VoidCallback? onTap;

  const PackageRevenueTile({super.key, this.onTap});

  @override
  State<PackageRevenueTile> createState() => _PackageRevenueTileState();
}

class _PackageRevenueTileState extends State<PackageRevenueTile> {
  double _revenue = 0.0;
  bool _isLoading = true;
  final List<_Pkg> _pkgs = [];

  @override
  void initState() {
    super.initState();
    _fetchRevenue();
  }

  Future<void> _fetchRevenue() async {
    try {
      final packages = await AdminService.getPackageSales();
      final total = packages.fold<double>(
        0,
        (sum, item) => sum + (item['totalRevenue'] ?? 0).toDouble(),
      );
      
      // Convert to _Pkg list
      final pkgList = packages.map((pkg) {
        return _Pkg(
          pkg['packageName'] ?? pkg['name'] ?? 'Unknown',
          (pkg['discountedPrice'] ?? pkg['originalPrice'] ?? pkg['price'] ?? 0).toInt(),
          pkg['packageId'] ?? pkg['_id'] ?? pkg['id'] ?? '',
        );
      }).toList();

      if (mounted) {
        setState(() {
          _revenue = total;
          _pkgs.clear();
          _pkgs.addAll(pkgList);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching package revenue: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _OverviewTile(
      label: 'Package Revenue',
      value: _isLoading ? '...' : '₪${_revenue.toStringAsFixed(0)}',
      icon: LucideIcons.dollarSign,
      color: Colors.blue,
      bgColor: Colors.blue[50]!,
      onTap: widget.onTap ?? () => _openPackages(context),
    );
  }

  void _openPackages(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Manage Packages',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: kTextColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _pkgs.isEmpty
                  ? Center(
                      child: Text(
                        'No packages found',
                        style: GoogleFonts.poppins(color: Colors.grey[600]),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                      itemCount: _pkgs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final p = _pkgs[i];
                        return Dismissible(
                          key: ValueKey(p.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(LucideIcons.trash2,
                                color: Colors.white),
                          ),
                          confirmDismiss: (_) async {
                            try {
                              await AdminService.deletePackageByName(p.name);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Package deleted',
                                        style: GoogleFonts.poppins()),
                                  ),
                                );
                              }
                              return true;
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error deleting package: $e',
                                        style: GoogleFonts.poppins()),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                              return false;
                            }
                          },
                          onDismissed: (_) =>
                              setState(() => _pkgs.removeAt(i)),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    p.name,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      color: kTextColor,
                                    ),
                                  ),
                                ),
                                Text(
                                  '₪${p.price}',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w800,
                                    color: kTextColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(LucideIcons.trash2,
                                      size: 18, color: Colors.red.shade600),
                                  onPressed: () async {
                                    try {
                                      await AdminService.deletePackageByName(
                                          p.name);
                                      setState(() => _pkgs.removeAt(i));
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text('Package deleted',
                                                style: GoogleFonts.poppins()),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Error deleting package: $e',
                                                style: GoogleFonts.poppins()),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
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

class _Pkg {
  final String name;
  final int price;
  final String id;
  _Pkg(this.name, this.price, this.id);
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
                  Icon(LucideIcons.chevronRight, size: 18, color: Colors.grey[400]),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
