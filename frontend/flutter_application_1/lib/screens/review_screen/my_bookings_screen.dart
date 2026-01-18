// lib/screens/my_bookings_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/services/user_service/review_service.dart';
import 'package:flutter_application_1/screens/review_screen/write_review_screen.dart';

const Color kBrandBlue = Color.fromARGB(215, 20, 20, 215);
const Color kBgColor = Color(0xFFF6F7FB);
const Color kTextPrimary = Color(0xFF0B1220);
const Color kTextMuted = Color(0xFF6B7280);

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({Key? key}) : super(key: key);

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _upcomingBookings = [];
  List<dynamic> _completedBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBookings();
  }

Future<void> _loadBookings() async {
  setState(() => _isLoading = true);
  
  try {
    // ✅ جلب جميع الحجوزات من الـ Backend
    final allBookings = await ReviewService.getUserBookings();
    
    print('📦 Total Bookings Fetched: ${allBookings.length}');
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // ✅ تقسيم الحجوزات: Upcoming و Completed
    final upcoming = <dynamic>[];
    final completed = <dynamic>[];
    
    for (var booking in allBookings) {
      print('🔍 Processing booking: ${booking['serviceName']}');
      print('   - Status: ${booking['status']}');
      print('   - Date: ${booking['bookingDate']}');
      
      // تحويل التاريخ
      final bookingDateStr = booking['bookingDate'];
      if (bookingDateStr == null) {
        print('⚠️ Booking has no date, skipping');
        continue;
      }
      
      final bookingDate = DateTime.parse(bookingDateStr);
      final bookingDay = DateTime(bookingDate.year, bookingDate.month, bookingDate.day);
      
      // تقسيم حسب التاريخ
      if (bookingDay.isAfter(today)) {
        print('   ➡️ Added to UPCOMING');
        upcoming.add(booking);
      } else {
        print('   ➡️ Added to COMPLETED');
        completed.add(booking);
      }
    }
    
    print('✅ Upcoming: ${upcoming.length}, Completed: ${completed.length}');
    
    setState(() {
      _upcomingBookings = upcoming;
      _completedBookings = completed;
      _isLoading = false;
    });
  } catch (e) {
    print('❌ Error loading bookings: $e');
    setState(() => _isLoading = false);
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Bookings',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: kTextPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: kBrandBlue,
          unselectedLabelColor: kTextMuted,
          indicatorColor: kBrandBlue,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kBrandBlue))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUpcomingTab(),
                _buildCompletedTab(),
              ],
            ),
    );
  }

  Widget _buildUpcomingTab() {
    if (_upcomingBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 80, color: kTextMuted.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'No upcoming bookings',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kTextMuted,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _upcomingBookings.length,
      itemBuilder: (context, index) {
        return _buildBookingCard(_upcomingBookings[index], isUpcoming: true);
      },
    );
  }

  Widget _buildCompletedTab() {
    if (_completedBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: kTextMuted.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'No completed bookings',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kTextMuted,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _completedBookings.length,
      itemBuilder: (context, index) {
        return _buildBookingCard(_completedBookings[index], isUpcoming: false);
      },
    );
  }

 Widget _buildBookingCard(dynamic booking, {required bool isUpcoming}) {
  final serviceName = booking['serviceName'] ?? 'Service';
  final status = booking['status'] ?? 'confirmed';
  final bookingDateStr = booking['bookingDate'] ?? '';
  final isReviewed = booking['isReviewed'] == true;
  
  DateTime? bookingDate;
  String formattedDate = 'N/A';
  
  if (bookingDateStr.isNotEmpty) {
    try {
      bookingDate = DateTime.parse(bookingDateStr);
      formattedDate = '${bookingDate.day}/${bookingDate.month}/${bookingDate.year}';
    } catch (e) {
      print('⚠️ Invalid date format: $bookingDateStr');
    }
  }

  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kBrandBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.event_available, color: kBrandBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  serviceName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: kTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: kTextMuted),
              const SizedBox(width: 8),
              Text(
                formattedDate,
                style: GoogleFonts.poppins(fontSize: 14, color: kTextMuted),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isUpcoming ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status == 'confirmed' ? 'Confirmed ✓' : 'Completed ✓',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isUpcoming ? Colors.blue : Colors.green,
                  ),
                ),
              ),
            ],
          ),
          if (!isUpcoming) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: isReviewed
                  // ✅ Reviewed Button - Disabled with different style
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade400, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Reviewed',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade400,
                            ),
                          ),
                        ],
                      ),
                    )
                  // ✅ Rate Now Button - Active
                  : ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WriteReviewScreen(
                              bookingId: booking['bookingId'] ?? booking['_id'] ?? '',
                              serviceId: booking['serviceId'] ?? '',
                              serviceName: serviceName,
                              companyName: booking['companyName'] ?? '',
                            ),
                          ),
                        ).then((_) => _loadBookings());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBrandBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Rate Now ⭐',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
          ],
        ],
      ),
    ),
  );
}

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}