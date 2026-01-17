// lib/screens/services_provider.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter_application_1/screens/provider/add_service/add_service_provider.dart';
import 'package:flutter_application_1/services/service_service.dart';
import 'showMore_provider.dart';
import 'provider/edit_service_provider.dart';

// ============================================================================
// 🎨 THEME COLORS
// ============================================================================
const Color kPrimaryColor = Color(0xFF6C63FF);
const Color kPrimaryLight = Color(0xFFE8E6FF);
const Color kBackgroundColor = Color(0xFFF8F9FC);
const Color kCardColor = Colors.white;
const Color kTextPrimary = Color(0xFF1A1D26);
const Color kTextSecondary = Color(0xFF6B7280);
const Color kSuccessColor = Color(0xFF10B981);
const Color kWarningColor = Color(0xFFFF6B35);

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

  Future<void> _openAddService() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddServiceProviderScreen()),
    );

    if (created == true) {
      await _loadServices();
      return;
    }

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.alertTriangle, color: Colors.red, size: 22),
            ),
            const SizedBox(width: 12),
            Text('Delete Service',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this service? This action cannot be undone.',
          style: GoogleFonts.poppins(fontSize: 14, color: kTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: kTextSecondary, fontWeight: FontWeight.w500)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteService(serviceId, index);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text('Delete', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: isError ? Colors.red : kSuccessColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
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
  // 🌐 WEB LAYOUT
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildWebLayout(bool isDesktop) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: kPrimaryColor),
              const SizedBox(height: 16),
              Text('Loading services...', style: GoogleFonts.poppins(color: kTextSecondary)),
            ],
          ),
        ),
      );
    }

    if (_hasError) {
      return _buildErrorState();
    }

    final total = _services.length;
    final activeCount = _services.where((s) => s['isActive'] == true).length;
    final hiddenCount = total - activeCount;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Column(
        children: [
          // ═══ TOP BAR ═══
          _buildWebTopBar(),
          
          // ═══ CONTENT ═══
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 32 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ═══ STATS CARDS ═══
                  Row(
                    children: [
                      Expanded(child: _buildStatCard(
                        icon: LucideIcons.sparkles,
                        title: 'Total Services',
                        value: total.toString(),
                        color: kPrimaryColor,
                      )),
                      const SizedBox(width: 20),
                      Expanded(child: _buildStatCard(
                        icon: LucideIcons.eye,
                        title: 'Active',
                        value: activeCount.toString(),
                        color: kSuccessColor,
                      )),
                      const SizedBox(width: 20),
                      Expanded(child: _buildStatCard(
                        icon: LucideIcons.eyeOff,
                        title: 'Hidden',
                        value: hiddenCount.toString(),
                        color: kWarningColor,
                      )),
                      const SizedBox(width: 20),
                      Expanded(child: _buildStatCard(
                        icon: LucideIcons.clock,
                        title: 'Last Updated',
                        value: _formatDate(_lastUpdated),
                        color: Colors.purple,
                      )),
                    ],
                  ),
                  const SizedBox(height: 28),
                  
                  // ═══ SEARCH & FILTERS ═══
                  _buildWebSearchAndFilters(),
                  const SizedBox(height: 24),
                  
                  // ═══ SERVICES GRID ═══
                  if (_filteredServices.isEmpty)
                    _buildEmptyState()
                  else
                    _buildServicesGrid(isDesktop),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebTopBar() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: kCardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back Button
          _HoverButton(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.arrowLeft, size: 20, color: kTextSecondary),
            ),
          ),
          const SizedBox(width: 20),
          
          // Title
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Services',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: kTextPrimary,
                ),
              ),
              Text(
                'Manage and organize your services',
                style: GoogleFonts.poppins(fontSize: 14, color: kTextSecondary),
              ),
            ],
          ),
          
          const Spacer(),
          
          // Refresh Button
          _HoverButton(
            onTap: _refresh,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: kBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.refreshCw, size: 18, color: kTextSecondary),
                  const SizedBox(width: 8),
                  Text('Refresh', style: GoogleFonts.poppins(fontSize: 14, color: kTextSecondary)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Add Service Button
          _HoverButton(
            onTap: _openAddService,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.plus, size: 20, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Add Service',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
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
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(20),
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: kTextPrimary,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.poppins(fontSize: 13, color: kTextSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWebSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(20),
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
          // Search
          Expanded(
            flex: 3,
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value.trim()),
              decoration: InputDecoration(
                hintText: 'Search by name, category, or price...',
                hintStyle: GoogleFonts.poppins(fontSize: 14, color: kTextSecondary),
                prefixIcon: const Icon(LucideIcons.search, size: 20, color: kTextSecondary),
                filled: true,
                fillColor: kBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Status Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: kBackgroundColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _statusFilter,
                icon: const Icon(LucideIcons.chevronDown, size: 18),
                style: GoogleFonts.poppins(fontSize: 14, color: kTextPrimary),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Status')),
                  DropdownMenuItem(value: 'active', child: Text('Active Only')),
                  DropdownMenuItem(value: 'hidden', child: Text('Hidden Only')),
                ],
                onChanged: (val) => setState(() => _statusFilter = val!),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Sort
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: kBackgroundColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sortOption,
                icon: const Icon(LucideIcons.chevronDown, size: 18),
                style: GoogleFonts.poppins(fontSize: 14, color: kTextPrimary),
                items: const [
                  DropdownMenuItem(value: 'recent', child: Text('Most Recent')),
                  DropdownMenuItem(value: 'price_low', child: Text('Price: Low to High')),
                  DropdownMenuItem(value: 'price_high', child: Text('Price: High to Low')),
                ],
                onChanged: (val) => setState(() => _sortOption = val!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesGrid(bool isDesktop) {
    final crossAxisCount = isDesktop ? 4 : 3;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 0.85,
      ),
      itemCount: _filteredServices.length,
      itemBuilder: (context, index) {
        final service = _filteredServices[index];
        final originalIndex = _services.indexOf(service);
        final serviceId = (service['_id'] ?? '').toString();

        return _WebServiceCard(
          service: service,
          onEdit: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditServiceProviderScreen(existingData: service),
              ),
            );
            if (result == true) _loadServices();
          },
          onDelete: () => _confirmDelete(originalIndex, serviceId),
          onToggleActive: (val) async {
            try {
              await ServiceService.updateService(serviceId, {'isActive': val});
              setState(() {
                _services[originalIndex]['isActive'] = val;
                _markUpdated();
              });
              _showSnackBar('Service visibility updated');
            } catch (e) {
              _showSnackBar('Failed to update: ${e.toString()}', isError: true);
            }
          },
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ShowMoreProviderScreen(service: service)),
            );
            if (result != null && result["edit"] == true) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditServiceProviderScreen(existingData: service),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: kPrimaryLight,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(LucideIcons.sparkles, size: 56, color: kPrimaryColor),
            ),
            const SizedBox(height: 24),
            Text(
              'No Services Yet',
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: kTextPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Start by adding your first service to showcase to customers.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 15, color: kTextSecondary),
            ),
            const SizedBox(height: 28),
            _HoverButton(
              onTap: _openAddService,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.8)]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: kPrimaryColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.plus, size: 20, color: Colors.white),
                    const SizedBox(width: 10),
                    Text('Add Your First Service',
                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(LucideIcons.alertCircle, size: 48, color: Colors.red),
            ),
            const SizedBox(height: 20),
            Text('Failed to load services',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(_errorMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, color: kTextSecondary)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadServices,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Try Again', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Never';
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 📱 MOBILE LAYOUT
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout() {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: _buildMobileAppBar(),
        body: const Center(child: CircularProgressIndicator(color: kPrimaryColor)),
      );
    }

    if (_hasError) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: _buildMobileAppBar(),
        body: _buildMobileErrorState(),
      );
    }

    final total = _services.length;
    final activeCount = _services.where((s) => s['isActive'] == true).length;
    final hiddenCount = total - activeCount;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: _buildMobileAppBar(),
      body: _filteredServices.isEmpty
          ? _buildMobileEmptyState()
          : RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMobileSummaryHeader(total, activeCount, hiddenCount),
                          const SizedBox(height: 16),
                          _buildMobileSearchAndFilters(),
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

                        return _MobileServiceCard(
                          service: service,
                          onEdit: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditServiceProviderScreen(existingData: service),
                              ),
                            );
                            if (result == true) _loadServices();
                          },
                          onDelete: () => _confirmDelete(originalIndex, serviceId),
                          onToggleActive: (val) async {
                            try {
                              await ServiceService.updateService(serviceId, {'isActive': val});
                              setState(() {
                                _services[originalIndex]['isActive'] = val;
                                _markUpdated();
                              });
                              _showSnackBar('Service visibility updated');
                            } catch (e) {
                              _showSnackBar('Failed to update: ${e.toString()}', isError: true);
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

  AppBar _buildMobileAppBar() {
    return AppBar(
      backgroundColor: kCardColor,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: kTextPrimary),
      title: Text(
        'My Services',
        style: GoogleFonts.poppins(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.grey.shade200),
      ),
      actions: [
        IconButton(onPressed: _openAddService, icon: const Icon(Icons.add)),
      ],
    );
  }

  Widget _buildMobileSummaryHeader(int total, int active, int hidden) {
    String lastUpdatedText = 'Not updated yet';
    if (_lastUpdated != null) {
      lastUpdatedText = _formatDate(_lastUpdated);
    }

    return Row(
      children: [
        _MiniStatCard(icon: Icons.widgets_outlined, label: 'Total', value: total.toString()),
        const SizedBox(width: 8),
        _MiniStatCard(icon: Icons.visibility_outlined, label: 'Active ┃ Hidden', value: '$active   ┃   $hidden'),
        const SizedBox(width: 8),
        Expanded(child: _MiniStatCard(icon: Icons.access_time, label: 'Last Updated', value: lastUpdatedText)),
      ],
    );
  }

  Widget _buildMobileSearchAndFilters() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _searchQuery = value.trim()),
      decoration: InputDecoration(
        hintText: 'Search by name, category, or price',
        hintStyle: GoogleFonts.poppins(fontSize: 13),
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color.fromARGB(255, 142, 142, 142)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: kPrimaryColor),
        ),
      ),
    );
  }

  Widget _buildMobileEmptyState() {
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
              child: const Icon(Icons.widgets_outlined, size: 64, color: kPrimaryColor),
            ),
            const SizedBox(height: 20),
            Text('No Services Yet', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Start by adding your first service.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _openAddService,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: Text('Add Service', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 6),
            Text('Failed to load services',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(_errorMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadServices,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: Text('Retry', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 🧩 WEB WIDGETS
// ════════════════════════════════════════════════════════════════════════════

class _HoverButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _HoverButton({required this.child, required this.onTap});

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: _isHovered ? 0.85 : 1.0,
          child: widget.child,
        ),
      ),
    );
  }
}

class _WebServiceCard extends StatefulWidget {
  final Map<String, dynamic> service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggleActive;

  const _WebServiceCard({
    required this.service,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
    required this.onToggleActive,
  });

  @override
  State<_WebServiceCard> createState() => _WebServiceCardState();
}

class _WebServiceCardState extends State<_WebServiceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.service['isActive'] == true;
    final images = List<String>.from(widget.service['images'] ?? []);
    final double originalPrice = (widget.service['price'] ?? 0).toDouble();
    final String? discountStr = widget.service['discount']?.toString();
    final bool hasDiscount = discountStr != null && discountStr.isNotEmpty;

    double finalPrice = originalPrice;
    if (hasDiscount) {
      final d = double.tryParse(discountStr!) ?? 0;
      finalPrice = originalPrice - (originalPrice * (d / 100));
    }

    final serviceName = widget.service['serviceName'] ?? widget.service['name'] ?? '';
    final category = widget.service['category'] ?? '';
    
    // Check if service is display-only (no price to show)
    final bookingType = widget.service['bookingType']?.toString().toLowerCase() ?? '';
    final isDisplayOnly = bookingType == 'display' || originalPrice <= 0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..translate(0.0, _isHovered ? -4.0 : 0.0),
          decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered ? kPrimaryColor.withOpacity(0.3) : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered ? kPrimaryColor.withOpacity(0.12) : Colors.black.withOpacity(0.04),
                blurRadius: _isHovered ? 16 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image - Compact
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: images.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: images.first,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: Colors.grey.shade100,
                                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: Colors.grey.shade100,
                                child: const Icon(Icons.broken_image, size: 32, color: Colors.grey),
                              ),
                            )
                          : Container(
                              color: kPrimaryLight,
                              child: const Center(
                                child: Icon(LucideIcons.image, size: 32, color: kPrimaryColor),
                              ),
                            ),
                    ),
                  ),
                  // Status Badge - Smaller
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? kSuccessColor : Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(isActive ? LucideIcons.eye : LucideIcons.eyeOff,
                              size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            isActive ? 'Active' : 'Hidden',
                            style: GoogleFonts.poppins(
                                fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Discount Badge
                  if (hasDiscount)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '-$discountStr%',
                          style: GoogleFonts.poppins(
                              fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
              
              // Content - More Compact
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        serviceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w700, color: kTextPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        category,
                        style: GoogleFonts.poppins(fontSize: 11, color: kTextSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      // Price Row with Actions
                      Row(
                        children: [
                          // Price (hidden for display-only services)
                          if (!isDisplayOnly)
                            Expanded(
                              child: Row(
                                children: [
                                  if (hasDiscount)
                                    Text(
                                      '₪${originalPrice.toStringAsFixed(0)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  if (hasDiscount) const SizedBox(width: 4),
                                  Text(
                                    '₪${finalPrice.toStringAsFixed(0)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: hasDiscount ? Colors.red : kPrimaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (isDisplayOnly)
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: kPrimaryLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Display',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: kPrimaryColor,
                                  ),
                                ),
                              ),
                            ),
                          // Quick Actions
                          _HoverButton(
                            onTap: widget.onEdit,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: kBackgroundColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(LucideIcons.edit2, size: 14, color: kPrimaryColor),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _HoverButton(
                            onTap: widget.onDelete,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(LucideIcons.trash2, size: 14, color: Colors.red),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Transform.scale(
                            scale: 0.7,
                            child: Switch(
                              value: isActive,
                              onChanged: widget.onToggleActive,
                              activeColor: kSuccessColor,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 🧩 MOBILE WIDGETS
// ════════════════════════════════════════════════════════════════════════════

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniStatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: kPrimaryColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class _MobileServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleActive;

  const _MobileServiceCard({
    required this.service,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

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
    final description = service['additionalInfo']?['description'] ?? service['fullDescription'] ?? '';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ShowMoreProviderScreen(service: service)),
          );
          if (result != null && result["edit"] == true) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EditServiceProviderScreen(existingData: service)),
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
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: SizedBox(
                      height: 170,
                      width: double.infinity,
                      child: PageView.builder(
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          return Image.network(images[index], fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.broken_image, size: 48),
                                  ));
                        },
                      ),
                    ),
                  ),
                  if (hasDiscount)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
                        child: Text('-${discountStr!.trim()}%',
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                ],
              )
            else
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Container(
                  height: 140,
                  color: Colors.grey.shade100,
                  child: Center(child: Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 40)),
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
                          child: Text(serviceName,
                              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600))),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (hasDiscount)
                            Text('₪${originalPrice.toStringAsFixed(0)}',
                                style: GoogleFonts.poppins(
                                    fontSize: 12, decoration: TextDecoration.lineThrough, color: Colors.grey)),
                          Text('₪${finalPrice.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: hasDiscount ? Colors.redAccent : kPrimaryColor)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(service['category'] ?? '',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 6),
                  Text(description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade800)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green.withOpacity(0.08) : Colors.grey.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(isActive ? 'Active' : 'Hidden',
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isActive ? Colors.green : Colors.grey.shade600)),
                      ),
                      const Spacer(),
                      _StatChip(icon: Icons.calendar_month_outlined, value: '${service['bookings'] ?? 0}'),
                      const SizedBox(width: 6),
                      _StatChip(icon: Icons.favorite_border, value: '${service['likes'] ?? 0}'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: onEdit,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: Text('Edit',
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: onDelete,
                        child: Text('Delete',
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.red, fontWeight: FontWeight.w500)),
                      ),
                      const Spacer(),
                      Text('Visible', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700)),
                      Switch.adaptive(value: isActive, activeColor: kPrimaryColor, onChanged: onToggleActive),
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

  const _StatChip({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Icon(icon, size: 14, color: kPrimaryColor),
          const SizedBox(width: 3),
          Text(value, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
