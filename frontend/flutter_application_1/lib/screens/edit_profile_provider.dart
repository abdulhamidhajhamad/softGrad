// lib/screens/edit_profile_provider.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_provider.dart';
import 'edit_profile_company.dart';

class EditProfileProvider extends StatefulWidget {
  final ProviderModel provider;

  const EditProfileProvider({Key? key, required this.provider})
      : super(key: key);

  @override
  State<EditProfileProvider> createState() => _EditProfileProviderState();
}

class _EditProfileProviderState extends State<EditProfileProvider> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _usernameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  String? _selectedCity;

  late TextEditingController _passCtrl;
  late TextEditingController _confirmCtrl;
  bool _showPass = false, _showConfirm = false;

  String _passwordStrengthLabel = '';
  Color _passwordStrengthColor = Colors.transparent;

  static const kPrimaryColor = Color.fromARGB(215, 20, 20, 215);

  final List<String> _cities = const [
    'Nablus',
    'Ramallah',
    'Hebron',
    'Jenin',
    'Tulkarm',
    'Qalqilya',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: widget.provider.brandName);
    _phoneCtrl = TextEditingController(text: widget.provider.phone);
    _emailCtrl = TextEditingController(text: widget.provider.email);
    _selectedCity =
        _cities.contains(widget.provider.city) ? widget.provider.city : null;

    _passCtrl = TextEditingController();
    _confirmCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  InputDecoration _decor(String hint, {IconData? icon, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade500),
      filled: true,
      fillColor: Colors.grey.shade100,
      prefixIcon: icon != null
          ? Icon(icon, color: Colors.grey.shade700, size: 20)
          : null,
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _modernCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ...children
        ],
      ),
    );
  }

  void _evaluatePasswordStrength(String pass) {
    if (pass.isEmpty) {
      _passwordStrengthLabel = '';
      _passwordStrengthColor = Colors.transparent;
    } else if (pass.length < 6) {
      _passwordStrengthLabel = 'Weak';
      _passwordStrengthColor = Colors.red;
    } else if (pass.length < 12) {
      _passwordStrengthLabel = 'Medium';
      _passwordStrengthColor = Colors.orange;
    } else {
      _passwordStrengthLabel = 'Strong';
      _passwordStrengthColor = Colors.green;
    }
    setState(() {});
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final updated = {
      "username": _usernameCtrl.text,
      "phone": _phoneCtrl.text,
      "email": _emailCtrl.text,
      "city": _selectedCity,
    };

    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text("Edit Profile",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: Colors.black,
                fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _modernCard("Profile Information", [
                TextFormField(
                  controller: _usernameCtrl,
                  decoration:
                      _decor("Username", icon: Icons.person_outline_rounded),
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: _decor("Phone", icon: Icons.phone_outlined),
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _decor("Email", icon: Icons.email_outlined),
                  validator: (v) =>
                      v != null && v.contains('@') ? null : "Invalid email",
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  decoration:
                      _decor("City", icon: Icons.location_city_outlined),
                  items: _cities
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c,
                                style: GoogleFonts.poppins(fontSize: 14)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    setState(() => _selectedCity = v);
                  },
                ),
              ]),

              _modernCard("Security", [
                TextFormField(
                  controller: _passCtrl,
                  obscureText: !_showPass,
                  onChanged: _evaluatePasswordStrength,
                  decoration: _decor("New Password",
                      icon: Icons.lock_outline,
                      suffix: IconButton(
                        icon: Icon(
                            _showPass
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.grey.shade700),
                        onPressed: () => setState(() => _showPass = !_showPass),
                      )),
                ),
                if (_passwordStrengthLabel.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _passwordStrengthLabel == "Weak"
                        ? 0.3
                        : _passwordStrengthLabel == "Medium"
                            ? 0.6
                            : 1.0,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation(_passwordStrengthColor),
                  ),
                ],
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: !_showConfirm,
                  decoration: _decor("Confirm Password",
                      icon: Icons.lock_outline,
                      suffix: IconButton(
                        icon: Icon(
                            _showConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.grey.shade700),
                        onPressed: () =>
                            setState(() => _showConfirm = !_showConfirm),
                      )),
                  validator: (v) {
                    if (_passCtrl.text.isNotEmpty &&
                        v != _passCtrl.text.trim()) {
                      return "Passwords do not match";
                    }
                    return null;
                  },
                ),
              ]),

              const SizedBox(height: 10),

              // SAVE CHANGES BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text("Save Changes",
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ),
              ),

              const SizedBox(height: 14),

              // GO TO COMPANY INFORMATION BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    side: BorderSide(color: kPrimaryColor, width: 3.0),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    final companyData = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EditProfileCompany()),
                    );

                    if (companyData != null) {
                      print("Company updated: $companyData");
                    }
                  },
                  child: Text(
                    "Go to Company Information",
                    style: GoogleFonts.poppins(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}