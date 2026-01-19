// lib/screens/compliance_provider/compliance_provider.dart
// شاشة التوثيق والامتثال للمزودين

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'compliance_provider_service.dart';
import 'package:flutter_application_1/screens/provider/home_provider.dart';

// ============================================================================
// 🎨 THEME COLORS
// ============================================================================
const Color kPrimaryColor = Color(0xFF6C63FF);
const Color kPrimaryLight = Color(0xFFE8E6FF);
const Color kBackgroundColor = Color(0xFFF8F9FC);
const Color kCardColor = Colors.white;
const Color kTextPrimary = Color(0xFF1A1D26);
const Color kTextSecondary = Color(0xFF6B7280);
const Color kSuccessColor = Color(0xFF10B981);
const Color kWarningColor = Color(0xFFFF6B35);
const Color kErrorColor = Color(0xFFEF4444);
const Color kInfoColor = Color(0xFF3B82F6);

// ============================================================================
// 📱 VERIFICATION SCREEN - شاشة التحقق الرئيسية
// ============================================================================
class VerificationScreen extends StatefulWidget {
  final bool isFromSignup;
  final Map<String, dynamic>? providerData;

  const VerificationScreen({
    Key? key,
    this.isFromSignup = true,
    this.providerData,
  }) : super(key: key);

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen>
    with SingleTickerProviderStateMixin {
  // Controllers
  final _formKey = GlobalKey<FormState>();
  final _idNumberCtrl = TextEditingController();
  final _arabicNameCtrl = TextEditingController();
  late AnimationController _animationController;

  // State
  ProviderType _selectedType = ProviderType.individual;
  DocumentType _documentType = DocumentType.nationalId;
  File? _selectedFile;
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  bool _isLoading = false;
  bool _isUploading = false;
  String? _errorMessage;
  VerificationResponse? _verificationResult;

  // Image picker
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _idNumberCtrl.dispose();
    _arabicNameCtrl.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ==================== Image Selection ====================

  Future<void> _pickImage(ImageSource source) async {
    try {
      // For document verification, we need HIGH QUALITY images for OCR
      // Don't compress the image to maintain text clarity
      final XFile? image = await _picker.pickImage(
        source: source,
        // Higher resolution for better OCR accuracy
        maxWidth: 4096,
        maxHeight: 4096,
        // 100% quality - no compression for documents
        imageQuality: 100,
      );

      if (image != null) {
        setState(() {
          _selectedFileName = image.name;
          _errorMessage = null;
        });

        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedFileBytes = bytes;
            _selectedFile = null;
          });
        } else {
          setState(() {
            _selectedFile = File(image.path);
            _selectedFileBytes = null;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: ${e.toString()}';
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Select Image Source',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildSourceOption(
                    icon: LucideIcons.camera,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSourceOption(
                    icon: LucideIcons.image,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: kPrimaryLight.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kPrimaryLight),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: kPrimaryColor),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Upload & Verify ====================

  Future<void> _uploadAndVerify() async {
    if (_selectedFile == null && _selectedFileBytes == null) {
      setState(() {
        _errorMessage = 'Please select a document image';
      });
      return;
    }

    if (_selectedType == ProviderType.individual && 
        _idNumberCtrl.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your ID number';
      });
      return;
    }

    if (_selectedType == ProviderType.individual &&
        _idNumberCtrl.text.trim().length != 9) {
      setState(() {
        _errorMessage = 'ID number must be exactly 9 digits';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final response = await ComplianceProviderService.uploadDocument(
        file: kIsWeb ? _selectedFileBytes : _selectedFile,
        fileName: _selectedFileName ?? 'document.jpg',
        documentType: _documentType,
        providerType: _selectedType,
        idNumber: _selectedType == ProviderType.individual 
            ? _idNumberCtrl.text.trim() 
            : null,
        arabicName: _arabicNameCtrl.text.trim().isNotEmpty 
            ? _arabicNameCtrl.text.trim() 
            : null,
      );

      setState(() {
        _verificationResult = response;
        _isUploading = false;
      });

      // Show result dialog
      _showVerificationResultDialog(response);
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  // ==================== Result Dialogs ====================

  void _showVerificationResultDialog(VerificationResponse response) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _VerificationResultDialog(
        response: response,
        onContinue: () {
          Navigator.pop(context);
          _navigateToHome(canAddServices: response.status == VerificationStatus.verified);
        },
        onUpdateInfo: () {
          Navigator.pop(context);
          _resetForm();
        },
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _selectedFile = null;
      _selectedFileBytes = null;
      _selectedFileName = null;
      _verificationResult = null;
      _errorMessage = null;
    });
  }

  void _navigateToHome({bool canAddServices = false}) {
    if (widget.isFromSignup && widget.providerData != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => HomeProviderScreen(
            provider: ProviderModel(
              brandName: widget.providerData!['companyName'] ?? '',
              email: widget.providerData!['email'] ?? '',
              phone: widget.providerData!['phone'] ?? '',
              description: widget.providerData!['description'] ?? '',
              city: widget.providerData!['city'] ?? '',
            ),
          ),
        ),
        (_) => false,
      );
    } else {
      Navigator.pop(context, canAddServices);
    }
  }

  // ==================== UI Build Methods ====================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        
        return Scaffold(
          backgroundColor: kBackgroundColor,
          appBar: _buildAppBar(),
          body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft, color: kTextPrimary),
        onPressed: () {
          if (widget.isFromSignup) {
            _showSkipDialog();
          } else {
            Navigator.pop(context);
          }
        },
      ),
      title: Text(
        'Account Verification',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: kTextPrimary,
        ),
      ),
      centerTitle: true,
      actions: [
        if (widget.isFromSignup)
          TextButton(
            onPressed: () => _showSkipDialog(),
            child: Text(
              'Skip',
              style: GoogleFonts.poppins(
                color: kTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  void _showSkipDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kWarningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.alertTriangle, color: kWarningColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Skip Verification?',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'You can continue without verification, but you won\'t be able to add services until your account is verified.',
          style: GoogleFonts.poppins(fontSize: 14, color: kTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Continue Verification',
              style: GoogleFonts.poppins(color: kPrimaryColor, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToHome(canAddServices: false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kTextSecondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Skip', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ==================== Desktop Layout ====================

  Widget _buildDesktopLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(48),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Side - Info
              Expanded(
                flex: 4,
                child: _buildInfoSection(),
              ),
              const SizedBox(width: 48),
              // Right Side - Form
              Expanded(
                flex: 5,
                child: _buildFormCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(LucideIcons.shieldCheck, size: 48, color: Colors.white),
              const SizedBox(height: 24),
              Text(
                'Verify Your Identity',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Complete your verification to unlock all features and build trust with your customers.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildBenefitCard(
          icon: LucideIcons.badgeCheck,
          title: 'Build Trust',
          description: 'Verified badges increase customer confidence by 47%',
        ),
        const SizedBox(height: 12),
        _buildBenefitCard(
          icon: LucideIcons.briefcase,
          title: 'Add Services',
          description: 'Start adding your services and grow your business',
        ),
        const SizedBox(height: 12),
        _buildBenefitCard(
          icon: LucideIcons.lock,
          title: 'Secure & Private',
          description: 'Your documents are encrypted and securely stored',
        ),
      ],
    );
  }

  Widget _buildBenefitCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kPrimaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: kPrimaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: kTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Mobile Layout ====================

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 20),
          _buildFormCard(),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.shieldCheck, size: 32, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verify Your Account',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Complete verification to add services',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider Type Selection
            _buildSectionTitle('Provider Type', LucideIcons.users),
            const SizedBox(height: 12),
            _buildProviderTypeSelector(),
            const SizedBox(height: 24),

            // Document Type Info
            _buildDocumentTypeInfo(),
            const SizedBox(height: 24),

            // ID Number Field (for individuals)
            if (_selectedType == ProviderType.individual) ...[
              _buildSectionTitle('ID Number', LucideIcons.creditCard),
              const SizedBox(height: 12),
              _buildIdNumberField(),
              const SizedBox(height: 24),
            ],

            // Arabic Name (optional)
            _buildSectionTitle('Arabic Name (Optional)', LucideIcons.user),
            const SizedBox(height: 12),
            _buildArabicNameField(),
            const SizedBox(height: 24),

            // Document Upload
            _buildSectionTitle('Upload Document', LucideIcons.upload),
            const SizedBox(height: 8),
            // ⚠️ تنبيه مهم للمستخدم
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kWarningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kWarningColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.alertTriangle, color: kWarningColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Make sure the image is clear and complete, and the ID number is fully visible and not covered.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: kWarningColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildDocumentUploader(),

            // Error Message
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              _buildErrorMessage(),
            ],

            const SizedBox(height: 24),

            // Submit Button
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: kPrimaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: kTextPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildProviderTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildTypeOption(
            type: ProviderType.individual,
            icon: LucideIcons.user,
            label: 'Individual',
            sublabel: 'Freelancer',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTypeOption(
            type: ProviderType.business,
            icon: LucideIcons.building2,
            label: 'Organization',
            sublabel: 'Company',
          ),
        ),
      ],
    );
  }

  Widget _buildTypeOption({
    required ProviderType type,
    required IconData icon,
    required String label,
    required String sublabel,
  }) {
    final isSelected = _selectedType == type;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
          _documentType = type == ProviderType.individual 
              ? DocumentType.nationalId 
              : DocumentType.businessLicense;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryLight : kBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? kPrimaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? kPrimaryColor.withOpacity(0.1) : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? kPrimaryColor : kTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? kPrimaryColor : kTextPrimary,
              ),
            ),
            Text(
              sublabel,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: kTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentTypeInfo() {
    final docInfo = _selectedType == ProviderType.individual
        ? {'icon': LucideIcons.creditCard, 'text': 'Palestinian National ID is required', 'color': kInfoColor}
        : {'icon': LucideIcons.fileText, 'text': 'Business License / Commercial Registration is required', 'color': kWarningColor};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (docInfo['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (docInfo['color'] as Color).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(docInfo['icon'] as IconData, size: 24, color: docInfo['color'] as Color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              docInfo['text'] as String,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: docInfo['color'] as Color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdNumberField() {
    return TextFormField(
      controller: _idNumberCtrl,
      keyboardType: TextInputType.number,
      maxLength: 9,
      decoration: InputDecoration(
        hintText: 'Enter 9-digit ID number',
        hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade500),
        filled: true,
        fillColor: kBackgroundColor,
        prefixIcon: const Icon(LucideIcons.hash, size: 20, color: kTextSecondary),
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimaryColor, width: 2),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'ID number is required';
        if (v.length != 9) return 'ID must be 9 digits';
        if (!RegExp(r'^\d{9}$').hasMatch(v)) return 'ID must contain only numbers';
        return null;
      },
    );
  }

  Widget _buildArabicNameField() {
    return TextFormField(
      controller: _arabicNameCtrl,
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(
        hintText: 'Arabic name (optional)',
        hintStyle: GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade500),
        filled: true,
        fillColor: kBackgroundColor,
        prefixIcon: const Icon(LucideIcons.languages, size: 20, color: kTextSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildDocumentUploader() {
    final hasFile = _selectedFile != null || _selectedFileBytes != null;

    return InkWell(
      onTap: _isUploading ? null : _showImageSourceDialog,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: hasFile ? kSuccessColor.withOpacity(0.05) : kBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasFile ? kSuccessColor.withOpacity(0.3) : Colors.grey.shade300,
            style: hasFile ? BorderStyle.solid : BorderStyle.none,
          ),
        ),
        child: Column(
          children: [
            if (hasFile) ...[
              if (kIsWeb && _selectedFileBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    _selectedFileBytes!,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                )
              else if (_selectedFile != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedFile!,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.checkCircle, size: 18, color: kSuccessColor),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _selectedFileName ?? 'Document selected',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: kSuccessColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to change',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: kTextSecondary,
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kPrimaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.upload, size: 32, color: kPrimaryColor),
              ),
              const SizedBox(height: 16),
              Text(
                'Upload Document',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Take a photo or choose from gallery',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: kTextSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Supported: JPG, PNG, PDF (Max 10MB)',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: kTextSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kErrorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kErrorColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertCircle, size: 20, color: kErrorColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: kErrorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isUploading ? null : _uploadAndVerify,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _isUploading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Analyzing data and official stamps...',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.shieldCheck, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Verify Document',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ============================================================================
// 📋 VERIFICATION RESULT DIALOG
// ============================================================================
class _VerificationResultDialog extends StatelessWidget {
  final VerificationResponse response;
  final VoidCallback onContinue;
  final VoidCallback onUpdateInfo;

  const _VerificationResultDialog({
    required this.response,
    required this.onContinue,
    required this.onUpdateInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(),
            const SizedBox(height: 20),
            _buildTitle(),
            const SizedBox(height: 12),
            _buildMessage(),
            const SizedBox(height: 24),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    Color color;
    Color bgColor;

    switch (response.status) {
      case VerificationStatus.verified:
        icon = LucideIcons.checkCircle;
        color = kSuccessColor;
        bgColor = kSuccessColor.withOpacity(0.1);
        break;
      case VerificationStatus.adminReview:
      case VerificationStatus.underReview:
        icon = LucideIcons.clock;
        color = kWarningColor;
        bgColor = kWarningColor.withOpacity(0.1);
        break;
      case VerificationStatus.rejected:
      case VerificationStatus.expired:
        icon = LucideIcons.xCircle;
        color = kErrorColor;
        bgColor = kErrorColor.withOpacity(0.1);
        break;
      default:
        icon = LucideIcons.alertCircle;
        color = kInfoColor;
        bgColor = kInfoColor.withOpacity(0.1);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 48, color: color),
    );
  }

  Widget _buildTitle() {
    String title;
    Color color;

    switch (response.status) {
      case VerificationStatus.verified:
        title = 'Verification Successful!';
        color = kSuccessColor;
        break;
      case VerificationStatus.adminReview:
        title = 'Under Admin Review';
        color = kWarningColor;
        break;
      case VerificationStatus.underReview:
        title = 'Document Under Review';
        color = kWarningColor;
        break;
      case VerificationStatus.rejected:
        title = 'Verification Failed';
        color = kErrorColor;
        break;
      case VerificationStatus.expired:
        title = 'Document Expired';
        color = kErrorColor;
        break;
      default:
        title = 'Verification Status';
        color = kTextPrimary;
    }

    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: color,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMessage() {
    String message;
    
    switch (response.status) {
      case VerificationStatus.verified:
        message = 'Your account has been verified successfully. You can now add services and start receiving bookings.';
        break;
      case VerificationStatus.adminReview:
        // 🔐 Special message for stamp verification issues
        if (response.isStampReview) {
            message = 'Your document is under additional review by the administration.\n\n'
              'The data has been extracted successfully, but the official stamps require manual verification. '
              'You will be notified of the result within 1-2 business days.';
        } else {
          message = 'Your documents require manual review by our team. This usually takes 1-2 business days. You can continue using the app, but adding services will be available after approval.';
        }
        break;
      case VerificationStatus.underReview:
        message = 'Your documents are being processed. Please wait while we verify your information.';
        break;
      case VerificationStatus.rejected:
        message = response.message.isNotEmpty 
            ? response.message 
            : 'Your verification was rejected. Please upload valid documents and try again.';
        break;
      case VerificationStatus.expired:
        message = 'Your document has expired. Please upload a valid, non-expired document.';
        break;
      default:
        message = response.message;
    }

    // 🔐 Add stamp verification score info if available
    Widget? stampInfo;
    if (response.stampVerification != null) {
      final stamp = response.stampVerification!;
      stampInfo = Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: stamp.found 
              ? kSuccessColor.withOpacity(0.1) 
              : kWarningColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: stamp.found 
                ? kSuccessColor.withOpacity(0.3) 
                : kWarningColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              stamp.found ? LucideIcons.checkCircle2 : LucideIcons.alertCircle,
              size: 18,
              color: stamp.found ? kSuccessColor : kWarningColor,
            ),
            const SizedBox(width: 8),
            Text(
                stamp.found 
                  ? 'Official stamp: Verified ✓' 
                  : 'Official stamp: Needs review',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: stamp.found ? kSuccessColor : kWarningColor,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Text(
          message,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: kTextSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        if (stampInfo != null) stampInfo,
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    switch (response.status) {
      case VerificationStatus.verified:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: kSuccessColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.arrowRight, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Go to Dashboard',
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );

      case VerificationStatus.adminReview:
      case VerificationStatus.underReview:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Continue to Dashboard',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        );

      case VerificationStatus.rejected:
      case VerificationStatus.expired:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onUpdateInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.refreshCw, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Upload New Document',
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onContinue,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Continue Without Verification',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: kTextSecondary,
                  ),
                ),
              ),
            ),
          ],
        );

      default:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Continue',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        );
    }
  }
}

// ============================================================================
// 🔒 VERIFICATION GUARD POPUP
// ============================================================================
class VerificationGuardPopup {
  static void show(BuildContext context, {VoidCallback? onGoToSettings}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kWarningColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.shieldAlert, size: 48, color: kWarningColor),
            ),
            const SizedBox(height: 20),
            Text(
              'Verification Required',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'You need to verify your account before adding services. Complete verification to unlock this feature.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: kTextSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (onGoToSettings != null) {
                    onGoToSettings();
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VerificationScreen(isFromSignup: false),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.shieldCheck, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Go to Verification',
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: kTextSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ⚙️ VERIFICATION SETTINGS SECTION
// ============================================================================
class VerificationSettingsSection extends StatefulWidget {
  const VerificationSettingsSection({Key? key}) : super(key: key);

  @override
  State<VerificationSettingsSection> createState() => _VerificationSettingsSectionState();
}

class _VerificationSettingsSectionState extends State<VerificationSettingsSection> {
  bool _isLoading = true;
  ProviderVerificationStatus? _status;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final status = await ComplianceProviderService.getVerificationStatus();
      if (mounted) {
        setState(() {
          _status = status;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: kPrimaryColor),
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(LucideIcons.alertCircle, size: 32, color: kErrorColor),
            const SizedBox(height: 12),
            Text(
              'Failed to load status',
              style: GoogleFonts.poppins(fontSize: 14, color: kTextSecondary),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadStatus();
              },
              child: Text('Retry', style: GoogleFonts.poppins(color: kPrimaryColor)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.shieldCheck, size: 22, color: kPrimaryColor),
              const SizedBox(width: 10),
              Text(
                'Verification Status',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatusBadge(),
          if (_status?.daysUntilExpiry != null && _status!.daysUntilExpiry! <= 30) ...[
            const SizedBox(height: 12),
            _buildExpiryWarning(),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VerificationScreen(isFromSignup: false),
                  ),
                );
                if (result == true) {
                  _loadStatus();
                }
              },
              icon: const Icon(LucideIcons.upload, size: 18),
              label: Text(
                _status?.verificationStatus == VerificationStatus.verified 
                    ? 'Update Documents' 
                    : 'Verify Now',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: kPrimaryColor,
                side: const BorderSide(color: kPrimaryColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    IconData icon;
    String text;

    switch (_status?.verificationStatus) {
      case VerificationStatus.verified:
        color = kSuccessColor;
        icon = LucideIcons.checkCircle;
        text = 'Verified';
        break;
      case VerificationStatus.adminReview:
      case VerificationStatus.underReview:
        color = kWarningColor;
        icon = LucideIcons.clock;
        text = 'Under Review';
        break;
      case VerificationStatus.rejected:
        color = kErrorColor;
        icon = LucideIcons.xCircle;
        text = 'Rejected';
        break;
      case VerificationStatus.expired:
        color = kErrorColor;
        icon = LucideIcons.alertTriangle;
        text = 'Expired';
        break;
      case VerificationStatus.deactivated:
        color = kTextSecondary;
        icon = LucideIcons.ban;
        text = 'Deactivated';
        break;
      default:
        color = kTextSecondary;
        icon = LucideIcons.helpCircle;
        text = 'Not Verified';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const Spacer(),
          if (_status?.canAddServices == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: kSuccessColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Can Add Services',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: kSuccessColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpiryWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kWarningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kWarningColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertTriangle, size: 18, color: kWarningColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your verification expires in ${_status!.daysUntilExpiry} days. Please renew soon.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: kWarningColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}