// lib/screens/showMore_provider.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'full_image_viewer_provider.dart';

const Color kPrimaryColor = Color.fromARGB(215, 20, 20, 215);

class ShowMoreProviderScreen extends StatefulWidget {
  final Map<String, dynamic> service;
  final Function(Map<String, dynamic>)? onEdit;

  const ShowMoreProviderScreen({
    Key? key,
    required this.service,
    this.onEdit,
  }) : super(key: key);

  @override
  State<ShowMoreProviderScreen> createState() => _ShowMoreProviderScreenState();
}

class _ShowMoreProviderScreenState extends State<ShowMoreProviderScreen> {
  @override
  Widget build(BuildContext context) {
    final service = widget.service;

    final images = List<String>.from(service['images'] ?? []);
    final highlights = List<String>.from(service['highlights'] ?? []);
    final packages = List<Map<String, dynamic>>.from(service['packages'] ?? []);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.3,
        title: Text(
          "Service Details",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),

            // IMAGES SECTION
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullImageViewer(images: images),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  height: 240,
                  child: images.isEmpty
                      ? Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(Icons.image_outlined,
                                color: Colors.grey, size: 60),
                          ))
                      : PageView.builder(
                          itemCount: images.length,
                          itemBuilder: (_, i) {
                            return Image.file(
                              File(images[i]),
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              service["name"] ?? "",
              style: GoogleFonts.poppins(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),

            Text(
              service["category"] ?? "",
              style: GoogleFonts.poppins(
                  fontSize: 15, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Text(
                  "\$${service['price']}",
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: kPrimaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  service["priceType"] ?? "",
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: Colors.grey.shade700),
                ),
              ],
            ),

            if (service["discount"] != null &&
                service["discount"].toString().isNotEmpty)
              Text(
                "Discount: ${service["discount"]}%",
                style:
                    GoogleFonts.poppins(color: Colors.redAccent, fontSize: 14),
              ),

            const SizedBox(height: 20),

            Text(
              service["shortDescription"] ?? "",
              style: GoogleFonts.poppins(fontSize: 15),
            ),

            const SizedBox(height: 20),

            Text(
              "Full Description",
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              service["fullDescription"] ?? "",
              style: GoogleFonts.poppins(fontSize: 14),
            ),

            const SizedBox(height: 22),

            // HIGHLIGHTS
            if (highlights.isNotEmpty) ...[
              Text(
                "Key Highlights",
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: highlights
                    .map(
                      (h) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: kPrimaryColor.withOpacity(0.2)),
                        ),
                        child: Text(
                          h,
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: Colors.black),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 22),
            ],

            // PACKAGES
            if (packages.isNotEmpty) ...[
              Text(
                "Packages",
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Column(
                children: packages
                    .map(
                      (p) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p["name"],
                              style: GoogleFonts.poppins(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "\$${p["price"]}",
                              style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: kPrimaryColor),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              p["desc"],
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: Colors.grey.shade800),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],

            const SizedBox(height: 70),
          ],
        ),
      ),

      // BOTTOM - EDIT BUTTON
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, -2))
          ],
        ),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.edit, color: Colors.white),
          onPressed: () {
            Navigator.pop(context, {"edit": true});
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          label: Text(
            "Edit This Service",
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
