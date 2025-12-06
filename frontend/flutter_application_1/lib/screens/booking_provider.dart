import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kPrimaryColor = Color.fromARGB(215, 20, 20, 215);
const Color kTextColor = Colors.black;
const Color kBackgroundColor = Colors.white;

class Booking {
  final String clientName;
  final String eventType;
  final String date;
  final String time;
  final String location;
  String status;

  Booking({
    required this.clientName,
    required this.eventType,
    required this.date,
    required this.time,
    required this.location,
    this.status = 'Pending',
  });
}

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  List<Booking> allBookings = [];
  String selectedFilter = 'All';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    // TODO: لاحقًا يتم الربط مع API
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      allBookings = []; // سيتم تعبئتها من الAPI لاحقًا
      isLoading = false;
    });
  }

  List<Booking> get filteredBookings {
    if (selectedFilter == 'All') return allBookings;
    return allBookings.where((b) => b.status == selectedFilter).toList();
  }

  // ----------------------
  //   🔥 إضافة التراجع Undo
  // ----------------------
  void updateStatus(Booking booking, String newStatus) {
    final oldStatus = booking.status;

    setState(() {
      booking.status = newStatus;
      // TODO: ارسال الحالة الجديدة للـ API
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Status changed to $newStatus"),
        action: SnackBarAction(
          label: "Undo",
          onPressed: () {
            setState(() {
              booking.status = oldStatus;
              // TODO: إعادة إرسال الحالة القديمة للـ API
            });
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("My Bookings",
            style: GoogleFonts.poppins(
              color: kTextColor,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            )),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilterTabs(),
                const SizedBox(height: 10),
                Expanded(
                  child: filteredBookings.isEmpty
                      ? Center(
                          child: Text("No bookings in this category",
                              style: GoogleFonts.poppins(color: Colors.grey)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filteredBookings.length,
                          itemBuilder: (context, index) {
                            final booking = filteredBookings[index];
                            return _BookingCard(
                              booking: booking,
                              onStatusChange: updateStatus,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = ['All', 'Pending', 'Approved', 'Rejected'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter;
          return ChoiceChip(
            label: Text(filter,
                style: GoogleFonts.poppins(
                    color: isSelected ? Colors.white : kTextColor)),
            selected: isSelected,
            selectedColor: kPrimaryColor,
            onSelected: (_) => setState(() => selectedFilter = filter),
          );
        }).toList(),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final Function(Booking, String) onStatusChange;

  const _BookingCard({
    required this.booking,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0, // بدون ظل
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: kPrimaryColor.withOpacity(0.1),
                  radius: 28,
                  child: Text(
                    booking.clientName[0],
                    style: const TextStyle(
                      color: kPrimaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _iconRow(Icons.person, booking.clientName),
                      _iconRow(Icons.event, booking.eventType),
                      _iconRow(Icons.calendar_month,
                          "${booking.date} at ${booking.time}"),
                      _iconRow(Icons.location_on, booking.location),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: booking.status == 'Approved'
                        ? Colors.green.shade100
                        : booking.status == 'Rejected'
                            ? Colors.red.shade100
                            : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    booking.status,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: booking.status == 'Approved'
                          ? Colors.green
                          : booking.status == 'Rejected'
                              ? Colors.red
                              : Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),
            if (booking.status == 'Pending') ...[
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => onStatusChange(booking, 'Rejected'),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text("Reject",
                        style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => onStatusChange(booking, 'Approved'),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text("Approve"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                    ),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _iconRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 4),
          Expanded(
            child: Text(text, style: GoogleFonts.poppins(fontSize: 13)),
          )
        ],
      ),
    );
  }
}
