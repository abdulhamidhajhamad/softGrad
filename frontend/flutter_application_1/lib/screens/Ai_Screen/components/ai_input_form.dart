// lib/screens/Ai_Screen/components/ai_input_form.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/ai_data_models.dart';

const Color kPrimaryColor = Color.fromARGB(215, 20, 20, 215);
const Color kAccentColor = Color.fromARGB(215, 20, 20, 215);
const Color kBackgroundColor = Color(0xFFF8F9FC);
const Color kCardColor = Colors.white;
const Color kBorderColor = Color(0xFFE8EAF0);
const Color kTextPrimary = Color(0xFF1A1A2E);
const Color kTextSecondary = Color(0xFF6B7280);

class AiInputForm extends StatefulWidget {
  final FormData formData;
  final Function(FormData) onFormChanged;
  final VoidCallback onGeneratePressed;
  final bool isGenerating;

  const AiInputForm({
    Key? key,
    required this.formData,
    required this.onFormChanged,
    required this.onGeneratePressed,
    this.isGenerating = false,
  }) : super(key: key);

  @override
  State<AiInputForm> createState() => _AiInputFormState();
}

class _AiInputFormState extends State<AiInputForm> with SingleTickerProviderStateMixin {
  final TextEditingController _customEventCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  final TextEditingController _customServiceCtrl = TextEditingController();
  final TextEditingController _minBudgetCtrl = TextEditingController();
  final TextEditingController _maxBudgetCtrl = TextEditingController();
  final TextEditingController _guestCountCtrl = TextEditingController();
  
  late AnimationController _animationController;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _customEventCtrl.text = widget.formData.customEventType ?? '';
    _notesCtrl.text = widget.formData.notes;
    _minBudgetCtrl.text = widget.formData.budgetRange.start.toInt().toString();
    _maxBudgetCtrl.text = widget.formData.budgetRange.end.toInt().toString();
    _guestCountCtrl.text = widget.formData.guestCount.toString();
  }

  @override
  void dispose() {
    _customEventCtrl.dispose();
    _notesCtrl.dispose();
    _customServiceCtrl.dispose();
    _minBudgetCtrl.dispose();
    _maxBudgetCtrl.dispose();
    _guestCountCtrl.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBackgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildStepIndicator(),
            const SizedBox(height: 24),
            _buildCurrentStepContent(),
            const SizedBox(height: 24),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Eventry AI',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Let us help you plan your perfect event',
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

  Widget _buildStepIndicator() {
    final steps = ['Event', 'Budget', 'Details', 'Services'];
    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index == _currentStep;
        final isCompleted = index < _currentStep;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _currentStep = index),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isActive ? kPrimaryColor : isCompleted ? kPrimaryColor.withOpacity(0.2) : Colors.grey.shade200,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive || isCompleted ? kPrimaryColor : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: kPrimaryColor, size: 16)
                        : Text(
                            '${index + 1}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isActive ? Colors.white : kTextSecondary,
                            ),
                          ),
                  ),
                ),
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted ? kPrimaryColor.withOpacity(0.5) : Colors.grey.shade200,
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildEventTypeStep();
      case 1:
        return _buildBudgetStep();
      case 2:
        return _buildDetailsStep();
      case 3:
        return _buildServicesStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _currentStep--),
              icon: const Icon(Icons.arrow_back_ios, size: 16),
              label: Text('Back', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: kPrimaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                side: const BorderSide(color: kPrimaryColor, width: 1.5),
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: _currentStep < 3
              ? ElevatedButton.icon(
                  onPressed: () => setState(() => _currentStep++),
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  label: Text('Next', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                    shadowColor: kPrimaryColor.withOpacity(0.4),
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: widget.isGenerating ? null : widget.onGeneratePressed,
                  icon: widget.isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome, size: 20),
                  label: Text(
                    widget.isGenerating ? 'Generating...' : 'Generate Packages',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                    shadowColor: const Color(0xFF22C55E).withOpacity(0.4),
                  ),
                ),
        ),
      ],
    );
  }

  // ==================== STEP 1: EVENT TYPE ====================
  Widget _buildEventTypeStep() {
    return _buildStepCard(
      title: 'Event Type',
      subtitle: 'What kind of event are you planning?',
      icon: Icons.celebration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEventTypeGrid(),
          if (widget.formData.eventType == 'Other') ...[
            const SizedBox(height: 20),
            _buildAnimatedTextField(
              controller: _customEventCtrl,
              label: 'Describe your event',
              hint: 'e.g., Family gathering, Eid celebration...',
              icon: Icons.edit_note,
              onChanged: (val) => widget.onFormChanged(
                widget.formData.copyWith(customEventType: val),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventTypeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemCount: EventType.allTypes.length,
      itemBuilder: (context, index) {
        final eventType = EventType.allTypes[index];
        final isSelected = widget.formData.eventType == eventType.name;
        
        return GestureDetector(
          onTap: () {
            widget.onFormChanged(widget.formData.copyWith(eventType: eventType.name));
            if (eventType.name != 'Other') {
              widget.onFormChanged(widget.formData.copyWith(customEventType: null));
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? eventType.color.withOpacity(0.15) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? eventType.color : kBorderColor,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: eventType.color.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected ? eventType.color : eventType.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    eventType.icon,
                    color: isSelected ? Colors.white : eventType.color,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  eventType.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? eventType.color : kTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================== STEP 2: BUDGET ====================
  Widget _buildBudgetStep() {
    return _buildStepCard(
      title: 'Budget Range',
      subtitle: 'Set your budget limits in NIS',
      icon: Icons.account_balance_wallet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBudgetRangeInputs(),
          const SizedBox(height: 24),
          _buildBudgetSlider(),
          const SizedBox(height: 24),
          _buildPackagePreferenceSelector(),
        ],
      ),
    );
  }

  Widget _buildBudgetRangeInputs() {
    return Row(
      children: [
        Expanded(
          child: _buildCompactTextField(
            controller: _minBudgetCtrl,
            label: 'Min Budget',
            prefix: '₪',
            keyboardType: TextInputType.number,
            onChanged: (val) {
              final min = double.tryParse(val) ?? widget.formData.budgetRange.start;
              widget.onFormChanged(widget.formData.copyWith(
                budgetRange: RangeValues(min, widget.formData.budgetRange.end),
              ));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.compare_arrows, color: kPrimaryColor, size: 20),
          ),
        ),
        Expanded(
          child: _buildCompactTextField(
            controller: _maxBudgetCtrl,
            label: 'Max Budget',
            prefix: '₪',
            keyboardType: TextInputType.number,
            onChanged: (val) {
              final max = double.tryParse(val) ?? widget.formData.budgetRange.end;
              widget.onFormChanged(widget.formData.copyWith(
                budgetRange: RangeValues(widget.formData.budgetRange.start, max),
              ));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Adjust with slider',
              style: GoogleFonts.poppins(fontSize: 13, color: kTextSecondary),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '₪${widget.formData.budgetRange.start.toInt()} - ₪${widget.formData.budgetRange.end.toInt()}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kPrimaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: kPrimaryColor,
            inactiveTrackColor: kPrimaryColor.withOpacity(0.2),
            thumbColor: kPrimaryColor,
            overlayColor: kPrimaryColor.withOpacity(0.1),
            rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 12),
            trackHeight: 6,
          ),
          child: RangeSlider(
            values: widget.formData.budgetRange,
            min: 1000,
            max: 200000,
            divisions: 199,
            onChanged: (vals) {
              widget.onFormChanged(widget.formData.copyWith(budgetRange: vals));
              _minBudgetCtrl.text = vals.start.toInt().toString();
              _maxBudgetCtrl.text = vals.end.toInt().toString();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPackagePreferenceSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, color: kPrimaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Package Options',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildOptionTile(
            title: 'Within Budget Only',
            subtitle: 'Show packages within your budget range',
            isSelected: widget.formData.packagePreference == PackagePreference.withinBudget,
            onTap: () => widget.onFormChanged(
              widget.formData.copyWith(packagePreference: PackagePreference.withinBudget),
            ),
          ),
          const SizedBox(height: 8),
          _buildOptionTile(
            title: 'Show More Options',
            subtitle: 'Include +15% premium and -15% budget options',
            isSelected: widget.formData.packagePreference == PackagePreference.withOptions,
            onTap: () => widget.onFormChanged(
              widget.formData.copyWith(packagePreference: PackagePreference.withOptions),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? kPrimaryColor : kBorderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected ? kPrimaryColor : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? kPrimaryColor : kTextSecondary,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kTextPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: kTextSecondary,
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

  // ==================== STEP 3: DETAILS ====================
  Widget _buildDetailsStep() {
    return _buildStepCard(
      title: 'Event Details',
      subtitle: 'Tell us more about your event',
      icon: Icons.event_note,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCitySelector(),
          const SizedBox(height: 20),
          _buildVenueTypeSelector(),
          const SizedBox(height: 20),
          _buildGuestCountInput(),
          const SizedBox(height: 20),
          _buildNotesField(),
        ],
      ),
    );
  }

  Widget _buildCitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('City', Icons.location_city),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBorderColor),
          ),
          child: DropdownButtonFormField<String>(
            value: widget.formData.city.isEmpty ? null : widget.formData.city,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none,
              hintText: 'Select your city',
              hintStyle: GoogleFonts.poppins(fontSize: 14, color: kTextSecondary),
            ),
            style: GoogleFonts.poppins(fontSize: 14, color: kTextPrimary),
            icon: const Icon(Icons.keyboard_arrow_down, color: kPrimaryColor),
            items: CityData.palestinianCities.map((city) {
              return DropdownMenuItem(
                value: city,
                child: Text(city),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                widget.onFormChanged(widget.formData.copyWith(city: val));
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVenueTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Venue Type', Icons.home_work),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildVenueOption(
                icon: Icons.meeting_room,
                label: 'Indoor',
                isSelected: widget.formData.venueType == 'Indoor',
                onTap: () => widget.onFormChanged(widget.formData.copyWith(venueType: 'Indoor')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildVenueOption(
                icon: Icons.park,
                label: 'Outdoor',
                isSelected: widget.formData.venueType == 'Outdoor',
                onTap: () => widget.onFormChanged(widget.formData.copyWith(venueType: 'Outdoor')),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVenueOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? kPrimaryColor : kBorderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: kPrimaryColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : kPrimaryColor, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : kTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestCountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Number of Guests', Icons.people),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildCounterButton(
              icon: Icons.remove,
              onPressed: () {
                final newCount = (widget.formData.guestCount - 10).clamp(10, 1000);
                widget.onFormChanged(widget.formData.copyWith(guestCount: newCount));
                _guestCountCtrl.text = newCount.toString();
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kBorderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people, color: kPrimaryColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _guestCountCtrl,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: kTextPrimary,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (val) {
                          final count = int.tryParse(val) ?? widget.formData.guestCount;
                          widget.onFormChanged(widget.formData.copyWith(guestCount: count.clamp(10, 1000)));
                        },
                      ),
                    ),
                    Text(
                      ' guests',
                      style: GoogleFonts.poppins(fontSize: 14, color: kTextSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            _buildCounterButton(
              icon: Icons.add,
              onPressed: () {
                final newCount = (widget.formData.guestCount + 10).clamp(10, 1000);
                widget.onFormChanged(widget.formData.copyWith(guestCount: newCount));
                _guestCountCtrl.text = newCount.toString();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCounterButton({required IconData icon, required VoidCallback onPressed}) {
    return Material(
      color: kPrimaryColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: kPrimaryColor, size: 24),
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Additional Notes', Icons.note_add, isOptional: true),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBorderColor),
          ),
          child: TextField(
            controller: _notesCtrl,
            maxLines: 3,
            style: GoogleFonts.poppins(fontSize: 14, color: kTextPrimary),
            decoration: InputDecoration(
              hintText: 'Any special requests or preferences...',
              hintStyle: GoogleFonts.poppins(fontSize: 14, color: kTextSecondary.withOpacity(0.7)),
              contentPadding: const EdgeInsets.all(16),
              border: InputBorder.none,
            ),
            onChanged: (val) => widget.onFormChanged(widget.formData.copyWith(notes: val)),
          ),
        ),
      ],
    );
  }

  // ==================== STEP 4: SERVICES ====================
  Widget _buildServicesStep() {
    return _buildStepCard(
      title: 'Required Services',
      subtitle: 'Select and prioritize services (drag to reorder)',
      icon: Icons.checklist,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildServicesGrid(),
          if (widget.formData.selectedServices.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSelectedServicesReorder(),
          ],
          if (widget.formData.selectedServices.any((s) => s.name == 'Other')) ...[
            const SizedBox(height: 20),
            _buildAnimatedTextField(
              controller: _customServiceCtrl,
              label: 'Describe your custom service',
              hint: 'e.g., Henna artist, Fireworks...',
              icon: Icons.edit,
              onChanged: (val) {
                final services = widget.formData.selectedServices.map((s) {
                  if (s.name == 'Other') {
                    return s.copyWith(customName: val);
                  }
                  return s;
                }).toList();
                widget.onFormChanged(widget.formData.copyWith(selectedServices: services));
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServicesGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.touch_app, color: kPrimaryColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'Tap to select services',
                style: GoogleFonts.poppins(fontSize: 13, color: kTextSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ServiceCategory.allServices.map((service) {
              final isSelected = widget.formData.selectedServices.any((s) => s.name == service.name);
              final priority = widget.formData.selectedServices.indexWhere((s) => s.name == service.name) + 1;
              
              return GestureDetector(
                onTap: () => _toggleService(service),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? service.color.withOpacity(0.15) : Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected ? service.color : kBorderColor,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: service.color,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$priority',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      Icon(
                        service.icon,
                        size: 18,
                        color: isSelected ? service.color : kTextSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        service.name,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? service.color : kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedServicesReorder() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.sort, color: kPrimaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Priority Order',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kTextPrimary,
                      ),
                    ),
                    Text(
                      'Drag to reorder by importance',
                      style: GoogleFonts.poppins(fontSize: 11, color: kTextSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.formData.selectedServices.length,
            onReorder: (oldIndex, newIndex) {
              final services = List<SelectedService>.from(widget.formData.selectedServices);
              if (newIndex > oldIndex) newIndex--;
              final item = services.removeAt(oldIndex);
              services.insert(newIndex, item);
              // Update priorities
              final updatedServices = services.asMap().entries.map((e) {
                return e.value.copyWith(priority: e.key + 1);
              }).toList();
              widget.onFormChanged(widget.formData.copyWith(selectedServices: updatedServices));
            },
            itemBuilder: (context, index) {
              final service = widget.formData.selectedServices[index];
              final serviceCategory = ServiceCategory.allServices.firstWhere(
                (s) => s.name == service.name,
                orElse: () => ServiceCategory.allServices.last,
              );
              
              return Container(
                key: ValueKey(service.name),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: serviceCategory.color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: serviceCategory.color.withOpacity(0.3)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: serviceCategory.color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Icon(serviceCategory.icon, color: serviceCategory.color, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        service.customName ?? service.name,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red.shade400, size: 20),
                        onPressed: () => _toggleService(serviceCategory),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.drag_handle, color: kTextSecondary),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _toggleService(ServiceCategory service) {
    final services = List<SelectedService>.from(widget.formData.selectedServices);
    final existingIndex = services.indexWhere((s) => s.name == service.name);
    
    if (existingIndex >= 0) {
      services.removeAt(existingIndex);
      // Update priorities
      for (int i = 0; i < services.length; i++) {
        services[i] = services[i].copyWith(priority: i + 1);
      }
    } else {
      services.add(SelectedService(
        name: service.name,
        priority: services.length + 1,
      ));
    }
    
    widget.onFormChanged(widget.formData.copyWith(selectedServices: services));
  }

  // ==================== HELPER WIDGETS ====================
  Widget _buildStepCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: kPrimaryColor, size: 22),
              ),
              const SizedBox(width: 12),
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
                        fontSize: 12,
                        color: kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label, IconData icon, {bool isOptional = false}) {
    return Row(
      children: [
        Icon(icon, color: kPrimaryColor, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: kTextPrimary,
          ),
        ),
        if (isOptional)
          Text(
            ' (Optional)',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: kTextSecondary,
            ),
          ),
      ],
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Function(String) onChanged,
  }) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorderColor),
        ),
        child: TextField(
          controller: controller,
          style: GoogleFonts.poppins(fontSize: 14, color: kTextPrimary),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.poppins(fontSize: 14, color: kTextSecondary),
            hintText: hint,
            hintStyle: GoogleFonts.poppins(fontSize: 13, color: kTextSecondary.withOpacity(0.6)),
            prefixIcon: Icon(icon, color: kPrimaryColor, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: InputBorder.none,
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String label,
    String? prefix,
    TextInputType? keyboardType,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: kTextSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorderColor),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: kTextPrimary,
            ),
            decoration: InputDecoration(
              prefixText: prefix,
              prefixStyle: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kPrimaryColor,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none,
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}