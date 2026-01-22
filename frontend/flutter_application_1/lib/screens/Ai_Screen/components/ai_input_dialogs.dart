// lib/screens/Ai_Screen/components/ai_input_dialogs.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/ai_data_models.dart';

const Color kPrimaryColor = Color.fromARGB(215, 20, 20, 215);
const Color kTextPrimary = Color(0xFF1A1A2E);
const Color kTextSecondary = Color(0xFF6B7280);

// ============ BASE DIALOG CONTAINER ============
class DialogContainer extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final double heightFactor;

  const DialogContainer({
    Key? key,
    required this.title,
    required this.icon,
    required this.child,
    this.heightFactor = 0.7,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * heightFactor,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: kPrimaryColor, size: 22),
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: kTextPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: kTextSecondary),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ============ SERVICE TYPE DIALOG ============
class ServiceTypeDialog extends StatelessWidget {
  final String selectedService;
  final Function(String) onSelected;

  const ServiceTypeDialog({
    Key? key,
    required this.selectedService,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DialogContainer(
      title: 'Select Service Type',
      icon: Icons.category_rounded,
      child: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.9,
        ),
        itemCount: ServiceCategory.allServices.length,
        itemBuilder: (context, index) {
          final service = ServiceCategory.allServices[index];
          final isSelected = selectedService == service.name;
          
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                onSelected(service.name);
                Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? kPrimaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? kPrimaryColor : const Color(0xFFE8EAF0),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: kPrimaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.2)
                            : service.color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        service.icon,
                        color: isSelected ? Colors.white : service.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      service.name,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : kTextPrimary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============ CITY DIALOG ============
class CityDialog extends StatelessWidget {
  final String selectedCity;
  final Function(String) onSelected;

  const CityDialog({
    Key? key,
    required this.selectedCity,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DialogContainer(
      title: 'Select City',
      icon: Icons.location_city_rounded,
      heightFactor: 0.6,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: CityData.palestinianCities.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final city = CityData.palestinianCities[index];
          final isSelected = selectedCity == city;
          
          return Material(
            color: isSelected ? kPrimaryColor.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () {
                onSelected(city);
                Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? kPrimaryColor : const Color(0xFFE8EAF0),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: isSelected ? kPrimaryColor : kTextSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      city,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? kPrimaryColor : kTextPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: kPrimaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 14),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============ TIME RANGE DIALOG ============
class TimeRangeDialog extends StatefulWidget {
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final Function(TimeOfDay, TimeOfDay) onConfirm;

  const TimeRangeDialog({
    Key? key,
    this.startTime,
    this.endTime,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<TimeRangeDialog> createState() => _TimeRangeDialogState();
}

class _TimeRangeDialogState extends State<TimeRangeDialog> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    _startTime = widget.startTime ?? const TimeOfDay(hour: 18, minute: 0);
    _endTime = widget.endTime ?? const TimeOfDay(hour: 23, minute: 0);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return DialogContainer(
      title: 'Select Time',
      icon: Icons.access_time_rounded,
      heightFactor: 0.45,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildTimeSelector(
                    label: 'Start Time',
                    time: _startTime,
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _startTime,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(primary: kPrimaryColor),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (time != null) {
                        setState(() => _startTime = time);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.arrow_forward, color: kTextSecondary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeSelector(
                    label: 'End Time',
                    time: _endTime,
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _endTime,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(primary: kPrimaryColor),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (time != null) {
                        setState(() => _endTime = time);
                      }
                    },
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onConfirm(_startTime, _endTime);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Confirm',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kPrimaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kPrimaryColor.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: kTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatTime(time),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ GUEST COUNT DIALOG ============
class GuestCountDialog extends StatefulWidget {
  final int currentCount;
  final Function(int) onConfirm;

  const GuestCountDialog({
    Key? key,
    required this.currentCount,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<GuestCountDialog> createState() => _GuestCountDialogState();
}

class _GuestCountDialogState extends State<GuestCountDialog> {
  late int _count;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _count = widget.currentCount;
    _controller = TextEditingController(text: _count.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateCount(int newCount) {
    if (newCount >= 1 && newCount <= 10000) {
      setState(() {
        _count = newCount;
        _controller.text = _count.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DialogContainer(
      title: 'Number of Guests',
      icon: Icons.people_rounded,
      heightFactor: 0.45,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCountButton(
                  icon: Icons.remove,
                  onPressed: () => _updateCount(_count - 10),
                ),
                const SizedBox(width: 20),
                Container(
                  width: 120,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
                  ),
                  child: TextField(
                    controller: _controller,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: kPrimaryColor,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) {
                      final newCount = int.tryParse(value);
                      if (newCount != null) {
                        setState(() => _count = newCount);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 20),
                _buildCountButton(
                  icon: Icons.add,
                  onPressed: () => _updateCount(_count + 10),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'guests',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: kTextSecondary,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                _buildQuickButton(50),
                const SizedBox(width: 8),
                _buildQuickButton(100),
                const SizedBox(width: 8),
                _buildQuickButton(200),
                const SizedBox(width: 8),
                _buildQuickButton(500),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onConfirm(_count);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Confirm',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountButton({required IconData icon, required VoidCallback onPressed}) {
    return Material(
      color: kPrimaryColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          child: Icon(icon, color: kPrimaryColor, size: 28),
        ),
      ),
    );
  }

  Widget _buildQuickButton(int value) {
    final isSelected = _count == value;
    return Expanded(
      child: Material(
        color: isSelected ? kPrimaryColor : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => _updateCount(value),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              value.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : kTextPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============ BUDGET DIALOG ============
class BudgetDialog extends StatefulWidget {
  final double minBudget;
  final double maxBudget;
  final bool? hasFlexibility;
  final int? flexibilityPercent;
  final VariationType? flexibilityType;
  final bool showFlexibilityOption;
  final Function(double, double, bool?, int?, VariationType?) onConfirm;

  const BudgetDialog({
    Key? key,
    required this.minBudget,
    required this.maxBudget,
    this.hasFlexibility,
    this.flexibilityPercent,
    this.flexibilityType,
    this.showFlexibilityOption = false,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<BudgetDialog> {
  late double _minBudget;
  late double _maxBudget;
  late bool _hasFlexibility;
  late int _flexibilityPercent;
  late VariationType _flexibilityType;
  late TextEditingController _percentageController;
  late TextEditingController _minController;
  late TextEditingController _maxController;
  String? _percentageError;
  String? _minError;
  String? _maxError;

  @override
  void initState() {
    super.initState();
    _minBudget = widget.minBudget;
    _maxBudget = widget.maxBudget;
    _hasFlexibility = widget.hasFlexibility ?? false;
    _flexibilityPercent = widget.flexibilityPercent ?? 10;
    _flexibilityType = widget.flexibilityType ?? VariationType.both;
    _percentageController = TextEditingController(text: _flexibilityPercent.toString());
    _minController = TextEditingController(text: _minBudget.toInt().toString());
    _maxController = TextEditingController(text: _maxBudget.toInt().toString());
  }

  @override
  void dispose() {
    _percentageController.dispose();
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _validateMinBudget(String value) {
    setState(() {
      if (value.isEmpty) {
        _minError = 'Required';
        return;
      }
      final parsed = double.tryParse(value);
      if (parsed == null) {
        _minError = 'Invalid number';
        return;
      }
      if (parsed < 0) {
        _minError = 'Must be positive';
        return;
      }
      _minError = null;
      _minBudget = parsed;
    });
  }

  void _validateMaxBudget(String value) {
    setState(() {
      if (value.isEmpty) {
        _maxError = 'Required';
        return;
      }
      final parsed = double.tryParse(value);
      if (parsed == null) {
        _maxError = 'Invalid number';
        return;
      }
      if (parsed <= 0) {
        _maxError = 'Must be greater than 0';
        return;
      }
      _maxError = null;
      _maxBudget = parsed;
    });
  }

  void _validateAndSetPercentage(String value) {
    setState(() {
      if (value.isEmpty) {
        _percentageError = 'Enter a percentage';
        return;
      }
      
      final parsed = int.tryParse(value);
      if (parsed == null) {
        _percentageError = 'Enter a valid number';
        return;
      }
      
      if (parsed < 0 || parsed > 50) {
        _percentageError = 'Must be 0-50';
        return;
      }
      
      _percentageError = null;
      _flexibilityPercent = parsed;
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.error_outline, color: Colors.red.shade700, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Error',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(fontSize: 14, color: kTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: kPrimaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _handleConfirm() {
    // Validate min budget
    if (_minController.text.isEmpty) {
      _showErrorDialog('Please enter minimum budget');
      return;
    }
    final minParsed = double.tryParse(_minController.text);
    if (minParsed == null) {
      _showErrorDialog('Please enter a valid minimum budget');
      return;
    }
    
    // Validate max budget
    if (_maxController.text.isEmpty) {
      _showErrorDialog('Please enter maximum budget');
      return;
    }
    final maxParsed = double.tryParse(_maxController.text);
    if (maxParsed == null) {
      _showErrorDialog('Please enter a valid maximum budget');
      return;
    }
    
    if (minParsed > maxParsed) {
      _showErrorDialog('Minimum budget cannot be greater than maximum');
      return;
    }
    
    // For both modes, check flexibility if enabled
    if (_hasFlexibility) {
      final percentText = _percentageController.text;
      if (percentText.isEmpty) {
        _showErrorDialog('Please enter a percentage value');
        return;
      }
      
      final parsed = int.tryParse(percentText);
      if (parsed == null) {
        _showErrorDialog('Please enter a valid number');
        return;
      }
      
      if (parsed < 0 || parsed > 50) {
        _showErrorDialog('Percentage must be between 0 and 50');
        return;
      }
      
      widget.onConfirm(_minBudget, _maxBudget, true, parsed, _flexibilityType);
    } else {
      // No flexibility - pass null for flexibility params
      widget.onConfirm(_minBudget, _maxBudget, false, null, null);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Always show flexibility options now (for both Package and Single Service)
    return DialogContainer(
      title: 'Budget Range',
      icon: Icons.payments_rounded,
      heightFactor: _hasFlexibility ? 0.75 : 0.62,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            // Budget Range Section - Manual Input
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBudgetInputField('Min', _minController, _minError, _validateMinBudget),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  margin: const EdgeInsets.only(top: 36),
                  child: Text(
                    'to',
                    style: GoogleFonts.poppins(fontSize: 14, color: kTextSecondary),
                  ),
                ),
                _buildBudgetInputField('Max', _maxController, _maxError, _validateMaxBudget),
              ],
            ),
            
            // Budget Flexibility Section (shown for ALL modes now)
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              height: 1,
              color: Colors.grey.shade200,
            ),
            const SizedBox(height: 20),
            
            // Flexibility Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.tune_rounded, color: kPrimaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Budget Flexibility',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Flexibility Toggle
            Row(
              children: [
                _buildFlexibilityToggle(
                  icon: Icons.lock_rounded,
                  label: 'Strict',
                  isSelected: !_hasFlexibility,
                  onTap: () => setState(() => _hasFlexibility = false),
                ),
                const SizedBox(width: 12),
                _buildFlexibilityToggle(
                  icon: Icons.tune_rounded,
                  label: 'Flexible',
                  isSelected: _hasFlexibility,
                  onTap: () => setState(() => _hasFlexibility = true),
                ),
              ],
            ),
            
            // Flexibility Options (when enabled)
            if (_hasFlexibility) ...[
              const SizedBox(height: 20),
              
              // Percentage Input
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Percentage',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: kTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _percentageError != null ? Colors.red : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _percentageController,
                                  keyboardType: TextInputType.number,
                                  onChanged: _validateAndSetPercentage,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: kTextPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '10',
                                    hintStyle: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: kTextSecondary.withOpacity(0.5),
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: kPrimaryColor.withOpacity(0.1),
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(11),
                                    bottomRight: Radius.circular(11),
                                  ),
                                ),
                                child: Text(
                                  '%',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: kPrimaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_percentageError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _percentageError!,
                              style: GoogleFonts.poppins(fontSize: 10, color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Direction',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: kTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildDirectionChip(
                              icon: Icons.arrow_downward_rounded,
                              label: 'Lower',
                              type: VariationType.lower,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 6),
                            _buildDirectionChip(
                              icon: Icons.arrow_upward_rounded,
                              label: 'Higher',
                              type: VariationType.higher,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 6),
                            _buildDirectionChip(
                              icon: Icons.swap_vert_rounded,
                              label: 'Both',
                              type: VariationType.both,
                              color: kPrimaryColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Confirm',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetInputField(
    String label,
    TextEditingController controller,
    String? error,
    Function(String) onChanged,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: kTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: error != null ? Colors.red : kPrimaryColor.withOpacity(0.3),
                width: error != null ? 1 : 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(11),
                      bottomLeft: Radius.circular(11),
                    ),
                  ),
                  child: Text(
                    '₪',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: kPrimaryColor,
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    onChanged: onChanged,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: kTextPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: label == 'Min' ? '5000' : '50000',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 16,
                        color: kTextSecondary.withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                error,
                style: GoogleFonts.poppins(fontSize: 10, color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFlexibilityToggle({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? kPrimaryColor.withOpacity(0.1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? kPrimaryColor : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? kPrimaryColor : kTextSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? kPrimaryColor : kTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDirectionChip({
    required IconData icon,
    required String label,
    required VariationType type,
    required Color color,
  }) {
    final isSelected = _flexibilityType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _flexibilityType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : kTextSecondary, size: 18),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? color : kTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }}

// ============ EVENT TYPE DIALOG ============
class EventTypeDialog extends StatefulWidget {
  final String selectedEventType;
  final Function(String, String?) onSelected;

  const EventTypeDialog({
    Key? key,
    required this.selectedEventType,
    required this.onSelected,
  }) : super(key: key);

  @override
  State<EventTypeDialog> createState() => _EventTypeDialogState();
}

class _EventTypeDialogState extends State<EventTypeDialog> {
  late String _selectedType;
  final TextEditingController _customController = TextEditingController();
  bool _showCustomField = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedEventType;
    _showCustomField = _selectedType == 'Other';
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DialogContainer(
      title: 'Event Type',
      icon: Icons.celebration_rounded,
      child: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: EventType.allTypes.length,
              itemBuilder: (context, index) {
                final event = EventType.allTypes[index];
                final isSelected = _selectedType == event.name;
                
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedType = event.name;
                        _showCustomField = event.name == 'Other';
                      });
                      if (event.name != 'Other') {
                        widget.onSelected(event.name, null);
                        Navigator.pop(context);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? event.color : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? event.color : const Color(0xFFE8EAF0),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            event.icon,
                            color: isSelected ? Colors.white : event.color,
                            size: 28,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            event.name,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : kTextPrimary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_showCustomField)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextField(
                    controller: _customController,
                    decoration: InputDecoration(
                      hintText: 'Enter custom event type',
                      hintStyle: GoogleFonts.poppins(color: kTextSecondary),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    style: GoogleFonts.poppins(fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onSelected('Other', _customController.text);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Confirm',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ============ VENUE TYPE DIALOG ============
class VenueTypeDialog extends StatelessWidget {
  final String selectedVenueType;
  final Function(String) onSelected;

  const VenueTypeDialog({
    Key? key,
    required this.selectedVenueType,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Venue Type',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildVenueOption(
                  context,
                  icon: Icons.apartment_rounded,
                  label: 'Indoor',
                  isSelected: selectedVenueType == 'Indoor',
                  onTap: () {
                    onSelected('Indoor');
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildVenueOption(
                  context,
                  icon: Icons.park_rounded,
                  label: 'Outdoor',
                  isSelected: selectedVenueType == 'Outdoor',
                  onTap: () {
                    onSelected('Outdoor');
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildVenueOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32),
          decoration: BoxDecoration(
            color: isSelected ? kPrimaryColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? kPrimaryColor : const Color(0xFFE8EAF0),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : kPrimaryColor,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : kTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ SERVICES DIALOG ============
class ServicesDialog extends StatefulWidget {
  final List<SelectedService> selectedServices;
  final Function(List<SelectedService>) onConfirm;

  const ServicesDialog({
    Key? key,
    required this.selectedServices,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<ServicesDialog> createState() => _ServicesDialogState();
}

class _ServicesDialogState extends State<ServicesDialog> {
  late List<SelectedService> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedServices);
  }

  int get _totalBudgetPercent => _selected.fold(0, (sum, s) => sum + s.budgetPercent);

  void _toggleService(String serviceName) async {
    final index = _selected.indexWhere((s) => s.name == serviceName);
    if (index >= 0) {
      // Removing service
      setState(() {
        _selected.removeAt(index);
        // Recalculate priorities
        for (int i = 0; i < _selected.length; i++) {
          _selected[i] = _selected[i].copyWith(priority: i + 1);
        }
      });
    } else {
      // Adding service - show budget percentage dialog
      final percent = await _showBudgetPercentDialog(serviceName);
      if (percent != null) {
        setState(() {
          _selected.add(SelectedService(
            name: serviceName,
            priority: _selected.length + 1,
            budgetPercent: percent,
          ));
        });
      }
    }
  }

  Future<int?> _showBudgetPercentDialog(String serviceName) async {
    final service = ServiceCategory.allServices.firstWhere((s) => s.name == serviceName);
    final TextEditingController controller = TextEditingController();
    String? errorText;
    
    return showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Service icon header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [service.color.withOpacity(0.2), service.color.withOpacity(0.1)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(service.icon, color: service.color, size: 32),
                  ),
                  const SizedBox(height: 16),
                  
                  // Title
                  Text(
                    serviceName,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Description
                  Text(
                    'Enter the percentage of your total budget you want to allocate to this service',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: kTextSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Current allocation info
                  if (_selected.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kPrimaryColor.withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pie_chart_rounded, color: kPrimaryColor, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Already allocated: $_totalBudgetPercent%',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: kPrimaryColor,
                            ),
                          ),
                          Text(
                            ' (${100 - _totalBudgetPercent}% remaining)',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: kTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_selected.isNotEmpty) const SizedBox(height: 20),
                  
                  // Percentage input
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: errorText != null ? Colors.red : kPrimaryColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            autofocus: true,
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: kPrimaryColor,
                            ),
                            decoration: InputDecoration(
                              hintText: '0',
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: kTextSecondary.withOpacity(0.3),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            ),
                            onChanged: (value) {
                              setDialogState(() {
                                if (value.isEmpty) {
                                  errorText = null;
                                  return;
                                }
                                final parsed = int.tryParse(value);
                                if (parsed == null) {
                                  errorText = 'Please enter a valid number';
                                } else if (parsed < 1 || parsed > 100) {
                                  errorText = 'Must be between 1 and 100';
                                } else {
                                  errorText = null;
                                }
                              });
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withOpacity(0.1),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(14),
                              bottomRight: Radius.circular(14),
                            ),
                          ),
                          child: Text(
                            '%',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: kPrimaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Error text
                  if (errorText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        errorText!,
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.red),
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Quick selection buttons
                  Row(
                    children: [10, 20, 30, 50].map((percent) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Material(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              onTap: () {
                                controller.text = percent.toString();
                                setDialogState(() => errorText = null);
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Text(
                                  '$percent%',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: kTextPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, null),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: kTextSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final value = int.tryParse(controller.text);
                            if (value == null || value < 1 || value > 100) {
                              setDialogState(() => errorText = 'Please enter a valid percentage (1-100)');
                              return;
                            }
                            Navigator.pop(context, value);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Confirm',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _autoBalancePercentages() {
    if (_selected.isEmpty) return;
    
    final total = _totalBudgetPercent;
    if (total == 100) return;
    
    final difference = 100 - total;
    final perService = difference ~/ _selected.length;
    final remainder = difference % _selected.length;
    
    setState(() {
      for (int i = 0; i < _selected.length; i++) {
        int additionalPercent = perService;
        if (i < remainder.abs()) {
          additionalPercent += difference > 0 ? 1 : -1;
        }
        _selected[i] = _selected[i].copyWith(
          budgetPercent: (_selected[i].budgetPercent + additionalPercent).clamp(1, 100),
        );
      }
    });
  }

  void _handleConfirm() {
    // Auto-balance if needed
    if (_totalBudgetPercent != 100 && _selected.isNotEmpty) {
      _autoBalancePercentages();
    }
    widget.onConfirm(_selected);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final totalPercent = _totalBudgetPercent;
    final isBalanced = totalPercent == 100;
    
    return DialogContainer(
      title: 'Select Services',
      icon: Icons.list_alt_rounded,
      heightFactor: 0.85,
      child: Column(
        children: [
          if (_selected.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: kPrimaryColor.withOpacity(0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Selected (${_selected.length}) - Drag to reorder',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kTextSecondary,
                        ),
                      ),
                      // Budget allocation indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isBalanced ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isBalanced ? Colors.green : Colors.orange,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isBalanced ? Icons.check_circle : Icons.info_outline,
                              size: 14,
                              color: isBalanced ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$totalPercent%',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isBalanced ? Colors.green : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 52,
                    child: ReorderableListView(
                      scrollDirection: Axis.horizontal,
                      buildDefaultDragHandles: false,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex--;
                          final item = _selected.removeAt(oldIndex);
                          _selected.insert(newIndex, item);
                          // Update priorities
                          for (int i = 0; i < _selected.length; i++) {
                            _selected[i] = _selected[i].copyWith(priority: i + 1);
                          }
                        });
                      },
                      children: _selected.asMap().entries.map((entry) {
                        final index = entry.key;
                        final service = entry.value;
                        return ReorderableDragStartListener(
                          key: ValueKey(service.name),
                          index: index,
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: kPrimaryColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: kPrimaryColor.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${service.priority}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      service.name,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${service.budgetPercent}%',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.drag_handle, color: Colors.white70, size: 16),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: ServiceCategory.allServices.length,
              itemBuilder: (context, index) {
                final service = ServiceCategory.allServices[index];
                final selectedService = _selected.cast<SelectedService?>().firstWhere(
                  (s) => s?.name == service.name,
                  orElse: () => null,
                );
                final isSelected = selectedService != null;
                final priority = selectedService?.priority;
                final budgetPercent = selectedService?.budgetPercent;
                
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _toggleService(service.name),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? kPrimaryColor.withOpacity(0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? kPrimaryColor : const Color(0xFFE8EAF0),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: service.color.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    service.icon,
                                    color: service.color,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  service.name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: kTextPrimary,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                ),
                                // Show budget percentage badge for selected services
                                if (isSelected && budgetPercent != null) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.8)],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$budgetPercent%',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (isSelected && priority != null)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: kPrimaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '$priority',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Info message about auto-balance
          if (_selected.isNotEmpty && !isBalanced)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_fix_high, color: Colors.orange.shade700, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Budget will be auto-balanced to 100% when you confirm',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selected.isNotEmpty ? _handleConfirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: kPrimaryColor.withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _selected.isEmpty 
                      ? 'Select at least one service' 
                      : 'Confirm (${_selected.length} services)',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============ PACKAGE OPTIONS DIALOG ============
class PackageOptionsDialog extends StatefulWidget {
  final PackagePreference currentPreference;
  final int currentExtraPackages;
  final int currentVariationPercentage;
  final VariationType currentVariationType;
  final Function(PackagePreference, int, int, VariationType) onSelected;

  const PackageOptionsDialog({
    Key? key,
    required this.currentPreference,
    required this.currentExtraPackages,
    required this.currentVariationPercentage,
    required this.currentVariationType,
    required this.onSelected,
  }) : super(key: key);

  @override
  State<PackageOptionsDialog> createState() => _PackageOptionsDialogState();
}

class _PackageOptionsDialogState extends State<PackageOptionsDialog> {
  late PackagePreference _selectedPreference;
  late int _extraPackages;
  late int _variationPercentage;
  late VariationType _variationType;
  late TextEditingController _percentageController;
  String? _percentageError;

  @override
  void initState() {
    super.initState();
    _selectedPreference = widget.currentPreference;
    _extraPackages = widget.currentExtraPackages;
    _variationPercentage = widget.currentVariationPercentage;
    _variationType = widget.currentVariationType;
    _percentageController = TextEditingController(text: _variationPercentage.toString());
  }

  @override
  void dispose() {
    _percentageController.dispose();
    super.dispose();
  }

  void _validateAndSetPercentage(String value) {
    setState(() {
      if (value.isEmpty) {
        _percentageError = 'Please enter a percentage';
        return;
      }
      
      final parsed = int.tryParse(value);
      if (parsed == null) {
        _percentageError = 'Please enter a valid number';
        return;
      }
      
      if (parsed < 0 || parsed > 50) {
        _percentageError = 'Percentage must be between 0 and 50';
        return;
      }
      
      _percentageError = null;
      _variationPercentage = parsed;
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.error_outline, color: Colors.red.shade700, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Error',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: kTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: kPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleConfirm() {
    // Validate percentage
    final percentText = _percentageController.text;
    if (percentText.isEmpty) {
      _showErrorDialog('Please enter a percentage value');
      return;
    }
    
    final parsed = int.tryParse(percentText);
    if (parsed == null) {
      _showErrorDialog('Please enter a valid number');
      return;
    }
    
    if (parsed < 0 || parsed > 50) {
      _showErrorDialog('Percentage must be between 0 and 50');
      return;
    }
    
    widget.onSelected(
      _selectedPreference,
      _extraPackages,
      parsed,
      _variationType,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Package Options',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 24),
            _buildOptionTile(
              icon: Icons.price_check,
              title: 'Within Budget Only',
              subtitle: 'Generate packages strictly within your budget range',
              isSelected: _selectedPreference == PackagePreference.withinBudget,
              onTap: () {
                setState(() {
                  _selectedPreference = PackagePreference.withinBudget;
                });
              },
            ),
            const SizedBox(height: 12),
            _buildOptionTile(
              icon: Icons.tune,
              title: 'With Budget Variations',
              subtitle: 'Include packages with budget flexibility',
              isSelected: _selectedPreference == PackagePreference.withOptions,
              onTap: () {
                setState(() {
                  _selectedPreference = PackagePreference.withOptions;
                });
              },
            ),
            
            // Show variation options when "With Budget Variations" is selected
            if (_selectedPreference == PackagePreference.withOptions) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              
              // Extra packages count
              _buildVariationSection(
                title: 'Number of Extra Packages',
                subtitle: 'How many additional packages do you want?',
                child: _buildPackageCountSelector(),
              ),
              
              const SizedBox(height: 20),
              
              // Variation percentage
              _buildVariationSection(
                title: 'Budget Variation Percentage',
                subtitle: 'How much flexibility from your budget?',
                child: _buildPercentageSelector(),
              ),
              
              const SizedBox(height: 20),
              
              // Variation type
              _buildVariationSection(
                title: 'Variation Direction',
                subtitle: 'Do you want cheaper, more expensive, or both?',
                child: _buildVariationTypeSelector(),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Confirm button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedPreference == PackagePreference.withOptions 
                    ? _handleConfirm 
                    : () {
                        widget.onSelected(
                          _selectedPreference,
                          _extraPackages,
                          _variationPercentage,
                          _variationType,
                        );
                        Navigator.pop(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Confirm',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildVariationSection({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: kTextPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: kTextSecondary,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildPackageCountSelector() {
    return Row(
      children: [1, 2, 3, 4, 5].map((count) {
        final isSelected = _extraPackages == count;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _extraPackages = count),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? kPrimaryColor : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? kPrimaryColor : Colors.grey.shade300,
                ),
              ),
              child: Center(
                child: Text(
                  '$count',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : kTextPrimary,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPercentageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _percentageError != null ? Colors.red : Colors.grey.shade300,
              width: _percentageError != null ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _percentageController,
                  keyboardType: TextInputType.number,
                  onChanged: _validateAndSetPercentage,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter percentage',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 16,
                      color: kTextSecondary.withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                ),
                child: Text(
                  '%',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: kPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_percentageError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              _percentageError!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 4),
          child: Text(
            'Enter a value between 0 and 50',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: kTextSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVariationTypeSelector() {
    return Row(
      children: [
        _buildVariationTypeOption(
          icon: Icons.arrow_downward_rounded,
          label: 'Lower',
          type: VariationType.lower,
          color: Colors.green,
        ),
        const SizedBox(width: 8),
        _buildVariationTypeOption(
          icon: Icons.arrow_upward_rounded,
          label: 'Higher',
          type: VariationType.higher,
          color: Colors.orange,
        ),
        const SizedBox(width: 8),
        _buildVariationTypeOption(
          icon: Icons.swap_vert_rounded,
          label: 'Both',
          type: VariationType.both,
          color: kPrimaryColor,
        ),
      ],
    );
  }

  Widget _buildVariationTypeOption({
    required IconData icon,
    required String label,
    required VariationType type,
    required Color color,
  }) {
    final isSelected = _variationType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _variationType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? color : kTextSecondary,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? color : kTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? kPrimaryColor.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? kPrimaryColor : const Color(0xFFE8EAF0),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? kPrimaryColor : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : kTextSecondary,
                  size: 24,
                ),
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
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: kPrimaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ NOTES DIALOG ============
class NotesDialog extends StatefulWidget {
  final String currentNotes;
  final Function(String) onConfirm;

  const NotesDialog({
    Key? key,
    required this.currentNotes,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<NotesDialog> createState() => _NotesDialogState();
}

class _NotesDialogState extends State<NotesDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentNotes);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DialogContainer(
        title: 'Additional Notes',
        icon: Icons.note_rounded,
        heightFactor: 0.5,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: 'Add any special requirements or notes...',
                    hintStyle: GoogleFonts.poppins(color: kTextSecondary),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: GoogleFonts.poppins(fontSize: 15),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onConfirm(_controller.text);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Confirm',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ BUDGET FLEXIBILITY DIALOG (Single Service) ============
class BudgetFlexibilityDialog extends StatefulWidget {
  final bool hasFlexibility;
  final int flexibilityPercent;
  final VariationType flexibilityType;
  final Function(bool, int, VariationType) onConfirm;

  const BudgetFlexibilityDialog({
    Key? key,
    required this.hasFlexibility,
    required this.flexibilityPercent,
    required this.flexibilityType,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<BudgetFlexibilityDialog> createState() => _BudgetFlexibilityDialogState();
}

class _BudgetFlexibilityDialogState extends State<BudgetFlexibilityDialog> {
  late bool _hasFlexibility;
  late int _flexibilityPercent;
  late VariationType _flexibilityType;
  late TextEditingController _percentageController;
  String? _percentageError;

  @override
  void initState() {
    super.initState();
    _hasFlexibility = widget.hasFlexibility;
    _flexibilityPercent = widget.flexibilityPercent;
    _flexibilityType = widget.flexibilityType;
    _percentageController = TextEditingController(text: _flexibilityPercent.toString());
  }

  @override
  void dispose() {
    _percentageController.dispose();
    super.dispose();
  }

  void _validateAndSetPercentage(String value) {
    setState(() {
      if (value.isEmpty) {
        _percentageError = 'Please enter a percentage';
        return;
      }
      
      final parsed = int.tryParse(value);
      if (parsed == null) {
        _percentageError = 'Please enter a valid number';
        return;
      }
      
      if (parsed < 0 || parsed > 50) {
        _percentageError = 'Percentage must be between 0 and 50';
        return;
      }
      
      _percentageError = null;
      _flexibilityPercent = parsed;
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.error_outline, color: Colors.red.shade700, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Error',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: kTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: kPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleConfirm() {
    if (!_hasFlexibility) {
      widget.onConfirm(false, _flexibilityPercent, _flexibilityType);
      Navigator.pop(context);
      return;
    }

    final percentText = _percentageController.text;
    if (percentText.isEmpty) {
      _showErrorDialog('Please enter a percentage value');
      return;
    }
    
    final parsed = int.tryParse(percentText);
    if (parsed == null) {
      _showErrorDialog('Please enter a valid number');
      return;
    }
    
    if (parsed < 0 || parsed > 50) {
      _showErrorDialog('Percentage must be between 0 and 50');
      return;
    }
    
    widget.onConfirm(true, parsed, _flexibilityType);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Budget Flexibility',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Do you want flexibility in your budget range?',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: kTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Flexibility toggle options
            _buildFlexibilityOption(
              icon: Icons.lock_rounded,
              title: 'Strict Budget',
              subtitle: 'Search within exact budget range only',
              isSelected: !_hasFlexibility,
              onTap: () => setState(() => _hasFlexibility = false),
            ),
            const SizedBox(height: 12),
            _buildFlexibilityOption(
              icon: Icons.tune_rounded,
              title: 'Flexible Budget',
              subtitle: 'Allow results outside budget range',
              isSelected: _hasFlexibility,
              onTap: () => setState(() => _hasFlexibility = true),
            ),
            
            // Show flexibility options when enabled
            if (_hasFlexibility) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              
              // Percentage input
              _buildSectionTitle('Flexibility Percentage'),
              const SizedBox(height: 12),
              _buildPercentageInput(),
              
              const SizedBox(height: 20),
              
              // Direction selector
              _buildSectionTitle('Flexibility Direction'),
              const SizedBox(height: 12),
              _buildDirectionSelector(),
            ],
            
            const SizedBox(height: 24),
            
            // Confirm button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Confirm',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: kTextPrimary,
        ),
      ),
    );
  }

  Widget _buildFlexibilityOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? kPrimaryColor.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? kPrimaryColor : const Color(0xFFE8EAF0),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? kPrimaryColor : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : kTextSecondary,
                  size: 24,
                ),
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
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: kPrimaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPercentageInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _percentageError != null ? Colors.red : Colors.grey.shade300,
              width: _percentageError != null ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _percentageController,
                  keyboardType: TextInputType.number,
                  onChanged: _validateAndSetPercentage,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter percentage',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 16,
                      color: kTextSecondary.withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                ),
                child: Text(
                  '%',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: kPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_percentageError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              _percentageError!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 4),
          child: Text(
            'Enter a value between 0 and 50',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: kTextSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDirectionSelector() {
    return Row(
      children: [
        _buildDirectionOption(
          icon: Icons.arrow_downward_rounded,
          label: 'Lower',
          type: VariationType.lower,
          color: Colors.green,
        ),
        const SizedBox(width: 8),
        _buildDirectionOption(
          icon: Icons.arrow_upward_rounded,
          label: 'Higher',
          type: VariationType.higher,
          color: Colors.orange,
        ),
        const SizedBox(width: 8),
        _buildDirectionOption(
          icon: Icons.swap_vert_rounded,
          label: 'Both',
          type: VariationType.both,
          color: kPrimaryColor,
        ),
      ],
    );
  }

  Widget _buildDirectionOption({
    required IconData icon,
    required String label,
    required VariationType type,
    required Color color,
  }) {
    final isSelected = _flexibilityType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _flexibilityType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? color : kTextSecondary,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? color : kTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
