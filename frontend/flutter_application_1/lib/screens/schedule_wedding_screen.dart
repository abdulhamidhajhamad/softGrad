// lib/screens/schedule_wedding_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ScheduleWeddingScreen extends StatefulWidget {
  const ScheduleWeddingScreen({super.key});

  @override
  State<ScheduleWeddingScreen> createState() => _ScheduleWeddingScreenState();
}

class _ScheduleWeddingScreenState extends State<ScheduleWeddingScreen> {
  static const Color kBrand = Color(0xFFB14E56);

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 30));
  TimeOfDay _from = const TimeOfDay(hour: 11, minute: 0);
  TimeOfDay _to = const TimeOfDay(hour: 12, minute: 0);
  final _notes = TextEditingController();

  String get _dateLabel => DateFormat('MMMM dd, yyyy').format(_selectedDate);

  String _fmt(TimeOfDay t) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, t.hour, t.minute);
    return DateFormat('hh:mm a').format(dt);
  }

  Future<void> _pickFrom() async {
    final v = await showTimePicker(context: context, initialTime: _from);
    if (v != null) setState(() => _from = v);
  }

  Future<void> _pickTo() async {
    final v = await showTimePicker(context: context, initialTime: _to);
    if (v != null) setState(() => _to = v);
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cardWidth = size.width * 0.88;

    // تخصيص مظهر التقويم: اليوم المختار بلون ماركة وهالة خفيفة
    final datePickerTheme = DatePickerThemeData(
      dayForegroundColor: MaterialStateProperty.resolveWith((states) {
        return states.contains(MaterialState.selected)
            ? const Color.fromARGB(255, 249, 0, 0)
            : const Color(0xFF2B2B2B);
      }),
      dayBackgroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return kBrand;
        return Colors.transparent;
      }),
      dayOverlayColor: MaterialStateProperty.all(kBrand.withOpacity(0.12)),
      todayForegroundColor: MaterialStateProperty.all(const Color(0xFF2B2B2B)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFC55B63), Color(0xFFB14E56)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Container(
                width: cardWidth,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Set Wedding Details',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cookie(
                        fontSize: 35,
                        fontWeight: FontWeight.w700,
                        color: const Color.fromARGB(255, 120, 14, 14),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // التقويم
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F3F3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(datePickerTheme: datePickerTheme),
                        child: CalendarDatePicker(
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365 * 5),
                          ),
                          onDateChanged: (d) =>
                              setState(() => _selectedDate = d),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // التاريخ المختار
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Selected Wedding Date',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: const Color(0xFF757575),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _dateLabel,
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: kBrand,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // الوقت
                    Text(
                      'Set wedding time',
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2B2B2B),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                'From:',
                                style: GoogleFonts.montserrat(fontSize: 14),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: _pickFrom,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: kBrand),
                                  foregroundColor: kBrand,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(90),
                                  ),
                                ),
                                child: Text(_fmt(_from)),
                              ),
                              const Spacer(),
                              Text(
                                'To:',
                                style: GoogleFonts.montserrat(fontSize: 14),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: _pickTo,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: kBrand),
                                  foregroundColor: kBrand,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(90),
                                  ),
                                ),
                                child: Text(_fmt(_to)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _notes,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Additional Notes',
                              hintStyle: GoogleFonts.montserrat(
                                color: const Color.fromARGB(255, 116, 114, 114),
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Next
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kBrand,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Next',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
