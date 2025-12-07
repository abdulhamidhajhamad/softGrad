// lib/screens/services_provider.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
// ⭐️ NEW: Import the Service Layer
import 'package:flutter_application_1/services/service_service.dart';

import 'package:flutter_application_1/screens/add_service_provider.dart';
import 'showMore_provider.dart';
import 'edit_service_provider.dart';

const Color kPrimaryColor = Color.fromARGB(215, 20, 20, 215);
const Color kTextColor = Colors.black;
const Color kBackgroundColor = Colors.white;

class ServicesProviderScreen extends StatefulWidget {
  const ServicesProviderScreen({Key? key}) : super(key: key);

  @override
  State<ServicesProviderScreen> createState() => _ServicesProviderScreenState();
}

class _ServicesProviderScreenState extends State<ServicesProviderScreen> {
<<<<<<< HEAD
  // ⭐️ MODIFIED: Now holds the Future for the API call
  late Future<List<ServiceModel>> _servicesFuture;
  
  // ⭐️ NEW: List to store the fetched data (used for filtering/sorting)
  List<ServiceModel> _servicesList = [];
=======
  static final List<Map<String, dynamic>> _services = [];
>>>>>>> main

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
    'Music',
  ];

<<<<<<< HEAD
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // ⭐️ NEW: Start fetching services when the screen initializes
    _servicesFuture = _fetchServices(); 
=======
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

    if (_searchQuery.isNotEmpty) {
      list = list.where((service) {
        final name = (service['name'] ?? '').toString().toLowerCase();
        final cat = (service['category'] ?? '').toString().toLowerCase();
        final price = (service['price'] ?? '').toString();
        final q = _searchQuery.toLowerCase();
        return name.contains(q) || cat.contains(q) || price.contains(q);
      }).toList();
    }

    if (_statusFilter == 'active') {
      list = list.where((s) => s['isActive'] == true).toList();
    } else if (_statusFilter == 'hidden') {
      list = list.where((s) => s['isActive'] == false).toList();
    }

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
    setState(() => _lastUpdated = DateTime.now());
  }

  Future<void> _refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    setState(() {});
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
            Text('Delete Service',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ],
        ),
        content: Text('Are you sure you want to delete this service?',
            style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: Colors.grey.shade700)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _services.removeAt(index);
                _markUpdated();
              });
              Navigator.pop(context);
            },
            child:
                Text('Delete', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );
>>>>>>> main
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

<<<<<<< HEAD
  // ⭐️ NEW: Method to fetch services from the API
  Future<List<ServiceModel>> _fetchServices() async {
    try {
      final fetchedServices = await ServiceService.fetchMyServices();
      // Update the state list with fetched data
      setState(() {
        _servicesList = fetchedServices;
        _lastUpdated = DateTime.now();
      });
      return fetchedServices;
    } catch (e) {
      // Re-throw the error to be handled by FutureBuilder
      rethrow; 
    }
  }
=======
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
>>>>>>> main

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  void _onSortChanged(String? newSort) {
    if (newSort != null) {
      setState(() {
        _sortOption = newSort;
      });
    }
  }

  void _onFilterChanged(String? newFilter) {
    if (newFilter != null) {
      setState(() {
        _statusFilter = newFilter;
      });
    }
  }

  void _onToggleActive(String serviceId, bool newValue) {
    // ⭐️ MODIFIED: Logic to update the isActive status in the local list
    setState(() {
      final index = _servicesList.indexWhere((s) => s.id == serviceId);
      if (index != -1) {
        // NOTE: In a real app, you would call an API to update the status first.
        // For local state:
        // _servicesList[index] = _servicesList[index].copyWith(isActive: newValue); 
        // Since ServiceModel is immutable, we would need a copyWith method, 
        // but for simplicity, we'll just re-fetch or use a mutable list in a real scenario.
        // For now, assume this is handled server-side or update state directly for UI change:
        _servicesList[index] = ServiceModel(
          id: _servicesList[index].id,
          name: _servicesList[index].name,
          description: _servicesList[index].description,
          price: _servicesList[index].price,
          category: _servicesList[index].category,
          isActive: newValue, // The updated value
          reviewsCount: _servicesList[index].reviewsCount,
          rating: _servicesList[index].rating,
        );
      }
    });
  }

  // ⭐️ MODIFIED: Getter to apply all filters and sorting to the fetched data
  List<ServiceModel> get _filteredServices {
    List<ServiceModel> filtered = _servicesList;

    // 1. Apply Search Query (on name and description)
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((service) => 
          service.name.toLowerCase().contains(_searchQuery) ||
          service.description.toLowerCase().contains(_searchQuery)
      ).toList();
    }

    // 2. Apply Status Filter
    if (_statusFilter == 'active') {
      filtered = filtered.where((service) => service.isActive).toList();
    } else if (_statusFilter == 'inactive') {
      filtered = filtered.where((service) => !service.isActive).toList();
    }
    
    // 3. Apply Sorting
    filtered.sort((a, b) {
      if (_sortOption == 'recent') {
        // You'll need a creation date field (createdAt) in ServiceModel for true "recent" sorting.
        // Using name as a placeholder for now.
        return a.name.compareTo(b.name); 
      } else if (_sortOption == 'price_low') {
        return a.price.compareTo(b.price);
      } else if (_sortOption == 'price_high') {
        return b.price.compareTo(a.price);
      } else if (_sortOption == 'rating') {
        return b.rating.compareTo(a.rating);
      }
      return 0;
    });

    return filtered;
  }

  /// Builds the dedicated UI for when the provider has no services created yet.
  Widget _buildNoServicesFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.construction_outlined,
            size: 80,
            color: Colors.grey,
          ),
<<<<<<< HEAD
          const SizedBox(height: 16),
          Text(
            'No Services Found',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'It looks like you haven\'t created any services yet.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to the screen to create a new service
              Navigator.push(
=======
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final newService = await Navigator.push(
>>>>>>> main
                context,
                MaterialPageRoute(
                  builder: (_) => AddServiceProviderScreen(
                    existingData: null, // ← ← ← التعديل الوحيد
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: Text(
              'Add New Service',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

<<<<<<< HEAD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text(
          'My Services',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: kTextColor,
          ),
        ),
        backgroundColor: kBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: kTextColor),
        actions: [
          IconButton(
            onPressed: () {
              // ⭐️ NEW: Add functionality to refresh the data
              setState(() {
                _servicesFuture = _fetchServices();
              });
            },
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddServiceProviderScreen(),
                ),
              );
=======
              if (newService != null) {
                setState(() {
                  final service = Map<String, dynamic>.from(newService);
                  service['views'] = 0;
                  service['bookings'] = 0;
                  service['likes'] = 0;
                  service['createdAt'] = DateTime.now();
                  service['updatedAt'] = DateTime.now();

                  if (service['discount'] != null &&
                      service['discount'].toString().isNotEmpty) {
                    final p = service['price'] as double;
                    final d = double.tryParse(service['discount']) ?? 0;
                    service['finalPrice'] = p - (p * (d / 100));
                  } else {
                    service['finalPrice'] = service['price'];
                  }

                  _services.add(service);
                  _markUpdated();
                });
              }
>>>>>>> main
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search and Filter Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Search Field
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search services...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
<<<<<<< HEAD
                  const SizedBox(height: 12),
                  // Sort and Filter Dropdowns
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Sort Dropdown
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Sort by',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          value: _sortOption,
                          items: const [
                            DropdownMenuItem(value: 'recent', child: Text('Recent')),
                            DropdownMenuItem(value: 'rating', child: Text('Rating')),
                            DropdownMenuItem(value: 'price_low', child: Text('Price (Low)')),
                            DropdownMenuItem(value: 'price_high', child: Text('Price (High)')),
                          ],
                          onChanged: _onSortChanged,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Filter Dropdown
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          value: _statusFilter,
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('All')),
                            DropdownMenuItem(value: 'active', child: Text('Active')),
                            DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                          ],
                          onChanged: _onFilterChanged,
                        ),
                      ),
                    ],
=======
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList.builder(
                      itemCount: _filteredServices.length,
                      itemBuilder: (context, index) {
                        final service = _filteredServices[index];
                        final originalIndex = _services.indexOf(service);

                        return _ServiceCard(
                          service: service,
                          onEdit: () async {
                            final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditServiceProviderScreen(
                                    existingData: service),
                              ),
                            );

                            if (updated != null) {
                              setState(() {
                                _services[originalIndex] = {
                                  ..._services[originalIndex],
                                  ...updated,
                                  "updatedAt": DateTime.now(),
                                };
                              });
                              _markUpdated();
                            }
                          },
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
>>>>>>> main
                  ),
                ],
              ),
            ),
<<<<<<< HEAD

            // ⭐️ MODIFIED: Using FutureBuilder to handle async data fetching
            Expanded(
              child: FutureBuilder<List<ServiceModel>>(
                future: _servicesFuture,
                builder: (context, snapshot) {
                  // 1. Show loading indicator
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
                  } 
                  // 2. Show error message
                  else if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          // Display a user-friendly error message
                          'Failed to load services. Please check your connection or log in again.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: Colors.red),
                        ),
                      ),
                    );
                  } 
                  // 3. Data loaded successfully: Check if the filtered list is empty
                  else {
                    final displayedServices = _filteredServices;

                    if (displayedServices.isEmpty) {
                       // 4. Show the No Services Found widget (main basic page if list is empty)
                      return _buildNoServicesFound();
                    } else {
                      // 5. Display the list of filtered services
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        itemCount: displayedServices.length,
                        itemBuilder: (context, index) {
                          final service = displayedServices[index];
                          return ServiceCard(
                            service: service, // Pass the ServiceModel object
                            onToggleActive: (newValue) {
                              _onToggleActive(service.id, newValue);
                            },
                          );
                        },
                      );
                    }
                  }
                },
              ),
=======
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
            setState(() => _searchQuery = value.trim());
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
            Text('No Services Yet',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              'Start by adding your first service.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () async {
                final newService = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddServiceProviderScreen(
                      existingData: null, // ← ← ← التعديل فقط
                    ),
                  ),
                );

                if (newService != null) {
                  setState(() {
                    final service = Map<String, dynamic>.from(newService);
                    service['views'] = 0;
                    service['bookings'] = 0;
                    service['likes'] = 0;
                    service['createdAt'] = DateTime.now();
                    service['updatedAt'] = DateTime.now();

                    if (service['discount'] != null &&
                        service['discount'].toString().isNotEmpty) {
                      final p = service['price'] as double;
                      final d = double.tryParse(service['discount']) ?? 0;
                      service['finalPrice'] = p - (p * (d / 100));
                    } else {
                      service['finalPrice'] = service['price'];
                    }

                    _services.add(service);
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
              child: Text('Add Service',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
>>>>>>> main
            ),
          ],
        ),
      ),
      // Floating Action Button can be used for 'Add Service' as an alternative
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () { /* Add Service Navigation */ },
      //   child: const Icon(Icons.add),
      // ),
    );
  }
}

// ⭐️ MODIFIED: The ServiceCard now uses the corrected ServiceModel data
class ServiceCard extends StatelessWidget {
  final ServiceModel service; // The service data model
  final Function(bool) onToggleActive;

  const ServiceCard({
    Key? key,
    required this.service,
    required this.onToggleActive,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    // ⭐️ Use data directly from the ServiceModel
    final isActive = service.isActive;
    // Ensure rating is not null before converting to fixed(1)
    final rating = service.rating.toStringAsFixed(1); 
    final reviews = service.reviewsCount.toString();
    final price = service.price.toStringAsFixed(2);
    // ⭐️ NEW: Get the image URL
    final imageUrl = service.imageUrl; 
=======
    final isActive = service['isActive'] == true;
    final images = List<String>.from(service['images'] ?? []);

    final double originalPrice = (service['price'] ?? 0).toDouble();
    final String? discountStr = service['discount']?.toString();
    final bool hasDiscount = discountStr != null && discountStr.isNotEmpty;

    double finalPrice = originalPrice;

    if (hasDiscount) {
      final d = double.tryParse(discountStr!) ?? 0;
      finalPrice = originalPrice - (originalPrice * (d / 100));
    }
>>>>>>> main

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.only(bottom: 20),
      child: InkWell(
<<<<<<< HEAD
        onTap: () {
          // TODO: Implement navigation to service details/edit screen
=======
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ShowMoreProviderScreen(service: service),
            ),
          );

          if (result != null && result["edit"] == true) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditServiceProviderScreen(
                  existingData: service,
                ),
              ),
            );
          }
>>>>>>> main
        },
        borderRadius: BorderRadius.circular(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
<<<<<<< HEAD
            // Image Placeholder (or actual image loading)
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                // ⭐️ NEW: Use NetworkImage if imageUrl is available
                image: imageUrl != null && imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null, // No background image if no URL
=======
            if (images.isNotEmpty)
              Stack(
                children: [
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
                  ),
                  if (hasDiscount)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "-${discountStr!.trim()}%",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                ],
              )
            else
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
                child: Container(
                  height: 140,
                  color: Colors.grey.shade100,
                  child: Center(
                    child: Icon(Icons.image_outlined,
                        color: Colors.grey.shade400, size: 40),
                  ),
                ),
>>>>>>> main
              ),
              alignment: Alignment.center,
              // Display placeholder icon only if no image is available
              child: imageUrl == null || imageUrl.isEmpty
                  ? const Icon(Icons.image, size: 50, color: Colors.grey)
                  : null, // Don't show icon if image is loaded
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name, // Now correctly mapped to serviceName
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                  ),
                  // ⭐️ REMOVED: Removed the description text block as requested
                  
                  const SizedBox(height: 12), 
                  // Stats Chips (Rating, Reviews, Price)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatChip(icon: Icons.star, value: rating),
                      _StatChip(icon: Icons.comment, value: reviews),
                      _StatChip(icon: Icons.money, value: '\$$price'),
                    ],
                  ),
                  const Divider(height: 30),
                  // Active/Inactive Toggle
                  Row(
                    children: [
<<<<<<< HEAD
                      Text(
                        'Status:',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: kTextColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isActive ? 'Active' : 'Inactive',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.green.shade700 : Colors.red.shade700,
                        ),
=======
                      Expanded(
                        child: Text(
                          service['name'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (hasDiscount)
                            Text(
                              "₪${originalPrice.toStringAsFixed(0)}",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                              ),
                            ),
                          Text(
                            "₪${finalPrice.toStringAsFixed(0)}",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: hasDiscount
                                  ? Colors.redAccent
                                  : kPrimaryColor,
                            ),
                          ),
                        ],
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
                          value: '${service['views'] ?? 0}'),
                      const SizedBox(width: 6),
                      _StatChip(
                          icon: Icons.calendar_month_outlined,
                          value: '${service['bookings'] ?? 0}'),
                      const SizedBox(width: 6),
                      _StatChip(
                          icon: Icons.favorite_border,
                          value: '${service['likes'] ?? 0}'),
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
                        label: Text('Edit',
                            style: GoogleFonts.poppins(
                                fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: onDelete,
                        child: Text('Delete',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.red,
                                fontWeight: FontWeight.w500)),
>>>>>>> main
                      ),
                      const Spacer(),
                      Text('Visible',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.grey.shade700)),
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
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}