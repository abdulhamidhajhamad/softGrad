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

  // -----------------------------
  //  ⭐ Dummy Data Added Here
  // -----------------------------
  Future<void> fetchBookings() async {
    await Future.delayed(const Duration(milliseconds: 700));

    setState(() {
      allBookings = [
        Booking(
          clientName: "Alaa Khader",
          eventType: "Wedding Photography",
          date: "12 Jan 2026",
          time: "4:00 PM",
          location: "Rawabi City Hall",
          status: "Pending",
        ),
        Booking(
          clientName: "Sara Mahmoud",
          eventType: "Engagement Party",
          date: "20 Jan 2026",
          time: "7:00 PM",
          location: "Nablus - AlMashtal",
          status: "Approved",
        ),
        Booking(
          clientName: "Yara Sabri",
          eventType: "Birthday Event",
          date: "3 Feb 2026",
          time: "5:30 PM",
          location: "Ramallah - AlBireh",
          status: "Rejected",
        ),
      ];
      isLoading = false;
    });
  }

  List<Booking> get filteredBookings {
    if (selectedFilter == 'All') return allBookings;
    return allBookings.where((b) => b.status == selectedFilter).toList();
  }

  void updateStatus(Booking booking, String newStatus) {
    final oldStatus = booking.status;

    setState(() => booking.status = newStatus);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text("Status changed to $newStatus"),
        action: SnackBarAction(
          label: "Undo",
          onPressed: () {
            setState(() => booking.status = oldStatus);
          },
        ),
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
        title: Text(
          "My Bookings",
          style: GoogleFonts.poppins(
            color: kTextColor,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
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
                          child: Text(
                            "No bookings in this category",
                            style: GoogleFonts.poppins(color: Colors.grey),
                          ),
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
            label: Text(
              filter,
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.white : kTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            selected: isSelected,
            selectedColor: kPrimaryColor,
            backgroundColor: Colors.grey.shade200,
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
      color: Colors.white,
      elevation: 1.2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                          "${booking.date} • ${booking.time}"),
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
                            : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    booking.status,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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

            // --------------------------
            //  ACTION BUTTONS
            // --------------------------
            if (booking.status == 'Pending') ...[
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => onStatusChange(booking, 'Rejected'),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text(
                      "Reject",
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => onStatusChange(booking, 'Approved'),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text("Approve"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _iconRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          )
        ],
      ),
    );
  }
}