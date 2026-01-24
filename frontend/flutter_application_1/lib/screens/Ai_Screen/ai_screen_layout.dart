// lib/screens/Ai_Screen/ai_screen_layout.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'models/ai_data_models.dart';
import 'components/ai_package_card.dart';
import 'components/ai_input_dialogs.dart';
import 'components/ai_service_details_screen.dart';
import '../../services/ai_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/booking_details_modal.dart';
import '../user/payment/cart.dart';

const Color kPrimaryColor = Color.fromARGB(215, 20, 20, 215);
const Color kAccentColor = Color.fromARGB(215, 20, 20, 215);
const Color kBackgroundColor = Color(0xFFF8F9FC);
const Color kCardColor = Colors.white;
const Color kTextPrimary = Color(0xFF1A1A2E);
const Color kTextSecondary = Color(0xFF6B7280);

class AiScreenLayout extends StatefulWidget {
  const AiScreenLayout({Key? key}) : super(key: key);

  @override
  State<AiScreenLayout> createState() => _AiScreenLayoutState();
}

class _AiScreenLayoutState extends State<AiScreenLayout> with TickerProviderStateMixin {
  // Search mode
  SearchMode? _searchMode;
  
  // Package form data
  FormData _packageFormData = FormData();
  
  // Single service form data  
  SingleServiceData _singleServiceData = SingleServiceData();
  
  // Results
  List<PackageResult> _generatedPackages = [];
  List<ServiceSearchResult> _serviceResults = [];
  
  // State
  bool _isGenerating = false;
  bool _showResults = false;
  String? _errorMessage;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _resetToModeSelection() {
    setState(() {
      _searchMode = null;
      _showResults = false;
      _generatedPackages = [];
      _serviceResults = [];
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: _buildAppBar(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_showResults) {
      return _searchMode == SearchMode.singleService
          ? _buildServiceResults()
          : _buildPackageResults();
    }
    
    if (_searchMode == null) {
      return _buildModeSelection();
    }
    
    return _searchMode == SearchMode.singleService
        ? _buildSingleServiceForm()
        : _buildPackageForm();
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: _searchMode != null || _showResults
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: kTextPrimary, size: 20),
              onPressed: () {
                if (_showResults) {
                  setState(() => _showResults = false);
                } else {
                  _resetToModeSelection();
                }
              },
            )
          : null,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            'AI Assistant',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: kTextPrimary,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: const Color(0xFFE8EAF0), height: 1),
      ),
    );
  }

  // ============ MODE SELECTION ============
  Widget _buildModeSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildWelcomeHeader(),
          const SizedBox(height: 40),
          _buildModeCard(
            icon: Icons.search_rounded,
            title: 'Single Service',
            subtitle: 'Find a specific service\n(Venue, Photography, etc.)',
            color: const Color(0xFF6366F1),
            onTap: () => setState(() => _searchMode = SearchMode.singleService),
          ),
          const SizedBox(height: 20),
          _buildModeCard(
            icon: Icons.auto_awesome_mosaic_rounded,
            title: 'Full Package',
            subtitle: 'AI generates complete\nevent packages for you',
            color: kPrimaryColor,
            onTap: () => setState(() => _searchMode = SearchMode.fullPackage),
          ),
          const SizedBox(height: 40),
          _buildFeaturesList(),
          const SizedBox(height: 100), // Bottom padding for navigation bar
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimaryColor.withOpacity(0.1), kPrimaryColor.withOpacity(0.05)],
            ),
            shape: BoxShape.circle,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.8)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: kPrimaryColor.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome, size: 36, color: Colors.white),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'What are you looking for?',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: kTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose how you want to search',
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: kTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildModeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.2), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: kTextSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildFeatureItem(Icons.psychology, 'Smart AI Matching'),
          const Divider(height: 24),
          _buildFeatureItem(Icons.price_check, 'Budget Optimization'),
          const Divider(height: 24),
          _buildFeatureItem(Icons.verified, 'Quality Guaranteed'),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kPrimaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: kPrimaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: kTextPrimary,
          ),
        ),
      ],
    );
  }

  // ============ SINGLE SERVICE FORM ============
  Widget _buildSingleServiceForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Find Single Service',
            'Tap each field to enter details',
            Icons.search_rounded,
          ),
          const SizedBox(height: 24),
          
          // Service Type
          _buildInputTile(
            icon: Icons.category_rounded,
            title: 'Service Type',
            value: _singleServiceData.serviceType.isEmpty 
                ? null 
                : _singleServiceData.serviceType,
            placeholder: 'Select service type',
            isRequired: true,
            onTap: () => _showServiceTypeDialog(),
          ),
          
          // City
          _buildInputTile(
            icon: Icons.location_city_rounded,
            title: 'City',
            value: _singleServiceData.city.isEmpty ? null : _singleServiceData.city,
            placeholder: 'Select city',
            isRequired: true,
            onTap: () => _showCityDialog(isSingleService: true),
          ),
          
          // Venue Type (only show when service type is Venue)
          if (_singleServiceData.serviceType == 'Venue')
            _buildInputTile(
              icon: Icons.home_work_rounded,
              title: 'Venue Type',
              value: _singleServiceData.venueType,
              onTap: () => _showVenueTypeDialog(isSingleService: true),
            ),
          
          // Event Date
          _buildInputTile(
            icon: Icons.calendar_month_rounded,
            title: 'Event Date',
            value: _singleServiceData.eventDate != null
                ? '${_singleServiceData.eventDate!.day}/${_singleServiceData.eventDate!.month}/${_singleServiceData.eventDate!.year}'
                : null,
            placeholder: 'Select date',
            isRequired: true,
            onTap: () => _showDateDialog(isSingleService: true),
          ),
          
          // Time Range
          _buildInputTile(
            icon: Icons.access_time_rounded,
            title: 'Time',
            value: _singleServiceData.startTime != null && _singleServiceData.endTime != null
                ? '${_formatTime(_singleServiceData.startTime!)} - ${_formatTime(_singleServiceData.endTime!)}'
                : null,
            placeholder: 'Select time range',
            onTap: () => _showTimeDialog(isSingleService: true),
          ),
          
          // Guest Count
          _buildInputTile(
            icon: Icons.people_rounded,
            title: 'Guests',
            value: '${_singleServiceData.guestCount} guests',
            onTap: () => _showGuestCountDialog(isSingleService: true),
          ),
          
          // Budget Range (with Flexibility option included)
          _buildInputTile(
            icon: Icons.payments_rounded,
            title: 'Budget',
            value: _getBudgetDisplayValue(true),
            onTap: () => _showBudgetDialog(isSingleService: true),
          ),
          
          // Event Type
          _buildInputTile(
            icon: Icons.celebration_rounded,
            title: 'Event Type',
            value: _singleServiceData.eventType,
            onTap: () => _showEventTypeDialog(isSingleService: true),
          ),
          
          // Notes (Optional)
          _buildInputTile(
            icon: Icons.note_rounded,
            title: 'Notes',
            value: _singleServiceData.notes.isEmpty ? null : _singleServiceData.notes,
            placeholder: 'Add notes (optional)',
            onTap: () => _showNotesDialog(isSingleService: true),
          ),
          
          const SizedBox(height: 32),
          _buildSearchButton(
            onPressed: _singleServiceData.serviceType.isNotEmpty && 
                       _singleServiceData.city.isNotEmpty
                ? _handleSingleServiceSearch
                : null,
          ),
          const SizedBox(height: 100), // Bottom padding for navigation bar
        ],
      ),
    );
  }

  // ============ PACKAGE FORM ============
  Widget _buildPackageForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Create Event Package',
            'Tap each field to enter details',
            Icons.auto_awesome_mosaic_rounded,
          ),
          const SizedBox(height: 24),
          
          // Event Type
          _buildInputTile(
            icon: Icons.celebration_rounded,
            title: 'Event Type',
            value: _packageFormData.eventType,
            isRequired: true,
            onTap: () => _showEventTypeDialog(isSingleService: false),
          ),
          
          // City
          _buildInputTile(
            icon: Icons.location_city_rounded,
            title: 'City',
            value: _packageFormData.city.isEmpty ? null : _packageFormData.city,
            placeholder: 'Select city',
            isRequired: true,
            onTap: () => _showCityDialog(isSingleService: false),
          ),
          
          // Event Date
          _buildInputTile(
            icon: Icons.calendar_month_rounded,
            title: 'Event Date',
            value: _packageFormData.eventDate != null
                ? '${_packageFormData.eventDate!.day}/${_packageFormData.eventDate!.month}/${_packageFormData.eventDate!.year}'
                : null,
            placeholder: 'Select date',
            onTap: () => _showDateDialog(isSingleService: false),
          ),
          
          // Time Range
          _buildInputTile(
            icon: Icons.access_time_rounded,
            title: 'Time',
            value: _packageFormData.startTime != null && _packageFormData.endTime != null
                ? '${_formatTime(_packageFormData.startTime!)} - ${_formatTime(_packageFormData.endTime!)}'
                : null,
            placeholder: 'Select time range',
            onTap: () => _showTimeDialog(isSingleService: false),
          ),
          
          // Guest Count
          _buildInputTile(
            icon: Icons.people_rounded,
            title: 'Guests',
            value: '${_packageFormData.guestCount} guests',
            onTap: () => _showGuestCountDialog(isSingleService: false),
          ),
          
          // Budget Range
          _buildInputTile(
            icon: Icons.payments_rounded,
            title: 'Budget',
            value: _getBudgetDisplayValue(false),
            onTap: () => _showBudgetDialog(isSingleService: false),
          ),
          
          // Venue Type
          _buildInputTile(
            icon: Icons.apartment_rounded,
            title: 'Venue Type',
            value: _packageFormData.venueType,
            onTap: () => _showVenueTypeDialog(),
          ),
          
          // Services
          _buildInputTile(
            icon: Icons.list_alt_rounded,
            title: 'Services',
            value: _packageFormData.selectedServices.isEmpty
                ? null
                : '${_packageFormData.selectedServices.length} services selected',
            placeholder: 'Select required services',
            isRequired: true,
            onTap: () => _showServicesDialog(),
          ),
          
          // Notes (Optional)
          _buildInputTile(
            icon: Icons.note_rounded,
            title: 'Notes',
            value: _packageFormData.notes.isEmpty ? null : _packageFormData.notes,
            placeholder: 'Add notes (optional)',
            onTap: () => _showNotesDialog(isSingleService: false),
          ),
          
          const SizedBox(height: 32),
          _buildSearchButton(
            label: 'Generate Packages',
            icon: Icons.auto_awesome,
            onPressed: _packageFormData.city.isNotEmpty && 
                       _packageFormData.selectedServices.isNotEmpty
                ? _handleGeneratePackages
                : null,
          ),
          const SizedBox(height: 100), // Bottom padding for navigation bar
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
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

  Widget _buildInputTile({
    required IconData icon,
    required String title,
    String? value,
    String? placeholder,
    bool isRequired = false,
    required VoidCallback onTap,
  }) {
    final hasValue = value != null && value.isNotEmpty;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasValue ? kPrimaryColor.withOpacity(0.3) : const Color(0xFFE8EAF0),
                width: hasValue ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: hasValue ? kPrimaryColor.withOpacity(0.1) : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: hasValue ? kPrimaryColor : kTextSecondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: kTextSecondary,
                            ),
                          ),
                          if (isRequired)
                            Text(
                              ' *',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasValue ? value! : (placeholder ?? 'Tap to select'),
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                          color: hasValue ? kTextPrimary : kTextSecondary.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: kTextSecondary.withOpacity(0.5),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchButton({
    String label = 'Search',
    IconData icon = Icons.search_rounded,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isGenerating ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: kPrimaryColor.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: onPressed != null ? 4 : 0,
          shadowColor: kPrimaryColor.withOpacity(0.5),
        ),
        child: _isGenerating
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
      ),
    );
  }

  // ============ DIALOG METHODS ============
  
  void _showServiceTypeDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ServiceTypeDialog(
        selectedService: _singleServiceData.serviceType,
        onSelected: (service) {
          setState(() {
            _singleServiceData = _singleServiceData.copyWith(serviceType: service);
          });
        },
      ),
    );
  }

  void _showCityDialog({required bool isSingleService}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CityDialog(
        selectedCity: isSingleService ? _singleServiceData.city : _packageFormData.city,
        onSelected: (city) {
          setState(() {
            if (isSingleService) {
              _singleServiceData = _singleServiceData.copyWith(city: city);
            } else {
              _packageFormData = _packageFormData.copyWith(city: city);
            }
          });
        },
      ),
    );
  }

  void _showDateDialog({required bool isSingleService}) async {
    final initialDate = isSingleService 
        ? _singleServiceData.eventDate ?? DateTime.now().add(const Duration(days: 30))
        : _packageFormData.eventDate ?? DateTime.now().add(const Duration(days: 30));
    
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: kPrimaryColor),
          ),
          child: child!,
        );
      },
    );
    
    if (date != null) {
      setState(() {
        if (isSingleService) {
          _singleServiceData = _singleServiceData.copyWith(eventDate: date);
        } else {
          _packageFormData = _packageFormData.copyWith(eventDate: date);
        }
      });
    }
  }

  void _showTimeDialog({required bool isSingleService}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TimeRangeDialog(
        startTime: isSingleService ? _singleServiceData.startTime : _packageFormData.startTime,
        endTime: isSingleService ? _singleServiceData.endTime : _packageFormData.endTime,
        onConfirm: (start, end) {
          setState(() {
            if (isSingleService) {
              _singleServiceData = _singleServiceData.copyWith(
                startTime: start,
                endTime: end,
              );
            } else {
              _packageFormData = _packageFormData.copyWith(
                startTime: start,
                endTime: end,
              );
            }
          });
        },
      ),
    );
  }

  void _showGuestCountDialog({required bool isSingleService}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GuestCountDialog(
        currentCount: isSingleService ? _singleServiceData.guestCount : _packageFormData.guestCount,
        onConfirm: (count) {
          setState(() {
            if (isSingleService) {
              _singleServiceData = _singleServiceData.copyWith(guestCount: count);
            } else {
              _packageFormData = _packageFormData.copyWith(guestCount: count);
            }
          });
        },
      ),
    );
  }

  void _showBudgetDialog({required bool isSingleService}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BudgetDialog(
        minBudget: isSingleService ? _singleServiceData.minBudget : _packageFormData.budgetRange.start,
        maxBudget: isSingleService ? _singleServiceData.maxBudget : _packageFormData.budgetRange.end,
        showFlexibilityOption: true, // Always show flexibility options now
        hasFlexibility: isSingleService ? _singleServiceData.hasBudgetFlexibility : _packageFormData.hasBudgetFlexibility,
        flexibilityPercent: isSingleService ? _singleServiceData.budgetFlexibilityPercent : _packageFormData.budgetFlexibilityPercent,
        flexibilityType: isSingleService ? _singleServiceData.budgetFlexibilityType : _packageFormData.budgetFlexibilityType,
        onConfirm: (min, max, hasFlexibility, flexPercent, flexType) {
          setState(() {
            if (isSingleService) {
              _singleServiceData = _singleServiceData.copyWith(
                minBudget: min,
                maxBudget: max,
                hasBudgetFlexibility: hasFlexibility ?? false,
                budgetFlexibilityPercent: flexPercent ?? 10,
                budgetFlexibilityType: flexType ?? VariationType.both,
              );
            } else {
              _packageFormData = _packageFormData.copyWith(
                budgetRange: RangeValues(min, max),
                hasBudgetFlexibility: hasFlexibility ?? false,
                budgetFlexibilityPercent: flexPercent ?? 10,
                budgetFlexibilityType: flexType ?? VariationType.both,
              );
            }
          });
        },
      ),
    );
  }

  void _showEventTypeDialog({required bool isSingleService}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EventTypeDialog(
        selectedEventType: isSingleService ? _singleServiceData.eventType : _packageFormData.eventType,
        onSelected: (eventType, customType) {
          setState(() {
            if (isSingleService) {
              _singleServiceData = _singleServiceData.copyWith(
                eventType: eventType,
                customEventType: customType,
              );
            } else {
              _packageFormData = _packageFormData.copyWith(
                eventType: eventType,
                customEventType: customType,
              );
            }
          });
        },
      ),
    );
  }

  void _showVenueTypeDialog({bool isSingleService = false}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => VenueTypeDialog(
        selectedVenueType: isSingleService ? _singleServiceData.venueType : _packageFormData.venueType,
        onSelected: (venueType) {
          setState(() {
            if (isSingleService) {
              _singleServiceData = _singleServiceData.copyWith(venueType: venueType);
            } else {
              _packageFormData = _packageFormData.copyWith(venueType: venueType);
            }
          });
        },
      ),
    );
  }

  void _showServicesDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ServicesDialog(
        selectedServices: _packageFormData.selectedServices,
        onConfirm: (services) {
          setState(() {
            _packageFormData = _packageFormData.copyWith(selectedServices: services);
          });
        },
      ),
    );
  }

  void _showPackageOptionsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PackageOptionsDialog(
        currentPreference: _packageFormData.packagePreference,
        currentExtraPackages: _packageFormData.extraPackagesCount,
        currentVariationPercentage: _packageFormData.variationPercentage,
        currentVariationType: _packageFormData.variationType,
        onSelected: (preference, extraPackages, variationPercentage, variationType) {
          setState(() {
            _packageFormData = _packageFormData.copyWith(
              packagePreference: preference,
              extraPackagesCount: extraPackages,
              variationPercentage: variationPercentage,
              variationType: variationType,
            );
          });
        },
      ),
    );
  }

  String _getPackageOptionsDisplayValue() {
    if (_packageFormData.packagePreference == PackagePreference.withinBudget) {
      return 'Within budget only';
    }
    
    String directionText;
    switch (_packageFormData.variationType) {
      case VariationType.lower:
        directionText = 'lower';
        break;
      case VariationType.higher:
        directionText = 'higher';
        break;
      case VariationType.both:
        directionText = 'both';
        break;
    }
    
    return '${_packageFormData.extraPackagesCount} extra, ±${_packageFormData.variationPercentage}% ($directionText)';
  }

  String _getBudgetDisplayValue([bool isSingleService = true]) {
    if (isSingleService) {
      String budgetStr = '₪${_singleServiceData.minBudget.toInt()} - ₪${_singleServiceData.maxBudget.toInt()}';
      
      if (_singleServiceData.hasBudgetFlexibility) {
        String directionIcon;
        switch (_singleServiceData.budgetFlexibilityType) {
          case VariationType.lower:
            directionIcon = '↓';
            break;
          case VariationType.higher:
            directionIcon = '↑';
            break;
          case VariationType.both:
            directionIcon = '↕';
            break;
        }
        budgetStr += ' (±${_singleServiceData.budgetFlexibilityPercent}%$directionIcon)';
      }
      
      return budgetStr;
    } else {
      // Package form data
      String budgetStr = '₪${_packageFormData.budgetRange.start.toInt()} - ₪${_packageFormData.budgetRange.end.toInt()}';
      
      if (_packageFormData.hasBudgetFlexibility) {
        String directionIcon;
        switch (_packageFormData.budgetFlexibilityType) {
          case VariationType.lower:
            directionIcon = '↓';
            break;
          case VariationType.higher:
            directionIcon = '↑';
            break;
          case VariationType.both:
            directionIcon = '↕';
            break;
        }
        budgetStr += ' (±${_packageFormData.budgetFlexibilityPercent}%$directionIcon)';
      }
      
      return budgetStr;
    }
  }

  void _showNotesDialog({required bool isSingleService}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotesDialog(
        currentNotes: isSingleService ? _singleServiceData.notes : _packageFormData.notes,
        onConfirm: (notes) {
          setState(() {
            if (isSingleService) {
              _singleServiceData = _singleServiceData.copyWith(notes: notes);
            } else {
              _packageFormData = _packageFormData.copyWith(notes: notes);
            }
          });
        },
      ),
    );
  }

  // ============ SEARCH HANDLERS ============

  Future<void> _handleSingleServiceSearch() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final response = await AiService.searchSingleService(_singleServiceData);

      if (response.success && response.results != null) {
        setState(() {
          _serviceResults = response.results!;
          _isGenerating = false;
          _showResults = true;
        });
        _fadeController.forward(from: 0);
      } else {
        setState(() {
          _isGenerating = false;
          _errorMessage = response.error ?? 'Failed to find services';
        });
        _showErrorDialog(_errorMessage!);
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _errorMessage = e.toString();
      });
      _showErrorDialog('Error: ${e.toString()}');
    }
  }

  Future<void> _handleGeneratePackages() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final response = await AiService.generatePackages(_packageFormData);

      if (response.success && response.packages != null) {
        setState(() {
          _generatedPackages = response.packages!;
          _isGenerating = false;
          _showResults = true;
        });
        _fadeController.forward(from: 0);
      } else {
        setState(() {
          _isGenerating = false;
          _errorMessage = response.error ?? 'Failed to generate packages';
        });
        _showErrorDialog(_errorMessage!);
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _errorMessage = e.toString();
      });
      _showErrorDialog('Error: ${e.toString()}');
    }
  }

  void _showErrorDialog(String message) {
    // Extract a cleaner error message
    String cleanMessage = message
        .replaceAll('Exception: ', '')
        .replaceAll('Error: ', '')
        .trim();
    
    // Determine if it's a "no results" type error
    final bool isNoResults = cleanMessage.toLowerCase().contains('no ') && 
        (cleanMessage.toLowerCase().contains('found') || 
         cleanMessage.toLowerCase().contains('matching') ||
         cleanMessage.toLowerCase().contains('available'));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isNoResults ? Colors.orange.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isNoResults ? Icons.search_off_rounded : Icons.error_outline_rounded,
                color: isNoResults ? Colors.orange.shade600 : Colors.red.shade500,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                isNoResults ? 'No Results Found' : 'Something Went Wrong',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: kTextPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cleanMessage,
              style: GoogleFonts.poppins(fontSize: 14, color: kTextSecondary, height: 1.5),
            ),
            if (isNoResults) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.blue.shade600, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Suggestions',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildSuggestionItem('Try expanding your budget range'),
                    _buildSuggestionItem('Select a different city'),
                    _buildSuggestionItem('Adjust the date or time'),
                    _buildSuggestionItem('Enable budget flexibility option'),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (isNoResults)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _showResults = false);
              },
              child: Text(
                'Modify Search',
                style: GoogleFonts.poppins(color: kPrimaryColor, fontWeight: FontWeight.w600),
              ),
            ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(
              'Got it',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: GoogleFonts.poppins(fontSize: 13, color: Colors.blue.shade600)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.blue.shade700),
            ),
          ),
        ],
      ),
    );
  }

  // ============ RESULTS VIEWS ============

  Widget _buildServiceResults() {
    return Column(
      children: [
        _buildResultsHeader(
          '${_serviceResults.length} Services Found',
          'Based on your search criteria',
        ),
        Expanded(
          child: _serviceResults.isEmpty
              ? _buildEmptyState()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                      left: 20, right: 20, top: 20, bottom: 100,
                    ),
                    itemCount: _serviceResults.length,
                    itemBuilder: (context, index) {
                      return _buildServiceResultCard(_serviceResults[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPackageResults() {
    return Column(
      children: [
        _buildResultsHeader(
          '${_generatedPackages.length} Packages Generated',
          'AI-curated packages for your event',
        ),
        Expanded(
          child: _generatedPackages.isEmpty
              ? _buildEmptyState()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                      left: 20, right: 20, top: 20, bottom: 100,
                    ),
                    itemCount: _generatedPackages.length,
                    itemBuilder: (context, index) {
                      // ✅ Pass isStrictBudget to hide level labels when budget is strict
                      final isStrictBudget = _packageFormData.packagePreference == PackagePreference.withinBudget;
                      return AiPackageCard(
                        package: _generatedPackages[index],
                        onAddToCart: () => _handleAddToCart(_generatedPackages[index]),
                        isStrictBudget: isStrictBudget,
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildResultsHeader(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _searchMode == SearchMode.singleService
                  ? Icons.check_circle_rounded
                  : Icons.auto_awesome,
              color: kPrimaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: kTextPrimary,
                  ),
                ),
                Text(
                  subtitle,
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

  Widget _buildServiceResultCard(ServiceSearchResult service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section with Price Badge
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Service Image
                  service.imageUrl != null && service.imageUrl!.isNotEmpty
                      ? Image.network(
                          service.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholderImage(service.category),
                        )
                      : _buildPlaceholderImage(service.category),
                  // Gradient Overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.0),
                            Colors.black.withOpacity(0.25),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Rating Badge (top left)
                  if (service.rating != null && service.rating! > 0)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              service.rating!.toStringAsFixed(1),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.amber.shade800,
                              ),
                            ),
                            if (service.reviewCount != null && service.reviewCount! > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(${service.reviewCount})',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: kTextSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  // Price Badge (top right)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(
                        '₪${service.price.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: kPrimaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service Name
                Text(
                  service.serviceName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: kPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                // Provider Name
                Text(
                  service.providerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: kTextSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                // Info Chips (Category, City, Price Type)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      icon: Icons.grid_view_rounded,
                      text: service.category,
                      isPrimary: true,
                    ),
                    if (service.city != null)
                      _buildInfoChip(
                        icon: Icons.location_on_rounded,
                        text: service.city!,
                        isPrimary: false,
                      ),
                    _buildInfoChip(
                      icon: Icons.payments_rounded,
                      text: service.priceLabel,
                      isPrimary: false,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Action Buttons Row
                Row(
                  children: [
                    // Add to Cart Button
                    Expanded(
                      child: ValueListenableBuilder<List<CartItem>>(
                        valueListenable: CartStore.instance.itemsListenable,
                        builder: (_, items, __) {
                          final inCart = items.any((e) => e.id == service.id);
                          return ElevatedButton.icon(
                            onPressed: inCart ? null : () => _handleAddServiceToCart(service),
                            icon: Icon(
                              inCart ? Icons.check_circle_rounded : Icons.add_shopping_cart_rounded,
                              size: 18,
                            ),
                            label: Text(
                              inCart ? 'In Cart' : 'Add to Cart',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: inCart ? Colors.green : kPrimaryColor,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.green.withOpacity(0.8),
                              disabledForegroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Full Details Button
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF0F172A),
                            const Color(0xFF1E293B),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _handleViewServiceDetails(service),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Full Details',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage(String category) {
    return Container(
      color: kPrimaryColor.withOpacity(0.1),
      child: Center(
        child: Icon(
          _getServiceIcon(category),
          size: 48,
          color: kPrimaryColor.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String text, required bool isPrimary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isPrimary ? kPrimaryColor.withOpacity(0.1) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPrimary ? kPrimaryColor.withOpacity(0.2) : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isPrimary ? kPrimaryColor : kTextSecondary,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isPrimary ? kPrimaryColor : kTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Handle adding a single service to cart
  void _handleAddServiceToCart(ServiceSearchResult service) {
    _showServiceBookingDialog(service);
  }

  /// Handle viewing full service details
  void _handleViewServiceDetails(ServiceSearchResult service) {
    if (service.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Service details not available',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Navigate to AI service details page (with Chat only)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiServiceDetailsScreen(
          serviceId: service.id,
          serviceName: service.serviceName,
          imageUrl: service.imageUrl,
          providerName: service.providerName,
          category: service.category,
          city: service.city,
          price: service.price,
          payType: service.payType,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off_rounded, size: 60, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          Text(
            'No results found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search criteria',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: kTextSecondary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() => _showResults = false),
            icon: const Icon(Icons.arrow_back),
            label: Text('Go Back', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // ============ HELPER METHODS ============

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  IconData _getServiceIcon(String category) {
    final service = ServiceCategory.allServices.firstWhere(
      (s) => s.name.toLowerCase() == category.toLowerCase(),
      orElse: () => const ServiceCategory(
        name: 'Other',
        nameAr: 'أخرى',
        icon: Icons.category,
        color: Colors.grey,
      ),
    );
    return service.icon;
  }

  void _handleAddToCart(PackageResult package) {
    // Show a dialog to add all services from the package to cart
    _showAddPackageToCartDialog(package);
  }

  /// Show dialog to add all services from a package to cart
  void _showAddPackageToCartDialog(PackageResult package) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.shopping_cart_checkout, color: kPrimaryColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Add Package to Cart',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will add the following ${package.services.length} services to your cart:',
              style: GoogleFonts.poppins(fontSize: 14, color: kTextSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Column(
                  children: package.services.map((service) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: kPrimaryColor, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${service.category}: ${service.name}',
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                        ),
                        Text(
                          '₪${service.price.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total:',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '₪${package.price.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: kPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '💡 Each service will need booking details (date, time, guests) when you proceed to checkout.',
              style: GoogleFonts.poppins(fontSize: 12, color: kTextSecondary, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: kTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _processAddPackageToCart(package);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Add All to Cart',
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// Process adding all services from package to cart
  void _processAddPackageToCart(PackageResult package) async {
    // For now, show a snackbar. In real implementation, you would:
    // 1. Open booking modal for each service
    // 2. Or add to cart with default booking details
    
    int addedCount = 0;
    for (final service in package.services) {
      if (service.id.isNotEmpty) {
        // TODO: Implement actual cart addition with booking details
        addedCount++;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${package.name} - ${package.services.length} services ready to book!',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () {
            Navigator.pushNamed(context, '/cart');
          },
        ),
      ),
    );
  }

  void _handleBookService(ServiceSearchResult service) {
    // Open booking modal for the service
    _showServiceBookingDialog(service);
  }

  /// Show booking dialog for a single service
  void _showServiceBookingDialog(ServiceSearchResult service) {
    // Determine price display based on pay type
    String priceNote = '';
    if (service.payType != null) {
      switch (service.payType!.toLowerCase()) {
        case 'perhour':
        case 'per hour':
          priceNote = '💡 Final price will be calculated based on booking hours.';
          break;
        case 'perperson':
        case 'per person':
          priceNote = '💡 Final price will be calculated based on number of guests.';
          break;
        case 'perday':
        case 'per day':
          priceNote = '💡 Price is per day of service.';
          break;
        case 'display':
          priceNote = '⚠️ This service is for display only - contact provider for pricing.';
          break;
        default:
          priceNote = '💡 You\'ll be able to select date and time in the booking process.';
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.event_available, color: kPrimaryColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Book Service',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    service.serviceName,
                    style: GoogleFonts.poppins(fontSize: 13, color: kTextSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildServiceInfoRow(Icons.person_outline, 'Provider', service.providerName),
            const SizedBox(height: 12),
            _buildServiceInfoRow(Icons.category_outlined, 'Category', service.category),
            if (service.city != null) ...[
              const SizedBox(height: 12),
              _buildServiceInfoRow(Icons.location_on_outlined, 'City', service.city!),
            ],
            const SizedBox(height: 12),
            if (service.rating != null && service.rating! > 0)
              _buildServiceInfoRow(
                Icons.star_outline,
                'Rating',
                '${service.rating!.toStringAsFixed(1)} ${service.reviewCount != null && service.reviewCount! > 0 ? "(${service.reviewCount} reviews)" : ""}',
              ),
            const SizedBox(height: 16),
            // Price Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '₪${service.price.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: kPrimaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        service.priceLabel,
                        style: GoogleFonts.poppins(fontSize: 14, color: kTextSecondary),
                      ),
                    ],
                  ),
                  if (service.calculatedPrice > 0 && service.calculatedPrice != service.price) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Estimated: ₪${service.calculatedPrice.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              priceNote,
              style: GoogleFonts.poppins(fontSize: 12, color: kTextSecondary, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: kTextSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _openBookingModal(service);
            },
            icon: const Icon(Icons.add_shopping_cart, size: 18),
            label: Text(
              'Continue',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: kTextSecondary, size: 20),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: GoogleFonts.poppins(fontSize: 13, color: kTextSecondary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  /// Open the booking modal for a service
  void _openBookingModal(ServiceSearchResult service) async {
    // Check if already in cart
    final inCart = CartStore.instance.contains(service.id);
    if (inCart) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
          content: Text(
            'This service is already in your cart',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
          ),
          action: SnackBarAction(
            label: 'View Cart',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartPage()),
              );
            },
          ),
        ),
      );
      return;
    }

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
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
            Expanded(
              child: Text(
                'Loading service details...',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: kPrimaryColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      // Fetch full service data from API
      final baseUrl = AuthService.baseUrl;
      final response = await http.get(
        Uri.parse('$baseUrl/services/${service.id}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load service details');
      }

      final serviceData = json.decode(response.body) as Map<String, dynamic>;
      final bookingType = serviceData['bookingType']?.toString() ?? 'daily';
      
      // Check if display only
      if (bookingType.toLowerCase() == 'display') {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'This service is for display only. Please contact the provider.',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Hide loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Show booking modal
      await showBookingModal(
        context: context,
        serviceId: service.id,
        serviceName: service.serviceName,
        bookingTypeString: bookingType,
        serviceData: serviceData,
        onSuccess: () {
          setState(() {}); // Refresh UI
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
              content: Text(
                'Added to cart successfully!',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
              ),
              action: SnackBarAction(
                label: 'View Cart',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartPage()),
                  );
                },
              ),
            ),
          );
        },
      );
    } catch (e) {
      print('❌ Error opening booking modal: $e');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load service details. Please try again.',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}