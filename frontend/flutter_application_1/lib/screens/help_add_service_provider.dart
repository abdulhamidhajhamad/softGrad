import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kPrimaryColor = Color.fromARGB(215, 20, 20, 215);

class HelpAddServiceProvider extends StatelessWidget {
  const HelpAddServiceProvider({super.key});

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
    );
  }

  Widget _sectionText(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.grey.shade800,
        height: 1.5,
      ),
    );
  }

  Widget _card(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.4,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
        title: Text(
          "How to Add a Service",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("1. Basic Information"),
                  const SizedBox(height: 10),
                  _sectionText(
                    "• Enter a clear and accurate service name.\n"
                    "• You may add a short tagline to describe your service.\n"
                    "• Make sure your brand name is correct as it will be shown to clients.",
                  ),
                ],
              ),
            ),
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("2. Category & Location"),
                  const SizedBox(height: 10),
                  _sectionText(
                    "• Select the correct category for the service.\n"
                    "• Choose your city. If it doesn’t exist, use the 'Other' option.\n"
                    "• You may add an exact address to help clients find you.",
                  ),
                ],
              ),
            ),
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("3. Pricing"),
                  const SizedBox(height: 10),
                  _sectionText(
                    "• Enter the starting price accurately.\n"
                    "• Choose the price type (Per Event, Per Hour, Per Person).\n"
                    "• Add a discount percentage if available.",
                  ),
                ],
              ),
            ),
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("4. Packages"),
                  const SizedBox(height: 10),
                  _sectionText(
                    "• Add multiple packages for your service.\n"
                    "• Each package includes: a name, price, and short description.\n"
                    "• Examples: Standard Package, Premium Package, Gold Package.",
                  ),
                ],
              ),
            ),
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("5. Description & Highlights"),
                  const SizedBox(height: 10),
                  _sectionText(
                    "• Write a short description to summarize your service.\n"
                    "• Add a full detailed description to give clients all the details they need.\n"
                    "• You can add highlights such as:\n"
                    "  – Free delivery\n"
                    "  – Professional team\n"
                    "  – Modern equipment",
                  ),
                ],
              ),
            ),
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("6. Service Photos"),
                  const SizedBox(height: 10),
                  _sectionText(
                    "• Upload high-quality and real photos.\n"
                    "• You can upload up to 10 images.\n"
                    "• Photos are one of the most important elements — choose them wisely.",
                  ),
                ],
              ),
            ),
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("7. Visibility"),
                  const SizedBox(height: 10),
                  _sectionText(
                    "• You can hide or show the service anytime.\n"
                    "• Hidden services will not appear to clients.",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  "Got it",
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
