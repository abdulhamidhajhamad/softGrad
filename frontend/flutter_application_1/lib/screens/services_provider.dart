// lib/screens/services_provider.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

// NEW: import add service screen
import 'add_service_provider.dart';
// NEW: import showMore screen
import 'showMore_provider.dart';

const Color kPrimaryColor = Color.fromARGB(215, 20, 20, 215);
const Color kTextColor = Colors.black;
const Color kBackgroundColor = Colors.white;

class ServicesProviderScreen extends StatefulWidget {
  const ServicesProviderScreen({Key? key}) : super(key: key);

  @override
  State<ServicesProviderScreen> createState() => _ServicesProviderScreenState();
}

class _ServicesProviderScreenState extends State<ServicesProviderScreen> {
  // ⭐ KEEP SERVICES PERSISTENT
  static final List<Map<String, dynamic>> _services = [];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortOption = 'recent';
  String _statusFilter = 'all';

  DateTime? _lastUpdated;

  final List<String> _categories = const [
    'Venues',
    'Photographers',
    'Catering',
    'Cake',
    'Flower Shops',
    'Makeup Artists',
    'Music & DJ',
    'Decor & Lighting',
    'Other',
  ];

  final List<String> _cities = const [
    'Nablus',
    'Ramallah',
    'Hebron',
    'Jenin',
    'Tulkarm',
    'Qalqilya',
    'Other',
  ];

  List<Map<String, dynamic>> get _filteredServices {
    List<Map<String, dynamic>> list = _services.toList();

    // filter by search
    if (_searchQuery.isNotEmpty) {
      list = list.where((service) {
        final name = (service['name'] ?? '').toString().toLowerCase();
        final cat = (service['category'] ?? '').toString().toLowerCase();
        final price = (service['price'] ?? '').toString();
        final q = _searchQuery.toLowerCase();
        return name.contains(q) || cat.contains(q) || price.contains(q);
      }).toList();
    }

    // filter by status
    if (_statusFilter == 'active') {
      list = list.where((s) => s['isActive'] == true).toList();
    } else if (_statusFilter == 'hidden') {
      list = list.where((s) => s['isActive'] == false).toList();
    }

    // sort
    if (_sortOption == 'price_low') {
      list.sort(
          (a, b) => (a['price'] as double).compareTo(b['price'] as double));
    } else if (_sortOption == 'price_high') {
      list.sort(
          (a, b) => (b['price'] as double).compareTo(a['price'] as double));
    } else {
      list.sort((a, b) {
        final da = (a['updatedAt'] ?? a['createdAt']) as DateTime;
        final db = (b['updatedAt'] ?? b['createdAt']) as DateTime;
        return db.compareTo(da);
      });
    }

    return list;
  }

  void _markUpdated() {
    setState(() {
      _lastUpdated = DateTime.now();
    });
  }

  Future<void> _refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    setState(() {});
  }

  // used for editing only
  void _openServiceForm({Map<String, dynamic>? service, int? index}) {
    final isEditing = service != null;
    final formKey = GlobalKey<FormState>();

    final nameController =
        TextEditingController(text: service != null ? service['name'] : '');
    final shortDescController = TextEditingController(
        text: service != null ? service['shortDescription'] : '');
    final fullDescController = TextEditingController(
        text: service != null ? service['fullDescription'] : '');
    final priceController = TextEditingController(
        text: service != null ? service['price'].toString() : '');
    String selectedCategory =
        service != null ? service['category'] as String : _categories.first;
    String selectedCity =
        service != null ? service['city'] as String : _cities.first;
    bool isActive = service != null ? service['isActive'] as bool : true;
    List<String> images =
        service != null ? List<String>.from(service['images'] ?? []) : [];

    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> pickImage(ImageSource source) async {
              final picked =
                  await picker.pickImage(source: source, imageQuality: 80);
              if (picked != null) {
                setSheetState(() {
                  if (images.length < 10) {
                    images.add(picked.path);
                  }
                });
              }
            }

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.9,
              maxChildSize: 0.95,
              minChildSize: 0.6,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        Text(
                          isEditing ? 'Edit Service' : 'Add Service',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // name
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Service Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedCategory,
                                decoration: const InputDecoration(
                                  labelText: 'Category',
                                  border: OutlineInputBorder(),
                                ),
                                items: _categories
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value == null) return;
                                  setSheetState(() {
                                    selectedCategory = value;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedCity,
                                decoration: const InputDecoration(
                                  labelText: 'City',
                                  border: OutlineInputBorder(),
                                ),
                                items: _cities
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value == null) return;
                                  setSheetState(() {
                                    selectedCity = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Price',
                            prefixText: '\$ ',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            final parsed = double.tryParse(value);
                            if (parsed == null || parsed < 0) {
                              return 'Enter a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: shortDescController,
                          maxLength: 200,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Short Description',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                        const SizedBox(height: 4),

                        TextFormField(
                          controller: fullDescController,
                          maxLength: 1500,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Full Description',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Service visibility',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Switch.adaptive(
                              value: isActive,
                              activeColor: kPrimaryColor,
                              onChanged: (v) {
                                setSheetState(() {
                                  isActive = v;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Text(
                          'Service Images',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),

                        SizedBox(
                          height: 110,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  showModalBottomSheet(
                                    context: context,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                    ),
                                    builder: (_) => SafeArea(
                                      child: Wrap(
                                        children: [
                                          ListTile(
                                            leading: const Icon(Icons.photo),
                                            title: const Text(
                                                'Upload from Gallery'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              pickImage(ImageSource.gallery);
                                            },
                                          ),
                                          ListTile(
                                            leading:
                                                const Icon(Icons.camera_alt),
                                            title: const Text(
                                                'Capture from Camera'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              pickImage(ImageSource.camera);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 100,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo_outlined,
                                          color: kPrimaryColor),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Add Image',
                                        style:
                                            GoogleFonts.poppins(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              ...images.map(
                                (path) => Container(
                                  width: 100,
                                  margin: const EdgeInsets.only(right: 10),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.file(
                                          File(path),
                                          fit: BoxFit.cover,
                                          width: 100,
                                          height: 110,
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () {
                                            setSheetState(() {
                                              images.remove(path);
                                            });
                                          },
                                          child: Container(
                                            width: 22,
                                            height: 22,
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius:
                                                  BorderRadius.circular(11),
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey.shade700,
                                  side: BorderSide(color: Colors.grey.shade300),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (!formKey.currentState!.validate()) {
                                    return;
                                  }
                                  final price =
                                      double.tryParse(priceController.text) ??
                                          0;
                                  final newService = {
                                    'name': nameController.text.trim(),
                                    'category': selectedCategory,
                                    'city': selectedCity,
                                    'shortDescription':
                                        shortDescController.text.trim(),
                                    'fullDescription':
                                        fullDescController.text.trim(),
                                    'price': price,
                                    'isActive': isActive,
                                    'views':
                                        service != null ? service['views'] : 0,
                                    'bookings': service != null
                                        ? service['bookings']
                                        : 0,
                                    'likes':
                                        service != null ? service['likes'] : 0,
                                    'images': images,
                                    'createdAt': service != null
                                        ? service['createdAt']
                                        : DateTime.now(),
                                    'updatedAt': DateTime.now(),
                                  };

                                  setState(() {
                                    if (isEditing && index != null) {
                                      _services[index] = newService;
                                    } else {
                                      _services.add(newService);
                                    }
                                    _markUpdated();
                                  });
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimaryColor,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  'Save Service',
                                  style: GoogleFonts.poppins(
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
            );
          },
        );
      },
    );
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Colors.red, size: 24),
            ),
            const SizedBox(width: 10),
            Text(
              'Delete Service',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this service?',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey.shade700),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _services.removeAt(index);
                _markUpdated();
              });
              Navigator.pop(context);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _services.length;
    final activeCount = _services.where((s) => s['isActive'] == true).length;
    final hiddenCount = total - activeCount;
    final lastUpdated = _lastUpdated ??
        (_services.isNotEmpty
            ? _services
                .map<DateTime>(
                    (s) => (s['updatedAt'] ?? s['createdAt']) as DateTime)
                .reduce((a, b) => a.isAfter(b) ? a : b)
            : null);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: kTextColor),
        title: Text(
          'My Services',
          style: GoogleFonts.poppins(
            color: kTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
        actions: [
          IconButton(
            // زر +
            onPressed: () async {
              final newService = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddServiceProviderScreen(),
                ),
              );

              if (newService != null) {
                setState(() {
                  _services.add({
                    'name': newService['name'],
                    'category': newService['category'],
                    'city': newService['city'],
                    'shortDescription': newService['shortDescription'],
                    'fullDescription': newService['fullDescription'],
                    'price': newService['price'],
                    'isActive': newService['isActive'],
                    'views': 0,
                    'bookings': 0,
                    'likes': 0,
                    'images': List<String>.from(newService['images'] ?? []),
                    'createdAt': DateTime.now(),
                    'updatedAt': DateTime.now(),
                  });
                  _markUpdated();
                });
              }
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _filteredServices.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummaryHeader(
                              total, activeCount, hiddenCount, lastUpdated),
                          const SizedBox(height: 16),
                          _buildSearchAndFilters(),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList.builder(
                      itemCount: _filteredServices.length,
                      itemBuilder: (context, index) {
                        final service = _filteredServices[index];
                        final originalIndex =
                            _services.indexOf(service); // for edits/deletes
                        return _ServiceCard(
                          service: service,
                          onEdit: () => _openServiceForm(
                              service: service, index: originalIndex),
                          onDelete: () => _confirmDelete(originalIndex),
                          onToggleActive: (val) {
                            setState(() {
                              _services[originalIndex]['isActive'] = val;
                              _services[originalIndex]['updatedAt'] =
                                  DateTime.now();
                              _markUpdated();
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
      floatingActionButton: _services.isEmpty
          ? null
          : FloatingActionButton(
              backgroundColor: kPrimaryColor,
              // floating add button
              onPressed: () async {
                final newService = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddServiceProviderScreen(),
                  ),
                );

                if (newService != null) {
                  setState(() {
                    _services.add({
                      'name': newService['name'],
                      'category': newService['category'],
                      'city': newService['city'],
                      'shortDescription': newService['shortDescription'],
                      'fullDescription': newService['fullDescription'],
                      'price': newService['price'],
                      'isActive': newService['isActive'],
                      'views': 0,
                      'bookings': 0,
                      'likes': 0,
                      'images': List<String>.from(newService['images'] ?? []),
                      'createdAt': DateTime.now(),
                      'updatedAt': DateTime.now(),
                    });
                    _markUpdated();
                  });
                }
              },
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }

  Widget _buildSummaryHeader(
    int total,
    int active,
    int hidden,
    DateTime? lastUpdated,
  ) {
    String lastUpdatedText = 'Not updated yet';
    if (lastUpdated != null) {
      lastUpdatedText =
          '${lastUpdated.year}/${lastUpdated.month.toString().padLeft(2, '0')}/${lastUpdated.day.toString().padLeft(2, '0')}';
    }

    return Row(
      children: [
        _MiniStatCard(
          icon: Icons.widgets_outlined,
          label: 'Total',
          value: total.toString(),
        ),
        const SizedBox(width: 8),
        _MiniStatCard(
          icon: Icons.visibility_outlined,
          label: 'Active / Hidden',
          value: '$active / $hidden',
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniStatCard(
            icon: Icons.access_time,
            label: 'Last Updated',
            value: lastUpdatedText,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value.trim();
            });
          },
          decoration: InputDecoration(
            hintText: 'Search by name, category, or price',
            hintStyle: GoogleFonts.poppins(fontSize: 13),
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: kPrimaryColor),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _sortOption,
                decoration: InputDecoration(
                  labelText: 'Sort',
                  labelStyle: GoogleFonts.poppins(fontSize: 12),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'recent',
                    child: Text('Recently added'),
                  ),
                  DropdownMenuItem(
                    value: 'price_low',
                    child: Text('Price: Low → High'),
                  ),
                  DropdownMenuItem(
                    value: 'price_high',
                    child: Text('Price: High → Low'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _sortOption = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _statusFilter,
                decoration: InputDecoration(
                  labelText: 'Status',
                  labelStyle: GoogleFonts.poppins(fontSize: 12),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'hidden', child: Text('Hidden')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _statusFilter = value;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(
                Icons.widgets_outlined,
                size: 64,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Services Yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Start by adding your first service.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 18),

            // ⭐⭐⭐ المطلوب فقط ⭐⭐⭐
            ElevatedButton(
              onPressed: () async {
                final newService = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddServiceProviderScreen(),
                  ),
                );

                if (newService != null) {
                  setState(() {
                    _services.add({
                      'name': newService['name'],
                      'category': newService['category'],
                      'city': newService['city'],
                      'shortDescription': newService['shortDescription'],
                      'fullDescription': newService['fullDescription'],
                      'price': newService['price'],
                      'isActive': newService['isActive'],
                      'views': 0,
                      'bookings': 0,
                      'likes': 0,
                      'images': List<String>.from(newService['images'] ?? []),
                      'createdAt': DateTime.now(),
                      'updatedAt': DateTime.now(),
                    });
                    _markUpdated();
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                'Add Service',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniStatCard({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: kPrimaryColor),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleActive;

  const _ServiceCard({
    Key? key,
    required this.service,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isActive = service['isActive'] == true;
    final images = List<String>.from(service['images'] ?? []);
    final price = service['price'] as double? ?? 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ShowMoreProviderScreen(
                service: service,
              ),
            ),
          );

          if (result != null && result['edit'] == true) {
            onEdit();
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (images.isNotEmpty)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
                child: SizedBox(
                  height: 170,
                  width: double.infinity,
                  child: PageView.builder(
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return Image.file(
                        File(images[index]),
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
              )
            else
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
                child: Container(
                  height: 140,
                  color: Colors.grey.shade100,
                  child: Center(
                    child: Icon(
                      Icons.image_outlined,
                      color: Colors.grey.shade400,
                      size: 40,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          service['name'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '\$${price.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: kPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service['category'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    service['shortDescription'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green.withOpacity(0.08)
                              : Colors.grey.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isActive ? 'Active' : 'Hidden',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color:
                                isActive ? Colors.green : Colors.grey.shade600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      _StatChip(
                        icon: Icons.visibility_outlined,
                        value: '${service['views'] ?? 0}',
                      ),
                      const SizedBox(width: 6),
                      _StatChip(
                        icon: Icons.calendar_month_outlined,
                        value: '${service['bookings'] ?? 0}',
                      ),
                      const SizedBox(width: 6),
                      _StatChip(
                        icon: Icons.favorite_border,
                        value: '${service['likes'] ?? 0}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: onEdit,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: Text(
                          'Edit',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: onDelete,
                        child: Text(
                          'Delete',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Visible',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Switch.adaptive(
                        value: isActive,
                        activeColor: kPrimaryColor,
                        onChanged: onToggleActive,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;

  const _StatChip({Key? key, required this.icon, required this.value})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: kPrimaryColor),
          const SizedBox(width: 3),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
