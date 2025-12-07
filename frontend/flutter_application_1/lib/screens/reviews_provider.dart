// lib/screens/reviews_provider.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Core colors – keep consistent with the rest of the app
const Color kPrimaryColor = Color.fromARGB(215, 20, 20, 215);
const Color kTextColor = Colors.black;
const Color kBackgroundColor = Colors.white;

/// Review model
class ProviderReview {
  final String id;
  final String customerName;
  final String? serviceName;
  final int rating; // 1–5 فقط
  final String comment;
  final DateTime createdAt;

  ProviderReview({
    required this.id,
    required this.customerName,
    this.serviceName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });
}

/// Sorting options
enum ReviewSortOption {
  newest,
  oldest,
  highestRating,
  lowestRating,
}

/// Repository / data source – connect this to your backend / API later
class ReviewsRepository {
  static Future<List<ProviderReview>> fetchReviewsForProvider(
    String providerId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 400));
    // TODO: Replace with real implementation:
    //  - Call your REST API or Firestore here
    //  - Map response to List<ProviderReview>
    return [];
  }
}

/// Main screen
class ReviewsProviderScreen extends StatefulWidget {
  final String? providerId;

  const ReviewsProviderScreen({Key? key, this.providerId}) : super(key: key);

  @override
  State<ReviewsProviderScreen> createState() => _ReviewsProviderScreenState();
}

class _ReviewsProviderScreenState extends State<ReviewsProviderScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  List<ProviderReview> _reviews = [];

  ReviewSortOption _sortOption = ReviewSortOption.newest;
  int? _minRatingFilter; // null = all, 3/4/5 => filter

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ReviewsRepository.fetchReviewsForProvider(
        widget.providerId ?? 'provider-id',
      );
      setState(() {
        _reviews = data;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load reviews.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ====== derived values ======

  List<ProviderReview> get _visibleReviews {
    List<ProviderReview> list = List<ProviderReview>.from(_reviews);

    // Filter by minimum rating
    if (_minRatingFilter != null) {
      list = list.where((r) => r.rating >= _minRatingFilter!).toList();
    }

    // Sort
    list.sort((a, b) {
      switch (_sortOption) {
        case ReviewSortOption.newest:
          return b.createdAt.compareTo(a.createdAt);
        case ReviewSortOption.oldest:
          return a.createdAt.compareTo(b.createdAt);
        case ReviewSortOption.highestRating:
          final cmp = b.rating.compareTo(a.rating);
          if (cmp != 0) return cmp;
          return b.createdAt.compareTo(a.createdAt);
        case ReviewSortOption.lowestRating:
          final cmp = a.rating.compareTo(b.rating);
          if (cmp != 0) return cmp;
          return a.createdAt.compareTo(b.createdAt);
      }
    });

    return list;
  }

  double get _averageRating {
    if (_reviews.isEmpty) return 0;
    final sum = _reviews.fold<double>(0, (acc, r) => acc + r.rating);
    return sum / _reviews.length;
  }

  int get _reviewsCount => _reviews.length;

  // ====== helpers ======

  void _setSortOption(ReviewSortOption option) {
    setState(() {
      _sortOption = option;
    });
  }

  void _setRatingFilter(int? minRating) {
    setState(() {
      _minRatingFilter = minRating;
    });
  }

  String _sortLabel(ReviewSortOption option) {
    switch (option) {
      case ReviewSortOption.newest:
        return "Newest";
      case ReviewSortOption.oldest:
        return "Oldest";
      case ReviewSortOption.highestRating:
        return "Highest rating";
      case ReviewSortOption.lowestRating:
        return "Lowest rating";
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleReviews;

    return SafeArea(
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          backgroundColor: kBackgroundColor,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: kTextColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Reviews',
            style: GoogleFonts.poppins(
              color: kTextColor,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: _isLoading
            ? const _LoadingState()
            : _errorMessage != null
                ? _ErrorState(onRetry: _loadReviews)
                : _reviews.isEmpty
                    ? const _EmptyState()
                    : Column(
                        children: [
                          _SummaryHeader(
                            averageRating: _averageRating,
                            totalReviews: _reviewsCount,
                          ),
                          _FiltersBar(
                            currentSort: _sortOption,
                            sortLabel: _sortLabel,
                            onSortChanged: _setSortOption,
                            minRatingFilter: _minRatingFilter,
                            onRatingFilterChanged: _setRatingFilter,
                          ),
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: _loadReviews,
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                itemCount: visible.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final review = visible[index];
                                  return _ReviewCard(review: review);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }
}

/// Top summary: average rating + total
class _SummaryHeader extends StatelessWidget {
  final double averageRating;
  final int totalReviews;

  const _SummaryHeader({
    Key? key,
    required this.averageRating,
    required this.totalReviews,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final rounded = averageRating.toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F4FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.star_rounded,
              color: kPrimaryColor,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$rounded / 5',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: kTextColor,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _StarRow(rating: averageRating, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '$totalReviews reviews',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Sort + filter bar
class _FiltersBar extends StatelessWidget {
  final ReviewSortOption currentSort;
  final String Function(ReviewSortOption) sortLabel;
  final ValueChanged<ReviewSortOption> onSortChanged;

  final int? minRatingFilter;
  final ValueChanged<int?> onRatingFilterChanged;

  const _FiltersBar({
    Key? key,
    required this.currentSort,
    required this.sortLabel,
    required this.onSortChanged,
    required this.minRatingFilter,
    required this.onRatingFilterChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16.0).copyWith(bottom: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<ReviewSortOption>(
                      value: currentSort,
                      isDense: true,
                      icon: const Icon(Icons.expand_more_rounded),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: kTextColor,
                      ),
                      onChanged: (value) {
                        if (value != null) onSortChanged(value);
                      },
                      items: ReviewSortOption.values.map((option) {
                        return DropdownMenuItem(
                          value: option,
                          child: Text(sortLabel(option)),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Filter:',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 4),
              _RatingFilterChip(
                label: 'All',
                selected: minRatingFilter == null,
                onTap: () => onRatingFilterChanged(null),
              ),
              _RatingFilterChip(
                label: '3+',
                selected: minRatingFilter == 3,
                onTap: () => onRatingFilterChanged(3),
              ),
              _RatingFilterChip(
                label: '4+',
                selected: minRatingFilter == 4,
                onTap: () => onRatingFilterChanged(4),
              ),
              _RatingFilterChip(
                label: '5★',
                selected: minRatingFilter == 5,
                onTap: () => onRatingFilterChanged(5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RatingFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RatingFilterChip({
    Key? key,
    required this.label,
    required this.selected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color:
                selected ? kPrimaryColor.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? kPrimaryColor : Colors.grey.shade400,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: selected ? kPrimaryColor : Colors.grey.shade800,
            ),
          ),
        ),
      ),
    );
  }
}

/// Single review card
class _ReviewCard extends StatelessWidget {
  final ProviderReview review;

  const _ReviewCard({Key? key, required this.review}) : super(key: key);

  String _formatDate(DateTime time) {
    final day = time.day.toString().padLeft(2, '0');
    final month = time.month.toString().padLeft(2, '0');
    final year = time.year.toString();
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final dateText = _formatDate(review.createdAt);
    final initials = review.customerName.isNotEmpty
        ? review.customerName.trim()[0].toUpperCase()
        : '?';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + name + date
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: kPrimaryColor.withOpacity(0.12),
                child: Text(
                  initials,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: kPrimaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _StarRow(rating: review.rating.toDouble(), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          review.rating.toString(), // بدون كسور
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                dateText,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.comment,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple star row widget (يقبل double لكنه يرسم حسب القيمة)
class _StarRow extends StatelessWidget {
  final double rating; // 0–5
  final double size;

  const _StarRow({Key? key, required this.rating, this.size = 18})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fullStars = rating.floor();
    final hasHalf = (rating - fullStars) >= 0.5;
    final total = 5;

    List<Widget> stars = [];
    for (int i = 0; i < total; i++) {
      IconData icon;
      if (i < fullStars) {
        icon = Icons.star_rounded;
      } else if (i == fullStars && hasHalf) {
        icon = Icons.star_half_rounded;
      } else {
        icon = Icons.star_border_rounded;
      }
      stars.add(Icon(
        icon,
        size: size,
        color: kPrimaryColor,
      ));
    }

    return Row(children: stars);
  }
}

/// Loading state
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            strokeWidth: 2.5,
            color: kPrimaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading reviews...',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.reviews_outlined,
              size: 64,
              color: kPrimaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When customers start rating your services,\nyou will see their feedback here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error state
class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({Key? key, required this.onRetry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 52,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn’t load your reviews.\nPlease try again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
