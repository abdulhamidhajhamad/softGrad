import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/widgets/auth/auth_responsive_wrapper.dart';

/// ✅ Responsive Sign Up Screen for Mobile & Web
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Form Key
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _otherCityCtrl = TextEditingController();

  // Cities Dropdown
  final List<String> _cities = const [
    'Nablus',
    'Ramallah',
    'Jerusalem',
    'Hebron',
    'Bethlehem',
    'Jenin',
    'Tulkarm',
    'Qalqilya',
    'Jericho',
    'Salfit',
    'Tubas',
    'Gaza',
    'Khan Yunis',
    'Rafah',
    'Deir al-Balah',
    'Al-Bireh',
    'Other',
  ];

  String? _selectedCity = "Nablus";
  String _passwordStrengthLabel = "";
  Color _passwordStrengthColor = Colors.transparent;
  bool _showPass = false;
  bool _showConfirm = false;
  bool _isLoading = false;

  // لحفظ الدور الحالي
  String _currentRole = 'user'; // ✅ تم تغييره من 'customer' إلى 'user'

  @override
  void initState() {
    super.initState();
    // استخدام AuthService
    AuthService.testConnection();
  }

  Future<void> _testConnection() async {
    print('🔗 Testing connection to server...');
    await AuthService.testConnection();
  }

  static const kPrimaryButtonColor = Color.fromARGB(215, 20, 20, 215);
  static const kTextColor = Colors.black;

  // Decoration
  InputDecoration _decor({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade500),
      filled: true,
      fillColor: Colors.grey.shade50,
      prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade700),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: kPrimaryButtonColor, width: 2),
      ),
    );
  }

  Text _label(String text) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: kTextColor,
        ),
      );

  // ===============================================
  // SUBMIT (API Call)
  // ===============================================
  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // **التعديل هنا:** قراءة الدور من الـ Arguments
      final arguments =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final String userRole = arguments?['role'] ?? 'user'; // ✅ Backend يتوقع 'user' وليس 'customer'

      try {
        // **التعديل هنا:** استخدام AuthService.signup وتمرير الدور
        final response = await AuthService.signup(
          userName: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          phone: _phoneCtrl.text.trim(),
          city: _selectedCity == 'Other'
              ? _otherCityCtrl.text.trim()
              : _selectedCity!,
          role: userRole, // تمرير الدور ('user' أو 'vendor')
        );

        if (response.containsKey('message')) {
          // نجح التسجيل - الانتقال لشاشة التحقق
          Navigator.pushReplacementNamed(
            context,
            '/verification',
            arguments: {
              "email": _emailCtrl.text.trim(),
              // تمرير الدور إلى شاشة التحقق ليتم توجيهه بعدها إلى شاشة المزود إذا كان الدور 'vendor'
              "role": userRole,
              "name": _nameCtrl.text.trim(),
            },
          );
        } else {
          _showErrorDialog('Signup failed. Please try again.');
        }
      } catch (e) {
        String errorMessage = 'An error occurred. Please try again.';

        if (e.toString().contains('email already exists')) {
          errorMessage = 'Email already exists. Please use a different email.';
        } else if (e.toString().contains('Network error')) {
          errorMessage = 'Network error. Please check your connection.';
        }

        _showErrorDialog(errorMessage);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Signup Failed',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(message, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                color: const Color.fromARGB(215, 20, 20, 215),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Password Strength Logic
  void _evaluatePasswordStrength(String password) {
    String label;
    Color color;

    if (password.isEmpty) {
      label = '';
      color = Colors.transparent;
    } else if (password.length < 6) {
      label = 'Weak';
      color = Colors.red;
    } else if (password.length < 16) {
      label = 'Medium';
      color = Colors.orange;
    } else {
      label = 'Strong';
      color = Colors.green;
    }

    setState(() {
      _passwordStrengthLabel = label;
      _passwordStrengthColor = color;
    });
  }

  double _strengthValue() {
    switch (_passwordStrengthLabel) {
      case 'Weak':
        return 0.33;
      case 'Medium':
        return 0.66;
      case 'Strong':
        return 1.0;
      default:
        return 0.0;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _otherCityCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // قراءة الدور وتحديث حالة الواجهة عند تغيير التبعيات
    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _currentRole = arguments?['role'] ?? 'user';
  }

  @override
  Widget build(BuildContext context) {
    final String roleDisplay = _currentRole == 'vendor' ? 'Provider' : 'Customer';

    return AuthResponsiveWrapper(
      pageType: AuthPageType.signUp,
      showBackButton: true,
      onBack: () => Navigator.pop(context),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            Text(
              'Create Account',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A2E),
              ),
            ),

            const SizedBox(height: 4),

            Row(
              children: [
                Text(
                  'Signing up as ',
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    color: Colors.grey.shade600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    roleDisplay,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Full Name
            AuthTextField(
              controller: _nameCtrl,
              label: 'Full Name',
              hint: 'Enter your full name',
              prefixIcon: Icons.person_outline,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
            ),

            const SizedBox(height: 16),

            // Email
            AuthTextField(
              controller: _emailCtrl,
              label: 'Email',
              hint: 'you@example.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter your email';
                final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim());
                return ok ? null : 'Enter a valid email';
              },
            ),

            const SizedBox(height: 16),

            // Phone
            AuthTextField(
              controller: _phoneCtrl,
              label: 'Phone Number',
              hint: 'Enter your phone number',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter phone number' : null,
            ),

            const SizedBox(height: 16),

            // City Dropdown
            AuthDropdownField<String>(
              label: 'City',
              hint: 'Select your city',
              prefixIcon: Icons.location_city_outlined,
              value: _selectedCity,
              items: _cities.map((city) => DropdownMenuItem(
                value: city,
                child: Text(city, style: GoogleFonts.poppins(fontSize: 14)),
              )).toList(),
              onChanged: (v) => setState(() => _selectedCity = v),
              validator: (v) => (v == null || v.isEmpty) ? 'Select your city' : null,
            ),

            if (_selectedCity == 'Other') ...[
              const SizedBox(height: 12),
              AuthTextField(
                controller: _otherCityCtrl,
                label: 'Your City',
                hint: 'Enter your city',
                prefixIcon: Icons.edit_location_alt_outlined,
                validator: (v) {
                  if (_selectedCity == 'Other' && (v == null || v.trim().isEmpty)) {
                    return 'Please enter your city';
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: 16),

            // Password
            AuthTextField(
              controller: _passCtrl,
              label: 'Password',
              hint: '••••••••',
              prefixIcon: Icons.lock_outline,
              obscureText: !_showPass,
              onChanged: _evaluatePasswordStrength,
              suffix: IconButton(
                onPressed: () => setState(() => _showPass = !_showPass),
                icon: Icon(
                  _showPass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.grey,
                ),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Enter a password' : null,
            ),

            // Password Strength Indicator
            if (_passwordStrengthLabel.isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  value: _strengthValue(),
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.bolt_rounded, size: 16, color: _passwordStrengthColor),
                  const SizedBox(width: 6),
                  Text(
                    'Password strength: $_passwordStrengthLabel',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _passwordStrengthColor,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Confirm Password
            AuthTextField(
              controller: _confirmCtrl,
              label: 'Confirm Password',
              hint: '••••••••',
              prefixIcon: Icons.lock_outline,
              obscureText: !_showConfirm,
              suffix: IconButton(
                onPressed: () => setState(() => _showConfirm = !_showConfirm),
                icon: Icon(
                  _showConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.grey,
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Confirm your password';
                if (v != _passCtrl.text) return 'Passwords do not match';
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Sign Up Button
            AuthButton(
              text: 'Sign up as $roleDisplay',
              onPressed: _submit,
              isLoading: _isLoading,
            ),

            const SizedBox(height: 24),

            // Sign In Link
            AuthLinkText(
              prefix: 'Already have an account? ',
              linkText: 'Sign In',
              onTap: () => Navigator.pushReplacementNamed(context, '/signin'),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
