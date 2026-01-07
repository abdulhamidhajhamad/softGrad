import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';

class TotalUsersTile extends StatelessWidget {
  final VoidCallback? onTap;

  const TotalUsersTile({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return _OverviewTile(
      label: 'Total Users',
      value: '2,543',
      icon: LucideIcons.users,
      color: Colors.amber[800]!,
      bgColor: Colors.amber[50]!,
      onTap: onTap,
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
        child: Row(
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
        ),
      ),
    );
  }
}
