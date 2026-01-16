// lib/screens/provider/edit_service_provider.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_1/services/service_service.dart';
import '../map_location_picker.dart' hide kPrimaryColor, kTextColor;

// =====================
// 🎨 Design Tokens
// =====================
const Color kPrimaryColor = Color.fromARGB(215, 20, 20, 215);
const Color kBackgroundColor = Color(0xFFF7F8FC);
const Color kTextColor = Color(0xFF0B1220);
const Color kMutedColor = Color(0xFF6B7280);
const Color kSuccessColor = Color(0xFF10B981);
const Color kErrorColor = Color(0xFFEF4444);

class EditServiceProviderScreen extends StatefulWidget {
  final Map<String, dynamic> existingData;

  const EditServiceProviderScreen({
    super.key,
    required this.existingData,
  });

  @override
  State<EditServiceProviderScreen> createState() => _EditServiceProviderScreenState();
}

class _EditServiceProviderScreenState extends State<EditServiceProviderScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _hasChanges = false;

  // =====================
  // 📝 Controllers
  // =====================
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _maxCapacityCtrl;
  late TextEditingController _minHoursCtrl;
  late TextEditingController _maxHoursCtrl;

  // =====================
  // 📊 State Variables
  // =====================
  String? _selectedCity;
  String? _selectedCategory;
  String? _bookingType;
  String? _payType;
  bool _isActive = true;
  bool _hasFixedLocation = true;

  double? _latitude;
  double? _longitude;
  bool _hasLocationSet = false;

  List<String> _existingImages = [];
  List<Uint8List> _newImages = [];

  final Set<String> _selectedDays = {};
  TimeOfDay? _fromTime;
  TimeOfDay? _toTime;

  // =====================
  // 📋 Options Lists
  // =====================
  final List<String> _categories = const [
    'Venues',
    'Photographers',
    'Catering',
    'Cake',
    'Flower Shops',
    'Decor & Lighting',
    'Music & Entertainment',
    'Event Planners & Coordinators',
    'Card Printing',
    'Jewelry & Accessories',
    'Car Rental & Transportation',
    'Gift & Souvenir',
    'Other',
  ];

  final List<String> _cities = const [
    'Nablus',
    'Ramallah',
    'Jenin',
    'Tulkarm',
    'Qalqilya',
    'Hebron',
    'Bethlehem',
    'Jericho',
    'Jerusalem',
    'Other',
  ];

  final List<String> _weekdays = const [
    'sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'
  ];

  final Map<String, String> _bookingTypeLabels = const {
    'hourly': 'Hourly',
    'daily': 'Daily',
    'capacity': 'Capacity',
    'mixed': 'Mixed',
    'display': 'Display Only',
  };

  final Map<String, String> _payTypeLabels = const {
    'per hour': 'Per Hour',
    'per day': 'Per Day',
    'per person': 'Per Person',
    'display': 'Display',
  };

  @override
  void initState() {
    super.initState();
    _initializeFromExistingData();
  }

  void _initializeFromExistingData() {
    final data = widget.existingData;
    
    // Debug: print received data
    print('📝 Edit Service - Received data: $data');

    // Basic Info
    _nameCtrl = TextEditingController(text: data['serviceName'] ?? data['name'] ?? '');
    
    // Description from additionalInfo or direct
    String desc = '';
    if (data['additionalInfo'] is Map) {
      desc = data['additionalInfo']['description'] ?? '';
    }
    if (desc.isEmpty) {
      desc = data['description'] ?? data['fullDescription'] ?? data['shortDescription'] ?? '';
    }
    _descCtrl = TextEditingController(text: desc);

    // Location
    _addressCtrl = TextEditingController(text: data['address'] ?? '');
    final cityRaw = data['city']?.toString();
    _selectedCity = (cityRaw?.isNotEmpty ?? false) ? cityRaw : null;
    _latitude = _toDoubleOrNull(data['latitude']);
    _longitude = _toDoubleOrNull(data['longitude']);
    _hasLocationSet = _latitude != null && _longitude != null;
    _hasFixedLocation = data['hasFixedLocation'] ?? true;

    // Pricing
    final price = data['price'];
    _priceCtrl = TextEditingController(
      text: price is num ? price.toString() : (price ?? '').toString(),
    );

    // Category & Types
    _selectedCategory = data['category']?.toString();
    if (_selectedCategory?.isEmpty ?? true) _selectedCategory = null;
    
    final bookingTypeRaw = data['bookingType']?.toString().toLowerCase();
    _bookingType = (bookingTypeRaw?.isNotEmpty ?? false) ? bookingTypeRaw : null;
    
    final payTypeRaw = data['payType']?.toString();
    _payType = (payTypeRaw?.isNotEmpty ?? false) ? payTypeRaw : null;

    // Status
    _isActive = data['isActive'] ?? true;

    // Images
    final images = data['images'];
    if (images is List) {
      _existingImages = List<String>.from(images.map((e) => e.toString()));
    }

    // Working Days
    final workingDays = data['workingDays'];
    if (workingDays is List) {
      _selectedDays.addAll(workingDays.map((e) => e.toString().toLowerCase()));
    } else {
      _selectedDays.addAll(_weekdays); // Default all days
    }

    // Capacity & Hours
    _maxCapacityCtrl = TextEditingController(
      text: data['maxCapacity']?.toString() ?? '',
    );
    _minHoursCtrl = TextEditingController(
      text: data['minBookingHours']?.toString() ?? '',
    );
    _maxHoursCtrl = TextEditingController(
      text: data['maxBookingHours']?.toString() ?? '',
    );

    // Available Hours (time range)
    final availableHours = data['availableHours'];
    if (availableHours is List && availableHours.isNotEmpty) {
      final hours = availableHours.map((e) => e as int).toList()..sort();
      _fromTime = TimeOfDay(hour: hours.first, minute: 0);
      _toTime = TimeOfDay(hour: hours.last, minute: 0);
    }
  }

  double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _priceCtrl.dispose();
    _maxCapacityCtrl.dispose();
    _minHoursCtrl.dispose();
    _maxHoursCtrl.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  // =====================
  // 🖼️ Image Handling
  // =====================
  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      for (final file in picked) {
        final bytes = await file.readAsBytes();
        setState(() {
          _newImages.add(bytes);
          _markChanged();
        });
      }
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImages.removeAt(index);
      _markChanged();
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
      _markChanged();
    });
  }

  // =====================
  // 📍 Location Picker
  // =====================
  Future<void> _pickLocation() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => MapLocationPicker(
          initialLat: _latitude ?? 32.2211,
          initialLng: _longitude ?? 35.2544,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _latitude = result['latitude'];
        _longitude = result['longitude'];
        _addressCtrl.text = result['address'] ?? '';
        _hasLocationSet = true;
        _markChanged();
      });
    }
  }

  // =====================
  // ⏰ Time Pickers
  // =====================
  Future<void> _pickTime(bool isFrom) async {
    final initial = isFrom
        ? (_fromTime ?? const TimeOfDay(hour: 9, minute: 0))
        : (_toTime ?? const TimeOfDay(hour: 22, minute: 0));

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPrimaryColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromTime = picked;
        } else {
          _toTime = picked;
        }
        _markChanged();
      });
    }
  }

  // =====================
  // 💾 Save Changes
  // =====================
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final serviceId = widget.existingData['_id']?.toString() ?? '';
      if (serviceId.isEmpty) {
        throw Exception('Service ID not found');
      }

      // Build update data
      final updateData = <String, dynamic>{
        'serviceName': _nameCtrl.text.trim(),
        'category': _selectedCategory,
        'isActive': _isActive,
        'hasFixedLocation': _hasFixedLocation,
      };

      // Description in additionalInfo
      updateData['additionalInfo'] = {
        'description': _descCtrl.text.trim(),
      };

      // Booking Type & Pay Type
      if (_bookingType != null) {
        updateData['bookingType'] = _bookingType;
      }
      if (_payType != null) {
        updateData['payType'] = _payType;
      }

      // Price
      final price = double.tryParse(_priceCtrl.text.trim());
      if (price != null && price > 0) {
        updateData['price'] = price;
      }

      // Location (only if hasFixedLocation)
      if (_hasFixedLocation) {
        updateData['location'] = {
          'address': _addressCtrl.text.trim(),
          'city': _selectedCity,
          'latitude': _latitude,
          'longitude': _longitude,
        };
      }

      // Working Days
      if (_selectedDays.isNotEmpty) {
        updateData['workingDays'] = _selectedDays.toList();
      }

      // Capacity & Hours
      final maxCapacity = int.tryParse(_maxCapacityCtrl.text.trim());
      if (maxCapacity != null && maxCapacity > 0) {
        updateData['maxCapacity'] = maxCapacity;
      }

      final minHours = int.tryParse(_minHoursCtrl.text.trim());
      if (minHours != null && minHours > 0) {
        updateData['minBookingHours'] = minHours;
      }

      final maxHours = int.tryParse(_maxHoursCtrl.text.trim());
      if (maxHours != null && maxHours > 0) {
        updateData['maxBookingHours'] = maxHours;
      }

      // Available Hours
      if (_fromTime != null && _toTime != null) {
        final hours = <int>[];
        for (int h = _fromTime!.hour; h <= _toTime!.hour; h++) {
          hours.add(h);
        }
        updateData['availableHours'] = hours;
      }

      // Keep existing images
      updateData['images'] = _existingImages;

      // Prepare new images
      List<Map<String, dynamic>>? newImagesData;
      if (_newImages.isNotEmpty) {
        newImagesData = _newImages.asMap().entries.map((entry) => {
          'bytes': entry.value,
          'name': 'image_${entry.key}.jpg',
        }).toList();
      }

      await ServiceService.updateService(
        serviceId,
        updateData,
        newImages: newImagesData,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('Service updated successfully!', style: GoogleFonts.poppins()),
            ],
          ),
          backgroundColor: kSuccessColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Failed: ${e.toString()}', style: GoogleFonts.poppins()),
              ),
            ],
          ),
          backgroundColor: kErrorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // =====================
  // 🎨 Build UI
  // =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildImagesSection(),
                    const SizedBox(height: 20),
                    _buildBasicInfoSection(),
                    const SizedBox(height: 20),
                    _buildCategorySection(),
                    const SizedBox(height: 20),
                    _buildPricingSection(),
                    const SizedBox(height: 20),
                    _buildLocationTypeToggle(),
                    const SizedBox(height: 20),
                    if (_hasFixedLocation) ...[
                      _buildLocationSection(),
                      const SizedBox(height: 20),
                    ],
                    _buildAvailabilitySection(),
                    const SizedBox(height: 20),
                    if (_bookingType == 'hourly') ...[
                      _buildHourlySettingsSection(),
                      const SizedBox(height: 20),
                    ],
                    if (_bookingType == 'capacity' || _bookingType == 'mixed') ...[
                      _buildCapacitySection(),
                      const SizedBox(height: 20),
                    ],
                    _buildStatusSection(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildSaveButton(),
    );
  }

  // =====================
  // 🔝 Header
  // =====================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
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
          IconButton(
            onPressed: () {
              if (_hasChanges) {
                _showDiscardDialog();
              } else {
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Service',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: kTextColor,
                  ),
                ),
                Text(
                  widget.existingData['serviceName'] ?? 'Service',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: kMutedColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (_hasChanges)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Unsaved',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: kPrimaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showDiscardDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Discard Changes?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'You have unsaved changes. Are you sure you want to leave?',
          style: GoogleFonts.poppins(color: kMutedColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: kMutedColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text('Discard', style: GoogleFonts.poppins(color: kErrorColor)),
          ),
        ],
      ),
    );
  }

  // =====================
  // 🖼️ Images Section
  // =====================
  Widget _buildImagesSection() {
    return _buildCard(
      title: 'Images',
      icon: Icons.photo_library_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_existingImages.isEmpty && _newImages.isEmpty)
            _buildEmptyImagesPlaceholder()
          else
            SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Existing images
                  ..._existingImages.asMap().entries.map((entry) {
                    return _buildImageTile(
                      imageUrl: entry.value,
                      onRemove: () => _removeExistingImage(entry.key),
                    );
                  }),
                  // New images
                  ..._newImages.asMap().entries.map((entry) {
                    return _buildImageTile(
                      imageBytes: entry.value,
                      onRemove: () => _removeNewImage(entry.key),
                    );
                  }),
                  // Add button
                  _buildAddImageButton(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyImagesPlaceholder() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: kBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_photo_alternate_outlined, size: 32, color: kMutedColor),
              const SizedBox(height: 8),
              Text(
                'Add Images',
                style: GoogleFonts.poppins(fontSize: 12, color: kMutedColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageTile({String? imageUrl, Uint8List? imageBytes, required VoidCallback onRemove}) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 10),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image),
                    ),
                  )
                : Image.memory(
                    imageBytes!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: kErrorColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: kBackgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 28, color: kPrimaryColor),
            const SizedBox(height: 4),
            Text(
              'Add',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: kPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================
  // 📝 Basic Info Section
  // =====================
  Widget _buildBasicInfoSection() {
    return _buildCard(
      title: 'Basic Information',
      icon: Icons.info_outline_rounded,
      child: Column(
        children: [
          _buildTextField(
            controller: _nameCtrl,
            label: 'Service Name',
            hint: 'Enter service name',
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _descCtrl,
            label: 'Description',
            hint: 'Describe your service...',
            maxLines: 4,
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  // =====================
  // 📂 Category Section
  // =====================
  Widget _buildCategorySection() {
    return _buildCard(
      title: 'Category & Type',
      icon: Icons.category_outlined,
      child: Column(
        children: [
          _buildDropdown(
            label: 'Category',
            value: _selectedCategory,
            items: _categories,
            onChanged: (val) {
              setState(() {
                _selectedCategory = val;
                _markChanged();
              });
            },
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Booking Type',
            value: _bookingType,
            items: _bookingTypeLabels.keys.toList(),
            itemLabels: _bookingTypeLabels,
            onChanged: (val) {
              setState(() {
                _bookingType = val;
                _markChanged();
              });
            },
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Pay Type',
            value: _payType,
            items: _payTypeLabels.keys.toList(),
            itemLabels: _payTypeLabels,
            onChanged: (val) {
              setState(() {
                _payType = val;
                _markChanged();
              });
            },
          ),
        ],
      ),
    );
  }

  // =====================
  // 💰 Pricing Section
  // =====================
  Widget _buildPricingSection() {
    return _buildCard(
      title: 'Pricing',
      icon: Icons.attach_money_rounded,
      child: Column(
        children: [
          _buildTextField(
            controller: _priceCtrl,
            label: 'Price',
            hint: 'Enter price',
            keyboardType: TextInputType.number,
            prefix: '\$ ',
          ),
          if (_payType != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Price will be charged ${_payTypeLabels[_payType] ?? _payType}',
                style: GoogleFonts.poppins(fontSize: 11, color: kMutedColor),
              ),
            ),
        ],
      ),
    );
  }

  // =====================
  // 🏠 Location Type Toggle
  // =====================
  Widget _buildLocationTypeToggle() {
    return _buildCard(
      title: 'Service Location Type',
      icon: Icons.home_work_outlined,
      child: Column(
        children: [
          _buildToggleOption(
            title: 'Fixed Location',
            subtitle: 'Customers come to your location',
            icon: Icons.store_outlined,
            isSelected: _hasFixedLocation,
            onTap: () {
              setState(() {
                _hasFixedLocation = true;
                _markChanged();
              });
            },
          ),
          const SizedBox(height: 10),
          _buildToggleOption(
            title: 'Mobile Service',
            subtitle: 'You go to customer\'s location',
            icon: Icons.delivery_dining_outlined,
            isSelected: !_hasFixedLocation,
            onTap: () {
              setState(() {
                _hasFixedLocation = false;
                _markChanged();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor.withOpacity(0.08) : kBackgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? kPrimaryColor : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? kPrimaryColor.withOpacity(0.15) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? kPrimaryColor : kMutedColor,
                size: 20,
              ),
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
                      color: isSelected ? kPrimaryColor : kTextColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(fontSize: 11, color: kMutedColor),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: kPrimaryColor, size: 22),
          ],
        ),
      ),
    );
  }

  // =====================
  // 📍 Location Section
  // =====================
  Widget _buildLocationSection() {
    return _buildCard(
      title: 'Location',
      icon: Icons.location_on_outlined,
      child: Column(
        children: [
          _buildDropdown(
            label: 'City',
            value: _selectedCity,
            items: _cities,
            onChanged: (val) {
              setState(() {
                _selectedCity = val;
                _markChanged();
              });
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _addressCtrl,
            label: 'Address',
            hint: 'Enter address',
          ),
          const SizedBox(height: 16),
          _buildLocationPicker(),
        ],
      ),
    );
  }

  Widget _buildLocationPicker() {
    return GestureDetector(
      onTap: _pickLocation,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kBackgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _hasLocationSet ? kSuccessColor.withOpacity(0.1) : kPrimaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _hasLocationSet ? Icons.check_circle : Icons.map_outlined,
                color: _hasLocationSet ? kSuccessColor : kPrimaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _hasLocationSet ? 'Location Set' : 'Pick Location on Map',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kTextColor,
                    ),
                  ),
                  if (_hasLocationSet && _latitude != null && _longitude != null)
                    Text(
                      '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                      style: GoogleFonts.poppins(fontSize: 11, color: kMutedColor),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: kMutedColor),
          ],
        ),
      ),
    );
  }

  // =====================
  // 📅 Availability Section
  // =====================
  Widget _buildAvailabilitySection() {
    return _buildCard(
      title: 'Working Days',
      icon: Icons.calendar_today_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select available days',
            style: GoogleFonts.poppins(fontSize: 12, color: kMutedColor),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _weekdays.map((day) => _buildDayChip(day)).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedDays.addAll(_weekdays);
                    _markChanged();
                  });
                },
                icon: const Icon(Icons.select_all, size: 18),
                label: Text('Select All', style: GoogleFonts.poppins(fontSize: 12)),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedDays.clear();
                    _markChanged();
                  });
                },
                icon: const Icon(Icons.deselect, size: 18),
                label: Text('Clear', style: GoogleFonts.poppins(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayChip(String day) {
    final isSelected = _selectedDays.contains(day);
    final displayName = day[0].toUpperCase() + day.substring(1, 3);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedDays.remove(day);
          } else {
            _selectedDays.add(day);
          }
          _markChanged();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? kPrimaryColor : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kPrimaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          displayName,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : kTextColor,
          ),
        ),
      ),
    );
  }

  // =====================
  // ⏰ Hourly Settings Section
  // =====================
  Widget _buildHourlySettingsSection() {
    return _buildCard(
      title: 'Hourly Settings',
      icon: Icons.access_time_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTimePicker(
                  label: 'Opens At',
                  time: _fromTime,
                  onTap: () => _pickTime(true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimePicker(
                  label: 'Closes At',
                  time: _toTime,
                  onTap: () => _pickTime(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _minHoursCtrl,
                  label: 'Min Hours',
                  hint: '1',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _maxHoursCtrl,
                  label: 'Max Hours',
                  hint: '8',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker({
    required String label,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kBackgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 11, color: kMutedColor),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule, size: 18, color: kPrimaryColor),
                const SizedBox(width: 8),
                Text(
                  time != null
                      ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                      : 'Not set',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: time != null ? kTextColor : kMutedColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =====================
  // 👥 Capacity Section
  // =====================
  Widget _buildCapacitySection() {
    return _buildCard(
      title: 'Capacity Settings',
      icon: Icons.people_outline,
      child: _buildTextField(
        controller: _maxCapacityCtrl,
        label: 'Maximum Capacity',
        hint: 'Enter max number of people',
        keyboardType: TextInputType.number,
      ),
    );
  }

  // =====================
  // ✅ Status Section
  // =====================
  Widget _buildStatusSection() {
    return _buildCard(
      title: 'Service Status',
      icon: Icons.toggle_on_outlined,
      child: SwitchListTile(
        value: _isActive,
        onChanged: (val) {
          setState(() {
            _isActive = val;
            _markChanged();
          });
        },
        title: Text(
          _isActive ? 'Active' : 'Inactive',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _isActive ? kSuccessColor : kMutedColor,
          ),
        ),
        subtitle: Text(
          _isActive
              ? 'Service is visible to customers'
              : 'Service is hidden from customers',
          style: GoogleFonts.poppins(fontSize: 11, color: kMutedColor),
        ),
        activeColor: kSuccessColor,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  // =====================
  // 💾 Save Button
  // =====================
  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              disabledBackgroundColor: kPrimaryColor.withOpacity(0.5),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save_rounded, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(
                        'Save Changes',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // =====================
  // 🎨 Common Widgets
  // =====================
  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                child: Icon(icon, size: 18, color: kPrimaryColor),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? prefix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 14, color: kTextColor),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefix,
        labelStyle: GoogleFonts.poppins(fontSize: 12, color: kMutedColor),
        hintStyle: GoogleFonts.poppins(fontSize: 13, color: kMutedColor.withOpacity(0.6)),
        filled: true,
        fillColor: kBackgroundColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kErrorColor),
        ),
      ),
      validator: validator,
      onChanged: (_) => _markChanged(),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    Map<String, String>? itemLabels,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 12, color: kMutedColor),
        filled: true,
        fillColor: kBackgroundColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            itemLabels?[item] ?? item,
            style: GoogleFonts.poppins(fontSize: 13, color: kTextColor),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: kPrimaryColor),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(14),
    );
  }
}
