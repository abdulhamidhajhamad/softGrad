// lib/screens/provider/packages_provider.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_application_1/services/package_service.dart';

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

// ============================================================================
// 📦 BUNDLE PACKAGE MODEL
// ============================================================================
class BundlePackage {
  final String id;
  final String name;
  final List<String> serviceIds;
  final List<String> serviceNames;
  final List<double> servicePrices;
  final double bundlePrice;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? packageImageUrl;
  final bool isActive;
  
  BundlePackage({
    required this.id,
    required this.name,
    required this.serviceIds,
    required this.serviceNames,
    required this.servicePrices,
    required this.bundlePrice,
    this.startDate,
    this.endDate,
    this.packageImageUrl,
    this.isActive = true,
  });

  factory BundlePackage.fromJson(Map<String, dynamic> json) {
    final List<dynamic> servicesArray = json['services'] as List<dynamic>? ?? [];
    
    final List<String> extractedIds = [];
    final List<String> extractedNames = [];
    final List<double> extractedPrices = [];
    
    for (final service in servicesArray) {
      if (service is Map<String, dynamic>) {
        final id = service['serviceId']?.toString() ?? '';
        final name = service['serviceName']?.toString() ?? '';
        final price = (service['newPrice'] as num?)?.toDouble() ?? 0.0;
        if (id.isNotEmpty) extractedIds.add(id);
        if (name.isNotEmpty) extractedNames.add(name);
        extractedPrices.add(price);
      }
    }

    final double price = (json['newPrice'] as num?)?.toDouble() ?? 0.0;
    final DateTime? start = DateTime.tryParse(json['startDate'] as String? ?? '');
    final DateTime? end = DateTime.tryParse(json['endDate'] as String? ?? '');

    return BundlePackage(
      id: json['_id'] as String? ?? '',
      name: json['packageName'] as String? ?? 'N/A',
      serviceIds: extractedIds,
      serviceNames: extractedNames,
      servicePrices: extractedPrices,
      bundlePrice: price,
      startDate: start,
      endDate: end,
      packageImageUrl: json['packageImageUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

// ============================================================================
// 📦 PACKAGES PROVIDER SCREEN
// ============================================================================
class PackagesProviderScreen extends StatefulWidget {
  const PackagesProviderScreen({Key? key}) : super(key: key);

  @override
  State<PackagesProviderScreen> createState() => _PackagesProviderScreenState();
}

class _PackagesProviderScreenState extends State<PackagesProviderScreen> {
  List<BundlePackage> _packages = [];
  List<Map<String, dynamic>> _services = [];
  final Map<String, int> _serviceQuantities = {};

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final fetchedServices = await PackageService.fetchProviderServicesForCreation();
      final fetchedPackagesJson = await PackageService.fetchProviderPackages();

      setState(() {
        _services = fetchedServices;
        _packages = fetchedPackagesJson.map((json) => BundlePackage.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  double _calculateServicePrice(Map<String, dynamic> service) {
    final String priceType = service['priceType'] ?? 'fixed';
    final String serviceId = service['_id'] ?? '';
    final int quantity = _serviceQuantities[serviceId] ?? 1;

    if (priceType == 'hourly') {
      final double perHour = service['perHour'] ?? 0.0;
      return perHour * quantity;
    } else if (priceType == 'capacity') {
      final double perPerson = service['perPerson'] ?? 0.0;
      return perPerson * quantity;
    } else {
      return service['basePrice'] ?? 0.0;
    }
  }

  String _serviceIdAt(int index) => (_services[index]['_id'] ?? '').toString();
  String _serviceNameAt(int index) => (_services[index]['name'] ?? '').toString();

  double _getServicePriceById(String serviceId) {
    final service = _services.firstWhere((s) => s['_id'] == serviceId, orElse: () => {});
    return _calculateServicePrice(service);
  }

  double _baseTotalForPackage(BundlePackage p) {
    double sum = 0;
    for (final id in p.serviceIds) {
      sum += _getServicePriceById(id);
    }
    return sum;
  }

  double _discountPercent(BundlePackage p) {
    final base = _baseTotalForPackage(p);
    if (base <= 0) return 0;
    final diff = base - p.bundlePrice;
    if (diff <= 0) return 0;
    return (diff / base) * 100;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Select date";
    return "${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _deletePackage(String packageId) async {
    setState(() => _isLoading = true);
    try {
      await PackageService.deletePackage(packageId);
      await _fetchData();
      _showSnackBar('Package deleted successfully');
    } catch (e) {
      _showSnackBar('Failed to delete: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoading = false);
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
              Text('Loading packages...', style: GoogleFonts.poppins(color: kTextSecondary)),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Column(
        children: [
          _buildWebTopBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 32 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Banner
                  _buildInfoBanner(),
                  const SizedBox(height: 28),
                  
                  // Stats Row
                  Row(
                    children: [
                      Expanded(child: _buildStatCard(
                        icon: LucideIcons.package,
                        title: 'Total Packages',
                        value: _packages.length.toString(),
                        color: kPrimaryColor,
                      )),
                      const SizedBox(width: 20),
                      Expanded(child: _buildStatCard(
                        icon: LucideIcons.eye,
                        title: 'Active',
                        value: _packages.where((p) => p.isActive).length.toString(),
                        color: kSuccessColor,
                      )),
                      const SizedBox(width: 20),
                      Expanded(child: _buildStatCard(
                        icon: LucideIcons.sparkles,
                        title: 'Available Services',
                        value: _services.length.toString(),
                        color: kWarningColor,
                      )),
                    ],
                  ),
                  const SizedBox(height: 28),
                  
                  // Packages Grid or Empty State
                  if (_packages.isEmpty)
                    _buildEmptyState()
                  else
                    _buildPackagesGrid(isDesktop),
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
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          _HoverButton(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: kBackgroundColor, borderRadius: BorderRadius.circular(12)),
              child: const Icon(LucideIcons.arrowLeft, size: 20, color: kTextSecondary),
            ),
          ),
          const SizedBox(width: 20),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Packages', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: kTextPrimary)),
              Text('Create bundle offers with special prices', style: GoogleFonts.poppins(fontSize: 14, color: kTextSecondary)),
            ],
          ),
          const Spacer(),
          _HoverButton(
            onTap: _fetchData,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: kBackgroundColor, borderRadius: BorderRadius.circular(12)),
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
          if (_services.isNotEmpty)
            _HoverButton(
              onTap: () => _openPackageSheet(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.8)]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: kPrimaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.plus, size: 20, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('Create Package', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: kPrimaryColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(LucideIcons.gift, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bundle Your Services! 🎁', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 6),
                Text(
                  'Combine multiple services into attractive packages with special discounts. Perfect for weddings, events, and more!',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.white.withOpacity(0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({required IconData icon, required String title, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w800, color: kTextPrimary)),
              Text(title, style: GoogleFonts.poppins(fontSize: 13, color: kTextSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPackagesGrid(bool isDesktop) {
    final crossAxisCount = isDesktop ? 3 : 2;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 0.75,
      ),
      itemCount: _packages.length,
      itemBuilder: (context, index) {
        final p = _packages[index];
        return _WebPackageCard(
          package: p,
          baseTotal: _baseTotalForPackage(p),
          discount: _discountPercent(p),
          onEdit: () => _openPackageSheet(editingPackage: p),
          onDelete: () => _confirmDelete(p),
          onToggleActive: (val) => _togglePackageStatus(index, p, val),
        );
      },
    );
  }

  void _confirmDelete(BundlePackage p) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(LucideIcons.alertTriangle, color: Colors.red, size: 22),
            ),
            const SizedBox(width: 12),
            Text('Delete Package', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
          ],
        ),
        content: Text('Are you sure you want to delete "${p.name}"?', style: GoogleFonts.poppins(fontSize: 14, color: kTextSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.poppins(color: kTextSecondary))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePackage(p.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Delete', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _togglePackageStatus(int index, BundlePackage p, bool val) async {
    setState(() {
      _packages[index] = BundlePackage(
        id: p.id, name: p.name, serviceIds: p.serviceIds, serviceNames: p.serviceNames,
        servicePrices: p.servicePrices, bundlePrice: p.bundlePrice, startDate: p.startDate,
        endDate: p.endDate, packageImageUrl: p.packageImageUrl, isActive: val,
      );
    });

    try {
      await PackageService.updatePackageStatus(packageId: p.id, isActive: val);
      _showSnackBar(val ? 'Package is now visible' : 'Package is now hidden');
    } catch (e) {
      setState(() {
        _packages[index] = BundlePackage(
          id: p.id, name: p.name, serviceIds: p.serviceIds, serviceNames: p.serviceNames,
          servicePrices: p.servicePrices, bundlePrice: p.bundlePrice, startDate: p.startDate,
          endDate: p.endDate, packageImageUrl: p.packageImageUrl, isActive: !val,
        );
      });
      _showSnackBar('Failed to update: ${e.toString()}', isError: true);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(60),
        child: Column(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(30)),
              child: const Icon(LucideIcons.package, size: 56, color: kPrimaryColor),
            ),
            const SizedBox(height: 24),
            Text('No Packages Yet', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: kTextPrimary)),
            const SizedBox(height: 8),
            Text(
              _services.isEmpty
                  ? 'Add services first, then come back to create bundles.'
                  : 'Create your first bundle by selecting services and giving them a special price.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 15, color: kTextSecondary),
            ),
            if (_services.isNotEmpty) ...[
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: _services.take(6).map((s) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(20)),
                    child: Text(s['name'] ?? '', style: GoogleFonts.poppins(fontSize: 13, color: kPrimaryColor)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              _HoverButton(
                onTap: () => _openPackageSheet(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.8)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: kPrimaryColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.plus, size: 20, color: Colors.white),
                      const SizedBox(width: 10),
                      Text('Create Your First Package', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
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
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: const Icon(LucideIcons.alertCircle, size: 48, color: Colors.red),
            ),
            const SizedBox(height: 20),
            Text('Failed to load packages', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(_error ?? '', style: GoogleFonts.poppins(fontSize: 14, color: kTextSecondary)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchData,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor, foregroundColor: Colors.white,
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

  // ══════════════════════════════════════════════════════════════════════════
  // 📝 PACKAGE SHEET (Create/Edit)
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _openPackageSheet({BundlePackage? editingPackage}) async {
    final selectedServiceIds = <String>{
      if (editingPackage != null) ...editingPackage.serviceIds,
    };

    final Map<String, TextEditingController> newPriceControllers = {};
    _serviceQuantities.clear();
    
    if (editingPackage != null) {
      for (int i = 0; i < editingPackage.serviceIds.length; i++) {
        final serviceId = editingPackage.serviceIds[i];
        _serviceQuantities[serviceId] = 1;
        if (i < editingPackage.servicePrices.length) {
          newPriceControllers[serviceId] = TextEditingController(text: editingPackage.servicePrices[i].toStringAsFixed(0));
        }
      }
    }

    final nameCtrl = TextEditingController(text: editingPackage?.name ?? '');
    DateTime? startDate = editingPackage?.startDate;
    DateTime? endDate = editingPackage?.endDate;
    Uint8List? coverImageBytes;
    String? existingImageUrl = editingPackage?.packageImageUrl;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            width: 600,
            constraints: const BoxConstraints(maxHeight: 700),
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                double baseTotal = 0;
                double newTotal = 0;
                
                for (final id in selectedServiceIds) {
                  final service = _services.firstWhere((s) => s['_id'] == id, orElse: () => {});
                  final oldPrice = _calculateServicePrice(service);
                  baseTotal += oldPrice;
                  final newPriceCtrl = newPriceControllers[id];
                  if (newPriceCtrl != null) {
                    final newPrice = double.tryParse(newPriceCtrl.text.trim()) ?? 0.0;
                    newTotal += newPrice;
                  }
                }

                double discount = 0;
                if (baseTotal > 0 && newTotal > 0 && newTotal < baseTotal) {
                  discount = ((baseTotal - newTotal) / baseTotal) * 100;
                }

                return Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.8)]),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(LucideIcons.package, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(editingPackage == null ? 'Create New Package' : 'Edit Package',
                                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                                Text('Bundle services with special pricing',
                                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70)),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    
                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Package Name
                            Text('Package Name', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: kTextPrimary)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: nameCtrl,
                              decoration: InputDecoration(
                                hintText: 'e.g., Wedding Complete Package',
                                hintStyle: GoogleFonts.poppins(color: kTextSecondary),
                                prefixIcon: const Icon(LucideIcons.tag, size: 20, color: kTextSecondary),
                                filled: true,
                                fillColor: kBackgroundColor,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Cover Image
                            Text('Cover Image (Optional)', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: kTextPrimary)),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () async {
                                final picker = ImagePicker();
                                final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, maxHeight: 1200, imageQuality: 85);
                                if (picked != null) {
                                  final bytes = await picked.readAsBytes();
                                  setDialogState(() {
                                    coverImageBytes = bytes;
                                    existingImageUrl = null;
                                  });
                                }
                              },
                              child: Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  color: kBackgroundColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: kPrimaryColor.withOpacity(0.3), width: 2, style: BorderStyle.solid),
                                ),
                                child: coverImageBytes != null
                                    ? Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(14),
                                            child: Image.memory(coverImageBytes!, height: 120, width: double.infinity, fit: BoxFit.cover),
                                          ),
                                          Positioned(
                                            top: 8, right: 8,
                                            child: GestureDetector(
                                              onTap: () => setDialogState(() => coverImageBytes = null),
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                                child: const Icon(Icons.close, color: Colors.white, size: 14),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : existingImageUrl != null && existingImageUrl!.isNotEmpty
                                        ? Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(14),
                                                child: CachedNetworkImage(
                                                  imageUrl: existingImageUrl!,
                                                  height: 120, width: double.infinity, fit: BoxFit.cover,
                                                  placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                                ),
                                              ),
                                              Positioned(
                                                top: 8, right: 8,
                                                child: GestureDetector(
                                                  onTap: () => setDialogState(() => existingImageUrl = null),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(6),
                                                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(LucideIcons.imagePlus, size: 32, color: kPrimaryColor.withOpacity(0.5)),
                                              const SizedBox(height: 8),
                                              Text('Click to upload cover image', style: GoogleFonts.poppins(fontSize: 13, color: kTextSecondary)),
                                            ],
                                          ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Select Services
                            Text('Select Services & Set Prices', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: kTextPrimary)),
                            const SizedBox(height: 8),
                            Container(
                              constraints: const BoxConstraints(maxHeight: 200),
                              decoration: BoxDecoration(color: kBackgroundColor, borderRadius: BorderRadius.circular(16)),
                              child: ListView.builder(
                                shrinkWrap: true,
                                padding: const EdgeInsets.all(8),
                                itemCount: _services.length,
                                itemBuilder: (context, index) {
                                  final service = _services[index];
                                  final id = _serviceIdAt(index);
                                  final name = _serviceNameAt(index);
                                  final isChecked = selectedServiceIds.contains(id);
                                  final oldPrice = _calculateServicePrice(service);

                                  if (!newPriceControllers.containsKey(id)) {
                                    newPriceControllers[id] = TextEditingController();
                                  }

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isChecked ? kPrimaryLight : kCardColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: isChecked ? kPrimaryColor : Colors.grey.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          value: isChecked,
                                          activeColor: kPrimaryColor,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                          onChanged: (val) {
                                            setDialogState(() {
                                              if (val == true) {
                                                selectedServiceIds.add(id);
                                                _serviceQuantities[id] = 1;
                                              } else {
                                                selectedServiceIds.remove(id);
                                                _serviceQuantities.remove(id);
                                                newPriceControllers[id]?.clear();
                                              }
                                            });
                                          },
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                                              Text('Original: ₪${oldPrice.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 12, color: kTextSecondary, decoration: isChecked ? TextDecoration.lineThrough : null)),
                                            ],
                                          ),
                                        ),
                                        if (isChecked)
                                          SizedBox(
                                            width: 100,
                                            child: TextField(
                                              controller: newPriceControllers[id],
                                              keyboardType: TextInputType.number,
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: kPrimaryColor),
                                              decoration: InputDecoration(
                                                hintText: '₪0',
                                                hintStyle: GoogleFonts.poppins(color: kTextSecondary),
                                                filled: true,
                                                fillColor: kCardColor,
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kPrimaryColor.withOpacity(0.3))),
                                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kPrimaryColor, width: 2)),
                                              ),
                                              onChanged: (_) => setDialogState(() {}),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Duration
                            Text('Package Duration (Optional)', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: kTextPrimary)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _DatePickerButton(
                                    label: 'Start Date',
                                    value: _formatDate(startDate),
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: ctx,
                                        initialDate: startDate ?? DateTime.now(),
                                        firstDate: DateTime(DateTime.now().year - 1),
                                        lastDate: DateTime(DateTime.now().year + 3),
                                      );
                                      if (picked != null) setDialogState(() => startDate = picked);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _DatePickerButton(
                                    label: 'End Date',
                                    value: _formatDate(endDate),
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: ctx,
                                        initialDate: endDate ?? (startDate ?? DateTime.now()),
                                        firstDate: startDate ?? DateTime.now(),
                                        lastDate: DateTime(DateTime.now().year + 3),
                                      );
                                      if (picked != null) setDialogState(() => endDate = picked);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            
                            // Summary
                            if (selectedServiceIds.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: kSuccessColor.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Summary', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: kTextPrimary)),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Original Total:', style: GoogleFonts.poppins(fontSize: 14, color: kTextSecondary)),
                                        Text('₪${baseTotal.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 14, decoration: TextDecoration.lineThrough, color: kTextSecondary)),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Bundle Price:', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: kPrimaryColor)),
                                        Text('₪${newTotal.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: kPrimaryColor)),
                                      ],
                                    ),
                                    if (discount > 0)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Discount:', style: GoogleFonts.poppins(fontSize: 14, color: kSuccessColor)),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(color: kSuccessColor, borderRadius: BorderRadius.circular(20)),
                                            child: Text('-${discount.toStringAsFixed(1)}%', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    
                    // Actions
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: kCardColor,
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text('Cancel', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: kTextSecondary)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () {
                                final name = nameCtrl.text.trim();
                                if (name.isEmpty || selectedServiceIds.isEmpty) {
                                  _showSnackBar('Please fill name and select services', isError: true);
                                  return;
                                }

                                bool allHavePrices = true;
                                for (final id in selectedServiceIds) {
                                  final priceText = newPriceControllers[id]?.text.trim() ?? '';
                                  if ((double.tryParse(priceText) ?? 0) <= 0) {
                                    allHavePrices = false;
                                    break;
                                  }
                                }

                                if (!allHavePrices) {
                                  _showSnackBar('Please enter prices for all services', isError: true);
                                  return;
                                }

                                double totalNewPrice = 0;
                                final List<Map<String, dynamic>> formattedServices = [];
                                for (final id in selectedServiceIds) {
                                  final priceText = newPriceControllers[id]?.text.trim() ?? '';
                                  final price = double.tryParse(priceText) ?? 0;
                                  totalNewPrice += price;
                                  formattedServices.add({'id': id, 'serviceId': id, 'customPrice': price, 'newPrice': price});
                                }

                                Navigator.pop(ctx, {
                                  'packageName': name,
                                  'services': formattedServices,
                                  'totalPrice': totalNewPrice,
                                  'startDate': startDate,
                                  'endDate': endDate,
                                  'coverImageBytes': coverImageBytes,
                                  'existingImageUrl': existingImageUrl,
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text(editingPackage == null ? 'Create Package' : 'Save Changes',
                                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    if (result != null) {
      setState(() => _isLoading = true);
      try {
        if (editingPackage != null) {
          await PackageService.updatePackage(
            packageId: editingPackage.id,
            newPackageName: result['packageName'],
            services: result['services'],
            newPrice: result['totalPrice'],
            startDate: result['startDate'],
            endDate: result['endDate'],
            newCoverImageBytes: result['coverImageBytes'],
            existingImageUrl: result['existingImageUrl'],
          );
          _showSnackBar('Package updated successfully!');
        } else {
          await PackageService.createPackage(
            packageName: result['packageName'],
            services: result['services'],
            totalPrice: result['totalPrice'],
            startDate: result['startDate'],
            endDate: result['endDate'],
            coverImageBytes: result['coverImageBytes'],
          );
          _showSnackBar('Package created successfully!');
        }
        await _fetchData();
      } catch (e) {
        _showSnackBar('Failed: ${e.toString()}', isError: true);
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 📱 MOBILE LAYOUT
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout() {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: kBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          backgroundColor: kCardColor, elevation: 0.5, centerTitle: true,
          title: Text('My Packages', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: kTextPrimary)),
          iconTheme: const IconThemeData(color: kTextPrimary),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 10),
              Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.red)),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _fetchData, style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor), child: const Text('Try Again')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kCardColor, elevation: 0.5, centerTitle: true,
        title: Text('My Packages', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: kTextPrimary)),
        iconTheme: const IconThemeData(color: kTextPrimary),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: kPrimaryColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))]),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.all_inclusive_rounded, color: kPrimaryColor, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Select multiple services and create bundle offers with a special price.', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[800], height: 1.3))),
                  ],
                ),
              ),

              if (_packages.isEmpty)
                _MobileEmptyPackagesCard(services: _services)
              else
                ...List.generate(_packages.length, (index) {
                  final p = _packages[index];
                  return _MobilePackageCard(
                    package: p,
                    baseTotal: _baseTotalForPackage(p),
                    discount: _discountPercent(p),
                    formatDate: _formatDate,
                    onEdit: () => _openPackageSheet(editingPackage: p),
                    onDelete: () => _deletePackage(p.id),
                    onToggleActive: (val) => _togglePackageStatus(index, p, val),
                  );
                }),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _services.isEmpty ? null : FloatingActionButton.extended(
        onPressed: () => _openPackageSheet(),
        backgroundColor: kPrimaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text("Add Package", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
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
        child: AnimatedOpacity(duration: const Duration(milliseconds: 150), opacity: _isHovered ? 0.85 : 1.0, child: widget.child),
      ),
    );
  }
}

class _WebPackageCard extends StatefulWidget {
  final BundlePackage package;
  final double baseTotal;
  final double discount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleActive;

  const _WebPackageCard({
    required this.package,
    required this.baseTotal,
    required this.discount,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  State<_WebPackageCard> createState() => _WebPackageCardState();
}

class _WebPackageCardState extends State<_WebPackageCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.package;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..translate(0.0, _isHovered ? -6.0 : 0.0),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _isHovered ? kPrimaryColor.withOpacity(0.15) : Colors.black.withOpacity(0.04),
              blurRadius: _isHovered ? 20 : 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: p.packageImageUrl != null && p.packageImageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: p.packageImageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: Colors.grey.shade100, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                            errorWidget: (_, __, ___) => Container(color: Colors.grey.shade100, child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey)),
                          )
                        : Container(color: kPrimaryLight, child: const Center(child: Icon(LucideIcons.package, size: 40, color: kPrimaryColor))),
                  ),
                ),
                // Status
                Positioned(
                  top: 12, left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: p.isActive ? kSuccessColor : Colors.grey, borderRadius: BorderRadius.circular(20)),
                    child: Text(p.isActive ? 'Active' : 'Hidden', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
                // Discount
                if (widget.discount > 0)
                  Positioned(
                    top: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: kSuccessColor, borderRadius: BorderRadius.circular(20)),
                      child: Text('-${widget.discount.toStringAsFixed(0)}%', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
              ],
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: kTextPrimary)),
                    const SizedBox(height: 4),
                    if (p.serviceNames.isNotEmpty)
                      Text('${p.serviceNames.length} services included', style: GoogleFonts.poppins(fontSize: 12, color: kTextSecondary)),
                    const Spacer(),
                    // Price
                    Row(
                      children: [
                        if (widget.baseTotal > 0)
                          Text('₪${widget.baseTotal.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 13, decoration: TextDecoration.lineThrough, color: Colors.grey)),
                        if (widget.baseTotal > 0) const SizedBox(width: 8),
                        Text('₪${p.bundlePrice.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: kPrimaryColor)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: _HoverButton(
                            onTap: widget.onEdit,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(10)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(LucideIcons.edit3, size: 16, color: kPrimaryColor),
                                  const SizedBox(width: 6),
                                  Text('Edit', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: kPrimaryColor)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _HoverButton(
                          onTap: widget.onDelete,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(value: p.isActive, activeColor: kPrimaryColor, onChanged: widget.onToggleActive),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePickerButton extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DatePickerButton({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: kBackgroundColor, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            const Icon(LucideIcons.calendar, size: 18, color: kTextSecondary),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.poppins(fontSize: 11, color: kTextSecondary)),
                Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: kTextPrimary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 🧩 MOBILE WIDGETS
// ════════════════════════════════════════════════════════════════════════════

class _MobileEmptyPackagesCard extends StatelessWidget {
  final List<Map<String, dynamic>> services;
  const _MobileEmptyPackagesCard({required this.services});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("No packages yet", style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text("Create your first bundle by selecting services and giving them a special price.", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700], height: 1.3)),
          const SizedBox(height: 12),
          if (services.isNotEmpty)
            Wrap(
              spacing: 8, runSpacing: 6,
              children: services.map((s) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(999)),
                  child: Text(s['name'] ?? '', style: GoogleFonts.poppins(fontSize: 11.5, color: kPrimaryColor)),
                );
              }).toList(),
            )
          else
            Text("Add services first, then come back to create bundles.", style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _MobilePackageCard extends StatelessWidget {
  final BundlePackage package;
  final double baseTotal;
  final double discount;
  final String Function(DateTime?) formatDate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleActive;

  const _MobilePackageCard({
    required this.package,
    required this.baseTotal,
    required this.discount,
    required this.formatDate,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final p = package;
    String? rangeText;
    if (p.startDate != null && p.endDate != null) {
      rangeText = "${formatDate(p.startDate)}  -  ${formatDate(p.endDate)}";
    } else if (p.startDate != null) {
      rangeText = "From ${formatDate(p.startDate)}";
    } else if (p.endDate != null) {
      rangeText = "Until ${formatDate(p.endDate)}";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p.packageImageUrl != null && p.packageImageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Image.network(p.packageImageUrl!, width: double.infinity, height: 170, fit: BoxFit.cover,
                  loadingBuilder: (_, child, loadingProgress) => loadingProgress == null ? child : Container(height: 170, color: Colors.grey.shade200, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                  errorBuilder: (_, __, ___) => Container(height: 170, color: Colors.grey.shade100, child: const Center(child: Icon(Icons.image_not_supported_outlined, size: 48, color: kPrimaryColor)))),
            )
          else
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Container(width: double.infinity, height: 170, color: Colors.grey.shade100, child: Center(child: Icon(Icons.inventory_2_rounded, color: Colors.grey.shade400, size: 48))),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(p.name, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600))),
                    Text("₪${p.bundlePrice.toStringAsFixed(0)}", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryColor)),
                  ],
                ),
                const SizedBox(height: 4),
                if (p.serviceNames.isNotEmpty) Text("Includes: ${p.serviceNames.join(', ')}", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                if (rangeText != null) ...[
                  const SizedBox(height: 6),
                  Row(children: [Icon(Icons.schedule_outlined, size: 16, color: Colors.grey[700]), const SizedBox(width: 4), Text(rangeText, style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey[700]))]),
                ],
                const SizedBox(height: 6),
                if (baseTotal > 0)
                  Row(children: [
                    Text("Base: ₪${baseTotal.toStringAsFixed(0)}", style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey[700])),
                    if (discount > 0) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: kSuccessColor.withOpacity(0.15), borderRadius: BorderRadius.circular(999)),
                        child: Text("-${discount.toStringAsFixed(1)}%", style: GoogleFonts.poppins(fontSize: 11, color: kSuccessColor, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ]),
                const SizedBox(height: 10),
                Row(children: [
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), side: BorderSide(color: Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text('Edit', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(width: 8),
                  TextButton(onPressed: onDelete, child: Text('Delete', style: GoogleFonts.poppins(fontSize: 13, color: Colors.red, fontWeight: FontWeight.w500))),
                  const Spacer(),
                  Text('Visible', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700)),
                  Switch.adaptive(value: p.isActive, activeColor: kPrimaryColor, onChanged: onToggleActive),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
