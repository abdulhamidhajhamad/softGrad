import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Import your signup screens
import 'signup_customer.dart';
import 'signup_provider.dart';

enum UserRole { customer, provider }

class ChooseRoleScreen extends StatefulWidget {
  const ChooseRoleScreen({Key? key}) : super(key: key);

  @override
  State<ChooseRoleScreen> createState() => _ChooseRoleScreenState();
}

class _ChooseRoleScreenState extends State<ChooseRoleScreen> {
  UserRole? _selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // سماوي فاتح للخلفية العامة
      backgroundColor: const Color(0xFFE3F2FD),
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 26, vertical: 84),
            padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Title
                Text(
                  "Choose Your Role",
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 12),

                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // CUSTOMER CARD
                      _roleCard(
                        title: "Customer",
                        imagePath: "assets/images/customer.png",
                        isSelected: _selectedRole == UserRole.customer,
                        onTap: () {
                          setState(() => _selectedRole = UserRole.customer);
                        },
                      ),

                      const SizedBox(height: 18),

                      // PROVIDER CARD
                      _roleCard(
                        title: "Provider",
                        imagePath: "assets/images/provider.png",
                        isSelected: _selectedRole == UserRole.provider,
                        onTap: () {
                          setState(() => _selectedRole = UserRole.provider);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Continue BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _selectedRole == null
                        ? null
                        : () {
                            if (_selectedRole == UserRole.customer) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignUpScreen(),
                                ),
                              );
                            } else if (_selectedRole == UserRole.provider) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const SignUpProviderScreen(),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(215, 20, 20, 215),
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      "Continue",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ROLE CARD WIDGET
  Widget _roleCard({
    required String title,
    required String imagePath,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Center(
        child: SizedBox(
          width: 240, // لتكون أقرب لمربّع ومش ممتدة على كامل الشاشة
          child: Card(
            elevation: 6,
            shadowColor: Colors.black.withOpacity(0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: isSelected
                    ? const Color.fromARGB(215, 20, 20, 215)
                    : Colors.grey.shade200,
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // الصورة داخل شكل ناعم modern
                  Container(
                    height: 90,
                    width: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.grey.shade100,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
