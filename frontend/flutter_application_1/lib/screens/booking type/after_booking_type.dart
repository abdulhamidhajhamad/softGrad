// lib/screens/after_booking_type.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

const Color kPrimaryColor = Color.fromARGB(215, 20, 20, 215);
const Color kTextColor = Color(0xFF111827);
const Color kBackgroundColor = Color(0xFFF3F4F6);

class AfterBookingTypeScreen extends StatefulWidget {
  final String bookingType;
  final String category;

  const AfterBookingTypeScreen({
    Key? key,
    required this.bookingType,
    required this.category,
  }) : super(key: key);

  @override
  State<AfterBookingTypeScreen> createState() => _AfterBookingTypeScreenState();
}

class _AfterBookingTypeScreenState extends State<AfterBookingTypeScreen> {
  DateTime? selectedDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  final TextEditingController notesCtrl = TextEditingController();
  final TextEditingController peopleCtrl = TextEditingController();
  final TextEditingController quantityCtrl = TextEditingController();

  Uint8List? uploadedImage;

  Future<void> pickDate() async {
    final pick = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (pick != null) setState(() => selectedDate = pick);
  }

  Future<void> pickTime(bool isStart) async {
    final pick =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (pick != null) {
      setState(() {
        if (isStart)
          startTime = pick;
        else
          endTime = pick;
      });
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      uploadedImage = await img.readAsBytes();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.3,
        title: Text(
          widget.category,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: kTextColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _buildDynamicUI(),
      ),
      bottomNavigationBar: _buildSaveButton(),
    );
  }

  Widget _buildDynamicUI() {
    switch (widget.bookingType) {
      case "Hourly Booking":
        return _hourlyUI();
      case "Full-Day Booking":
        return _fullDayUI();

      // ✅ دعم الاسمَين (حسب اللي عندك بباقي الشاشات)
      case "Capacity Booking":
      case "Capacity-based Booking":
        return _capacityUI();

      // ✅ دعم الاسمَين (حسب اللي عندك بباقي الشاشات)
      case "Order-Based Booking":
      case "Order-based Booking":
        return _orderUI();

      default:
        return Text("Unknown booking type");
    }
  }

  Widget _hourlyUI() {
    return Column(
      children: [
        _sectionLabel("Select Date"),
        _datePickerTile(),
        const SizedBox(height: 16),
        _sectionLabel("Time Range"),
        _timePickerRow("Start Time", startTime, () => pickTime(true)),
        _timePickerRow("End Time", endTime, () => pickTime(false)),
        const SizedBox(height: 16),
        _notesField(),
      ],
    );
  }

  Widget _fullDayUI() {
    return Column(
      children: [
        _sectionLabel("Event Date"),
        _datePickerTile(),
        const SizedBox(height: 16),
        _notesField(),
      ],
    );
  }

  Widget _capacityUI() {
    return Column(
      children: [
        _sectionLabel("Number of People"),
        _roundedInput("People Count", peopleCtrl),
        const SizedBox(height: 16),
        _notesField(),
      ],
    );
  }

  Widget _orderUI() {
    return Column(
      children: [
        _sectionLabel("Quantity"),
        _roundedInput("Quantity", quantityCtrl),
        const SizedBox(height: 16),
        _sectionLabel("Design Image (Optional)"),
        _imagePicker(),
        const SizedBox(height: 16),
        _sectionLabel("Delivery Date"),
        _datePickerTile(),
        const SizedBox(height: 16),
        _notesField(),
      ],
    );
  }

  Widget _sectionLabel(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: kTextColor,
        ),
      ),
    );
  }

  Widget _timePickerRow(String label, TimeOfDay? time, VoidCallback tap) {
    return GestureDetector(
      onTap: tap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        margin: const EdgeInsets.only(top: 10),
        decoration: _boxDecoration(),
        child: Row(
          children: [
            Text(label, style: GoogleFonts.poppins(fontSize: 13)),
            const Spacer(),
            Text(
              time == null ? "Select" : time.format(context),
              style: GoogleFonts.poppins(fontSize: 13, color: kPrimaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundedInput(String label, TextEditingController ctrl) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: _boxDecoration(),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: label,
          border: InputBorder.none,
        ),
        style: GoogleFonts.poppins(fontSize: 13),
      ),
    );
  }

  Widget _datePickerTile() {
    return GestureDetector(
      onTap: pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        margin: const EdgeInsets.only(top: 10),
        decoration: _boxDecoration(),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 18),
            const SizedBox(width: 12),
            Text(
              selectedDate == null
                  ? "Select Date"
                  : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePicker() {
    return GestureDetector(
      onTap: pickImage,
      child: Container(
        height: 130,
        decoration: _boxDecoration(),
        child: uploadedImage == null
            ? Center(
                child: Text(
                  "Upload Image",
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.memory(uploadedImage!, fit: BoxFit.cover),
              ),
      ),
    );
  }

  Widget _notesField() {
    return Column(
      children: [
        _sectionLabel("Notes (Optional)"),
        Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: _boxDecoration(),
          child: TextField(
            maxLines: 3,
            controller: notesCtrl,
            decoration: const InputDecoration(
              hintText: "Add additional notes...",
              border: InputBorder.none,
            ),
            style: GoogleFonts.poppins(fontSize: 13),
          ),
        ),
      ],
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE5E7EB)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 7,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          onPressed: () {
            // ✅ Validations حسب نوع البوكينغ
            if (widget.bookingType == "Hourly Booking") {
              if (selectedDate == null || startTime == null || endTime == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please select date + time range")),
                );
                return;
              }
            }

            if (widget.bookingType == "Full-Day Booking") {
              if (selectedDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please select event date")),
                );
                return;
              }
            }

            if (widget.bookingType == "Capacity Booking" ||
                widget.bookingType == "Capacity-based Booking") {
              if (peopleCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter people count")),
                );
                return;
              }
            }

            if (widget.bookingType == "Order-Based Booking" ||
                widget.bookingType == "Order-based Booking") {
              if (quantityCtrl.text.trim().isEmpty || selectedDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter quantity + delivery date")),
                );
                return;
              }
            }

            // ✅ رجّعي payload موحد
            Navigator.pop(context, {
              "ok": true,
              "bookingType": widget.bookingType,
              "category": widget.category,
              "date": selectedDate?.toIso8601String(),
              "startTime": startTime == null
                  ? null
                  : "${startTime!.hour}:${startTime!.minute}",
              "endTime":
                  endTime == null ? null : "${endTime!.hour}:${endTime!.minute}",
              "people": int.tryParse(peopleCtrl.text.trim()),
              "quantity": int.tryParse(quantityCtrl.text.trim()),
              "notes": notesCtrl.text.trim(),
              "designImageBytes": uploadedImage,
            });
          },
          child: Text(
            "Save & Continue",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
