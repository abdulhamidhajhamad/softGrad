import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../../../services/admin_service/admin_service.dart';

class AdminProvider {
  final String name;
  final String email;
  final String id;

  const AdminProvider({
    required this.name,
    required this.email,
    required this.id,
  });

  factory AdminProvider.fromJson(Map<String, dynamic> json) {
    return AdminProvider(
      name: json['companyName'] ?? json['userName'] ?? 'Unknown',
      email: json['email'] ?? json['details']?['email'] ?? '',
      id: json['_id'] ?? json['id'] ?? '',
    );
  }
}

class ProvidersCountTile extends StatefulWidget {
  const ProvidersCountTile({super.key});

  @override
  State<ProvidersCountTile> createState() => _ProvidersCountTileState();
}

class _ProvidersCountTileState extends State<ProvidersCountTile> {
  List<AdminProvider> _providers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProviders();
  }

  Future<void> _fetchProviders() async {
    try {
      final response = await AdminService.getAllProviders();
      final providersList = response['providers'] ?? response['data'] ?? [];
      
      final providers = (providersList as List)
          .map((json) => AdminProvider.fromJson(json))
          .toList();

      if (mounted) {
        setState(() {
          _providers = providers;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching providers: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _OverviewTile(
      label: 'Number of Providers',
      value: _isLoading ? '...' : _providers.length.toString(),
      icon: LucideIcons.briefcase,
      color: Colors.purple,
      bgColor: Colors.purple[50]!,
      onTap: () => _openProvidersList(context),
    );
  }

  void _openProvidersList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Providers',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
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
              child: _providers.isEmpty
                  ? Center(
                      child: Text(
                        _isLoading ? 'Loading...' : 'No providers found',
                        style: GoogleFonts.poppins(color: Colors.grey[600]),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                      itemCount: _providers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final p = _providers[i];
                        return Dismissible(
                          key: ValueKey(p.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(LucideIcons.trash2,
                                color: Colors.white),
                          ),
                          confirmDismiss: (_) async {
                            try {
                              await AdminService.deleteProviderByEmail(p.email);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Provider deleted',
                                      style: GoogleFonts.poppins()),
                                ),
                              );
                              return true;
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error deleting provider: $e',
                                      style: GoogleFonts.poppins()),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return false;
                            }
                          },
                          onDismissed: (_) {
                            setState(() => _providers.removeAt(i));
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: Colors.purple.withOpacity(0.12),
                                  child: Text(
                                    p.name.isEmpty ? '?' : p.name[0].toUpperCase(),
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w900,
                                      color: Colors.purple[700],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.name,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          color: kTextColor,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        p.email,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
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
