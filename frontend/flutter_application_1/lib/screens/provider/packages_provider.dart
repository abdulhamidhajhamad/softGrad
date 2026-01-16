// lib/screens/provider/packages_provider.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_application_1/services/package_service.dart';

const Color kPrimaryColor = Color.fromARGB(215, 20, 20, 215);

class BundlePackage {
  final String id;
  final String name;
  final List<String> serviceIds;
  final List<String> serviceNames;
  final List<double> servicePrices; // ✅ أسعار الخدمات داخل الباقة
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
    // ✅ التعديل هنا - نجيب services من الـ array
    final List<dynamic> servicesArray = json['services'] as List<dynamic>? ?? [];
    
    // نستخرج الـ IDs والأسماء والأسعار من services array
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
        _packages = fetchedPackagesJson
            .map((json) => BundlePackage.fromJson(json))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
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

  String _serviceNameAt(int index) =>
      (_services[index]['name'] ?? '').toString();

  double _getServicePriceById(String serviceId) {
    final service = _services.firstWhere(
      (s) => s['_id'] == serviceId,
      orElse: () => {},
    );
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
    print('Attempting to delete package with ID: $packageId');
    setState(() => _isLoading = true);
    try {
      await PackageService.deletePackage(packageId);
      await _fetchData();
    } catch (e) {
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _openPackageSheet({BundlePackage? editingPackage}) async {
    final selectedServiceIds = <String>{
      if (editingPackage != null) ...editingPackage.serviceIds,
    };

    final Map<String, TextEditingController> newPriceControllers = {};
    
    _serviceQuantities.clear();
    
    // ✅ عند التعديل، نملأ الأسعار من الباقة الموجودة
    if (editingPackage != null) {
      for (int i = 0; i < editingPackage.serviceIds.length; i++) {
        final serviceId = editingPackage.serviceIds[i];
        _serviceQuantities[serviceId] = 1;
        // ✅ إضافة controller بالسعر المحدد مسبقاً
        if (i < editingPackage.servicePrices.length) {
          newPriceControllers[serviceId] = TextEditingController(
            text: editingPackage.servicePrices[i].toStringAsFixed(0),
          );
        }
      }
    }

    final nameCtrl = TextEditingController(text: editingPackage?.name ?? '');

    DateTime? startDate = editingPackage?.startDate;
    DateTime? endDate = editingPackage?.endDate;
    
    // ✅ صورة الغلاف
    Uint8List? coverImageBytes;
    String? existingImageUrl = editingPackage?.packageImageUrl;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 16,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              double baseTotal = 0;
              double newTotal = 0;
              
              for (final id in selectedServiceIds) {
                final service = _services.firstWhere(
                  (s) => s['_id'] == id,
                  orElse: () => {},
                );
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

              Future<void> pickStartDate() async {
                final now = DateTime.now();
                final first = DateTime(now.year - 1, now.month, now.day);
                final last = DateTime(now.year + 3, now.month, now.day);
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: startDate ?? now,
                  firstDate: first,
                  lastDate: last,
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: kPrimaryColor,
                          onPrimary: Colors.white,
                          onSurface: Colors.black,
                        ),
                        textButtonTheme: TextButtonThemeData(
                          style: TextButton.styleFrom(
                            foregroundColor: kPrimaryColor,
                          ),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setSheetState(() {
                    startDate = picked;
                    if (endDate != null && endDate!.isBefore(startDate!)) {
                      endDate = startDate;
                    }
                  });
                }
              }

              Future<void> pickEndDate() async {
                final now = DateTime.now();
                final first = startDate ?? now;
                final last = DateTime(now.year + 3, now.month, now.day);
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: endDate ?? first,
                  firstDate: first,
                  lastDate: last,
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: kPrimaryColor,
                          onPrimary: Colors.white,
                          onSurface: Colors.black,
                        ),
                        textButtonTheme: TextButtonThemeData(
                          style: TextButton.styleFrom(
                            foregroundColor: kPrimaryColor,
                          ),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setSheetState(() {
                    endDate = picked;
                  });
                }
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Text(
                      editingPackage == null
                          ? "Create new package"
                          : "Edit package",
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: "Package name",
                        labelStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                          borderSide: BorderSide(
                            color: kPrimaryColor,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),

                    const SizedBox(height: 18),
                    
                    // ✅ قسم صورة الغلاف (اختياري)
                    Text(
                      "Cover image (optional)",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 1200,
                          maxHeight: 1200,
                          imageQuality: 85,
                        );
                        if (picked != null) {
                          final bytes = await picked.readAsBytes();
                          setSheetState(() {
                            coverImageBytes = bytes;
                            existingImageUrl = null; // نستبدل الصورة القديمة
                          });
                        }
                      },
                      child: Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                            width: 1.5,
                          ),
                        ),
                        child: coverImageBytes != null
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.memory(
                                      coverImageBytes!,
                                      height: 140,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () {
                                        setSheetState(() {
                                          coverImageBytes = null;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, color: Colors.white, size: 16),
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
                                          height: 140,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => const Center(
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                          errorWidget: (_, __, ___) => const Icon(Icons.error),
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: () {
                                            setSheetState(() {
                                              existingImageUrl = null;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate_outlined,
                                          size: 40, color: Colors.grey[400]),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Tap to add cover image",
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                    
                    const SizedBox(height: 18),

                    // ✅ زر لاختيار الخدمات وتحديد الأسعار
                    InkWell(
                      onTap: _services.isEmpty ? null : () async {
                        await showModalBottomSheet(
                          context: ctx,
                          isScrollControlled: true,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (dialogCtx) {
                            return StatefulBuilder(
                              builder: (context, setDialogState) {
                                return DraggableScrollableSheet(
                                  initialChildSize: 0.7,
                                  minChildSize: 0.5,
                                  maxChildSize: 0.9,
                                  expand: false,
                                  builder: (context, scrollController) {
                                    return Column(
                                      children: [
                                        // Header
                                        Container(
                                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.05),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 4,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade300,
                                                  borderRadius: BorderRadius.circular(999),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: kPrimaryColor.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: const Icon(Icons.checklist_rounded, color: kPrimaryColor, size: 20),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          editingPackage == null 
                                                              ? "Select Services" 
                                                              : "Edit Services & Prices",
                                                          style: GoogleFonts.poppins(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                        Text(
                                                          "${selectedServiceIds.length} selected",
                                                          style: GoogleFonts.poppins(
                                                            fontSize: 12,
                                                            color: Colors.grey[600],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(dialogCtx),
                                                    child: Text(
                                                      "Done",
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w600,
                                                        color: kPrimaryColor,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Services List
                                        Expanded(
                                          child: ListView.builder(
                                            controller: scrollController,
                                            padding: const EdgeInsets.all(16),
                                            itemCount: _services.length,
                                            itemBuilder: (context, index) {
                                              final service = _services[index];
                                              final name = _serviceNameAt(index);
                                              final id = _serviceIdAt(index);
                                              final String priceType = service['priceType'] ?? 'fixed';
                                              final isChecked = selectedServiceIds.contains(id);
                                              final double oldPrice = _calculateServicePrice(service);
                                              final int currentQty = _serviceQuantities[id] ?? 1;

                                              if (!newPriceControllers.containsKey(id)) {
                                                newPriceControllers[id] = TextEditingController();
                                              }

                                              return AnimatedContainer(
                                                duration: const Duration(milliseconds: 200),
                                                margin: const EdgeInsets.only(bottom: 10),
                                                decoration: BoxDecoration(
                                                  color: isChecked ? kPrimaryColor.withOpacity(0.05) : Colors.white,
                                                  borderRadius: BorderRadius.circular(14),
                                                  border: Border.all(
                                                    color: isChecked ? kPrimaryColor : Colors.grey.shade200,
                                                    width: isChecked ? 1.5 : 1,
                                                  ),
                                                  boxShadow: isChecked ? [
                                                    BoxShadow(
                                                      color: kPrimaryColor.withOpacity(0.1),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ] : null,
                                                ),
                                                child: Column(
                                                  children: [
                                                    // Service Header - Tap to select
                                                    InkWell(
                                                      onTap: () {
                                                        setDialogState(() {
                                                          if (isChecked) {
                                                            selectedServiceIds.remove(id);
                                                            _serviceQuantities.remove(id);
                                                            newPriceControllers[id]?.clear();
                                                          } else {
                                                            selectedServiceIds.add(id);
                                                            if (!_serviceQuantities.containsKey(id)) {
                                                              _serviceQuantities[id] = 1;
                                                            }
                                                          }
                                                        });
                                                        setSheetState(() {}); // Update parent
                                                      },
                                                      borderRadius: BorderRadius.circular(14),
                                                      child: Padding(
                                                        padding: const EdgeInsets.all(14),
                                                        child: Row(
                                                          children: [
                                                            AnimatedContainer(
                                                              duration: const Duration(milliseconds: 200),
                                                              width: 24,
                                                              height: 24,
                                                              decoration: BoxDecoration(
                                                                color: isChecked ? kPrimaryColor : Colors.transparent,
                                                                borderRadius: BorderRadius.circular(6),
                                                                border: Border.all(
                                                                  color: isChecked ? kPrimaryColor : Colors.grey.shade400,
                                                                  width: 2,
                                                                ),
                                                              ),
                                                              child: isChecked
                                                                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                                                                  : null,
                                                            ),
                                                            const SizedBox(width: 14),
                                                            Expanded(
                                                              child: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Text(
                                                                    name,
                                                                    style: GoogleFonts.poppins(
                                                                      fontSize: 14,
                                                                      fontWeight: FontWeight.w600,
                                                                      color: isChecked ? kPrimaryColor : Colors.black87,
                                                                    ),
                                                                  ),
                                                                  Text(
                                                                    service['priceLabel'] ?? 'Fixed Price',
                                                                    style: GoogleFonts.poppins(
                                                                      fontSize: 11,
                                                                      color: Colors.grey[600],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                              decoration: BoxDecoration(
                                                                color: Colors.grey.shade100,
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                              child: Text(
                                                                "₪${oldPrice.toStringAsFixed(0)}",
                                                                style: GoogleFonts.poppins(
                                                                  fontSize: 13,
                                                                  fontWeight: FontWeight.w600,
                                                                  color: Colors.grey[700],
                                                                  decoration: isChecked ? TextDecoration.lineThrough : null,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    // Price Input - Only when selected
                                                    if (isChecked)
                                                      Container(
                                                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                                                        child: Column(
                                                          children: [
                                                            const Divider(height: 1),
                                                            const SizedBox(height: 12),
                                                            if (priceType == 'hourly' || priceType == 'capacity')
                                                              Padding(
                                                                padding: const EdgeInsets.only(bottom: 10),
                                                                child: Row(
                                                                  children: [
                                                                    Icon(
                                                                      priceType == 'hourly' ? Icons.schedule : Icons.people_outline,
                                                                      size: 18,
                                                                      color: Colors.grey[600],
                                                                    ),
                                                                    const SizedBox(width: 8),
                                                                    Expanded(
                                                                      child: Text(
                                                                        priceType == 'hourly' ? "Hours" : "People",
                                                                        style: GoogleFonts.poppins(
                                                                          fontSize: 13,
                                                                          color: Colors.grey[700],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Container(
                                                                      width: 80,
                                                                      height: 36,
                                                                      child: TextField(
                                                                        keyboardType: TextInputType.number,
                                                                        textAlign: TextAlign.center,
                                                                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                                                                        decoration: InputDecoration(
                                                                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                                          filled: true,
                                                                          fillColor: Colors.grey.shade50,
                                                                          border: OutlineInputBorder(
                                                                            borderRadius: BorderRadius.circular(8),
                                                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                                                          ),
                                                                          enabledBorder: OutlineInputBorder(
                                                                            borderRadius: BorderRadius.circular(8),
                                                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                                                          ),
                                                                          focusedBorder: OutlineInputBorder(
                                                                            borderRadius: BorderRadius.circular(8),
                                                                            borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
                                                                          ),
                                                                        ),
                                                                        onChanged: (v) {
                                                                          final qty = int.tryParse(v.trim()) ?? 1;
                                                                          setDialogState(() {
                                                                            _serviceQuantities[id] = qty > 0 ? qty : 1;
                                                                          });
                                                                          setSheetState(() {});
                                                                        },
                                                                        controller: TextEditingController(text: currentQty.toString()),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            Row(
                                                              children: [
                                                                const Icon(Icons.local_offer_outlined, size: 18, color: kPrimaryColor),
                                                                const SizedBox(width: 8),
                                                                Expanded(
                                                                  child: Text(
                                                                    "New price (₪)",
                                                                    style: GoogleFonts.poppins(
                                                                      fontSize: 13,
                                                                      fontWeight: FontWeight.w500,
                                                                      color: kPrimaryColor,
                                                                    ),
                                                                  ),
                                                                ),
                                                                Container(
                                                                  width: 100,
                                                                  height: 40,
                                                                  child: TextField(
                                                                    controller: newPriceControllers[id],
                                                                    keyboardType: TextInputType.number,
                                                                    textAlign: TextAlign.center,
                                                                    style: GoogleFonts.poppins(
                                                                      fontSize: 15,
                                                                      fontWeight: FontWeight.w700,
                                                                      color: kPrimaryColor,
                                                                    ),
                                                                    decoration: InputDecoration(
                                                                      hintText: "0",
                                                                      hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                                                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                                      filled: true,
                                                                      fillColor: kPrimaryColor.withOpacity(0.05),
                                                                      border: OutlineInputBorder(
                                                                        borderRadius: BorderRadius.circular(10),
                                                                        borderSide: BorderSide(color: kPrimaryColor.withOpacity(0.3)),
                                                                      ),
                                                                      enabledBorder: OutlineInputBorder(
                                                                        borderRadius: BorderRadius.circular(10),
                                                                        borderSide: BorderSide(color: kPrimaryColor.withOpacity(0.3)),
                                                                      ),
                                                                      focusedBorder: OutlineInputBorder(
                                                                        borderRadius: BorderRadius.circular(10),
                                                                        borderSide: const BorderSide(color: kPrimaryColor, width: 2),
                                                                      ),
                                                                    ),
                                                                    onChanged: (_) {
                                                                      setDialogState(() {});
                                                                      setSheetState(() {});
                                                                    },
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                        setSheetState(() {}); // Refresh parent after closing dialog
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: selectedServiceIds.isEmpty 
                              ? const Color(0xFFF9FAFB) 
                              : kPrimaryColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selectedServiceIds.isEmpty 
                                ? const Color(0xFFE5E7EB) 
                                : kPrimaryColor.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: selectedServiceIds.isEmpty 
                                        ? Colors.grey.shade100 
                                        : kPrimaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    selectedServiceIds.isEmpty 
                                        ? Icons.add_circle_outline 
                                        : Icons.checklist_rounded,
                                    color: selectedServiceIds.isEmpty 
                                        ? Colors.grey[600] 
                                        : kPrimaryColor,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        editingPackage == null 
                                            ? "Select services & prices"
                                            : "Edit services & prices",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: selectedServiceIds.isEmpty 
                                              ? Colors.grey[800] 
                                              : kPrimaryColor,
                                        ),
                                      ),
                                      Text(
                                        selectedServiceIds.isEmpty
                                            ? "Tap to choose services for this package"
                                            : "${selectedServiceIds.length} service${selectedServiceIds.length > 1 ? 's' : ''} selected",
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: selectedServiceIds.isEmpty 
                                      ? Colors.grey[400] 
                                      : kPrimaryColor,
                                  size: 24,
                                ),
                              ],
                            ),
                            // Show selected services summary
                            if (selectedServiceIds.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: selectedServiceIds.map((id) {
                                  final service = _services.firstWhere(
                                    (s) => s['_id'] == id,
                                    orElse: () => {},
                                  );
                                  final name = service['name'] ?? '';
                                  final priceText = newPriceControllers[id]?.text.trim() ?? '';
                                  final price = double.tryParse(priceText) ?? 0;
                                  
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          name.length > 12 ? '${name.substring(0, 12)}...' : name,
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (price > 0) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: kPrimaryColor,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              "₪${price.toStringAsFixed(0)}",
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    if (_services.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          "No services found. Add services first.",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),

                    const SizedBox(height: 14),

                    Text(
                      "Package duration (optional)",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: pickStartDate,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 16,
                                    color: Colors.grey[700],
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Start",
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          _formatDate(startDate),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[900],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: pickEndDate,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_month_outlined,
                                    size: 16,
                                    color: Colors.grey[700],
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "End",
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          _formatDate(endDate),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[900],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    if (baseTotal > 0 && selectedServiceIds.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Summary",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Base total: ₪${baseTotal.toStringAsFixed(0)}",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[800],
                              ),
                            ),
                            if (newTotal > 0)
                              Text(
                                "Bundle price: ₪${newTotal.toStringAsFixed(0)}",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[800],
                                ),
                              ),
                            if (discount > 0)
                              Text(
                                "You give ~${discount.toStringAsFixed(1)}% off",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: () {
                          final name = nameCtrl.text.trim();
                          
                          if (name.isEmpty || selectedServiceIds.isEmpty) {
                            _showSnackBar(
                                "Please fill name and select at least one service.");
                            return;
                          }

                          bool allHavePrices = true;
                          for (final id in selectedServiceIds) {
                            final priceText = newPriceControllers[id]?.text.trim() ?? '';
                            final price = double.tryParse(priceText) ?? 0;
                            if (price <= 0) {
                              allHavePrices = false;
                              break;
                            }
                          }

                          if (!allHavePrices) {
                            _showSnackBar(
                                "Please enter a new price for all selected services.");
                            return;
                          }

                          double totalNewPrice = 0;
                          for (final id in selectedServiceIds) {
                            final priceText = newPriceControllers[id]?.text.trim() ?? '';
                            final price = double.tryParse(priceText) ?? 0;
                            totalNewPrice += price;
                          }

                        final List<Map<String, dynamic>> formattedServices = [];
                        for (final id in selectedServiceIds) {
                          final priceText = newPriceControllers[id]?.text.trim() ?? '';
                          final price = double.tryParse(priceText) ?? 0;
                          formattedServices.add({
                            'id': id,
                            'serviceId': id, // ✅ للتوافق مع الباك إند
                            'customPrice': price,
                            'newPrice': price, // ✅ للتوافق مع الباك إند
                          });
                        }

                        Navigator.pop(ctx, {
                          'packageName': name,
                          'services': formattedServices,
                          'totalPrice': totalNewPrice,
                          'startDate': startDate,
                          'endDate': endDate,
                          'coverImageBytes': coverImageBytes, // ✅ صورة الغلاف
                          'existingImageUrl': existingImageUrl, // ✅ URL الصورة الحالية
                        });
                        },
                        child: Text(
                          editingPackage == null
                              ? "Create package"
                              : "Save changes",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    if (result != null) {
      if (editingPackage != null) {
        setState(() {
          _isLoading = true;
        });
        try {
          await PackageService.updatePackage(
            packageId: editingPackage.id,
            newPackageName: result['packageName'],
            services: result['services'], // ✅ تم التغيير لإرسال map كامل
            newPrice: result['totalPrice'],
            startDate: result['startDate'],
            endDate: result['endDate'],
            newCoverImageBytes: result['coverImageBytes'], // ✅ صورة جديدة
            existingImageUrl: result['existingImageUrl'], // ✅ URL الصورة الحالية
          );
          await _fetchData();
          _showSnackBar('✅ Package updated successfully!');
        } catch (e) {
          print('Error updating package: $e');
          _showSnackBar('❌ Failed to update package: ${e.toString()}');
        } finally {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = true;
        });
        try {
            await PackageService.createPackage(
              packageName: result['packageName'],
              services: result['services'],
              totalPrice: result['totalPrice'],
              startDate: result['startDate'],
              endDate: result['endDate'],
              coverImageBytes: result['coverImageBytes'], // ✅ صورة الغلاف
            );
          await _fetchData();
          _showSnackBar('✅ Package created successfully!');
        } catch (e) {
          print('Error creating package: $e');
          _showSnackBar('❌ Failed to create package: ${e.toString()}');
        } finally {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: kPrimaryColor),
              SizedBox(height: 16),
              Text('Loading packages and services...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 40),
                const SizedBox(height: 10),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.red),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _fetchData,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final hasPackages = _packages.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: Text(
          'My Packages',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: kPrimaryColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0EAFF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.all_inclusive_rounded,
                        color: kPrimaryColor,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Select multiple services and create bundle offers with a special price.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[800],
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (!hasPackages)
                _EmptyPackagesCard(services: _services)
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(_packages.length, (index) {
                    final p = _packages[index];
                    final baseTotal = _baseTotalForPackage(p);
                    final discount = _discountPercent(p);

                    final includedNames = p.serviceNames ?? [];

                    String? rangeText;
                    if (p.startDate != null && p.endDate != null) {
                      rangeText =
                          "${_formatDate(p.startDate)}  -  ${_formatDate(p.endDate)}";
                    } else if (p.startDate != null) {
                      rangeText = "From ${_formatDate(p.startDate)}";
                    } else if (p.endDate != null) {
                      rangeText = "Until ${_formatDate(p.endDate)}";
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (p.packageImageUrl != null &&
                              p.packageImageUrl!.isNotEmpty)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(18)),
                              child: Image.network(
                                p.packageImageUrl!,
                                width: double.infinity,
                                height: 170,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: double.infinity,
                                    height: 170,
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                          color: kPrimaryColor, strokeWidth: 2),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  width: double.infinity,
                                  height: 170,
                                  color: Colors.grey.shade100,
                                  child: const Center(
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      size: 48,
                                      color: kPrimaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(18)),
                              child: Container(
                                width: double.infinity,
                                height: 170,
                                color: Colors.grey.shade100,
                                child: Center(
                                  child: Icon(Icons.inventory_2_rounded,
                                      color: Colors.grey.shade400, size: 48),
                                ),
                              ),
                            ),
                          
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        p.name,
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      "₪${p.bundlePrice.toStringAsFixed(0)}",
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: kPrimaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (includedNames.isNotEmpty)
                                  Text(
                                    "Includes: ${includedNames.join(', ')}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                if (rangeText != null) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.schedule_outlined,
                                        size: 16,
                                        color: Colors.grey[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          rangeText,
                                          style: GoogleFonts.poppins(
                                            fontSize: 11.5,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 6),
                                if (baseTotal > 0)
                                  Row(
                                    children: [
                                      Text(
                                        "Base: ₪${baseTotal.toStringAsFixed(0)}",
                                        style: GoogleFonts.poppins(
                                          fontSize: 11.5,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      if (discount > 0) ...[
                                        const SizedBox(width: 10),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE8F5E9),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            "-${discount.toStringAsFixed(1)}%",
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: const Color(0xFF2E7D32),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          _openPackageSheet(editingPackage: p),
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
                                      onPressed: () => _deletePackage(p.id),
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
                                      value: p.isActive,
                                      activeColor: kPrimaryColor,
                                      inactiveThumbColor: Colors.grey.shade400,
                                      inactiveTrackColor: Colors.grey.shade300,
                                      onChanged: (val) async {
                                        setState(() {
                                          _packages[index] = BundlePackage(
                                            id: p.id,
                                            name: p.name,
                                            serviceIds: p.serviceIds,
                                            serviceNames: p.serviceNames,
                                            servicePrices: p.servicePrices,
                                            bundlePrice: p.bundlePrice,
                                            startDate: p.startDate,
                                            endDate: p.endDate,
                                            packageImageUrl: p.packageImageUrl,
                                            isActive: val,
                                          );
                                        });

                                        try {
                                          await PackageService.updatePackageStatus(
                                            packageId: p.id,
                                            isActive: val,
                                          );
                                          _showSnackBar(val 
                                              ? 'Package is now visible' 
                                              : 'Package is now hidden');
                                        } catch (e) {
                                          setState(() {
                                            _packages[index] = BundlePackage(
                                              id: p.id,
                                              name: p.name,
                                              serviceIds: p.serviceIds,
                                              serviceNames: p.serviceNames,
                                              servicePrices: p.servicePrices,
                                              bundlePrice: p.bundlePrice,
                                              startDate: p.startDate,
                                              endDate: p.endDate,
                                              packageImageUrl: p.packageImageUrl,
                                              isActive: !val,
                                            );
                                          });
                                          _showSnackBar(
                                              'Failed to update package: ${e.toString()}');
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _services.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openPackageSheet(),
              backgroundColor: kPrimaryColor,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                "Add Package",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
    );
  }
}

class _EmptyPackagesCard extends StatelessWidget {
  final List<Map<String, dynamic>> services;

  const _EmptyPackagesCard({Key? key, required this.services})
      : super(key: key);

  String _serviceName(Map<String, dynamic> s) =>
      (s['name'] ?? '').toString().isEmpty ? "Unnamed" : s['name'].toString();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "No packages yet",
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Create your first bundle by selecting services and giving them a special price.",
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[700],
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          if (services.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: services.map((s) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _serviceName(s),
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: const Color(0xFF4B5563),
                    ),
                  ),
                );
              }).toList(),
            )
          else
            Text(
              "Add services first, then come back to create bundles.",
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }
}