import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import '../models/review.dart';
import '../widgets/review_card.dart';
import '../../../services/admin_service/admin_service.dart';
import '../../../services/socket_service.dart';
import 'admin_chat_screen.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  String _filter = 'all';
  List<Review> _reviews = [];
  bool _isLoading = true;
  StreamSubscription? _reviewSubscription;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
    _setupRealtimeUpdates();
  }

  @override
  void dispose() {
    _reviewSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchReviews() async {
    try {
      setState(() => _isLoading = true);
      final reviewsData = await AdminService.getAllReviews();
      final allReviews = (reviewsData['reviews'] ?? reviewsData['data'] ?? []) as List;
      
      if (mounted) {
        setState(() {
          _reviews = allReviews.map((r) => Review.fromJson(r)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching reviews: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setupRealtimeUpdates() {
    _reviewSubscription = SocketService.reviewStream.listen((data) {
      print('📨 New review received in real-time');
      _fetchReviews();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

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

  List<Review> _applyFilter(List<Review> source, String filter) {
    if (filter == 'all') return List<Review>.from(source);
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReviewReplyBottomSheet(
        review: review,
        onMessageSent: (chatId, recipientName) {
          // Navigate to chat screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminChatScreen(
                chatId: chatId,
                participantName: recipientName,
              ),
            ),
          );
        },
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

/// Bottom sheet for replying to a review - allows selecting recipient
class _ReviewReplyBottomSheet extends StatefulWidget {
  final dynamic review;
  final Function(String chatId, String recipientName) onMessageSent;

  const _ReviewReplyBottomSheet({
    required this.review,
    required this.onMessageSent,
  });

  @override
  State<_ReviewReplyBottomSheet> createState() => _ReviewReplyBottomSheetState();
}

class _ReviewReplyBottomSheetState extends State<_ReviewReplyBottomSheet> {
  String _selectedRecipient = 'user'; // 'user' or 'provider'
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _onRecipientChanged(String recipient) {
    if (_selectedRecipient != recipient) {
      setState(() {
        _selectedRecipient = recipient;
        _messageController.clear(); // ✅ Clear message when switching recipient
      });
    }
  }

  void _showPopupMessage({
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    bool isError = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: backgroundColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isError ? 'Oops!' : 'Success!',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: kTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isError ? Colors.red : kPrimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'OK',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
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

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      _showPopupMessage(
        message: 'Please write a message before sending.',
        icon: LucideIcons.messageSquare,
        backgroundColor: Colors.orange,
        iconColor: Colors.orange,
        isError: true,
      );
      return;
    }

    final recipientId = _selectedRecipient == 'user' 
        ? widget.review.userId 
        : widget.review.providerId;
    
    final recipientType = _selectedRecipient == 'user' ? 'Customer' : 'Provider';
    
    if (recipientId == null || recipientId.isEmpty) {
      _showPopupMessage(
        message: '$recipientType information is not available for this review. The review data may be incomplete.',
        icon: LucideIcons.userX,
        backgroundColor: Colors.red,
        iconColor: Colors.red,
        isError: true,
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final chatData = await AdminService.startChatWithUser(
        recipientId,
        _messageController.text.trim(),
      );
      
      final recipientName = _selectedRecipient == 'user' 
          ? widget.review.userName 
          : (widget.review.providerName ?? 'Provider');

      if (mounted) {
        setState(() => _isSending = false);
        _messageController.clear(); // Clear message after sending
        
        // Show success popup (stays in bottom sheet)
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (dialogContext) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kSuccessColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.checkCircle,
                      size: 40,
                      color: kSuccessColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Message Sent!',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: kTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your message to $recipientName has been sent successfully.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext); // Just close the dialog, stay in bottom sheet
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'OK',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
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
    } catch (e) {
      print('❌ Error sending message: $e');
      if (mounted) {
        setState(() => _isSending = false);
        _showPopupMessage(
          message: 'Failed to send message. Please try again later.',
          icon: LucideIcons.alertCircle,
          backgroundColor: Colors.red,
          iconColor: Colors.red,
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Reply to Review',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: kTextColor,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: Icon(LucideIcons.x, color: Colors.grey[600], size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Review Quote
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.quote, size: 16, color: kPrimaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Review by ${widget.review.userName}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kPrimaryColor,
                          ),
                        ),
                        const Spacer(),
                        // Rating stars
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < widget.review.rating 
                                  ? LucideIcons.star 
                                  : LucideIcons.star,
                              size: 12,
                              color: index < widget.review.rating 
                                  ? Colors.amber 
                                  : Colors.grey[300],
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.review.text,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Service: ${widget.review.serviceName}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Recipient Selection
              Text(
                'Send message to:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: kTextColor,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _RecipientOption(
                      icon: LucideIcons.user,
                      label: 'Customer',
                      sublabel: widget.review.userName,
                      isSelected: _selectedRecipient == 'user',
                      isAvailable: widget.review.userId != null && widget.review.userId!.isNotEmpty,
                      onTap: () => _onRecipientChanged('user'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RecipientOption(
                      icon: LucideIcons.building2,
                      label: 'Provider',
                      sublabel: widget.review.providerName ?? 'Service Owner',
                      isSelected: _selectedRecipient == 'provider',
                      isAvailable: widget.review.providerId != null && widget.review.providerId!.isNotEmpty,
                      onTap: () => _onRecipientChanged('provider'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Message Input
              Text(
                'Your message:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: kTextColor,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _messageController,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  hintText: _selectedRecipient == 'user'
                      ? 'Write a message to the customer about their review...'
                      : 'Write a message to the service provider...',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: kPrimaryColor, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSending ? null : () => Navigator.pop(context),
                      icon: const Icon(LucideIcons.x, size: 18),
                      label: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSending ? null : _sendMessage,
                      icon: _isSending
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(LucideIcons.send, size: 18),
                      label: Text(
                        _isSending ? 'Sending...' : 'Send Message',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        disabledBackgroundColor: kPrimaryColor.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Recipient option card
class _RecipientOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final bool isSelected;
  final bool isAvailable;
  final VoidCallback onTap;

  const _RecipientOption({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.isSelected,
    this.isAvailable = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor.withOpacity(0.08) : Colors.grey[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? kPrimaryColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? kPrimaryColor.withOpacity(0.15) : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? kPrimaryColor : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? kPrimaryColor : kTextColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
            if (!isAvailable) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Not Available',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[700],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
