// lib/features/provider/provider.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'become_provider.dart';

class ProviderScreen extends StatefulWidget {
  final bool isDarkMode;
  const ProviderScreen({Key? key, this.isDarkMode = false}) : super(key: key);

  @override
  State<ProviderScreen> createState() => _ProviderScreenState();
}

class _ProviderScreenState extends State<ProviderScreen> {
  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = widget.isDarkMode;

    // Page background (outside the card)
    final Color pageBg = isDarkMode
        ? const Color(0xFF121212)
        : const Color.fromARGB(255, 234, 241, 251);

    final Color text = isDarkMode ? Colors.white : Colors.black;
    const Color kAccentColor = Color.fromARGB(215, 20, 20, 215);

    // Inner card fill
    final Color innerFill = isDarkMode ? const Color(0xFF213248) : Colors.white;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: text),
        title: Text(
          'Provider Mode',
          style: GoogleFonts.poppins(
            color: text,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 640,
                maxHeight: 560,
              ),
              child: Card(
                color: Colors.white, // outer shell
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(48),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: innerFill, // inner content area
                    borderRadius: BorderRadius.circular(46),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 23),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.center, // center children
                    children: [
                      // Multiline centered headline
                      Text(
                        'Let’s share your talent\nReach more couples\nAnd grow your BRAND',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 15.3,
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                          height: 2.0,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Image — no border/clipping, white background, all edges visible
                      Semantics(
                        label: 'Provider illustration',
                        image: true,
                        child: Container(
                          color: Colors.white, // keep the area pure white
                          padding: const EdgeInsets.all(0),
                          child: Image.asset(
                            'assets/images/become_provider.png',
                            height: 240,
                            width: double.infinity,
                            fit: BoxFit.contain, // show full image edges
                            errorBuilder: (_, __, ___) => Container(
                              height: 170,
                              alignment: Alignment.center,
                              color: isDarkMode
                                  ? const Color(0xFF1E1E1E)
                                  : const Color(0xFFF3F3F3),
                              child: Icon(
                                Icons.storefront_rounded,
                                size: 44,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 17),

                      // CTA
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BecomeProviderScreen(
                                    isDarkMode: isDarkMode),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kAccentColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(74),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Start Now  ➔',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
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
      ),
    );
  }
}
