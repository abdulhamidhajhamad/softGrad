import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';
import '../widgets/review_card.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  String _filter = 'all';

  // Local mutable list so we can delete reviews in UI
  late final List<dynamic> _reviews;

  @override
  void initState() {
    super.initState();
    _reviews = List<dynamic>.from(mockReviews);
  }

  @override
  Widget build(BuildContext context) {
    final filteredReviews = _applyFilter(_reviews, _filter);

    final total = _reviews.length;
    final good = _reviews.where((r) => r.isPositive).length;
    final bad = total - good;

    // ✅ Force Poppins for ALL text in this screen (including ReviewCard)
    final baseTheme = Theme.of(context);
    final poppinsTheme = baseTheme.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(baseTheme.textTheme),
      primaryTextTheme:
          GoogleFonts.poppinsTextTheme(baseTheme.primaryTextTheme),
    );

    return Theme(
      data: poppinsTheme,
      child: DefaultTextStyle(
        style: GoogleFonts.poppins(
          textStyle: const TextStyle(
            color: kTextColor,
            fontSize: 14,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modern header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Reviews',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: kTextColor,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        _HeaderPill(
                          icon: LucideIcons.messageSquare,
                          label: '$total',
                          tooltip: 'Total',
                        ),
                        const SizedBox(width: 8),
                        _HeaderPill(
                          icon: LucideIcons.thumbsUp,
                          label: '$good',
                          tooltip: 'Good',
                        ),
                        const SizedBox(width: 8),
                        _HeaderPill(
                          icon: LucideIcons.thumbsDown,
                          label: '$bad',
                          tooltip: 'Bad',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage customer feedback, reply fast, and keep your page clean.',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _buildFilterChip(
                          label: 'All',
                          value: 'all',
                          icon: LucideIcons.list,
                        ),
                        const SizedBox(width: 10),
                        _buildFilterChip(
                          label: 'Good',
                          value: 'good',
                          icon: LucideIcons.thumbsUp,
                        ),
                        const SizedBox(width: 10),
                        _buildFilterChip(
                          label: 'Bad',
                          value: 'bad',
                          icon: LucideIcons.thumbsDown,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: filteredReviews.isEmpty
                    ? _EmptyState(
                        onReset: () => setState(() => _filter = 'all'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                        itemCount: filteredReviews.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final review = filteredReviews[index];

                          // Use stable key if you have review.id; otherwise fallback to hash
                          final key = ValueKey(review.hashCode);

                          return Dismissible(
                            key: key,
                            direction: DismissDirection.endToStart,
                            background: _SwipeDeleteBackground(),
                            confirmDismiss: (_) =>
                                _confirmDelete(context, review),
                            onDismissed: (_) => _deleteReview(context, review),
                            child: _ReviewWrapperCard(
                              child: ReviewCard(
                                review: review,
                                onReply: () =>
                                    _showReplyDialog(context, review),
                              ),
                              onDelete: () async {
                                final ok =
                                    await _confirmDelete(context, review);
                                if (ok == true) _deleteReview(context, review);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<dynamic> _applyFilter(List<dynamic> source, String filter) {
    if (filter == 'all') return List<dynamic>.from(source);
    if (filter == 'good') {
      return source.where((r) => r.isPositive).toList();
    }
    return source.where((r) => !r.isPositive).toList();
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _filter == value;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? kPrimaryColor : Colors.grey[300]!,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kPrimaryColor.withOpacity(0.22),
                    blurRadius: 26,
                    offset: const Offset(0, 14),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, dynamic review) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete review?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This will remove the review from your list.\n\n"${review.text}"',
          style: GoogleFonts.poppins(color: Colors.grey[700], height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteReview(BuildContext context, dynamic review) {
    final removedIndex = _reviews.indexOf(review);
    if (removedIndex == -1) return;

    setState(() => _reviews.removeAt(removedIndex));

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Review deleted', style: GoogleFonts.poppins()),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() => _reviews.insert(removedIndex, review));
          },
        ),
      ),
    );
  }

  void _showReplyDialog(BuildContext context, dynamic review) {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Reply to ${review.userName}',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.quote, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        review.text,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.35,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Write your reply...',
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(LucideIcons.x, size: 18),
                      label: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Reply sent successfully!',
                                style: GoogleFonts.poppins()),
                            backgroundColor: kSuccessColor,
                          ),
                        );
                      },
                      icon: const Icon(LucideIcons.send, size: 18),
                      label: Text(
                        'Send',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;

  const _HeaderPill({
    required this.icon,
    required this.label,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[700]),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeDeleteBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade600,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Icon(LucideIcons.trash2, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            'Delete',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewWrapperCard extends StatelessWidget {
  final Widget child;
  final VoidCallback onDelete;

  const _ReviewWrapperCard({
    required this.child,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.white,
          child: Stack(
            children: [
              child,
              Positioned(
                bottom: 12,
                right: 12,
                child: IconButton(
                  tooltip: 'Delete review',
                  onPressed: onDelete,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Icon(
                      LucideIcons.trash2,
                      size: 18,
                      color: Colors.red.shade600,
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

class _EmptyState extends StatelessWidget {
  final VoidCallback onReset;
  const _EmptyState({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(LucideIcons.inbox, color: Colors.grey[700]),
            ),
            const SizedBox(height: 14),
            Text(
              'No reviews here',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try switching filters or wait for new feedback.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onReset,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Reset filter',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
