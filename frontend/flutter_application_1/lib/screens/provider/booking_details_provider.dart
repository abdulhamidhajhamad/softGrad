// lib/screens/provider/booking_details_provider.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// 📋 Booking Details Screen for Provider
/// Shows comprehensive details of a booking with modern design
class BookingDetailsProvider extends StatelessWidget {
  final Map<String, dynamic> booking;

  const BookingDetailsProvider({
    super.key,
    required this.booking,
  });

  // 🎨 Theme Colors - Modern Purple
  static const Color kPrimaryColor = Color(0xFF6C63FF);
  static const Color kPrimaryLight = Color(0xFFE8E6FF);
  static const Color kSuccessColor = Color(0xFF10B981);
  static const Color kDangerColor = Color(0xFFEF4444);
  static const Color kWarningColor = Color(0xFFF59E0B);
  static const Color kBackgroundColor = Color(0xFFF8F9FC);
  static const Color kTextPrimary = Color(0xFF1A1D29);
  static const Color kTextSecondary = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1100;
        final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1100;

        if (isDesktop || isTablet) {
          return _buildWebLayout(context, isDesktop);
        }
        return _buildMobileLayout(context);
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 🌐 WEB LAYOUT - Modern Dashboard Style
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildWebLayout(BuildContext context, bool isDesktop) {
    final serviceName = booking['serviceName'] ?? 'Service';
    final serviceImage = booking['serviceImage'];
    final clientName = booking['clientName'] ?? 'Unknown Client';
    final status = booking['status'] ?? 'confirmed';
    final price = booking['price'];
    final bookingDate = booking['bookingDate'];

    final clientLocation = booking['clientLocation'];
    final hasClientLocation = clientLocation != null && 
        (clientLocation['address'] != null || clientLocation['city'] != null);

    final bookingDescription = booking['bookingDescription'];
    final hasDescription = bookingDescription != null && 
        bookingDescription.toString().trim().isNotEmpty;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Column(
        children: [
          // Modern Top Bar
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: kBackgroundColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.arrowLeft, size: 18, color: kTextSecondary),
                          const SizedBox(width: 8),
                          Text('Back', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: kTextSecondary)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kPrimaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.calendarCheck, size: 20, color: kPrimaryColor),
                ),
                const SizedBox(width: 14),
                Text(
                  'Booking Details',
                  style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: kTextPrimary),
                ),
                const Spacer(),
                _buildWebStatusBadge(status),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 24, vertical: 32),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 1100 : double.infinity),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column - Main Details
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            // Service Hero Card
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Service Image
                                  Container(
                                    height: 200,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                      gradient: serviceImage == null
                                          ? LinearGradient(colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.7)])
                                          : null,
                                      image: serviceImage != null
                                          ? DecorationImage(image: NetworkImage(serviceImage), fit: BoxFit.cover)
                                          : null,
                                    ),
                                    child: serviceImage == null
                                        ? Center(child: Icon(LucideIcons.image, size: 48, color: Colors.white.withOpacity(0.5)))
                                        : null,
                                  ),
                                  // Service Info
                                  Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(serviceName, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: kTextPrimary)),
                                        if (bookingDate != null) ...[
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              const Icon(LucideIcons.calendar, size: 18, color: kPrimaryColor),
                                              const SizedBox(width: 8),
                                              Text(_formatDate(bookingDate), style: GoogleFonts.poppins(fontSize: 15, color: kTextSecondary)),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Client Info
                            _buildWebInfoSection(
                              'Client Information',
                              LucideIcons.user,
                              [
                                _buildWebInfoRow(LucideIcons.user, 'Client Name', clientName),
                              ],
                            ),

                            if (hasClientLocation) ...[
                              const SizedBox(height: 20),
                              _buildWebLocationCard(clientLocation),
                            ],

                            if (hasDescription) ...[
                              const SizedBox(height: 20),
                              _buildWebInfoSection(
                                'Booking Description',
                                LucideIcons.fileText,
                                [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(bookingDescription.toString(), style: GoogleFonts.poppins(fontSize: 14, color: kTextSecondary, height: 1.6)),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Right Column - Price & Actions
                      SizedBox(
                        width: isDesktop ? 350 : 280,
                        child: Column(
                          children: [
                            // Price Card
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.85)]),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: kPrimaryColor.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 8))],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                                        child: const Icon(LucideIcons.wallet, size: 20, color: Colors.white),
                                      ),
                                      const SizedBox(width: 12),
                                      Text('Total Price', style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    price != null ? '₪${price.toStringAsFixed(0)}' : 'N/A',
                                    style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Status Card
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(status).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(_getStatusIcon(status), color: _getStatusColor(status), size: 24),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Status', style: GoogleFonts.poppins(fontSize: 12, color: kTextSecondary)),
                                            Text(_getStatusText(status), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: _getStatusColor(status))),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Timestamps
                            _buildWebInfoSection(
                              'Timestamps',
                              LucideIcons.clock,
                              [
                                if (booking['createdAt'] != null) _buildWebInfoRow(LucideIcons.plus, 'Created', _formatFullDate(booking['createdAt'])),
                                if (booking['updatedAt'] != null) _buildWebInfoRow(LucideIcons.edit, 'Updated', _formatFullDate(booking['updatedAt'])),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebStatusBadge(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(status), size: 16, color: color),
          const SizedBox(width: 8),
          Text(_getStatusText(status), style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildWebInfoSection(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, size: 18, color: kPrimaryColor),
                ),
                const SizedBox(width: 12),
                Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: kTextPrimary)),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildWebInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: kTextSecondary),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.poppins(fontSize: 13, color: kTextSecondary)),
          const Spacer(),
          Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: kTextPrimary)),
        ],
      ),
    );
  }

  Widget _buildWebLocationCard(Map<String, dynamic> location) {
    final address = location['address'] ?? 'N/A';
    final city = location['city'] ?? 'N/A';
    final description = location['locationDescription'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(LucideIcons.mapPin, size: 18, color: kPrimaryColor),
                ),
                const SizedBox(width: 12),
                Text('Client Location', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: kTextPrimary)),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildWebInfoRow(LucideIcons.home, 'Address', address),
          _buildWebInfoRow(LucideIcons.building, 'City', city),
          if (description.isNotEmpty) _buildWebInfoRow(LucideIcons.info, 'Notes', description),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEEE, MMM d, yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatFullDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy • h:mm a').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 📱 MOBILE LAYOUT
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout(BuildContext context) {
    // 🆕 التحقق من وجود موقع العميل
    final clientLocation = booking['clientLocation'];
    final hasClientLocation = clientLocation != null && 
        (clientLocation['address'] != null || clientLocation['city'] != null);

    // 🆕 التحقق من وجود وصف الحجز
    final bookingDescription = booking['bookingDescription'];
    final hasDescription = bookingDescription != null && 
        bookingDescription.toString().trim().isNotEmpty;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 20),
                  _buildClientInfoCard(),
                  const SizedBox(height: 20),
                  // 🆕 عرض موقع العميل إذا كان متوفراً
                  if (hasClientLocation) ...[
                    _buildClientLocationCard(),
                    const SizedBox(height: 20),
                  ],
                  // 🆕 عرض وصف الحجز إذا كان متوفراً
                  if (hasDescription) ...[
                    _buildBookingDescriptionCard(),
                    const SizedBox(height: 20),
                  ],
                  _buildBookingDetailsCard(),
                  const SizedBox(height: 20),
                  _buildPriceCard(),
                  const SizedBox(height: 20),
                  _buildTimestampCard(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 Sliver App Bar with gradient
  Widget _buildSliverAppBar(BuildContext context) {
    final serviceName = booking['serviceName'] ?? 'Booking Details';
    final serviceImage = booking['serviceImage'];
    
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: kPrimaryColor,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // 🖼️ صورة الخدمة أو Gradient
            if (serviceImage != null)
              Image.network(
                serviceImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        kPrimaryColor,
                        kPrimaryColor.withOpacity(0.8),
                        const Color(0xFF4F46E5),
                      ],
                    ),
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      kPrimaryColor,
                      kPrimaryColor.withOpacity(0.8),
                      const Color(0xFF4F46E5),
                    ],
                  ),
                ),
              ),
            // 🌑 Overlay for better text visibility
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.5),
                  ],
                ),
              ),
            ),
            // Background pattern
            Positioned(
              right: -50,
              top: -20,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          serviceName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
    );
  }

  /// 🟢 Status Card with icon
  Widget _buildStatusCard() {
    final status = booking['status'] ?? 'confirmed';
    final statusText = _getStatusText(status);
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(statusIcon, color: statusColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Booking Status',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status.toString().toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 👤 Client Information Card
  Widget _buildClientInfoCard() {
    final clientName = booking['clientName'] ?? 'Unknown Client';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
                child: Icon(Icons.person_outline, color: kPrimaryColor, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Client Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.badge_outlined,
            label: 'Client Name',
            value: clientName,
          ),
        ],
      ),
    );
  }

  /// � Client Location Card (للخدمات التي تذهب للعميل)
  Widget _buildClientLocationCard() {
    final clientLocation = booking['clientLocation'];
    final address = clientLocation?['address'] ?? 'N/A';
    final city = clientLocation?['city'] ?? 'N/A';
    final locationDescription = clientLocation?['locationDescription'] ?? ''; // 🆕

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: kPrimaryColor.withOpacity(0.2)),
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
                child: Icon(Icons.location_on_outlined, color: kPrimaryColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Client Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'You need to go to this location',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: kWarningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delivery_dining_rounded, color: kWarningColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Mobile',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: kWarningColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.location_city_outlined,
            label: 'City',
            value: city,
          ),
          const SizedBox(height: 14),
          _buildInfoRow(
            icon: Icons.home_outlined,
            label: 'Address',
            value: address,
          ),
          // 🆕 Location Description (Landmark)
          if (locationDescription.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildInfoRow(
              icon: Icons.place_outlined,
              label: 'Landmark',
              value: locationDescription,
            ),
          ],
          // 🆕 عرض الخريطة إذا كان العميل أدخل الموقع
          if (_hasMapLocation(clientLocation)) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            _buildMapPreview(clientLocation),
          ],
        ],
      ),
    );
  }

  /// 🗺️ التحقق من وجود إحداثيات الخريطة
  bool _hasMapLocation(Map<String, dynamic>? clientLocation) {
    if (clientLocation == null) return false;
    final lat = clientLocation['latitude'];
    final lng = clientLocation['longitude'];
    return lat != null && lng != null;
  }

  /// 🗺️ عرض الخريطة مع الدبوس الأحمر
  Widget _buildMapPreview(Map<String, dynamic>? clientLocation) {
    final lat = clientLocation?['latitude'] as double?;
    final lng = clientLocation?['longitude'] as double?;

    if (lat == null || lng == null) return const SizedBox.shrink();

    final position = LatLng(lat, lng);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.map_outlined, color: kPrimaryColor, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Pinned Location',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: kSuccessColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.gps_fixed_rounded, color: kSuccessColor, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'GPS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: kSuccessColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: kPrimaryColor.withOpacity(0.2), width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: position,
                  initialZoom: 15,
                  minZoom: 10,
                  maxZoom: 18,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none, // تعطيل التفاعل
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.flutter_application_1',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: position,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 📝 Booking Description Card (ملاحظات العميل)
  Widget _buildBookingDescriptionCard() {
    final description = booking['bookingDescription'] ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.message_outlined,
                  color: Color(0xFF8B5CF6),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Client Notes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Special requests from the client',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFF8B5CF6), size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Note',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📅 Booking Details Card
  Widget _buildBookingDetailsCard() {
    final bookingDate = booking['bookingDate'];
    final startHour = booking['startHour'];
    final endHour = booking['endHour'];
    final numberOfPeople = booking['numberOfPeople'];
    final isFullVenue = booking['isFullVenue'] ?? false;
    final bookingType = booking['bookingType'] ?? 'hourly';
    final companyName = booking['companyName'] ?? 'N/A';

    // Format date
    String formattedDate = 'N/A';
    if (bookingDate != null) {
      try {
        final date = DateTime.parse(bookingDate.toString());
        formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(date);
      } catch (e) {
        formattedDate = bookingDate.toString();
      }
    }

    // Format time range
    String timeRange = 'N/A';
    if (startHour != null && endHour != null) {
      final startFormatted = _formatHour(startHour);
      final endFormatted = _formatHour(endHour);
      final duration = endHour - startHour;
      timeRange = '$startFormatted - $endFormatted ($duration hours)';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
                  color: kWarningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.event_note_outlined, color: kWarningColor, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Booking Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.business_outlined,
            label: 'Company',
            value: companyName,
          ),
          const SizedBox(height: 14),
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Date',
            value: formattedDate,
          ),
          const SizedBox(height: 14),
          _buildInfoRow(
            icon: Icons.access_time_outlined,
            label: 'Time',
            value: timeRange,
          ),
          if (numberOfPeople != null) ...[
            const SizedBox(height: 14),
            _buildInfoRow(
              icon: Icons.group_outlined,
              label: 'Number of People',
              value: numberOfPeople.toString(),
            ),
          ],
          const SizedBox(height: 14),
          _buildInfoRow(
            icon: Icons.category_outlined,
            label: 'Booking Type',
            value: _formatBookingType(bookingType),
          ),
          if (isFullVenue) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.home_work_outlined, color: kPrimaryColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Full Venue Booking',
                    style: TextStyle(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 💰 Price Card
  Widget _buildPriceCard() {
    final price = booking['price'];
    String formattedPrice = 'N/A';
    if (price != null) {
      formattedPrice = '₪${price.toStringAsFixed(2)}';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kSuccessColor,
            kSuccessColor.withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kSuccessColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.attach_money_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Price',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedPrice,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'PAID',
              style: TextStyle(
                color: kSuccessColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🕐 Timestamp Card
  Widget _buildTimestampCard() {
    final createdAt = booking['createdAt'];
    String formattedCreatedAt = 'N/A';
    
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt.toString());
        formattedCreatedAt = DateFormat('MMM d, yyyy • h:mm a').format(date);
      } catch (e) {
        formattedCreatedAt = createdAt.toString();
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule_outlined, color: Colors.grey[500], size: 18),
          const SizedBox(width: 8),
          Text(
            'Booked on $formattedCreatedAt',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 📝 Helper: Info Row Widget
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[500], size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 🎨 Helper: Get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return kSuccessColor;
      case 'cancelled':
        return kDangerColor;
      case 'completed':
        return kPrimaryColor;
      default:
        return Colors.grey;
    }
  }

  /// 📝 Helper: Get status text
  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Confirmed';
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  /// 🎯 Helper: Get status icon
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'completed':
        return Icons.task_alt_outlined;
      default:
        return Icons.help_outline;
    }
  }

  /// 🕐 Helper: Format hour to readable string
  String _formatHour(int hour) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:00 $period';
  }

  /// 📦 Helper: Format booking type
  String _formatBookingType(String type) {
    switch (type.toLowerCase()) {
      case 'hourly':
        return 'Hourly Booking';
      case 'daily':
        return 'Daily Booking';
      case 'package':
        return 'Package Booking';
      default:
        return type;
    }
  }
}
