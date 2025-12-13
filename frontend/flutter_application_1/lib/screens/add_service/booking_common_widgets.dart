// lib/screens/booking type/booking_common_widgets.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kPrimaryColor = Color.fromARGB(215, 20, 20, 215);
const Color kBackgroundColor = Color(0xFFF3F4F6);
const Color kTextColor = Color(0xFF111827);

/// نفس المدن اللي عندك
const List<String> kCities = [
  'Nablus',
  'Ramallah',
  'Jenin',
  'Tulkarm',
  'Qalqilya',
  'Hebron',
  'Bethlehem',
  'Jericho',
  'Jerusalem',
  'Other',
];

BoxDecoration cardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 12,
          offset: const Offset(0, 6),
        )
      ],
    );

InputDecoration inputStyle(String label) => InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kPrimaryColor, width: 1.2),
      ),
    );

Widget sectionLabel(String text) => Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: kTextColor,
          ),
        ),
      ),
    );

Widget bookingTypeChip({
  required String bookingType,
  required String category,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: kPrimaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            bookingType,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kPrimaryColor,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            category,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kTextColor,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget saveButton(VoidCallback onTap) {
  return SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: onTap,
          child: Text(
            "Save",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ),
      ),
    ),
  );
}

/// ✅ عرض Date Range بشكل Modern (بدون كتابة)
class DateRangeTile extends StatelessWidget {
  final DateTimeRange? range;
  final VoidCallback onPick;
  final VoidCallback? onClear;
  final String title;
  final String subtitle;

  const DateRangeTile({
    super.key,
    required this.range,
    required this.onPick,
    this.onClear,
    this.title = "Availability Dates",
    this.subtitle = "Pick a date range for availability",
  });

  String _fmt(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    final has = range != null;
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.date_range_rounded, color: kPrimaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: kTextColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    has
                        ? "${_fmt(range!.start)} → ${_fmt(range!.end)}"
                        : subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: has ? kTextColor : Colors.grey.shade600,
                      fontWeight: has ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (has && onClear != null)
              IconButton(
                onPressed: onClear,
                icon: Icon(Icons.close_rounded, color: Colors.grey.shade600),
              )
            else
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }
}

/// ✅ صورة Cover بسيطة
class CoverImageBox extends StatelessWidget {
  final Uint8List? bytes;
  final VoidCallback onPick;

  const CoverImageBox({
    super.key,
    required this.bytes,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 150,
        child: bytes == null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_photo_alternate_outlined,
                        size: 32, color: kPrimaryColor),
                    const SizedBox(height: 6),
                    Text(
                      "Upload cover image",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: kPrimaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.memory(
                  bytes!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
      ),
    );
  }
}