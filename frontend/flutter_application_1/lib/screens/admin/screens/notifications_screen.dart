import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final List<dynamic> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = List<dynamic>.from(mockNotifications);
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'booking':
        return LucideIcons.calendar;
      case 'payment':
        return LucideIcons.dollarSign;
      case 'review':
        return LucideIcons.star;
      case 'system':
        return LucideIcons.settings;
      default:
        return LucideIcons.bell;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'booking':
        return kPrimaryColor;
      case 'payment':
        return Colors.green;
      case 'review':
        return Colors.amber[700]!;
      case 'system':
        return Colors.grey[600]!;
      default:
        return kPrimaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !(n.read == true)).length;

    final baseTheme = Theme.of(context);
    final poppinsTheme = baseTheme.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(baseTheme.textTheme),
      primaryTextTheme:
          GoogleFonts.poppinsTextTheme(baseTheme.primaryTextTheme),
    );

    return Theme(
      data: poppinsTheme,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modern header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: kTextColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$unreadCount unread notifications',
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (unreadCount > 0)
                    TextButton.icon(
                      onPressed: _markAllRead,
                      icon: const Icon(LucideIcons.checkCheck, size: 18),
                      label: Text(
                        'Mark all read',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: kPrimaryColor,
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              child: _notifications.isEmpty
                  ? _EmptyState(onReset: _restoreAll)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final n = _notifications[index];
                        final iconColor = _getNotificationColor(n.type);
                        final isUnread = !(n.read == true);

                        return Dismissible(
                          key: ValueKey(n.hashCode),
                          direction: DismissDirection.horizontal,
                          background: _SwipeMarkReadBg(isUnread: isUnread),
                          secondaryBackground: _SwipeDeleteBg(),
                          confirmDismiss: (dir) async {
                            if (dir == DismissDirection.startToEnd) {
                              _toggleRead(n);
                              return false; // don’t remove
                            }
                            return await _confirmDelete(context, n);
                          },
                          onDismissed: (_) => _deleteNotification(context, n),
                          child: _NotificationCard(
                            notification: n,
                            icon: _getNotificationIcon(n.type),
                            iconColor: iconColor,
                            isUnread: isUnread,
                            onDelete: () async {
                              final ok = await _confirmDelete(context, n);
                              if (ok == true) _deleteNotification(context, n);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleRead(dynamic n) {
    setState(() => n.read = !(n.read == true));
  }

  void _markAllRead() {
    setState(() {
      for (final n in _notifications) {
        n.read = true;
      }
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All notifications marked as read',
            style: GoogleFonts.poppins()),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, dynamic n) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete notification?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
          'This will remove it from your list.\n\n"${n.title}"',
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
            child: Text('Delete',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _deleteNotification(BuildContext context, dynamic n) {
    final removedIndex = _notifications.indexOf(n);
    if (removedIndex == -1) return;

    setState(() => _notifications.removeAt(removedIndex));

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notification deleted', style: GoogleFonts.poppins()),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() => _notifications.insert(removedIndex, n));
          },
        ),
      ),
    );
  }

  void _restoreAll() {
    setState(() {
      _notifications.clear();
      _notifications.addAll(List<dynamic>.from(mockNotifications));
    });
  }
}

class _NotificationCard extends StatelessWidget {
  final dynamic notification;
  final IconData icon;
  final Color iconColor;
  final bool isUnread;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notification,
    required this.icon,
    required this.iconColor,
    required this.isUnread,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isUnread ? kPrimaryColor.withOpacity(0.055) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              isUnread ? kPrimaryColor.withOpacity(0.20) : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon badge
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontWeight:
                                isUnread ? FontWeight.w800 : FontWeight.w700,
                            fontSize: 14,
                            color: kTextColor,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: kPrimaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.description,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Time + delete only (Read/Unread removed)
                  Row(
                    children: [
                      Icon(LucideIcons.clock,
                          size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          notification.time,
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: onDelete,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade100),
                          ),
                          child: Icon(
                            LucideIcons.trash2,
                            size: 16,
                            color: Colors.red.shade600,
                          ),
                        ),
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

class _SwipeMarkReadBg extends StatelessWidget {
  final bool isUnread;
  const _SwipeMarkReadBg({required this.isUnread});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(isUnread ? LucideIcons.check : LucideIcons.dot,
              color: Colors.white),
          const SizedBox(width: 8),
          Text(
            isUnread ? 'Mark read' : 'Mark unread',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeDeleteBg extends StatelessWidget {
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
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
              child: Icon(LucideIcons.bellOff, color: Colors.grey[700]),
            ),
            const SizedBox(height: 14),
            Text(
              'No notifications',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'New updates will appear here.',
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
                'Restore',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
