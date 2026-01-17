// lib/screens/add_service_provider.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

// انتبه لمسار الملفات: لأنهم داخل مجلد booking
import 'add_hourly_service.dart';
import 'add_full_day_service.dart';
import 'add_capacity_service.dart';
import 'add_order_service.dart';
import 'add_other_service.dart'; // 🆕 صفحة Other الجديدة
import 'add_display_service.dart'; // 🆕 صفحة Display للـ Flower, Jewelry, Gift

// ═══════════════════════════════════════════════════════════════════════════
// 🎨 Design Tokens - Modern Purple Theme
// ═══════════════════════════════════════════════════════════════════════════
const Color kPrimaryColor = Color(0xFF6C63FF);
const Color kPrimaryLight = Color(0xFFE8E6FF);
const Color kBackgroundColor = Color(0xFFF8F9FC);
const Color kTextColor = Color(0xFF1A1D29);
const Color kTextSecondary = Color(0xFF6B7280);

// ----------------------------------------------------------------------
// 🔥 Service Categories (نفس الـ 12 كاتيجوري + Other)
// ----------------------------------------------------------------------

const List<Map<String, dynamic>> kServiceCategories = [
  {'value': 'Venues', 'label': 'Venues', 'icon': Icons.apartment_rounded},
  {
    'value': 'Photographers',
    'label': 'Photographers',
    'icon': Icons.photo_camera_outlined
  },
  {
    'value': 'Catering',
    'label': 'Catering',
    'icon': Icons.restaurant_menu_rounded
  },
  {'value': 'Cake', 'label': 'Cake', 'icon': Icons.cake_outlined},
  {
    'value': 'Flower Shops',
    'label': 'Flower Shops',
    'icon': Icons.local_florist_outlined
  },
  {
    'value': 'Decor & Lighting',
    'label': 'Decor & Lighting',
    'icon': Icons.lightbulb_outline_rounded
  },
  {
    'value': 'Music & Entertainment',
    'label': 'Music',
    'icon': Icons.music_note_rounded
  },
  {
    'value': 'Event Planners & Coordinators',
    'label': 'Event Planners',
    'icon': Icons.event_available_rounded
  },
  {
    'value': 'Card Printing',
    'label': 'Card Printing',
    'icon': Icons.mail_outline_rounded
  },
  {
    'value': 'Jewelry & Accessories',
    'label': 'Jewelry & Accessories',
    'icon': Icons.diamond_outlined
  },
  {
    'value': 'Car Rental & Transportation',
    'label': 'Car Rental and Transportation',
    'icon': Icons.directions_car_filled_outlined
  },
  {
    'value': 'Gift & Souvenir',
    'label': 'Gift & Souvenir',
    'icon': Icons.card_giftcard_outlined
  },
  // 🆕 Other category للخدمات المخصصة
  {
    'value': 'Other',
    'label': 'Other',
    'icon': Icons.add_circle_outline_rounded
  },
];

// ----------------------------------------------------------------------
// 🔥 mapping: category → نوع البوكينغ (key + label)
// ----------------------------------------------------------------------

String _bookingTypeKey(String category) {
  switch (category) {
    case 'Venues':
    case 'Photographers':
    case 'Music & Entertainment':
    case 'Event Planners & Coordinators':
      return 'hourly';

    case 'Decor & Lighting':
    case 'Car Rental & Transportation':
      return 'full-day';

    case 'Catering':
    case 'Cake':
      return 'capacity';

    // 🆕 Display services - عرض المنتجات بدون سعر
    case 'Flower Shops':
    case 'Jewelry & Accessories':
    case 'Gift & Souvenir':
      return 'display';

    case 'Card Printing':
      return 'order';

    case 'Other':
      return 'other'; // 🆕

    default:
      return 'hourly';
  }
}

String _bookingTypeLabel(String key) {
  switch (key) {
    case 'hourly':
      return 'Hourly Booking';
    case 'full-day':
      return 'Full-Day Booking';
    case 'capacity':
      return 'Capacity Booking';
    case 'display':
      return 'Display Only'; // 🆕
    case 'other':
      return 'Custom Booking'; // 🆕
    case 'order':
    default:
      return 'Order-Based Booking';
  }
}

// ----------------------------------------------------------------------
// 🔥 الشاشة الرئيسية: بس اختيار كاتيجوري
// ----------------------------------------------------------------------

class AddServiceProviderScreen extends StatelessWidget {
  const AddServiceProviderScreen({Key? key}) : super(key: key);

  Future<void> _openBookingPage(BuildContext context, String category) async {
    final typeKey = _bookingTypeKey(category);
    final typeLabel = _bookingTypeLabel(typeKey);

    Widget page;
    switch (typeKey) {
      case 'hourly':
        page = AddHourlyService(
          category: category,
          bookingType: typeLabel,
        );
        break;

      case 'full-day':
        page = AddFullDayService(
          category: category,
          bookingType: typeLabel,
        );
        break;

      case 'capacity':
        page = AddCapacityService(
          category: category,
          bookingType: typeLabel,
        );
        break;

      case 'display': // 🆕 صفحة Display للـ Flower, Jewelry, Gift
        page = AddDisplayService(
          category: category,
          bookingType: typeLabel,
        );
        break;

      case 'other': // 🆕 صفحة Other الديناميكية
        page = const AddOtherService();
        break;

      case 'order':
      default:
        page = AddOrderService(
          category: category,
          bookingType: typeLabel,
        );
        break;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );

    // ✅ NEW: صفحات الإضافة رح ترجع bool (true) بعد الحفظ
    if (result == true) {
      Navigator.pop(context, true);
      return;
    }

    // ✅ OLD support: إذا كان عندك مكان ثاني بيرجع Map
    if (result is Map && result["created"] == true) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1100;
        final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1100;

        if (isDesktop || isTablet) {
          return _buildWebLayout(context, isDesktop);
        }
        return _buildMobileLayout(context);
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 🌐 WEB LAYOUT - Modern Grid
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildWebLayout(BuildContext context, bool isDesktop) {
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
                    color: kPrimaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.plusCircle, size: 20, color: kPrimaryColor),
                ),
                const SizedBox(width: 14),
                Text('Add New Service', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: kTextColor)),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 80 : 40, vertical: 40),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Choose Service Category', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w800, color: kTextColor)),
                      const SizedBox(height: 8),
                      Text('Select the category that best describes your service', style: GoogleFonts.poppins(fontSize: 15, color: kTextSecondary)),
                      const SizedBox(height: 40),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: kServiceCategories.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isDesktop ? 4 : 3,
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 20,
                          childAspectRatio: 1.2,
                        ),
                        itemBuilder: (context, index) {
                          final cat = kServiceCategories[index];
                          return _buildWebCategoryCard(context, cat);
                        },
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

  Widget _buildWebCategoryCard(BuildContext context, Map<String, dynamic> cat) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _openBookingPage(context, cat['value'] as String),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kPrimaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(cat['icon'] as IconData, size: 28, color: kPrimaryColor),
              ),
              const SizedBox(height: 14),
              Text(
                cat['label'] as String,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: kTextColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 📱 MOBILE LAYOUT
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: Text(
          "Choose Service Category",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: kTextColor,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: kTextColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: kServiceCategories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 11,
            childAspectRatio: 1.62,
          ),
          itemBuilder: (context, index) {
            final cat = kServiceCategories[index];
            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _openBookingPage(
                context,
                cat['value'] as String,
              ),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      cat['icon'] as IconData,
                      size: 26,
                      color: kPrimaryColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cat['label'] as String,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}