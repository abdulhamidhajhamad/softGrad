// lib/screens/services_provider.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_application_1/screens/add_service_provider.dart';
import 'showMore_provider.dart';
import 'edit_service_provider.dart';

const Color kPrimaryColor = Color.fromARGB(215, 20, 20, 215);
const Color kTextColor = Colors.black;
const Color kBackgroundColor = Colors.white;

class ServicesProviderScreen extends StatefulWidget {
  const ServicesProviderScreen({Key? key}) : super(key: key);

  @override
  State<ServicesProviderScreen> createState() => _ServicesProviderScreenState();
}

class _ServicesProviderScreenState extends State<ServicesProviderScreen> {
  static final List<Map<String, dynamic>> _services = [];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortOption = 'recent';
  String _statusFilter = 'all';

  DateTime? _lastUpdated;

  final List<String> _categories = const [
    'Venues',
    'Photographers',
    'Catering',
    'Cake',
    'Flower Shops',
    'Makeup Artists',
    'Music & DJ',
    'Decor & Lighting',
    'Other',
  ];

  final List<String> _cities = const [
    'Nablus',
    'Ramallah',
    'Hebron',
    'Jenin',
    'Tulkarm',
    'Qalqilya',
    'Other',
  ];

  List<Map<String, dynamic>> get _filteredServices {
    List<Map<String, dynamic>> list = _services.toList();

    if (_searchQuery.isNotEmpty) {
      list = list.where((service) {
        final name = (service['name'] ?? '').toString().toLowerCase();
        final cat = (service['category'] ?? '').toString().toLowerCase();
        final price = (service['price'] ?? '').toString();
        final q = _searchQuery.toLowerCase();
        return name.contains(q) || cat.contains(q) || price.contains(q);
      }).toList();
    }

    if (_statusFilter == 'active') {
      list = list.where((s) => s['isActive'] == true).toList();
    } else if (_statusFilter == 'hidden') {
      list = list.where((s) => s['isActive'] == false).toList();
    }

    if (_sortOption == 'price_low') {
      list.sort(
          (a, b) => (a['price'] as double).compareTo(b['price'] as double));
    } else if (_sortOption == 'price_high') {
      list.sort(
          (a, b) => (b['price'] as double).compareTo(a['price'] as double));
    } else {
      list.sort((a, b) {
        final da = (a['updatedAt'] ?? a['createdAt']) as DateTime;
        final db = (b['updatedAt'] ?? b['createdAt']) as DateTime;
        return db.compareTo(da);
      });
    }

    return list;
  }

  void _markUpdated() {
    setState(() => _lastUpdated = DateTime.now());
  }

  Future<void> _refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    setState(() {});
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Colors.red, size: 24),
            ),
            const SizedBox(width: 10),
            Text('Delete Service',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ],
        ),
        content: Text('Are you sure you want to delete this service?',
            style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: Colors.grey.shade700)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _services.removeAt(index);
                _markUpdated();
              });
              Navigator.pop(context);
            },
            child:
                Text('Delete', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _services.length;
    final activeCount = _services.where((s) => s['isActive'] == true).length;
    final hiddenCount = total - activeCount;

    final lastUpdated = _lastUpdated ??
        (_services.isNotEmpty
            ? _services
                .map<DateTime>(
                    (s) => (s['updatedAt'] ?? s['createdAt']) as DateTime)
                .reduce((a, b) => a.isAfter(b) ? a : b)
            : null);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: kTextColor),
        title: Text(
          'My Services',
          style: GoogleFonts.poppins(
            color: kTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final newService = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddServiceProviderScreen(
                    existingData: null, // ← ← ← التعديل الوحيد
                  ),
                ),
              );

              if (newService != null) {
                setState(() {
                  final service = Map<String, dynamic>.from(newService);
                  service['views'] = 0;
                  service['bookings'] = 0;
                  service['likes'] = 0;
                  service['createdAt'] = DateTime.now();
                  service['updatedAt'] = DateTime.now();

                  if (service['discount'] != null &&
                      service['discount'].toString().isNotEmpty) {
                    final p = service['price'] as double;
                    final d = double.tryParse(service['discount']) ?? 0;
                    service['finalPrice'] = p - (p * (d / 100));
                  } else {
                    service['finalPrice'] = service['price'];
                  }

                  _services.add(service);
                  _markUpdated();
                });
              }
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _filteredServices.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummaryHeader(
                              total, activeCount, hiddenCount, lastUpdated),
                          const SizedBox(height: 16),
                          _buildSearchAndFilters(),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList.builder(
                      itemCount: _filteredServices.length,
                      itemBuilder: (context, index) {
                        final service = _filteredServices[index];
                        final originalIndex = _services.indexOf(service);

                        return _ServiceCard(
                          service: service,
                          onEdit: () async {
                            final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditServiceProviderScreen(
                                    existingData: service),
                              ),
                            );

                            if (updated != null) {
                              setState(() {
                                _services[originalIndex] = {
                                  ..._services[originalIndex],
                                  ...updated,
                                  "updatedAt": DateTime.now(),
                                };
                              });
                              _markUpdated();
                            }
                          },
                          onDelete: () => _confirmDelete(originalIndex),
                          onToggleActive: (val) {
                            setState(() {
                              _services[originalIndex]['isActive'] = val;
                              _services[originalIndex]['updatedAt'] =
                                  DateTime.now();
                              _markUpdated();
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryHeader(
    int total,
    int active,
    int hidden,
    DateTime? lastUpdated,
  ) {
    String lastUpdatedText = 'Not updated yet';
    if (lastUpdated != null) {
      lastUpdatedText =
          '${lastUpdated.year}/${lastUpdated.month.toString().padLeft(2, '0')}/${lastUpdated.day.toString().padLeft(2, '0')}';
    }

    return Row(
      children: [
        _MiniStatCard(
          icon: Icons.widgets_outlined,
          label: 'Total',
          value: total.toString(),
        ),
        const SizedBox(width: 8),
        _MiniStatCard(
          icon: Icons.visibility_outlined,
          label: 'Active / Hidden',
          value: '$active / $hidden',
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniStatCard(
            icon: Icons.access_time,
            label: 'Last Updated',
            value: lastUpdatedText,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() => _searchQuery = value.trim());
          },
          decoration: InputDecoration(
            hintText: 'Search by name, category, or price',
            hintStyle: GoogleFonts.poppins(fontSize: 13),
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: kPrimaryColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(
                Icons.widgets_outlined,
                size: 64,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text('No Services Yet',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              'Start by adding your first service.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () async {
                final newService = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddServiceProviderScreen(
                      existingData: null, // ← ← ← التعديل فقط
                    ),
                  ),
                );

                if (newService != null) {
                  setState(() {
                    final service = Map<String, dynamic>.from(newService);
                    service['views'] = 0;
                    service['bookings'] = 0;
                    service['likes'] = 0;
                    service['createdAt'] = DateTime.now();
                    service['updatedAt'] = DateTime.now();

                    if (service['discount'] != null &&
                        service['discount'].toString().isNotEmpty) {
                      final p = service['price'] as double;
                      final d = double.tryParse(service['discount']) ?? 0;
                      service['finalPrice'] = p - (p * (d / 100));
                    } else {
                      service['finalPrice'] = service['price'];
                    }

                    _services.add(service);
                    _markUpdated();
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text('Add Service',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniStatCard({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: kPrimaryColor),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
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
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleActive;

  const _ServiceCard({
    Key? key,
    required this.service,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isActive = service['isActive'] == true;
    final images = List<String>.from(service['images'] ?? []);

    final double originalPrice = (service['price'] ?? 0).toDouble();
    final String? discountStr = service['discount']?.toString();
    final bool hasDiscount = discountStr != null && discountStr.isNotEmpty;

    double finalPrice = originalPrice;

    if (hasDiscount) {
      final d = double.tryParse(discountStr!) ?? 0;
      finalPrice = originalPrice - (originalPrice * (d / 100));
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ShowMoreProviderScreen(service: service),
            ),
          );

          if (result != null && result["edit"] == true) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditServiceProviderScreen(
                  existingData: service,
                ),
              ),
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (images.isNotEmpty)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(18)),
                    child: SizedBox(
                      height: 170,
                      width: double.infinity,
                      child: PageView.builder(
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          return Image.file(
                            File(images[index]),
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                  ),
                  if (hasDiscount)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "-${discountStr!.trim()}%",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                ],
              )
            else
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
                child: Container(
                  height: 140,
                  color: Colors.grey.shade100,
                  child: Center(
                    child: Icon(Icons.image_outlined,
                        color: Colors.grey.shade400, size: 40),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          service['name'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (hasDiscount)
                            Text(
                              "₪${originalPrice.toStringAsFixed(0)}",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                              ),
                            ),
                          Text(
                            "₪${finalPrice.toStringAsFixed(0)}",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: hasDiscount
                                  ? Colors.redAccent
                                  : kPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service['category'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    service['shortDescription'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green.withOpacity(0.08)
                              : Colors.grey.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isActive ? 'Active' : 'Hidden',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color:
                                isActive ? Colors.green : Colors.grey.shade600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      _StatChip(
                          icon: Icons.visibility_outlined,
                          value: '${service['views'] ?? 0}'),
                      const SizedBox(width: 6),
                      _StatChip(
                          icon: Icons.calendar_month_outlined,
                          value: '${service['bookings'] ?? 0}'),
                      const SizedBox(width: 6),
                      _StatChip(
                          icon: Icons.favorite_border,
                          value: '${service['likes'] ?? 0}'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: onEdit,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: Text('Edit',
                            style: GoogleFonts.poppins(
                                fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: onDelete,
                        child: Text('Delete',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.red,
                                fontWeight: FontWeight.w500)),
                      ),
                      const Spacer(),
                      Text('Visible',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.grey.shade700)),
                      Switch.adaptive(
                        value: isActive,
                        activeColor: kPrimaryColor,
                        onChanged: onToggleActive,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;

  const _StatChip({Key? key, required this.icon, required this.value})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: kPrimaryColor),
          const SizedBox(width: 3),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}