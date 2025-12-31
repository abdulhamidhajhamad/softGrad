// lib/screens/Ai_Screen/components/ai_input_form.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/ai_data_models.dart';

const Color kAccentColor = Color.fromARGB(215, 20, 20, 215);

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

class _AiInputFormState extends State<AiInputForm> {
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _detailsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cityCtrl.text = widget.formData.city;
    _detailsCtrl.text = widget.formData.customDetails;
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    _detailsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('A. Hard Constraints'),
          const SizedBox(height: 16),
          _buildEventTypeSelector(),
          const SizedBox(height: 20),
          _buildGuestCountSlider(),
          const SizedBox(height: 20),
          _buildBudgetRangeSlider(),
          const SizedBox(height: 20),
          _buildDateCityFields(),
          const SizedBox(height: 32),
          _buildSectionTitle('B. Vibe & Style'),
          const SizedBox(height: 16),
          _buildVibeStyleChips(),
          const SizedBox(height: 20),
          _buildVenueTypeDropdown(),
          const SizedBox(height: 20),
          _buildServicesCheckboxes(),
          const SizedBox(height: 32),
          _buildSectionTitle('C. The Magic Box'),
          const SizedBox(height: 16),
          _buildCustomDetailsField(),
          const SizedBox(height: 32),
          _buildGenerateButton(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1A1A2E),
      ),
    );
  }

  Widget _buildEventTypeSelector() {
    final types = [
      {'name': 'Wedding', 'icon': Icons.favorite},
      {'name': 'Engagement', 'icon': Icons.card_giftcard},
      {'name': 'Anniversary', 'icon': Icons.celebration},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Event Type',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: types.map((type) {
            final isSelected = widget.formData.eventType == type['name'];
            return GestureDetector(
              onTap: () {
                widget.onFormChanged(
                  widget.formData.copyWith(eventType: type['name'] as String),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? kAccentColor : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? kAccentColor : const Color(0xFFE3E4F2),
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: kAccentColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      type['icon'] as IconData,
                      color: isSelected ? Colors.white : kAccentColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      type['name'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF444444),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGuestCountSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Guest Count',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF555555),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kAccentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${widget.formData.guestCount} Guests',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: kAccentColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: kAccentColor,
            inactiveTrackColor: kAccentColor.withOpacity(0.2),
            thumbColor: kAccentColor,
            overlayColor: kAccentColor.withOpacity(0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Slider(
            value: widget.formData.guestCount.toDouble(),
            min: 20,
            max: 500,
            divisions: 48,
            onChanged: (val) {
              widget.onFormChanged(
                widget.formData.copyWith(guestCount: val.toInt()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetRangeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Budget Range (NIS)',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF555555),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kAccentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '₪${widget.formData.budgetRange.start.toInt()} - ₪${widget.formData.budgetRange.end.toInt()}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: kAccentColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        RangeSlider(
          values: widget.formData.budgetRange,
          min: 5000,
          max: 100000,
          divisions: 38,
          activeColor: kAccentColor,
          inactiveColor: kAccentColor.withOpacity(0.2),
          onChanged: (vals) {
            widget.onFormChanged(
              widget.formData.copyWith(budgetRange: vals),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDateCityFields() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: widget.formData.eventDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2030),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(primary: kAccentColor),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null) {
                widget.onFormChanged(widget.formData.copyWith(eventDate: date));
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE3E4F2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: kAccentColor, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    widget.formData.eventDate != null
                        ? '${widget.formData.eventDate!.day}/${widget.formData.eventDate!.month}/${widget.formData.eventDate!.year}'
                        : 'Event Date',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: widget.formData.eventDate != null
                          ? const Color(0xFF1A1A2E)
                          : const Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _cityCtrl,
            decoration: InputDecoration(
              hintText: 'City',
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF888888),
              ),
              prefixIcon: const Icon(Icons.location_city, color: kAccentColor, size: 20),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE3E4F2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE3E4F2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kAccentColor, width: 2),
              ),
            ),
            style: GoogleFonts.poppins(fontSize: 14),
            onChanged: (val) {
              widget.onFormChanged(widget.formData.copyWith(city: val));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVibeStyleChips() {
    final vibes = ['Classic', 'Modern', 'Rustic', 'Romantic', 'Bohemian', 'Luxury'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vibe & Style',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: vibes.map((vibe) {
            final isSelected = widget.formData.vibeStyles.contains(vibe);
            return GestureDetector(
              onTap: () {
                final updated = List<String>.from(widget.formData.vibeStyles);
                if (isSelected) {
                  updated.remove(vibe);
                } else {
                  updated.add(vibe);
                }
                widget.onFormChanged(widget.formData.copyWith(vibeStyles: updated));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? kAccentColor : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? kAccentColor : const Color(0xFFE3E4F2),
                  ),
                ),
                child: Text(
                  vibe,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF444444),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVenueTypeDropdown() {
    final venues = ['Indoor', 'Outdoor', 'Garden', 'Beach', 'Hotel Ballroom'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Venue Type',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE3E4F2)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: widget.formData.venueType,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: kAccentColor),
              style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1A1A2E)),
              items: venues.map((venue) {
                return DropdownMenuItem(value: venue, child: Text(venue));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  widget.onFormChanged(widget.formData.copyWith(venueType: val));
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServicesCheckboxes() {
    final services = [
      'Photography',
      'Catering',
      'Music & DJ',
      'Decoration',
      'Flowers',
      'Videography'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Required Services',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: services.map((service) {
            final isSelected = widget.formData.selectedServices.contains(service);
            return GestureDetector(
              onTap: () {
                final updated = List<String>.from(widget.formData.selectedServices);
                if (isSelected) {
                  updated.remove(service);
                } else {
                  updated.add(service);
                }
                widget.onFormChanged(widget.formData.copyWith(selectedServices: updated));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? kAccentColor.withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? kAccentColor : const Color(0xFFE3E4F2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected ? kAccentColor : const Color(0xFF888888),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      service,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? kAccentColor : const Color(0xFF444444),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomDetailsField() {
    return TextField(
      controller: _detailsCtrl,
      maxLines: 5,
      decoration: InputDecoration(
        hintText: 'Any special requests or custom details?\n(e.g., "I need halal food options", "Beach sunset theme", "Traditional music")',
        hintStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: const Color(0xFF888888),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE3E4F2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE3E4F2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kAccentColor, width: 2),
        ),
      ),
      style: GoogleFonts.poppins(fontSize: 14),
      onChanged: (val) {
        widget.onFormChanged(widget.formData.copyWith(customDetails: val));
      },
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: widget.isGenerating ? null : widget.onGeneratePressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: kAccentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: kAccentColor.withOpacity(0.5),
        ),
        child: widget.isGenerating
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Generate My Packages',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}