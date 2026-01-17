// lib/screens/user/web/pages/web_ai_page.dart
//
// ✅ Web AI Package Builder Page
// ✅ Multi-step form wizard
// ✅ Modern card-based design
// ✅ Search mode selection (Single Service / Full Package)
// ✅ Required field validation
// ✅ Manual budget input
// ✅ Flexible options for "With Options" preference

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../web_theme.dart';
import 'package:flutter_application_1/screens/Ai_Screen/models/ai_data_models.dart';
import 'package:flutter_application_1/services/ai_service.dart';

class WebAiPage extends StatefulWidget {
  const WebAiPage({super.key});

  @override
  State<WebAiPage> createState() => _WebAiPageState();
}

class _WebAiPageState extends State<WebAiPage> {
  // Search mode selection
  SearchMode? _searchMode;
  
  int _currentStep = 0;
  bool _isLoading = false;
  List<PackageResult> _results = [];
  List<ServiceSearchResult> _serviceResults = [];
  
  // Form Data for packages
  FormData _formData = FormData();
  
  // Form Data for single service
  SingleServiceData _singleServiceData = SingleServiceData();
  
  // Text controllers for manual input
  final TextEditingController _minBudgetCtrl = TextEditingController(text: '10000');
  final TextEditingController _maxBudgetCtrl = TextEditingController(text: '50000');
  final TextEditingController _guestCountCtrl = TextEditingController(text: '100');
  final TextEditingController _notesCtrl = TextEditingController();
  
  // Single service controllers
  final TextEditingController _singleMinBudgetCtrl = TextEditingController(text: '0');
  final TextEditingController _singleMaxBudgetCtrl = TextEditingController(text: '50000');
  final TextEditingController _singleGuestCountCtrl = TextEditingController(text: '100');
  
  // Steps for package mode
  final List<String> _packageSteps = [
    'Event Details',
    'Budget & Guests',
    'Services',
    'Preferences',
    'Review',
  ];
  
  // Steps for single service mode
  final List<String> _serviceSteps = [
    'Service Type',
    'Event Details',
    'Budget',
    'Review',
  ];
  
  List<String> get _steps => _searchMode == SearchMode.singleService 
      ? _serviceSteps 
      : _packageSteps;

  @override
  void initState() {
    super.initState();
    _minBudgetCtrl.text = _formData.budgetRange.start.toInt().toString();
    _maxBudgetCtrl.text = _formData.budgetRange.end.toInt().toString();
    _guestCountCtrl.text = _formData.guestCount.toString();
  }

  @override
  void dispose() {
    _minBudgetCtrl.dispose();
    _maxBudgetCtrl.dispose();
    _guestCountCtrl.dispose();
    _notesCtrl.dispose();
    _singleMinBudgetCtrl.dispose();
    _singleMaxBudgetCtrl.dispose();
    _singleGuestCountCtrl.dispose();
    super.dispose();
  }

  void _resetToModeSelection() {
    setState(() {
      _searchMode = null;
      _currentStep = 0;
      _results = [];
      _serviceResults = [];
      _formData = FormData();
      _singleServiceData = SingleServiceData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    // Show results if available
    if (_results.isNotEmpty || _serviceResults.isNotEmpty) {
      return _searchMode == SearchMode.singleService
          ? _buildServiceResultsView()
          : _buildResultsView();
    }
    
    // Show mode selection if not selected
    if (_searchMode == null) {
      return _buildModeSelection();
    }
    
    // Show form based on mode
    return _buildFormView();
  }

  // ============ MODE SELECTION ============
  Widget _buildModeSelection() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kWebPrimary.withOpacity(0.1), kWebPrimary.withOpacity(0.05)],
                ),
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kWebPrimary, kWebPrimaryDark],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kWebPrimary.withOpacity(0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome, size: 48, color: Colors.white),
              ),
            ),
            
            const SizedBox(height: 32),
            
            Text(
              'What are you looking for?',
              style: WebTypography.h2,
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how you want to search',
              style: WebTypography.body.copyWith(color: kWebTextMuted),
            ),
            
            const SizedBox(height: 48),
            
            // Mode cards
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildModeCard(
                  icon: Icons.search_rounded,
                  title: 'Single Service',
                  subtitle: 'Find a specific service\n(Venue, Photography, etc.)',
                  color: const Color(0xFF6366F1),
                  onTap: () => setState(() {
                    _searchMode = SearchMode.singleService;
                    _currentStep = 0;
                  }),
                ),
                const SizedBox(width: 24),
                _buildModeCard(
                  icon: Icons.auto_awesome_mosaic_rounded,
                  title: 'Full Package',
                  subtitle: 'AI generates complete\nevent packages for you',
                  color: kWebPrimary,
                  onTap: () => setState(() {
                    _searchMode = SearchMode.fullPackage;
                    _currentStep = 0;
                  }),
                ),
              ],
            ),
            
            const SizedBox(height: 48),
            
            // Features
            Container(
              width: 500,
              padding: const EdgeInsets.all(24),
              decoration: WebDecorations.card,
              child: Column(
                children: [
                  _buildFeatureItem(Icons.psychology, 'Smart AI Matching'),
                  const Divider(height: 24),
                  _buildFeatureItem(Icons.price_check, 'Budget Optimization'),
                  const Divider(height: 24),
                  _buildFeatureItem(Icons.verified, 'Quality Guaranteed'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: kWebBgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.2), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: kWebTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: kWebTextMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Get Started',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, color: color, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: kWebPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: kWebPrimary, size: 22),
        ),
        const SizedBox(width: 16),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: kWebTextPrimary,
          ),
        ),
      ],
    );
  }

  // ============ FORM VIEW ============
  Widget _buildFormView() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sidebar with steps
        SizedBox(
          width: 280,
          child: _buildStepsSidebar(),
        ),
        
        const SizedBox(width: 32),
        
        // Main content
        Expanded(
          child: Column(
            children: [
              Expanded(child: _buildStepContent()),
              const SizedBox(height: 24),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepsSidebar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: WebDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back to mode selection
          InkWell(
            onTap: _resetToModeSelection,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back_rounded, color: kWebTextMuted, size: 18),
                  const SizedBox(width: 8),
                  Text('Back to selection', style: WebTypography.caption),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [kWebPrimary, kWebPrimaryDark]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _searchMode == SearchMode.singleService
                      ? Icons.search_rounded
                      : Icons.auto_awesome_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _searchMode == SearchMode.singleService
                        ? 'Find Service'
                        : 'AI Builder',
                    style: WebTypography.h5,
                  ),
                  Text(
                    _searchMode == SearchMode.singleService
                        ? 'Search for a service'
                        : 'Create your package',
                    style: WebTypography.caption,
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          ...List.generate(_steps.length, (index) {
            final isActive = index == _currentStep;
            final isCompleted = index < _currentStep;
            final canNavigate = isCompleted;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: canNavigate ? () => setState(() => _currentStep = index) : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isActive ? kWebPrimary.withOpacity(0.1) : 
                           isCompleted ? kWebSuccess.withOpacity(0.05) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive ? kWebPrimary : 
                             isCompleted ? kWebSuccess.withOpacity(0.3) : kWebBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isActive ? kWebPrimary :
                                 isCompleted ? kWebSuccess : kWebBgSecondary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                              : Text(
                                  '${index + 1}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isActive ? Colors.white : kWebTextMuted,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _steps[index],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isActive ? kWebPrimary : kWebTextBody,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: WebDecorations.card,
      child: SingleChildScrollView(
        child: _searchMode == SearchMode.singleService
            ? _buildSingleServiceStepContent()
            : _buildPackageStepContent(),
      ),
    );
  }

  // ============ PACKAGE FORM STEPS ============
  Widget _buildPackageStepContent() {
    return switch (_currentStep) {
      0 => _buildEventDetailsStep(),
      1 => _buildBudgetStep(),
      2 => _buildServicesStep(),
      3 => _buildPreferencesStep(),
      4 => _buildReviewStep(),
      _ => const SizedBox(),
    };
  }

  Widget _buildEventDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Event Details', style: WebTypography.h4),
        const SizedBox(height: 8),
        Text('Tell us about your event (all fields are required)', 
            style: WebTypography.body.copyWith(color: kWebTextMuted)),
        
        const SizedBox(height: 32),
        
        // Event Type Selection
        _buildFieldLabel('Event Type', isRequired: true),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: EventType.allTypes.map((type) {
            final isSelected = _formData.eventType == type.name;
            return InkWell(
              onTap: () => setState(() => _formData.eventType = type.name),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? kWebPrimary.withOpacity(0.1) : kWebBgSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? kWebPrimary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(type.icon, color: isSelected ? kWebPrimary : kWebTextMuted, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      type.name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? kWebPrimary : kWebTextBody,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        
        const SizedBox(height: 32),
        
        // City Selection
        _buildFieldLabel('City', isRequired: true),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: CityData.palestinianCities.map((city) {
            final isSelected = _formData.city == city;
            return InkWell(
              onTap: () => setState(() => _formData.city = city),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? kWebPrimary.withOpacity(0.1) : kWebBgSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? kWebPrimary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Text(
                  city,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? kWebPrimary : kWebTextBody,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        
        const SizedBox(height: 32),
        
        // Event Date
        _buildFieldLabel('Event Date', isRequired: true),
        const SizedBox(height: 16),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _formData.eventDate ?? DateTime.now().add(const Duration(days: 30)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(primary: kWebPrimary),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) {
              setState(() => _formData.eventDate = date);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kWebBgSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _formData.eventDate != null ? kWebPrimary : kWebBorder,
                width: _formData.eventDate != null ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded, 
                  color: _formData.eventDate != null ? kWebPrimary : kWebTextMuted,
                ),
                const SizedBox(width: 12),
                Text(
                  _formData.eventDate != null
                      ? '${_formData.eventDate!.day}/${_formData.eventDate!.month}/${_formData.eventDate!.year}'
                      : 'Click to select date *',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: _formData.eventDate != null ? kWebTextPrimary : kWebTextMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Validation message
        if (_formData.city.isEmpty || _formData.eventDate == null)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kWebWarning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kWebWarning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: kWebWarning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Please select a city and event date to proceed',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: kWebWarning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBudgetStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Budget & Guests', style: WebTypography.h4),
        const SizedBox(height: 8),
        Text('Set your budget range and guest count', style: WebTypography.body.copyWith(color: kWebTextMuted)),
        
        const SizedBox(height: 32),
        
        // Guest Count
        _buildFieldLabel('Number of Guests', isRequired: true),
        const SizedBox(height: 16),
        Row(
          children: [
            IconButton(
              onPressed: _formData.guestCount > 10
                  ? () {
                      setState(() => _formData.guestCount -= 10);
                      _guestCountCtrl.text = _formData.guestCount.toString();
                    }
                  : null,
              icon: const Icon(Icons.remove_circle_rounded),
              color: kWebPrimary,
              iconSize: 32,
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 150,
              child: TextField(
                controller: _guestCountCtrl,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: kWebPrimary,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: kWebBgSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onChanged: (val) {
                  final count = int.tryParse(val) ?? _formData.guestCount;
                  setState(() => _formData.guestCount = count.clamp(10, 1000));
                },
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              onPressed: () {
                setState(() => _formData.guestCount += 10);
                _guestCountCtrl.text = _formData.guestCount.toString();
              },
              icon: const Icon(Icons.add_circle_rounded),
              color: kWebPrimary,
              iconSize: 32,
            ),
            const SizedBox(width: 16),
            Text('guests', style: WebTypography.body),
          ],
        ),
        
        const SizedBox(height: 40),
        
        // Budget Range - Manual Input
        _buildFieldLabel('Budget Range (NIS)', isRequired: true),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildBudgetTextField(
                controller: _minBudgetCtrl,
                label: 'Minimum Budget',
                onChanged: (val) {
                  final min = double.tryParse(val) ?? _formData.budgetRange.start;
                  if (min < _formData.budgetRange.end) {
                    setState(() {
                      _formData = _formData.copyWith(
                        budgetRange: RangeValues(min, _formData.budgetRange.end),
                      );
                    });
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kWebPrimary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.compare_arrows_rounded, color: kWebPrimary, size: 24),
              ),
            ),
            Expanded(
              child: _buildBudgetTextField(
                controller: _maxBudgetCtrl,
                label: 'Maximum Budget',
                onChanged: (val) {
                  final max = double.tryParse(val) ?? _formData.budgetRange.end;
                  if (max > _formData.budgetRange.start) {
                    setState(() {
                      _formData = _formData.copyWith(
                        budgetRange: RangeValues(_formData.budgetRange.start, max),
                      );
                    });
                  }
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Budget display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: kWebPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.payments_rounded, color: kWebPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Budget: ₪${_formData.budgetRange.start.toInt()} - ₪${_formData.budgetRange.end.toInt()}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kWebPrimary,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 40),
        
        // Venue Type
        _buildFieldLabel('Venue Type', isRequired: true),
        const SizedBox(height: 16),
        Row(
          children: ['Indoor', 'Outdoor', 'Both'].map((type) {
            final isSelected = _formData.venueType == type;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: InkWell(
                onTap: () => setState(() => _formData.venueType = type),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? kWebPrimary.withOpacity(0.1) : kWebBgSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? kWebPrimary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    type,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? kWebPrimary : kWebTextBody,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBudgetTextField({
    required TextEditingController controller,
    required String label,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: WebTypography.caption),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: kWebTextPrimary,
          ),
          decoration: InputDecoration(
            prefixText: '₪ ',
            prefixStyle: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kWebPrimary,
            ),
            filled: true,
            fillColor: kWebBgSecondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kWebPrimary, width: 2),
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildServicesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Services', style: WebTypography.h4),
        const SizedBox(height: 8),
        Text('Choose the services you need for your event (select at least one)', 
            style: WebTypography.body.copyWith(color: kWebTextMuted)),
        
        const SizedBox(height: 32),
        
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: ServiceCategory.allServices.map((service) {
            final isSelected = _formData.selectedServices.any((s) => s.name == service.name);
            return InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _formData.selectedServices = _formData.selectedServices
                        .where((s) => s.name != service.name)
                        .toList();
                  } else {
                    _formData.selectedServices = [
                      ..._formData.selectedServices,
                      SelectedService(
                        name: service.name,
                        priority: _formData.selectedServices.length + 1,
                      ),
                    ];
                  }
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 160,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isSelected ? kWebPrimary.withOpacity(0.1) : kWebBgSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? kWebPrimary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isSelected ? kWebPrimary : service.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        service.icon,
                        color: isSelected ? Colors.white : service.color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      service.name,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? kWebPrimary : kWebTextBody,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: kWebSuccess,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        
        const SizedBox(height: 24),
        
        if (_formData.selectedServices.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kWebSuccess.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: kWebSuccess),
                const SizedBox(width: 12),
                Text(
                  '${_formData.selectedServices.length} services selected',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: kWebSuccess,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kWebWarning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kWebWarning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: kWebWarning),
                const SizedBox(width: 12),
                Text(
                  'Please select at least one service to proceed',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: kWebWarning,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPreferencesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Preferences', style: WebTypography.h4),
        const SizedBox(height: 8),
        Text('Customize your package preferences', style: WebTypography.body.copyWith(color: kWebTextMuted)),
        
        const SizedBox(height: 32),
        
        // Package Preference
        _buildFieldLabel('Package Preference', isRequired: true),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildPreferenceCard(
              'Within Budget',
              'Get packages that strictly fit your budget range',
              Icons.savings_rounded,
              _formData.packagePreference == PackagePreference.withinBudget,
              () => setState(() => _formData.packagePreference = PackagePreference.withinBudget),
            ),
            const SizedBox(width: 16),
            _buildPreferenceCard(
              'With Options',
              'Get multiple options with budget flexibility',
              Icons.auto_awesome_rounded,
              _formData.packagePreference == PackagePreference.withOptions,
              () => setState(() => _formData.packagePreference = PackagePreference.withOptions),
            ),
          ],
        ),
        
        // Extra options when "With Options" is selected
        if (_formData.packagePreference == PackagePreference.withOptions) ...[
          const SizedBox(height: 32),
          
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kWebPrimary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kWebPrimary.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune_rounded, color: kWebPrimary),
                    const SizedBox(width: 12),
                    Text(
                      'Flexibility Options',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: kWebPrimary,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Number of extra packages
                Text('Number of Extra Packages', style: WebTypography.h6),
                const SizedBox(height: 12),
                Row(
                  children: [1, 2, 3, 4, 5].map((count) {
                    final isSelected = _formData.extraPackagesCount == count;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: InkWell(
                        onTap: () => setState(() => _formData.extraPackagesCount = count),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isSelected ? kWebPrimary : kWebBgSecondary,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? kWebPrimary : kWebBorder,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$count',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : kWebTextBody,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 24),
                
                // Variation percentage
                Text('Budget Variation (%)', style: WebTypography.h6),
                const SizedBox(height: 12),
                Row(
                  children: [5, 10, 15, 20, 25, 30].map((percent) {
                    final isSelected = _formData.variationPercentage == percent;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: InkWell(
                        onTap: () => setState(() => _formData.variationPercentage = percent),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? kWebPrimary : kWebBgSecondary,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? kWebPrimary : kWebBorder,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            '$percent%',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : kWebTextBody,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 24),
                
                // Variation type
                Text('Include Packages', style: WebTypography.h6),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildVariationTypeOption(
                      'Lower Budget',
                      'Below your range',
                      Icons.trending_down_rounded,
                      VariationType.lower,
                    ),
                    const SizedBox(width: 12),
                    _buildVariationTypeOption(
                      'Higher Budget',
                      'Above your range',
                      Icons.trending_up_rounded,
                      VariationType.higher,
                    ),
                    const SizedBox(width: 12),
                    _buildVariationTypeOption(
                      'Both',
                      'Lower & higher',
                      Icons.compare_arrows_rounded,
                      VariationType.both,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        
        const SizedBox(height: 32),
        
        // Additional Notes
        _buildFieldLabel('Additional Notes', isRequired: false),
        const SizedBox(height: 16),
        TextField(
          controller: _notesCtrl,
          onChanged: (value) => _formData.notes = value,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Any special requests or requirements...',
            hintStyle: GoogleFonts.poppins(fontSize: 14, color: kWebTextMuted),
            filled: true,
            fillColor: kWebBgSecondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kWebPrimary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVariationTypeOption(
    String title,
    String subtitle,
    IconData icon,
    VariationType type,
  ) {
    final isSelected = _formData.variationType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _formData.variationType = type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? kWebPrimary.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? kWebPrimary : kWebBorder,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? kWebPrimary : kWebTextMuted, size: 28),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? kWebPrimary : kWebTextBody,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: kWebTextMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreferenceCard(
    String title,
    String subtitle,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isSelected ? kWebPrimary.withOpacity(0.1) : kWebBgSecondary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? kWebPrimary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: isSelected ? kWebPrimary : kWebTextMuted, size: 32),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? kWebPrimary : kWebTextBody,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: WebTypography.caption,
              ),
              if (isSelected) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: kWebPrimary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review Your Selections', style: WebTypography.h4),
        const SizedBox(height: 8),
        Text('Make sure everything looks correct before generating', 
            style: WebTypography.body.copyWith(color: kWebTextMuted)),
        
        const SizedBox(height: 32),
        
        _buildReviewItem('Event Type', _formData.eventType, Icons.celebration_rounded),
        _buildReviewItem('City', _formData.city, Icons.location_on_rounded),
        _buildReviewItem('Event Date', 
            _formData.eventDate != null
                ? '${_formData.eventDate!.day}/${_formData.eventDate!.month}/${_formData.eventDate!.year}'
                : 'Not selected',
            Icons.calendar_today_rounded),
        _buildReviewItem('Guests', '${_formData.guestCount} guests', Icons.people_rounded),
        _buildReviewItem('Budget', '₪${_formData.budgetRange.start.toInt()} - ₪${_formData.budgetRange.end.toInt()}', Icons.payments_rounded),
        _buildReviewItem('Venue Type', _formData.venueType, Icons.apartment_rounded),
        _buildReviewItem('Services', _formData.selectedServices.map((s) => s.name).join(', '), Icons.checklist_rounded),
        _buildReviewItem('Preference', 
            _formData.packagePreference == PackagePreference.withinBudget 
                ? 'Within Budget Only' 
                : 'With Options (±${_formData.variationPercentage}%)',
            Icons.tune_rounded),
        
        if (_formData.notes.isNotEmpty)
          _buildReviewItem('Notes', _formData.notes, Icons.note_rounded),
      ],
    );
  }

  Widget _buildReviewItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kWebBgSecondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: kWebPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: kWebPrimary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: WebTypography.caption),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ SINGLE SERVICE FORM STEPS ============
  Widget _buildSingleServiceStepContent() {
    return switch (_currentStep) {
      0 => _buildServiceTypeStep(),
      1 => _buildSingleEventDetailsStep(),
      2 => _buildSingleBudgetStep(),
      3 => _buildSingleReviewStep(),
      _ => const SizedBox(),
    };
  }

  Widget _buildServiceTypeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Service Type', style: WebTypography.h4),
        const SizedBox(height: 8),
        Text('What type of service are you looking for?', 
            style: WebTypography.body.copyWith(color: kWebTextMuted)),
        
        const SizedBox(height: 32),
        
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: ServiceCategory.allServices.map((service) {
            final isSelected = _singleServiceData.serviceType == service.name;
            return InkWell(
              onTap: () => setState(() => _singleServiceData.serviceType = service.name),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 180,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isSelected ? kWebPrimary.withOpacity(0.1) : kWebBgSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? kWebPrimary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: isSelected ? kWebPrimary : service.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        service.icon,
                        color: isSelected ? Colors.white : service.color,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      service.name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? kWebPrimary : kWebTextBody,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        
        if (_singleServiceData.serviceType.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kWebWarning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kWebWarning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: kWebWarning),
                  const SizedBox(width: 12),
                  Text(
                    'Please select a service type to proceed',
                    style: GoogleFonts.poppins(fontSize: 14, color: kWebWarning),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSingleEventDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Event Details', style: WebTypography.h4),
        const SizedBox(height: 8),
        Text('Tell us about your event (all fields are required)', 
            style: WebTypography.body.copyWith(color: kWebTextMuted)),
        
        const SizedBox(height: 32),
        
        // Event Type
        _buildFieldLabel('Event Type', isRequired: true),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: EventType.allTypes.take(6).map((type) {
            final isSelected = _singleServiceData.eventType == type.name;
            return InkWell(
              onTap: () => setState(() => _singleServiceData.eventType = type.name),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? kWebPrimary.withOpacity(0.1) : kWebBgSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? kWebPrimary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(type.icon, color: isSelected ? kWebPrimary : kWebTextMuted, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      type.name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? kWebPrimary : kWebTextBody,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        
        const SizedBox(height: 32),
        
        // City
        _buildFieldLabel('City', isRequired: true),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: CityData.palestinianCities.map((city) {
            final isSelected = _singleServiceData.city == city;
            return InkWell(
              onTap: () => setState(() => _singleServiceData.city = city),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? kWebPrimary.withOpacity(0.1) : kWebBgSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? kWebPrimary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Text(
                  city,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? kWebPrimary : kWebTextBody,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        
        const SizedBox(height: 32),
        
        // Event Date
        _buildFieldLabel('Event Date', isRequired: true),
        const SizedBox(height: 16),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _singleServiceData.eventDate ?? DateTime.now().add(const Duration(days: 30)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(primary: kWebPrimary),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) {
              setState(() => _singleServiceData.eventDate = date);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kWebBgSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _singleServiceData.eventDate != null ? kWebPrimary : kWebBorder,
                width: _singleServiceData.eventDate != null ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded, 
                  color: _singleServiceData.eventDate != null ? kWebPrimary : kWebTextMuted,
                ),
                const SizedBox(width: 12),
                Text(
                  _singleServiceData.eventDate != null
                      ? '${_singleServiceData.eventDate!.day}/${_singleServiceData.eventDate!.month}/${_singleServiceData.eventDate!.year}'
                      : 'Click to select date *',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: _singleServiceData.eventDate != null ? kWebTextPrimary : kWebTextMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Guest Count
        _buildFieldLabel('Number of Guests', isRequired: true),
        const SizedBox(height: 16),
        Row(
          children: [
            IconButton(
              onPressed: _singleServiceData.guestCount > 10
                  ? () {
                      setState(() => _singleServiceData.guestCount -= 10);
                      _singleGuestCountCtrl.text = _singleServiceData.guestCount.toString();
                    }
                  : null,
              icon: const Icon(Icons.remove_circle_rounded),
              color: kWebPrimary,
              iconSize: 32,
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 120,
              child: TextField(
                controller: _singleGuestCountCtrl,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: kWebPrimary,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: kWebBgSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) {
                  final count = int.tryParse(val) ?? _singleServiceData.guestCount;
                  setState(() => _singleServiceData.guestCount = count.clamp(10, 1000));
                },
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              onPressed: () {
                setState(() => _singleServiceData.guestCount += 10);
                _singleGuestCountCtrl.text = _singleServiceData.guestCount.toString();
              },
              icon: const Icon(Icons.add_circle_rounded),
              color: kWebPrimary,
              iconSize: 32,
            ),
            const SizedBox(width: 12),
            Text('guests', style: WebTypography.body),
          ],
        ),
        
        // Validation
        if (_singleServiceData.city.isEmpty || _singleServiceData.eventDate == null)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kWebWarning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kWebWarning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: kWebWarning),
                  const SizedBox(width: 12),
                  Text(
                    'Please fill all required fields to proceed',
                    style: GoogleFonts.poppins(fontSize: 14, color: kWebWarning),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSingleBudgetStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Budget Range', style: WebTypography.h4),
        const SizedBox(height: 8),
        Text('Set your budget for this service', style: WebTypography.body.copyWith(color: kWebTextMuted)),
        
        const SizedBox(height: 32),
        
        Row(
          children: [
            Expanded(
              child: _buildBudgetTextField(
                controller: _singleMinBudgetCtrl,
                label: 'Minimum Budget',
                onChanged: (val) {
                  final min = double.tryParse(val) ?? _singleServiceData.minBudget;
                  if (min < _singleServiceData.maxBudget) {
                    setState(() => _singleServiceData.minBudget = min);
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kWebPrimary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.compare_arrows_rounded, color: kWebPrimary),
              ),
            ),
            Expanded(
              child: _buildBudgetTextField(
                controller: _singleMaxBudgetCtrl,
                label: 'Maximum Budget',
                onChanged: (val) {
                  final max = double.tryParse(val) ?? _singleServiceData.maxBudget;
                  if (max > _singleServiceData.minBudget) {
                    setState(() => _singleServiceData.maxBudget = max);
                  }
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 32),
        
        // Budget flexibility
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kWebBgSecondary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _singleServiceData.hasBudgetFlexibility,
                    onChanged: (val) => setState(() => _singleServiceData.hasBudgetFlexibility = val ?? false),
                    activeColor: kWebPrimary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Allow Budget Flexibility',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kWebTextPrimary,
                    ),
                  ),
                ],
              ),
              
              if (_singleServiceData.hasBudgetFlexibility) ...[
                const SizedBox(height: 16),
                Text('Flexibility Percentage', style: WebTypography.caption),
                const SizedBox(height: 8),
                Row(
                  children: [10, 15, 20, 25, 30].map((percent) {
                    final isSelected = _singleServiceData.budgetFlexibilityPercent == percent;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => setState(() => _singleServiceData.budgetFlexibilityPercent = percent),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? kWebPrimary : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isSelected ? kWebPrimary : kWebBorder),
                          ),
                          child: Text(
                            '±$percent%',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : kWebTextBody,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSingleReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review Your Search', style: WebTypography.h4),
        const SizedBox(height: 8),
        Text('Check your search criteria before proceeding', 
            style: WebTypography.body.copyWith(color: kWebTextMuted)),
        
        const SizedBox(height: 32),
        
        _buildReviewItem('Service Type', _singleServiceData.serviceType, Icons.category_rounded),
        _buildReviewItem('Event Type', _singleServiceData.eventType, Icons.celebration_rounded),
        _buildReviewItem('City', _singleServiceData.city, Icons.location_on_rounded),
        _buildReviewItem('Event Date', 
            _singleServiceData.eventDate != null
                ? '${_singleServiceData.eventDate!.day}/${_singleServiceData.eventDate!.month}/${_singleServiceData.eventDate!.year}'
                : 'Not selected',
            Icons.calendar_today_rounded),
        _buildReviewItem('Guests', '${_singleServiceData.guestCount} guests', Icons.people_rounded),
        _buildReviewItem('Budget', '₪${_singleServiceData.minBudget.toInt()} - ₪${_singleServiceData.maxBudget.toInt()}', Icons.payments_rounded),
        
        if (_singleServiceData.hasBudgetFlexibility)
          _buildReviewItem('Flexibility', '±${_singleServiceData.budgetFlexibilityPercent}%', Icons.tune_rounded),
      ],
    );
  }

  // ============ COMMON WIDGETS ============
  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return Row(
      children: [
        Text(label, style: WebTypography.h6),
        if (isRequired)
          Text(
            ' *',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: kWebError,
            ),
          ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    final isLastStep = _currentStep == _steps.length - 1;
    
    return Row(
      children: [
        if (_currentStep > 0)
          OutlinedButton.icon(
            onPressed: () => setState(() => _currentStep--),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Previous'),
            style: OutlinedButton.styleFrom(
              foregroundColor: kWebPrimary,
              side: const BorderSide(color: kWebPrimary),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        const Spacer(),
        if (!isLastStep)
          ElevatedButton.icon(
            onPressed: _canProceed() ? () => setState(() => _currentStep++) : null,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Next'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kWebPrimary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: kWebBgSecondary,
              disabledForegroundColor: kWebTextMuted,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _generate,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_rounded),
            label: Text(_isLoading 
                ? 'Searching...' 
                : _searchMode == SearchMode.singleService 
                    ? 'Search Services' 
                    : 'Generate Packages'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kWebPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
      ],
    );
  }

  bool _canProceed() {
    if (_searchMode == SearchMode.singleService) {
      switch (_currentStep) {
        case 0: // Service Type
          return _singleServiceData.serviceType.isNotEmpty;
        case 1: // Event Details
          return _singleServiceData.city.isNotEmpty && 
                 _singleServiceData.eventDate != null;
        case 2: // Budget
          return _singleServiceData.minBudget < _singleServiceData.maxBudget;
        default:
          return true;
      }
    } else {
      switch (_currentStep) {
        case 0: // Event Details
          return _formData.city.isNotEmpty && _formData.eventDate != null;
        case 1: // Budget & Guests
          return _formData.guestCount > 0 && 
                 _formData.budgetRange.start < _formData.budgetRange.end;
        case 2: // Services
          return _formData.selectedServices.isNotEmpty;
        default:
          return true;
      }
    }
  }

  Future<void> _generate() async {
    setState(() => _isLoading = true);
    
    try {
      if (_searchMode == SearchMode.singleService) {
        final response = await AiService.searchSingleService(_singleServiceData);
        
        if (response.success && response.results != null && response.results!.isNotEmpty) {
          setState(() {
            _serviceResults = response.results!;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
          _showErrorSnackbar(response.error ?? 'No services found');
        }
      } else {
        final response = await AiService.generatePackages(_formData);
        
        if (response.success && response.packages != null && response.packages!.isNotEmpty) {
          setState(() {
            _results = response.packages!;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
          _showErrorSnackbar(response.error ?? 'No packages found');
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Error: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: kWebError,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // ============ RESULTS VIEWS ============
  Widget _buildResultsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() {
                _results = [];
                _currentStep = 0;
              }),
              icon: const Icon(Icons.arrow_back_rounded),
              color: kWebPrimary,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Generated Packages', style: WebTypography.h3),
                Text(
                  '${_results.length} packages found based on your preferences',
                  style: WebTypography.body.copyWith(color: kWebTextMuted),
                ),
              ],
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _resetToModeSelection,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('New Search'),
              style: OutlinedButton.styleFrom(
                foregroundColor: kWebPrimary,
                side: const BorderSide(color: kWebPrimary),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 32),
        
        // Results grid
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.75,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
            ),
            itemCount: _results.length,
            itemBuilder: (context, index) {
              return _PackageResultCard(package: _results[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServiceResultsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() {
                _serviceResults = [];
                _currentStep = 0;
              }),
              icon: const Icon(Icons.arrow_back_rounded),
              color: kWebPrimary,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Service Results', style: WebTypography.h3),
                Text(
                  '${_serviceResults.length} services found for "${_singleServiceData.serviceType}"',
                  style: WebTypography.body.copyWith(color: kWebTextMuted),
                ),
              ],
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _resetToModeSelection,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('New Search'),
              style: OutlinedButton.styleFrom(
                foregroundColor: kWebPrimary,
                side: const BorderSide(color: kWebPrimary),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 32),
        
        // Results grid
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.85,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
            ),
            itemCount: _serviceResults.length,
            itemBuilder: (context, index) {
              return _ServiceResultCard(service: _serviceResults[index]);
            },
          ),
        ),
      ],
    );
  }
}

// ============ PACKAGE RESULT CARD ============
class _PackageResultCard extends StatefulWidget {
  final PackageResult package;

  const _PackageResultCard({required this.package});

  @override
  State<_PackageResultCard> createState() => _PackageResultCardState();
}

class _PackageResultCardState extends State<_PackageResultCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.package;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: kWebBgCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: _isHovered ? WebShadows.lg : WebShadows.sm,
          border: Border.all(
            color: _isHovered ? kWebPrimary.withOpacity(0.3) : kWebBorder,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Package level badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getLevelColor(p.packageLevel).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  p.packageLevel,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getLevelColor(p.packageLevel),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Name
              Text(
                p.name,
                style: WebTypography.h5,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // Description
              Text(
                p.description,
                style: WebTypography.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 16),
              
              // Services
              Text('Included Services:', style: WebTypography.label),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: p.services.length.clamp(0, 4),
                  itemBuilder: (context, index) {
                    final service = p.services[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: kWebSuccess, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              service.name,
                              style: GoogleFonts.poppins(fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              if (p.services.length > 4)
                Text(
                  '+${p.services.length - 4} more services',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: kWebPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Price
              Row(
                children: [
                  Text(
                    '₪${p.price.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: kWebPrimary,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: View package details
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kWebPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('View'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'basic':
        return kWebSuccess;
      case 'premium':
      case 'luxury':
        return kWebWarning;
      default:
        return kWebPrimary;
    }
  }
}

// ============ SERVICE RESULT CARD ============
class _ServiceResultCard extends StatefulWidget {
  final ServiceSearchResult service;

  const _ServiceResultCard({required this.service});

  @override
  State<_ServiceResultCard> createState() => _ServiceResultCardState();
}

class _ServiceResultCardState extends State<_ServiceResultCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.service;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: kWebBgCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: _isHovered ? WebShadows.lg : WebShadows.sm,
          border: Border.all(
            color: _isHovered ? kWebPrimary.withOpacity(0.3) : kWebBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image or placeholder
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: kWebPrimary.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: s.imageUrl != null
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Image.network(
                        s.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 40, color: kWebPrimary),
                      ),
                    )
                  : Center(
                      child: Icon(
                        _getCategoryIcon(s.category),
                        size: 48,
                        color: kWebPrimary,
                      ),
                    ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: kWebPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        s.category,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: kWebPrimary,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Name
                    Text(
                      s.serviceName,
                      style: WebTypography.h6,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Provider
                    Text(
                      s.providerName,
                      style: WebTypography.caption,
                    ),
                    
                    const Spacer(),
                    
                    // Rating
                    if (s.rating != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: kWebWarning, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            s.rating!.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (s.reviewCount != null)
                            Text(
                              ' (${s.reviewCount})',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: kWebTextMuted,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    // Price
                    Row(
                      children: [
                        Text(
                          '₪${s.calculatedPrice > 0 ? s.calculatedPrice.toStringAsFixed(0) : s.price.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: kWebPrimary,
                          ),
                        ),
                        if (s.payType != null)
                          Text(
                            ' /${s.priceLabel}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: kWebTextMuted,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'venue':
        return Icons.apartment_rounded;
      case 'photography':
      case 'photography & video':
        return Icons.camera_alt_rounded;
      case 'catering':
        return Icons.restaurant_menu_rounded;
      case 'cake':
        return Icons.cake_rounded;
      case 'decoration':
        return Icons.auto_fix_high_rounded;
      case 'flowers':
        return Icons.local_florist_rounded;
      case 'music & dj':
        return Icons.music_note_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}
