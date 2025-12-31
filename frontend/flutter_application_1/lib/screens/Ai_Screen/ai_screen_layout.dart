// lib/screens/Ai_Screen/ai_screen_layout.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/ai_data_models.dart';
import 'components/ai_input_form.dart';
import 'components/ai_package_card.dart';

const Color kAccentColor = Color.fromARGB(215, 20, 20, 215);

class AiScreenLayout extends StatefulWidget {
  const AiScreenLayout({Key? key}) : super(key: key);

  @override
  State<AiScreenLayout> createState() => _AiScreenLayoutState();
}

class _AiScreenLayoutState extends State<AiScreenLayout> {
  FormData _formData = FormData();
  List<PackageResult> _generatedPackages = [];
  bool _isGenerating = false;
  bool _showResults = false;
  TimeOfDay? _eventTime;

  void _handleFormChanged(FormData newData) {
    setState(() {
      _formData = newData;
    });
  }

  Future<void> _handleGeneratePackages() async {
    setState(() {
      _isGenerating = true;
      _showResults = false;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    final packages = _generateMockPackages();

    setState(() {
      _generatedPackages = packages;
      _isGenerating = false;
      _showResults = true;
    });
  }

  List<PackageResult> _generateMockPackages() {
    final budget = (_formData.budgetRange.start + _formData.budgetRange.end) / 2;

    return [
      PackageResult(
        id: '1',
        name: 'Essential ${_formData.eventType}',
        price: budget * 0.6,
        description: 'Perfect starter package with all the essentials',
        packageLevel: 'Basic',
        services: [
          ServiceItem(
            category: 'Venue',
            name: 'Garden Hall - 4 Hours',
            price: budget * 0.25,
          ),
          ServiceItem(
            category: 'Photography',
            name: 'Basic Coverage - 6 Hours',
            price: budget * 0.15,
          ),
          ServiceItem(
            category: 'Catering',
            name: 'Standard Menu - ${_formData.guestCount} Guests',
            price: budget * 0.20,
          ),
        ],
      ),
      PackageResult(
        id: '2',
        name: 'Premium ${_formData.eventType}',
        price: budget * 0.85,
        description: 'Enhanced experience with premium services',
        packageLevel: 'Premium',
        services: [
          ServiceItem(
            category: 'Venue',
            name: 'Luxury Ballroom - 6 Hours',
            price: budget * 0.30,
          ),
          ServiceItem(
            category: 'Photography',
            name: 'Premium Package - 8 Hours',
            price: budget * 0.20,
          ),
          ServiceItem(
            category: 'Catering',
            name: 'Deluxe Menu - ${_formData.guestCount} Guests',
            price: budget * 0.25,
          ),
          ServiceItem(
            category: 'Music',
            name: 'Live Band + DJ',
            price: budget * 0.10,
          ),
        ],
      ),
      PackageResult(
        id: '3',
        name: 'Luxury ${_formData.eventType}',
        price: budget * 1.0,
        description: 'The ultimate wedding experience with everything included',
        packageLevel: 'Luxury',
        services: [
          ServiceItem(
            category: 'Venue',
            name: 'Premium ${_formData.venueType} Venue - Full Day',
            price: budget * 0.35,
          ),
          ServiceItem(
            category: 'Photography',
            name: 'Cinematic Photo & Video',
            price: budget * 0.25,
          ),
          ServiceItem(
            category: 'Catering',
            name: 'Gourmet Menu - ${_formData.guestCount} Guests',
            price: budget * 0.25,
          ),
          ServiceItem(
            category: 'Decoration',
            name: 'Designer Floral & Lighting',
            price: budget * 0.10,
          ),
          ServiceItem(
            category: 'Music',
            name: 'Orchestra + DJ',
            price: budget * 0.05,
          ),
        ],
      ),
    ];
  }

  void _handleAddToCart(PackageResult package) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${package.name} added to cart!',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: kAccentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWeb = constraints.maxWidth > 900;

        if (isWeb) {
          return _buildWebLayout();
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F4F8),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
        title: Text(
          'AI Package Generator',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A2E),
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: Icon(Icons.auto_awesome, color: kAccentColor, size: 24),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _showResults ? _buildResultsView() : _buildFormView(),
      ),
    );
  }

  Widget _buildWebLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kAccentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, color: kAccentColor, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'AI Wedding Package Generator',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
      ),
      body: Row(
        children: [
          // Left Panel - Form (40%)
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.white,
              child: _buildFormView(),
            ),
          ),

          // Right Panel - Results (60%)
          Expanded(
            flex: 6,
            child: Container(
              color: const Color(0xFFF3F4F8),
              child: _showResults
                  ? _buildWebResultsGrid()
                  : _buildWebPlaceholder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('A. Hard Constraints'),
          const SizedBox(height: 16),
          _buildEventTypeDropdown(),
          const SizedBox(height: 20),
          _buildGuestCountField(),
          const SizedBox(height: 20),
          _buildBudgetRangeFields(),
          const SizedBox(height: 20),
          _buildDateTimeCityFields(),
          const SizedBox(height: 32),
          _buildSectionTitle('B. Vibe & Style'),
          const SizedBox(height: 16),
          _buildVibeStyleChips(),
          const SizedBox(height: 20),
          _buildIndoorOutdoorSelector(),
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

  Widget _buildEventTypeDropdown() {
    final eventTypes = ['Wedding', 'Engagement', 'Anniversary'];

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
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE3E4F2)),
          ),
          child: DropdownButtonFormField<String>(
            value: _formData.eventType,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF1A1A2E),
            ),
            icon: const Icon(Icons.arrow_drop_down, color: kAccentColor),
            items: eventTypes.map((type) {
              IconData icon;
              switch (type) {
                case 'Wedding':
                  icon = Icons.favorite;
                  break;
                case 'Engagement':
                  icon = Icons.card_giftcard;
                  break;
                case 'Anniversary':
                  icon = Icons.celebration;
                  break;
                default:
                  icon = Icons.event;
              }
              
              return DropdownMenuItem<String>(
                value: type,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(icon, color: kAccentColor, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        type,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF444444),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                _handleFormChanged(_formData.copyWith(eventType: value));
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGuestCountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Guest Count',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _formData.guestCount.toString(),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter number of guests',
            hintStyle: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF888888),
            ),
            prefixIcon: const Icon(Icons.people, color: kAccentColor, size: 20),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          style: GoogleFonts.poppins(fontSize: 14),
          onChanged: (value) {
            if (value.isNotEmpty) {
              final guestCount = int.tryParse(value) ?? _formData.guestCount;
              _handleFormChanged(_formData.copyWith(guestCount: guestCount));
            }
          },
        ),
      ],
    );
  }

  Widget _buildBudgetRangeFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Range (NIS)',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _formData.budgetRange.start.toInt().toString(),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Min',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF888888),
                  ),
                  prefixText: '₪',
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                style: GoogleFonts.poppins(fontSize: 14),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    final min = double.tryParse(value) ?? _formData.budgetRange.start;
                    _handleFormChanged(
                      _formData.copyWith(
                        budgetRange: RangeValues(
                          min,
                          _formData.budgetRange.end,
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'to',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF555555),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: _formData.budgetRange.end.toInt().toString(),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Max',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF888888),
                  ),
                  prefixText: '₪',
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                style: GoogleFonts.poppins(fontSize: 14),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    final max = double.tryParse(value) ?? _formData.budgetRange.end;
                    _handleFormChanged(
                      _formData.copyWith(
                        budgetRange: RangeValues(
                          _formData.budgetRange.start,
                          max,
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateTimeCityFields() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _formData.eventDate ?? DateTime.now(),
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
                _handleFormChanged(_formData.copyWith(eventDate: date));
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
                    _formData.eventDate != null
                        ? '${_formData.eventDate!.day}/${_formData.eventDate!.month}/${_formData.eventDate!.year}'
                        : 'Date',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: _formData.eventDate != null
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
          child: GestureDetector(
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _eventTime ?? TimeOfDay.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(primary: kAccentColor),
                    ),
                    child: child!,
                  );
                },
              );
              if (time != null) {
                setState(() {
                  _eventTime = time;
                });
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
                  const Icon(Icons.access_time, color: kAccentColor, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    _eventTime != null
                        ? _eventTime!.format(context)
                        : 'Time',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: _eventTime != null
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
          child: TextFormField(
            initialValue: _formData.city,
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            style: GoogleFonts.poppins(fontSize: 14),
            onChanged: (val) {
              _handleFormChanged(_formData.copyWith(city: val));
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
            final isSelected = _formData.vibeStyles.contains(vibe);
            return GestureDetector(
              onTap: () {
                final updated = List<String>.from(_formData.vibeStyles);
                if (isSelected) {
                  updated.remove(vibe);
                } else {
                  updated.add(vibe);
                }
                _handleFormChanged(_formData.copyWith(vibeStyles: updated));
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

  Widget _buildIndoorOutdoorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Venue Preference',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _handleFormChanged(_formData.copyWith(venueType: 'Indoor'));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _formData.venueType == 'Indoor' ? kAccentColor : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    border: Border.all(
                      color: _formData.venueType == 'Indoor' ? kAccentColor : const Color(0xFFE3E4F2),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.home,
                        color: _formData.venueType == 'Indoor' ? Colors.white : kAccentColor,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Indoor',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _formData.venueType == 'Indoor' ? Colors.white : const Color(0xFF444444),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _handleFormChanged(_formData.copyWith(venueType: 'Outdoor'));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _formData.venueType == 'Outdoor' ? kAccentColor : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    border: Border.all(
                      color: _formData.venueType == 'Outdoor' ? kAccentColor : const Color(0xFFE3E4F2),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.nature,
                        color: _formData.venueType == 'Outdoor' ? Colors.white : kAccentColor,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Outdoor',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _formData.venueType == 'Outdoor' ? Colors.white : const Color(0xFF444444),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
            final isSelected = _formData.selectedServices.contains(service);
            return GestureDetector(
              onTap: () {
                final updated = List<String>.from(_formData.selectedServices);
                if (isSelected) {
                  updated.remove(service);
                } else {
                  updated.add(service);
                }
                _handleFormChanged(_formData.copyWith(selectedServices: updated));
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
    return TextFormField(
      initialValue: _formData.customDetails,
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
        contentPadding: const EdgeInsets.all(16),
      ),
      style: GoogleFonts.poppins(fontSize: 14),
      onChanged: (val) {
        _handleFormChanged(_formData.copyWith(customDetails: val));
      },
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isGenerating ? null : _handleGeneratePackages,
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
        child: _isGenerating
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

  Widget _buildResultsView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
                onPressed: () {
                  setState(() {
                    _showResults = false;
                  });
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Custom Packages',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    Text(
                      '${_generatedPackages.length} packages generated',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF555555),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _generatedPackages.length,
            itemBuilder: (context, index) {
              return AiPackageCard(
                package: _generatedPackages[index],
                onAddToCart: () => _handleAddToCart(_generatedPackages[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWebResultsGrid() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE3E4F2))),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kAccentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.card_giftcard, color: kAccentColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Custom Packages',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    Text(
                      '${_generatedPackages.length} personalized options based on your preferences',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF555555),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 0.75,
            ),
            itemCount: _generatedPackages.length,
            itemBuilder: (context, index) {
              return AiPackageCard(
                package: _generatedPackages[index],
                onAddToCart: () => _handleAddToCart(_generatedPackages[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWebPlaceholder() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(40),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kAccentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 64,
                color: kAccentColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'AI-Powered Package Generator',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Fill in your preferences on the left\nand click "Generate" to see your custom packages',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: const Color(0xFF555555),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F4FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildFeatureRow(Icons.tune, 'Smart Matching'),
                  const SizedBox(height: 12),
                  _buildFeatureRow(Icons.price_check, 'Budget Optimization'),
                  const SizedBox(height: 12),
                  _buildFeatureRow(Icons.verified, 'Quality Guaranteed'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: kAccentColor, size: 20),
        const SizedBox(width: 10),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }
}