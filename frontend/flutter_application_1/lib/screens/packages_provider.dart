import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kPrimaryColor = Color.fromARGB(215, 20, 20, 215);

class PackagesProviderScreen extends StatefulWidget {
  final List<Map<String, dynamic>> services;

  const PackagesProviderScreen({
    Key? key,
    this.services = const [],
  }) : super(key: key);

  @override
  State<PackagesProviderScreen> createState() => _PackagesProviderScreenState();
}

class _PackagesProviderScreenState extends State<PackagesProviderScreen> {
  /// قايمة عامة (static) عشان تضل محتفظة بالباكيجات طول ما الأبلكيشن شغال
  static final List<_BundlePackage> _savedPackages = [];

  /// الباكيجات التي ينشئها البروفايدر (مرتبطة بـ _savedPackages)
  late List<_BundlePackage> _packages;

  @override
  void initState() {
    super.initState();
    _packages = _savedPackages; // نربطها بالليست المشتركة
  }

  /// اختصار للخدمات
  List<Map<String, dynamic>> get _services => widget.services;

  double _servicePriceAt(int index) {
    final raw = _services[index]['price'];
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '0') ?? 0;
  }

  String _serviceNameAt(int index) =>
      (_services[index]['name'] ?? '').toString();

  double _baseTotalForPackage(_BundlePackage p) {
    double sum = 0;
    for (final i in p.serviceIndices) {
      if (i >= 0 && i < _services.length) {
        sum += _servicePriceAt(i);
      }
    }
    return sum;
  }

  double _discountPercent(_BundlePackage p) {
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

  Future<void> _openPackageSheet({int? editingIndex}) async {
    final editing = (editingIndex != null) ? _packages[editingIndex] : null;

    final nameCtrl = TextEditingController(text: editing?.name ?? '');
    final priceCtrl = TextEditingController(
      text: editing != null ? editing.bundlePrice.toStringAsFixed(0) : '',
    );
    final selected = <int>{
      if (editing != null) ...editing.serviceIndices,
    };

    DateTime? startDate = editing?.startDate;
    DateTime? endDate = editing?.endDate;

    final result = await showModalBottomSheet<_BundlePackage>(
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
              for (final i in selected) {
                if (i >= 0 && i < _services.length) {
                  baseTotal += _servicePriceAt(i);
                }
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
                      editing == null ? "Create new package" : "Edit package",
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

                          final isChecked = selected.contains(index);

                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            value: isChecked,
                            onChanged: (v) {
                              setSheetState(() {
                                if (v == true) {
                                  selected.add(index);
                                } else {
                                  selected.remove(index);
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

                    // مدة الباكيج (تاريخ البداية والنهاية)
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
                          if (name.isEmpty || selected.isEmpty || price <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                    "Please fill name, select at least one service, and set bundle price."),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                            return;
                          }

                          final package = _BundlePackage(
                            name: name,
                            serviceIndices: selected.toList()..sort(),
                            bundlePrice: price,
                            startDate: startDate,
                            endDate: endDate,
                          );

                          Navigator.pop(ctx, package);
                        },
                        child: Text(
                          editing == null ? "Create package" : "Save changes",
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
      setState(() {
        if (editingIndex != null) {
          _packages[editingIndex] = result;
        } else {
          _packages.add(result);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: SingleChildScrollView(
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

                  final includedNames = p.serviceIndices
                      .where((i) => i >= 0 && i < _services.length)
                      .map(_serviceNameAt)
                      .toList();

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
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  size: 20, color: Colors.grey),
                              onPressed: () =>
                                  _openPackageSheet(editingIndex: index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 20, color: Colors.redAccent),
                              onPressed: () {
                                setState(() {
                                  _packages.removeAt(index);
                                });
                              },
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

/// موديل داخلي للباكيج
class _BundlePackage {
  final String name;
  final List<int> serviceIndices;
  final double bundlePrice;
  final DateTime? startDate;
  final DateTime? endDate;

  _BundlePackage({
    required this.name,
    required this.serviceIndices,
    required this.bundlePrice,
    this.startDate,
    this.endDate,
  });
}