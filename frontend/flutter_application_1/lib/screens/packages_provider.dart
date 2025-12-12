// lib/screens/packages_provider.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// 🚀 التأكد من مسار الاستيراد الصحيح
import 'package:flutter_application_1/services/package_service.dart';

const Color kPrimaryColor = Color.fromARGB(215, 20, 20, 215);

// 🔄 الموديل الجديد لتمثيل الباقة من الـ Backend
class BundlePackage {
  final String id;
  final String name;
  final List<String> serviceIds;
  final List<String> serviceNames;
  final double bundlePrice;
  final DateTime? startDate;
  final DateTime? endDate;
final String? packageImageUrl; // 🟢 الإضافة الجديدة هنا
  BundlePackage({
    required this.id,
    required this.name,
    required this.serviceIds,
    required this.serviceNames,
    required this.bundlePrice,
    this.startDate,
    this.endDate,
    this.packageImageUrl, // 🟢 إضافته للـ Constructor
  });

  // 🆕 دالة الإنشاء من JSON المعدلة للتعامل مع الأخطاء الرقمية (newPrice)
    factory BundlePackage.fromJson(Map<String, dynamic> json) {
      // 1. معالجة Service Names (للعرض)
      final List<dynamic> rawServiceNames = json['serviceNames'] as List<dynamic>? ?? [];
      
      // 2. معالجة Service IDs (للإرسال في الـ Backend)
      final List<dynamic> rawServiceIds = json['serviceIds'] as List<dynamic>? ?? [];
      
      // 3. معالجة السعر (يأتي كـ 'newPrice' من الباك إند)
      final double price = (json['newPrice'] as num?)?.toDouble() ?? 0.0;
      
      // 4. معالجة التواريخ
      final DateTime? start = DateTime.tryParse(json['startDate'] as String? ?? '');
      final DateTime? end = DateTime.tryParse(json['endDate'] as String? ?? '');
      
      return BundlePackage(
          id: json['_id'] as String? ?? '', 
          name: json['packageName'] as String? ?? 'N/A', // افتراض أن الحقل اسمه packageName
          serviceIds: rawServiceIds.map((e) => e.toString()).toList(),
          serviceNames: rawServiceNames.map((e) => e.toString()).toList(),
          bundlePrice: price,
          startDate: start,
          endDate: end,
          packageImageUrl: json['packageImageUrl'] as String?, // 🟢 قراءة رابط الصورة من الـ JSON
      );
    }
} 

class PackagesProviderScreen extends StatefulWidget {
  // ✅ تم التأكد من حذف الباراميتر services
  const PackagesProviderScreen({Key? key}) : super(key: key);

  @override
  State<PackagesProviderScreen> createState() => _PackagesProviderScreenState();
}

class _PackagesProviderScreenState extends State<PackagesProviderScreen> {
  List<BundlePackage> _packages = [];
  List<Map<String, dynamic>> _services = [];

  bool _isLoading = true; 
  String? _error; 

  @override
  void initState() {
    super.initState();
    _fetchData(); 
  }

  // 🆕 دالة جلب الخدمات والباقات
 // داخل class _PackagesProviderScreenState

Future<void> _fetchData() async {
  setState(() {
    _isLoading = true;
    _error = null;
  });
  
  try {
    // 1. جلب الخدمات المتاحة للـ Provider (لأجل الـ Bottom Sheet)
    final fetchedServices = await PackageService.fetchProviderServicesForCreation();

    // 2. جلب الباقات الموجودة للمزود
    final fetchedPackagesJson = await PackageService.fetchProviderPackages();

    setState(() {
      _services = fetchedServices; // ⬅️ تحديث قائمة الخدمات
      _packages = fetchedPackagesJson
          .map((json) => BundlePackage.fromJson(json))
          .toList();
      _isLoading = false; // ⬅️ إيقاف التحميل بعد النجاح
    });
  } catch (e) {
    print('Error fetching data: $e');
    setState(() {
      _error = 'Failed to load data: ${e.toString()}';
      _isLoading = false; // ⬅️ إيقاف التحميل بعد الفشل
    });
  }
}

  // دوال مساعدة لجلب البيانات من قائمة الخدمات (اللازمة للإنشاء)
  String _serviceIdAt(int index) => (_services[index]['_id'] ?? '').toString();

  double _servicePriceAt(int index) {
    final raw = _services[index]['price'];
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '0') ?? 0;
  }

  String _serviceNameAt(int index) =>
      (_services[index]['name'] ?? '').toString();

  double _getServicePriceById(String serviceId) {
    final service = _services.firstWhere(
      (s) => s['_id'] == serviceId,
      orElse: () => {'price': 0},
    );
    final raw = service['price'];
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '0') ?? 0;
  }

  // حساب الإجمالي الأساسي (مجموع أسعار الخدمات)
  double _baseTotalForPackage(BundlePackage p) {
    double sum = 0;
    // ⚠️ يعتمد هذا الحساب على توفر serviceIds في الـ BundlePackage
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

  // دالة الحذف
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

    final nameCtrl = TextEditingController(text: editingPackage?.name ?? '');
    final priceCtrl = TextEditingController(
      text: editingPackage != null
          ? editingPackage.bundlePrice.toStringAsFixed(0)
          : '',
    );

    DateTime? startDate = editingPackage?.startDate;
    DateTime? endDate = editingPackage?.endDate;

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
              for (final id in selectedServiceIds) {
                baseTotal += _getServicePriceById(id);
              }

              final bundlePrice = double.tryParse(priceCtrl.text.trim()) ?? 0.0;

              double discount = 0;
              if (baseTotal > 0 && bundlePrice > 0 && bundlePrice < baseTotal) {
                discount = (1 - (bundlePrice / baseTotal)) * 100;
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

                    // Package name
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

                    Text(
                      "Select services to include",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (_services.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 16),
                        child: Text(
                          "No services found. Add services first, then create a bundle.",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    else
                      Column(
                        children: List.generate(_services.length, (index) {
                          final name = _serviceNameAt(index);
                          final price = _servicePriceAt(index);
                          final id = _serviceIdAt(index);

                          final isChecked = selectedServiceIds.contains(id);

                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            value: isChecked,
                            onChanged: (v) {
                              setSheetState(() {
                                if (v == true) {
                                  selectedServiceIds.add(id);
                                } else {
                                  selectedServiceIds
                                      .remove(id); 
                                }
                              });
                            },
                            title: Text(
                              name,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              "₪${price.toStringAsFixed(0)}",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                            activeColor: kPrimaryColor,
                          );
                        }),
                      ),

                    const SizedBox(height: 10),

                    // Bundle price
                    TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Bundle price (₪)",
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
                      onChanged: (_) => setSheetState(() {}),
                    ),

                    const SizedBox(height: 14),

                    // Package duration (Start and End Date)
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

                    // Summary: base total + discount
                    if (baseTotal > 0)
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
                            if (bundlePrice > 0)
                              Text(
                                "Bundle price: ₪${bundlePrice.toStringAsFixed(0)}",
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
                          final price =
                              double.tryParse(priceCtrl.text.trim()) ?? 0;
                          if (name.isEmpty ||
                              selectedServiceIds.isEmpty ||
                              price <= 0) {
                            _showSnackBar(
                                "Please fill name, select at least one service, and set bundle price.");
                            return;
                          }

                          Navigator.pop(ctx, {
                            'packageName': name,
                            'serviceIds': selectedServiceIds.toList(),
                            'newPrice': price,
                            'startDate': startDate,
                            'endDate': endDate,
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

    // تنفيذ عملية الإضافة
    if (result != null) {
      if (editingPackage != null) {
        _showSnackBar('Update feature not implemented (Missing PUT/PATCH API).');
      } else {
        setState(() {
          _isLoading = true; 
        });
        try {
          await PackageService.createPackage(
            packageName: result['packageName'],
            serviceIds: result['serviceIds'].cast<String>(),
            newPrice: result['newPrice'],
            startDate: result['startDate'],
            endDate: result['endDate'],
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
              // Info card 
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
                      padding: const EdgeInsets.all(14),
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
                          // header row
                          Row(
                            children: [
                              // 🟢 الإضافة الجديدة هنا: عرض الصورة أو الأيقونة الافتراضية
                              if (p.packageImageUrl != null && p.packageImageUrl!.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.network(
                                    p.packageImageUrl!,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        width: 48,
                                        height: 48,
                                        color: Colors.grey.shade200,
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                              color: kPrimaryColor, strokeWidth: 2),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 48,
                                      height: 48,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: kPrimaryColor.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 20,
                                        color: kPrimaryColor,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                // الأيقونة الافتراضية
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: kPrimaryColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.inventory_2_rounded,
                                    size: 20,
                                    color: kPrimaryColor,
                                  ),
                                ),
                              // -------------------------------------------------------------
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  p.name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                "₪${p.bundlePrice.toStringAsFixed(0)}",
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: kPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (includedNames.isNotEmpty)
                            Text(
                              "Includes: ${includedNames.join(', ')}",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          if (rangeText != null) ...[
                            const SizedBox(height: 4),
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
                          const SizedBox(height: 4),
                          // عرض السعر الأساسي والخصم
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
                                      borderRadius: BorderRadius.circular(999),
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
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // ⚠️ التعديل غير مدعوم حالياً لعدم وجود API
                              IconButton(
                                icon: const Icon(Icons.edit_outlined,
                                    size: 20, color: Colors.grey),
                                onPressed: () =>
                                    _openPackageSheet(editingPackage: p),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 20, color: Colors.redAccent),
                                onPressed: () => _deletePackage(p.id),
                              ),
                            ],
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
      // لا تعرض زر الإضافة إذا كانت قائمة الخدمات فارغة
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

/// كارت حالة فارغة لما ما يكون في أي باكيجات
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