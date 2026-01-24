// lib/screens/provider/offers_provider.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/services/offer_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 🎨 Design Tokens - Modern Purple Theme
// ═══════════════════════════════════════════════════════════════════════════
const Color kPrimaryColor = Color(0xFF6C63FF);
const Color kPrimaryLight = Color(0xFFE8E6FF);
const Color kOfferColor = Color(0xFFFF6B35);
const Color kOfferLight = Color(0xFFFFF0EB);
const Color kSuccessColor = Color(0xFF10B981);
const Color kTextPrimary = Color(0xFF1A1D29);
const Color kTextSecondary = Color(0xFF6B7280);
const Color kBackgroundColor = Color(0xFFF8F9FC);

class OffersProviderScreen extends StatefulWidget {
  const OffersProviderScreen({Key? key}) : super(key: key);

  @override
  State<OffersProviderScreen> createState() => _OffersProviderScreenState();
}

class _OffersProviderScreenState extends State<OffersProviderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _activeOffers = [];
  List<dynamic> _availableServices = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final result = await OfferService.getMyServicesWithOffers();

    if (result['success'] == true) {
      setState(() {
        _activeOffers = result['activeOffers'] ?? [];
        _availableServices = result['availableServices'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      _showSnackBar(result['message'] ?? 'Failed to load data', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : kSuccessColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
  // 🌐 WEB LAYOUT - Modern Dashboard Style
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildWebLayout(bool isDesktop) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Column(
        children: [
          // Modern Top Bar
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: kBackgroundColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.arrowLeft, size: 18, color: kTextSecondary),
                          const SizedBox(width: 8),
                          Text('Back', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: kTextSecondary)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kOfferLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.tag, size: 20, color: kOfferColor),
                ),
                const SizedBox(width: 14),
                Text(
                  'Offers & Discounts',
                  style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: kTextPrimary),
                ),
                const Spacer(),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _loadData,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: kOfferLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.refreshCw, size: 16, color: kOfferColor),
                          const SizedBox(width: 8),
                          Text('Refresh', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: kOfferColor)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: kOfferColor))
                : SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 24, vertical: 32),
                    child: Center(
                      child: Container(
                        constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : double.infinity),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Stats Row
                            Row(
                              children: [
                                Expanded(child: _buildWebStatCard('Active Offers', _activeOffers.length, LucideIcons.tag, kOfferColor)),
                                const SizedBox(width: 20),
                                Expanded(child: _buildWebStatCard('Available Services', _availableServices.length, LucideIcons.package, kPrimaryColor)),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Two Column Layout
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Active Offers
                                Expanded(
                                  child: _buildWebOfferSection(
                                    'Active Offers',
                                    LucideIcons.tag,
                                    kOfferColor,
                                    _activeOffers,
                                    isActive: true,
                                  ),
                                ),
                                const SizedBox(width: 24),
                                // Available Services
                                Expanded(
                                  child: _buildWebOfferSection(
                                    'Available Services',
                                    LucideIcons.package,
                                    kPrimaryColor,
                                    _availableServices,
                                    isActive: false,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebStatCard(String label, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 26, color: color),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.poppins(fontSize: 14, color: kTextSecondary)),
              Text('$count', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w700, color: kTextPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWebOfferSection(String title, IconData icon, Color color, List<dynamic> items, {required bool isActive}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 12),
                Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: kTextPrimary)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${items.length}', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(48),
              child: Center(
                child: Column(
                  children: [
                    Icon(isActive ? LucideIcons.tag : LucideIcons.packagePlus, size: 40, color: kTextSecondary.withOpacity(0.5)),
                    const SizedBox(height: 12),
                    Text(
                      isActive ? 'No active offers' : 'No available services',
                      style: GoogleFonts.poppins(fontSize: 14, color: kTextSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildWebOfferItem(item, isActive: isActive);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildWebOfferItem(Map<String, dynamic> service, {required bool isActive}) {
    final name = service['name'] ?? 'Service';
    final originalPrice = (service['price'] ?? 0).toDouble();
    final discountedPrice = (service['discountedPrice'] ?? 0).toDouble();
    final image = service['images']?[0] as String?;
    final endDate = service['offerEndDate'];

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Image
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: kBackgroundColor,
                image: image != null ? DecorationImage(image: NetworkImage(image), fit: BoxFit.cover) : null,
              ),
              child: image == null ? const Icon(LucideIcons.image, size: 24, color: kTextSecondary) : null,
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: kTextPrimary)),
                  const SizedBox(height: 4),
                  if (isActive)
                    Row(
                      children: [
                        Text('₪$discountedPrice', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: kOfferColor)),
                        const SizedBox(width: 8),
                        Text('₪$originalPrice', style: GoogleFonts.poppins(fontSize: 12, color: kTextSecondary, decoration: TextDecoration.lineThrough)),
                      ],
                    )
                  else
                    Text('₪$originalPrice', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: kSuccessColor)),
                  if (isActive && endDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.clock, size: 12, color: kTextSecondary),
                          const SizedBox(width: 4),
                          Text('Ends ${DateFormat('MMM d').format(DateTime.parse(endDate))}', style: GoogleFonts.poppins(fontSize: 11, color: kTextSecondary)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Actions
            if (isActive)
              Row(
                children: [
                  _buildWebActionButton(LucideIcons.edit3, kPrimaryColor, () => _showEditOfferDialog(service)),
                  const SizedBox(width: 8),
                  _buildWebActionButton(LucideIcons.trash2, Colors.red, () => _removeOffer(service)),
                ],
              )
            else
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _showAddOfferDialog(service),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [kOfferColor, kOfferColor.withOpacity(0.85)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.plus, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text('Add Offer', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebActionButton(IconData icon, Color color, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 📱 MOBILE LAYOUT
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Offers & Discounts",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: kOfferColor,
          indicatorWeight: 3,
          labelColor: kOfferColor,
          unselectedLabelColor: Colors.grey.shade500,
          labelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_offer, size: 18),
                  const SizedBox(width: 6),
                  Text("Active (${_activeOffers.length})"),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 18),
                  const SizedBox(width: 6),
                  Text("Available (${_availableServices.length})"),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActiveOffersTab(),
                _buildAvailableServicesTab(),
              ],
            ),
    );
  }

  /// Active Offers Tab
  Widget _buildActiveOffersTab() {
    if (_activeOffers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.local_offer_outlined,
        title: "No Active Offers",
        subtitle: "Add offers to your services to attract more customers!",
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _activeOffers.length,
        itemBuilder: (context, index) {
          final service = _activeOffers[index];
          return _ActiveOfferCard(
            service: service,
            onRemoveOffer: () => _removeOffer(service),
            onEditOffer: () => _showEditOfferDialog(service),
          );
        },
      ),
    );
  }

  /// Available Services Tab
  Widget _buildAvailableServicesTab() {
    if (_availableServices.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inventory_2_outlined,
        title: "No Available Services",
        subtitle: "Add services first to create offers for them.",
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _availableServices.length,
        itemBuilder: (context, index) {
          final service = _availableServices[index];
          return _AvailableServiceCard(
            service: service,
            onAddOffer: () => _showAddOfferDialog(service),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kOfferColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: kOfferColor),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show Add Offer Dialog
  void _showAddOfferDialog(Map<String, dynamic> service) {
    final priceController = TextEditingController();
    final descController = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 7));
    final originalPrice = (service['price'] ?? 0).toDouble();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            double discountedPrice =
                double.tryParse(priceController.text) ?? originalPrice;
            double discountPercent = originalPrice > 0
                ? ((originalPrice - discountedPrice) / originalPrice) * 100
                : 0;

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),

                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: kOfferColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.local_offer,
                              color: kOfferColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Create Offer",
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                service['name'] ?? 'Service',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Original Price Display
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            "Original Price:",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "${originalPrice.toStringAsFixed(0)}",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Discounted Price Input
                    Text(
                      "Discounted Price",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "Enter discounted price",
                        prefixIcon:
                            const Icon(Icons.attach_money, color: kOfferColor),
                        suffixText: discountPercent > 0
                            ? "${discountPercent.toStringAsFixed(0)}% OFF"
                            : "",
                        suffixStyle: GoogleFonts.poppins(
                          color: kSuccessColor,
                          fontWeight: FontWeight.w600,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),

                    const SizedBox(height: 16),

                    // Date Range
                    Text(
                      "Offer Duration",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _DatePickerField(
                            label: "Start",
                            date: startDate,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: startDate,
                                firstDate: DateTime.now(),
                                lastDate:
                                    DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setModalState(() => startDate = picked);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DatePickerField(
                            label: "End",
                            date: endDate,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: endDate,
                                firstDate: startDate,
                                lastDate:
                                    DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setModalState(() => endDate = picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Description (Optional)
                    Text(
                      "Offer Description (Optional)",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: "e.g., Summer Sale, Limited Time Offer...",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Create Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final discountedPrice =
                              double.tryParse(priceController.text);
                          if (discountedPrice == null || discountedPrice <= 0) {
                            _showSnackBar('Please enter a valid discounted price',
                                isError: true);
                            return;
                          }
                          if (discountedPrice >= originalPrice) {
                            _showSnackBar(
                                'Discounted price must be less than original price',
                                isError: true);
                            return;
                          }

                          Navigator.pop(context);
                          await _createOffer(
                            service: service,
                            discountedPrice: discountedPrice,
                            startDate: startDate,
                            endDate: endDate,
                            description: descController.text,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kOfferColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          "Create Offer",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Show Edit Offer Dialog
  void _showEditOfferDialog(Map<String, dynamic> service) {
    final offer = service['offer'] as Map<String, dynamic>?;
    if (offer == null) return;

    final priceController = TextEditingController(
      text: (offer['discountedPrice'] ?? 0).toString(),
    );
    final descController = TextEditingController(
      text: offer['description'] ?? '',
    );
    DateTime startDate = offer['startDate'] != null
        ? DateTime.parse(offer['startDate'])
        : DateTime.now();
    DateTime endDate = offer['endDate'] != null
        ? DateTime.parse(offer['endDate'])
        : DateTime.now().add(const Duration(days: 7));
    final originalPrice = (service['price'] ?? 0).toDouble();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            double discountedPrice =
                double.tryParse(priceController.text) ?? originalPrice;
            double discountPercent = originalPrice > 0
                ? ((originalPrice - discountedPrice) / originalPrice) * 100
                : 0;

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),

                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.edit,
                              color: kPrimaryColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Edit Offer",
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                service['name'] ?? 'Service',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Original Price Display
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            "Original Price:",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "${originalPrice.toStringAsFixed(0)}",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Discounted Price Input
                    Text(
                      "Discounted Price",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "Enter discounted price",
                        prefixIcon:
                            const Icon(Icons.attach_money, color: kOfferColor),
                        suffixText: discountPercent > 0
                            ? "${discountPercent.toStringAsFixed(0)}% OFF"
                            : "",
                        suffixStyle: GoogleFonts.poppins(
                          color: kSuccessColor,
                          fontWeight: FontWeight.w600,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),

                    const SizedBox(height: 16),

                    // Date Range
                    Text(
                      "Offer Duration",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _DatePickerField(
                            label: "Start",
                            date: startDate,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: startDate,
                                firstDate: DateTime.now()
                                    .subtract(const Duration(days: 30)),
                                lastDate:
                                    DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setModalState(() => startDate = picked);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DatePickerField(
                            label: "End",
                            date: endDate,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: endDate,
                                firstDate: startDate,
                                lastDate:
                                    DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setModalState(() => endDate = picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Description (Optional)
                    Text(
                      "Offer Description (Optional)",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: "e.g., Summer Sale, Limited Time Offer...",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Update Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final discountedPrice =
                              double.tryParse(priceController.text);
                          if (discountedPrice == null || discountedPrice <= 0) {
                            _showSnackBar('Please enter a valid discounted price',
                                isError: true);
                            return;
                          }
                          if (discountedPrice >= originalPrice) {
                            _showSnackBar(
                                'Discounted price must be less than original price',
                                isError: true);
                            return;
                          }

                          Navigator.pop(context);
                          await _createOffer(
                            service: service,
                            discountedPrice: discountedPrice,
                            startDate: startDate,
                            endDate: endDate,
                            description: descController.text,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          "Update Offer",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Create Offer API Call
  Future<void> _createOffer({
    required Map<String, dynamic> service,
    required double discountedPrice,
    required DateTime startDate,
    required DateTime endDate,
    String? description,
  }) async {
    setState(() => _isLoading = true);

    final serviceId = service['_id'] ?? service['id'];
    final originalPrice = (service['price'] ?? 0).toDouble();

    final result = await OfferService.createOffer(
      serviceId: serviceId.toString(),
      discountedPrice: discountedPrice,
      discountPercentage:
          OfferService.calculateDiscountPercentage(originalPrice, discountedPrice),
      startDate: startDate,
      endDate: endDate,
      description: description,
    );

    if (result['success'] == true) {
      _showSnackBar('Offer created successfully! 🎉');
      await _loadData();
    } else {
      setState(() => _isLoading = false);
      _showSnackBar(result['message'] ?? 'Failed to create offer', isError: true);
    }
  }

  /// Remove Offer
  Future<void> _removeOffer(Map<String, dynamic> service) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Remove Offer?",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          "Are you sure you want to remove the offer from \"${service['name']}\"?",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              "Remove",
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    final serviceId = service['_id'] ?? service['id'];
    final result = await OfferService.removeOffer(serviceId.toString());

    if (result['success'] == true) {
      _showSnackBar('Offer removed successfully');
      await _loadData();
    } else {
      setState(() => _isLoading = false);
      _showSnackBar(result['message'] ?? 'Failed to remove offer', isError: true);
    }
  }
}

/// Active Offer Card Widget
class _ActiveOfferCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final VoidCallback onRemoveOffer;
  final VoidCallback onEditOffer;

  const _ActiveOfferCard({
    required this.service,
    required this.onRemoveOffer,
    required this.onEditOffer,
  });

  @override
  Widget build(BuildContext context) {
    final offer = service['offer'] as Map<String, dynamic>?;
    final originalPrice = (service['price'] ?? 0).toDouble();
    final discountedPrice = (offer?['discountedPrice'] ?? 0).toDouble();
    final discountPercent = (offer?['discountPercentage'] ?? 0).toDouble();
    final endDate = offer?['endDate'] != null
        ? DateTime.parse(offer!['endDate'])
        : DateTime.now();
    final remainingTime = OfferService.formatRemainingTime(endDate);
    final imageUrl = (service['gallery'] as List?)?.isNotEmpty == true
        ? service['gallery'][0]
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Offer Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kOfferColor, kOfferColor.withOpacity(0.8)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_offer, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  "${discountPercent.toStringAsFixed(0)}% OFF",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        remainingTime,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Service Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),
                const SizedBox(width: 12),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service['name'] ?? 'Service',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            "${discountedPrice.toStringAsFixed(0)}",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kOfferColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${originalPrice.toStringAsFixed(0)}",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: kPrimaryColor, size: 22),
                      onPressed: onEditOffer,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red, size: 22),
                      onPressed: onRemoveOffer,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.image, color: Colors.grey),
    );
  }
}

/// Available Service Card Widget
class _AvailableServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final VoidCallback onAddOffer;

  const _AvailableServiceCard({
    required this.service,
    required this.onAddOffer,
  });

  @override
  Widget build(BuildContext context) {
    final price = (service['price'] ?? 0).toDouble();
    final imageUrl = (service['gallery'] as List?)?.isNotEmpty == true
        ? service['gallery'][0]
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service['name'] ?? 'Service',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "${price.toStringAsFixed(0)}",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
              ],
            ),
          ),

          // Add Offer Button
          ElevatedButton.icon(
            onPressed: onAddOffer,
            icon: const Icon(Icons.local_offer, size: 16),
            label: const Text("Add Offer"),
            style: ElevatedButton.styleFrom(
              backgroundColor: kOfferColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.image, color: Colors.grey, size: 24),
    );
  }
}

/// Date Picker Field Widget
class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  Text(
                    DateFormat('MMM d, yyyy').format(date),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
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
