// lib/screens/pending_reviews_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/services/user_service/review_service.dart';
import 'package:flutter_application_1/models/review_model.dart';
import 'package:flutter_application_1/screens/review_screen/write_review_screen.dart';

const Color kBrandBlue = Color.fromARGB(215, 20, 20, 215);
const Color kBgColor = Color(0xFFF6F7FB);
const Color kTextPrimary = Color(0xFF0B1220);
const Color kTextMuted = Color(0xFF6B7280);

class PendingReviewsScreen extends StatefulWidget {
  const PendingReviewsScreen({Key? key}) : super(key: key);

  @override
  State<PendingReviewsScreen> createState() => _PendingReviewsScreenState();
}

class _PendingReviewsScreenState extends State<PendingReviewsScreen> {
  List<PendingReview> _pendingReviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingReviews();
  }

  Future<void> _loadPendingReviews() async {
    setState(() => _isLoading = true);

    try {
      final reviews = await ReviewService.getPendingReviews();
      setState(() {
        _pendingReviews = reviews;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading pending reviews: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pending Reviews',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: kTextPrimary,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kBrandBlue))
          : _pendingReviews.isEmpty
              ? _buildEmptyState()
              : _buildPendingList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox,
            size: 80,
            color: kTextMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No pending reviews',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "You're all caught up!",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: kTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingReviews.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final review = _pendingReviews[index];
        return _buildPendingCard(review);
      },
    );
  }

  Widget _buildPendingCard(PendingReview review) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Service Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: review.serviceImage != null
                  ? Image.network(
                      review.serviceImage!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
            const SizedBox(width: 16),

            // Service Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.serviceName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: kTextPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    review.companyName,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: kTextMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: kTextMuted),
                      const SizedBox(width: 6),
                      Text(
                        '${review.bookingDate.day}/${review.bookingDate.month}/${review.bookingDate.year}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: kTextMuted,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        review.daysAgo,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kBrandBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WriteReviewScreen(
                              bookingId: review.bookingId,
                              serviceId: review.serviceId,
                              serviceName: review.serviceName,
                              companyName: review.companyName,
                            ),
                          ),
                        ).then((_) => _loadPendingReviews());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBrandBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Write Review',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

  Widget _buildPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.image, size: 40, color: Colors.grey.shade400),
    );
  }
}