// lib/screens/services_provider.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
// ⭐️ NEW: Import the Service Layer
import 'package:flutter_application_1/services/service_service.dart';

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
  // ⭐️ MODIFIED: Now holds the Future for the API call
  late Future<List<ServiceModel>> _servicesFuture;
  
  // ⭐️ NEW: List to store the fetched data (used for filtering/sorting)
  List<ServiceModel> _servicesList = [];

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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // ⭐️ NEW: Start fetching services when the screen initializes
    _servicesFuture = _fetchServices(); 
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

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
                context,
                MaterialPageRoute(
                  builder: (_) => const AddServiceProviderScreen(),
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
                  ),
                ],
              ),
            ),

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
    // ⭐️ Use data directly from the ServiceModel
    final isActive = service.isActive;
    // Ensure rating is not null before converting to fixed(1)
    final rating = service.rating.toStringAsFixed(1); 
    final reviews = service.reviewsCount.toString();
    final price = service.price.toStringAsFixed(2);
    // ⭐️ NEW: Get the image URL
    final imageUrl = service.imageUrl; 

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: () {
          // TODO: Implement navigation to service details/edit screen
        },
        borderRadius: BorderRadius.circular(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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