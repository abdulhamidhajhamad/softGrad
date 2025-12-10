// lib/screens/notifications_provider.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// تأكد من استيراد ملف السيرفس الجديد بشكل صحيح
import 'package:flutter_application_1/services/notification_provider_service.dart';
/// Core colors – keep in sync with your app theme
const Color kPrimaryColor = Color.fromARGB(215, 20, 20, 215);
const Color kTextColor = Colors.black;
const Color kBackgroundColor = Colors.white;

/// Different kinds of notifications that a provider can receive.
enum NotificationType {
  message, // New message from customer
  booking, // New booking / update
  favorite, // Customer added service to favorites
  review, // New review / rating
  system, // System or app-level info
}

/// Model for a single notification.
class ProviderNotification {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final NotificationType type;

  bool isRead;

  ProviderNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.type,
    this.isRead = false,
  });
}

/// Main notifications screen for providers.
class NotificationsProviderScreen extends StatefulWidget {
  final String? providerId;

  const NotificationsProviderScreen({Key? key, this.providerId})
      : super(key: key);

  @override
  State<NotificationsProviderScreen> createState() =>
      _NotificationsProviderScreenState();
}

class _NotificationsProviderScreenState
    extends State<NotificationsProviderScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  List<ProviderNotification> _notifications = [];
  bool _showUnreadOnly = false;

  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. جلب الإشعارات من الباك إند
      final data = await NotificationProviderService.fetchNotifications();
      
      setState(() {
        _notifications = data;
        _isLoading = false;
      });

      // 2. حسب طلبك: بمجرد فتح الصفحة والنجاح في الجلب، يتم تعليم الكل كمقروء
      // نقوم بذلك في الخلفية
      if (data.any((n) => !n.isRead)) {
         // تحديث الواجهة محلياً أولاً لتبدو سريعة
         setState(() {
           for (var n in _notifications) {
             n.isRead = true;
           }
         });
         // إرسال الطلب للسيرفر
         await NotificationProviderService.markAllAsRead();
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load notifications.';
          _isLoading = false;
        });
      }
    }
  }

  List<ProviderNotification> get _visibleNotifications {
    if (_showUnreadOnly) {
      return _notifications.where((n) => !n.isRead).toList();
    }
    return _notifications;
  }

  bool get _hasUnread =>
      _notifications.any((notification) => !notification.isRead);

  void _enterSelectionMode(String id) {
    setState(() {
      _selectionMode = true;
      _selectedIds
        ..clear()
        ..add(id);
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _selectionMode = false;
        }
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _markSelectedAsRead() async {
    // بما أننا قمنا بتتعليم الكل كمقروء عند الدخول، هذه الدالة قد تكون إضافية
    // لكن سنبقي المنطق سليماً للواجهة
    final ids = _selectedIds.toList();
    setState(() {
      for (final n in _notifications) {
        if (ids.contains(n.id)) {
          n.isRead = true;
        }
      }
    });
    // ملاحظة: الـ Backend يدعم حالياً markAllAsRead فقط،
    // يمكنك إضافة endpoint لتعليم مجموعة محددة لاحقاً إذا أردت
    // حالياً سنكتفي بالتحديث المحلي لأن الصفحة تعلم الكل كمقروء تلقائياً
    _exitSelectionMode();
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
    await NotificationProviderService.markAllAsRead();
  }

  Future<void> _deleteSelected() async {
    final ids = _selectedIds.toList();
    
    // التحديث المتفائل للواجهة
    setState(() {
      _notifications.removeWhere((n) => ids.contains(n.id));
    });
    _exitSelectionMode();

    // إرسال طلبات الحذف للسيرفر
    for (String id in ids) {
      try {
        await NotificationProviderService.deleteNotification(id);
      } catch (e) {
        // يمكن إضافة معالجة خطأ هنا إذا لزم الأمر
        print("Error deleting $id");
      }
    }
  }

  Future<void> _deleteSingle(String id) async {
    // التحديث المتفائل للواجهة
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
    // إرسال طلب الحذف
    await NotificationProviderService.deleteNotification(id);
  }

  void _toggleFilterUnread() {
    setState(() {
      _showUnreadOnly = !_showUnreadOnly;
    });
  }

  PreferredSizeWidget _buildAppBar() {
    if (_selectionMode) {
      // Selection mode app bar
      return AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: kTextColor),
          onPressed: _exitSelectionMode,
        ),
        title: Text(
          '${_selectedIds.length} selected',
          style: GoogleFonts.poppins(
            color: kTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Mark as read',
            onPressed: _markSelectedAsRead,
            icon: const Icon(Icons.mark_email_read_outlined, color: kTextColor),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: _deleteSelected,
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          ),
        ],
      );
    }

    // Normal app bar
    return AppBar(
      backgroundColor: kBackgroundColor,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: kTextColor),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Notifications',
        style: GoogleFonts.poppins(
          color: kTextColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        if (_hasUnread)
          IconButton(
            tooltip: 'Mark all as read',
            onPressed: _markAllAsRead,
            icon: const Icon(Icons.done_all_rounded, color: kTextColor),
          ),
        IconButton(
          tooltip: _showUnreadOnly ? 'Show all' : 'Show unread only',
          onPressed: _toggleFilterUnread,
          icon: Icon(
            _showUnreadOnly
                ? Icons.filter_alt_off_outlined
                : Icons.filter_alt_outlined,
            color: kTextColor,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleNotifications;

    return SafeArea(
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: _buildAppBar(),
        body: _isLoading
            ? const _LoadingState()
            : _errorMessage != null
                ? _ErrorState(onRetry: _loadNotifications)
                : visible.isEmpty
                    ? const _EmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadNotifications,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          itemCount: visible.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final notification = visible[index];
                            final isSelected =
                                _selectedIds.contains(notification.id);

                            return Dismissible(
                              key: ValueKey(notification.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                              ),
                              onDismissed: (_) =>
                                  _deleteSingle(notification.id),
                              child: _NotificationTile(
                                notification: notification,
                                isSelected: isSelected,
                                selectionMode: _selectionMode,
                                onTap: () {
                                  if (_selectionMode) {
                                    _toggleSelection(notification.id);
                                    return;
                                  }
                                  setState(() {
                                    notification.isRead = true;
                                  });
                                  // TODO: Navigate based on notification.type
                                },
                                onLongPress: () {
                                  if (!_selectionMode) {
                                    _enterSelectionMode(notification.id);
                                  } else {
                                    _toggleSelection(notification.id);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}

/// Single notification tile with modern styling.
class _NotificationTile extends StatelessWidget {
  final ProviderNotification notification;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _NotificationTile({
    Key? key,
    required this.notification,
    required this.isSelected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  IconData _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return Icons.chat_bubble_outline;
      case NotificationType.booking:
        return Icons.event_available_outlined;
      case NotificationType.favorite:
        return Icons.favorite_border;
      case NotificationType.review:
        return Icons.star_border;
      case NotificationType.system:
      default:
        return Icons.notifications_none_outlined;
    }
  }

  Color _iconColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return kPrimaryColor;
      case NotificationType.booking:
        return const Color(0xFF22C55E); // green
      case NotificationType.favorite:
        return const Color(0xFFEF4444); // red
      case NotificationType.review:
        return const Color(0xFFF59E0B); // amber
      case NotificationType.system:
      default:
        return Colors.grey.shade700;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays >= 1) {
      return '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}';
    } else {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = !notification.isRead;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected
              ? kPrimaryColor.withOpacity(0.06)
              : hasUnread
                  ? const Color(0xFFF4F5FF)
                  : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? kPrimaryColor
                : hasUnread
                    ? kPrimaryColor.withOpacity(0.25)
                    : Colors.grey.shade300,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 8.0, top: 4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isSelected ? kPrimaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isSelected ? kPrimaryColor : Colors.grey.shade400,
                      width: 1.6,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _iconColorForType(notification.type).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _iconForType(notification.type),
                size: 20,
                color: _iconColorForType(notification.type),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + time
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight:
                                hasUnread ? FontWeight.w700 : FontWeight.w500,
                            color: kTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(notification.createdAt),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Body text
                  Text(
                    notification.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            if (hasUnread && !selectionMode)
              Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(
                  color: kPrimaryColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Loading state while notifications are being fetched.
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
            'Loading your notifications...',
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

/// Empty state when there are no notifications.
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
              Icons.notifications_none_outlined,
              size: 64,
              color: kPrimaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You will see updates here when customers interact\nwith your services.',
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

/// Error state for network / backend errors.
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
              'We couldn’t load your notifications.\nPlease try again.',
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