// lib/screens/add_service_provider.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// انتبه لمسار الملفات: لأنهم داخل مجلد booking
import 'add_hourly_service.dart';
import 'add_full_day_service.dart';
import 'add_capacity_service.dart';
import 'add_order_service.dart';

const Color kPrimaryColor = Color.fromARGB(215, 20, 20, 215);
const Color kBackgroundColor = Color(0xFFF3F4F6);
const Color kTextColor = Color(0xFF111827);

// ----------------------------------------------------------------------
// 🔥 Service Categories (نفس الـ 12 كاتيجوري)
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
    'value': 'Wedding Planners & Coordinators',
    'label': 'Wedding Planners',
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
    'label': 'Car Rental',
    'icon': Icons.directions_car_filled_outlined
  },
  {
    'value': 'Gift & Souvenir',
    'label': 'Gift & Souvenir',
    'icon': Icons.card_giftcard_outlined
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
    case 'Wedding Planners & Coordinators':
      return 'hourly';

    case 'Decor & Lighting':
    case 'Car Rental & Transportation':
      return 'full-day';

    case 'Catering':
    case 'Cake':
      return 'capacity';

    case 'Flower Shops':
    case 'Card Printing':
    case 'Jewelry & Accessories':
    case 'Gift & Souvenir':
      return 'order';

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
                      size: 26, // 👈 صغّرنا الأيقونات
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