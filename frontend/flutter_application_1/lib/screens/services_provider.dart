// lib/screens/services_provider.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_application_1/screens/add_service/add_service_provider.dart';
import 'package:flutter_application_1/services/service_service.dart';
import 'show more/showMore_provider.dart';
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
  List<Map<String, dynamic>> _services = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortOption = 'recent';
  String _statusFilter = 'all';

  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final services = await ServiceService.fetchMyServices();
      setState(() {
        _services = List<Map<String, dynamic>>.from(services);
        _isLoading = false;
        _lastUpdated = DateTime.now();
      });
    } catch (e) {
      if (e.toString().contains('No services found for vendor ID')) {
        setState(() {
          _services = [];
          _isLoading = false;
          _hasError = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
        print('Error loading services: $e');
      }
    }
  }

  List<Map<String, dynamic>> get _filteredServices {
    List<Map<String, dynamic>> list = _services.toList();

    if (_searchQuery.isNotEmpty) {
      list = list.where((service) {
        final name = (service['serviceName'] ?? service['name'] ?? '')
            .toString()
            .toLowerCase();
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
      list.sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));
    } else if (_sortOption == 'price_high') {
      list.sort((a, b) => (b['price'] as num).compareTo(a['price'] as num));
    } else {
      list.sort((a, b) {
        final da = DateTime.tryParse(a['updatedAt']?.toString() ??
                a['createdAt']?.toString() ??
                '') ??
            DateTime.now();
        final db = DateTime.tryParse(b['updatedAt']?.toString() ??
                b['createdAt']?.toString() ??
                '') ??
            DateTime.now();
        return db.compareTo(da);
      });
    }

    return list;
  }

  void _markUpdated() {
    setState(() => _lastUpdated = DateTime.now());
  }

  Future<void> _refresh() async {
    await _loadServices();
  }

  // ✅✅ التعديل المطلوب: حطّينا snippet بمكانه الصح + await
  Future<void> _openAddService() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddServiceProviderScreen()),
    );

    if (created == true) {
      await _loadServices(); // تعمل fetchMyServices وتعمل setState
      return;
    }

    // (اختياري) لو شاشة الإضافة بترجع Map بدل true
    if (created is Map && created["created"] == true) {
      final createdService = created["service"];
      if (createdService != null) {
        setState(() {
          _services.insert(0, Map<String, dynamic>.from(createdService));
          _markUpdated();
        });
      } else {
        await _loadServices();
      }
    }
  }

  void _confirmDelete(int index, String serviceId) {
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
            onPressed: () async {
              Navigator.pop(context);
              await _deleteService(serviceId, index);
            },
            child:
                Text('Delete', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteService(String serviceId, int index) async {
    try {
      await ServiceService.deleteService(serviceId);
      setState(() {
        _services.removeAt(index);
        _markUpdated();
      });
      _showSnackBar('Service deleted successfully');
    } catch (e) {
      _showSnackBar('Failed to delete service: ${e.toString()}', isError: true);
      print('Error deleting service: $e');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    if (_isLoading) {
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
        ),
        body: const Center(
          child: CircularProgressIndicator(color: kPrimaryColor),
        ),
      );
    }

    if (_hasError) {
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
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 6),
                Text(
                  'Failed to load services',
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadServices,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text('Retry',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final total = _services.length;
    final activeCount = _services.where((s) => s['isActive'] == true).length;
    final hiddenCount = total - activeCount;

    final lastUpdated = _lastUpdated;

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
            onPressed: _openAddService,
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
                        final serviceId = (service['_id'] ?? '').toString();

                        return _ServiceCard(
                          service: service,
                          onEdit: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditServiceProviderScreen(
                                    existingData: service),
                              ),
                            );

                            if (result == true) {
                              _loadServices();
                            }
                          },
                          onDelete: () =>
                              _confirmDelete(originalIndex, serviceId),
                          onToggleActive: (val) async {
                            try {
                              await ServiceService.updateService(
                                serviceId,
                                {'isActive': val},
                              );
                              setState(() {
                                _services[originalIndex]['isActive'] = val;
                                _markUpdated();
                              });
                              _showSnackBar('Service visibility updated');
                            } catch (e) {
                              _showSnackBar(
                                  'Failed to update service: ${e.toString()}',
                                  isError: true);
                            }
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
          label: 'Active ┃ Hidden',
          value: '$active   ┃   $hidden',
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
              borderSide:
                  const BorderSide(color: Color.fromARGB(255, 142, 142, 142)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide: BorderSide(color: kPrimaryColor),
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
              onPressed: _openAddService,
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
    return SizedBox(
      width: 110,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color.fromARGB(213, 1, 1, 85),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.white70,
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

    final serviceName = service['serviceName'] ?? service['name'] ?? '';
    final description = service['additionalInfo']?['description'] ??
        service['fullDescription'] ??
        '';

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
                          return Image.network(
                            images[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.broken_image, size: 48),
                              );
                            },
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
                          serviceName,
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
                    description,
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