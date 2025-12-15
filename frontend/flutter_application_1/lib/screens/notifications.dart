// notification.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// ✅ Brand Blue
const Color kBrandBlue = Color.fromARGB(215, 20, 20, 215);

/// 🎨 Premium minimal palette (Black/White + subtle gray)
const Color kBg = Color(0xFFF7F8FC);
const Color kCard = Colors.white;
const Color kText = Color(0xFF0B1220);
const Color kMuted = Color(0xFF6B7280);
const Color kBorder = Color(0xFFE5E7EB);
const Color kDanger = Color(0xFFEF4444);

enum NotifType { booking, message, offer, system }

class NotifItem {
  final String id;
  final String title;
  final String body;
  final NotifType type;
  final DateTime time;
  bool pinned;

  NotifItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.time,
    this.pinned = false,
  });
}

enum NotifFilter { all, pinned, booking, message, offer, system }

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  NotifFilter _filter = NotifFilter.all;

  final List<NotifItem> _items = _dummyNotifications();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final poppins = GoogleFonts.poppinsTextTheme(theme.textTheme).apply(
      bodyColor: kText,
      displayColor: kText,
    );

    final visible = _applyFilter(_items, _filter);

    // Build one ListView with headers + items (compact + fast)
    final entries = _buildEntries(visible, _filter);

    return Theme(
      data: theme.copyWith(
        scaffoldBackgroundColor: kBg,
        textTheme: poppins,
        appBarTheme: theme.appBarTheme.copyWith(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.white,
          foregroundColor: kText,
          iconTheme: const IconThemeData(color: kText),
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: kText,
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          actions: [
            if (_items.isNotEmpty)
              TextButton(
                onPressed: () => _clearAll(context),
                style: TextButton.styleFrom(
                  foregroundColor: kText,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: Text(
                  'Clear all',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            IconButton(
              tooltip: 'Settings',
              onPressed: () => _openSettingsSheet(context),
              icon: const Icon(Icons.settings_rounded),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 8),
              _FilterChipsRow(
                value: _filter,
                onChanged: (v) => setState(() => _filter = v),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: entries.isEmpty
                      ? _EmptyState(
                          onExplore: () =>
                              _softSnack('Explore services (no navigation).'),
                        )
                      : ListView.builder(
                          key: ValueKey(_filter),
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                          itemCount: entries.length,
                          itemBuilder: (context, index) {
                            final e = entries[index];
                            if (e is _HeaderEntry) {
                              return _SectionHeader(label: e.label);
                            }
                            final item = (e as _ItemEntry).item;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Dismissible(
                                key: ValueKey(item.id),
                                direction: DismissDirection.horizontal,
                                background: _SwipeBackground(
                                  alignment: Alignment.centerLeft,
                                  color: kBrandBlue.withOpacity(0.12),
                                  icon: Icons.push_pin_rounded,
                                  label: item.pinned ? 'Unpin' : 'Pin',
                                  iconColor: kBrandBlue,
                                ),
                                secondaryBackground: const _SwipeBackground(
                                  alignment: Alignment.centerRight,
                                  color: kDanger,
                                  icon: Icons.delete_rounded,
                                  label: 'Delete',
                                  iconColor: Colors.white,
                                  labelColor: Colors.white,
                                ),
                                confirmDismiss: (dir) async {
                                  // Swipe right => Pin/Unpin (do NOT dismiss)
                                  if (dir == DismissDirection.startToEnd) {
                                    setState(() => item.pinned = !item.pinned);
                                    HapticFeedback.selectionClick();
                                    _softSnack(
                                        item.pinned ? 'Pinned' : 'Unpinned');
                                    return false;
                                  }
                                  // Swipe left => Delete (dismiss)
                                  if (dir == DismissDirection.endToStart) {
                                    return true;
                                  }
                                  return false;
                                },
                                onDismissed: (_) {
                                  setState(() => _items
                                      .removeWhere((x) => x.id == item.id));
                                  HapticFeedback.lightImpact();
                                  _softSnack('Deleted');
                                },
                                child: _NotificationCard(
                                  item: item,
                                  onTap: () => _openDetailsSheet(context, item),
                                  onMore: (action) =>
                                      _handleMoreAction(action, item),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------
  // Actions
  // ----------------------------

  void _handleMoreAction(_MoreAction action, NotifItem item) {
    switch (action) {
      case _MoreAction.view:
        _openDetailsSheet(context, item);
        break;
      case _MoreAction.pin:
        setState(() => item.pinned = !item.pinned);
        _softSnack(item.pinned ? 'Pinned' : 'Unpinned');
        break;
      case _MoreAction.delete:
        setState(() => _items.removeWhere((x) => x.id == item.id));
        _softSnack('Deleted');
        break;
    }
  }

  Future<void> _clearAll(BuildContext context) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kBorder,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Clear all notifications?',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                'This will remove everything from the list.',
                style: GoogleFonts.poppins(color: kMuted, fontSize: 13),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: kBorder),
                        foregroundColor: kText,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Cancel',
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kDanger,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Clear',
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (ok == true) {
      setState(() => _items.clear());
      _softSnack('Cleared');
    }
  }

  void _openSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kBorder,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kBrandBlue.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kBrandBlue.withOpacity(0.15)),
                    ),
                    child:
                        const Icon(Icons.settings_rounded, color: kBrandBlue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Notification settings',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'This demo page is display-only. You can add real settings later without changing the UI style.',
                style: GoogleFonts.poppins(
                    color: kMuted, fontSize: 13, height: 1.35),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _openDetailsSheet(BuildContext context, NotifItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.85,
          builder: (ctx, controller) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: kBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TypeIconBox(type: item.type),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatDateTime(item.time),
                              style: GoogleFonts.poppins(
                                  color: kMuted, fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: controller,
                      child: Text(
                        item.body,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          height: 1.45,
                          color: kText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() => item.pinned = !item.pinned);
                            Navigator.pop(ctx);
                            _softSnack(item.pinned ? 'Pinned' : 'Unpinned');
                          },
                          icon: Icon(
                            Icons.push_pin_rounded,
                            size: 18,
                            color: kBrandBlue.withOpacity(0.95),
                          ),
                          label: Text(
                            item.pinned ? 'Unpin' : 'Pin',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kText,
                            side: const BorderSide(color: kBorder),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() =>
                                _items.removeWhere((x) => x.id == item.id));
                            Navigator.pop(ctx);
                            _softSnack('Deleted');
                          },
                          icon: const Icon(Icons.delete_rounded, size: 18),
                          label: Text(
                            'Delete',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w800),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kDanger,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _softSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(msg, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: kText,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }
}

// ============================
// Filtering + Grouping helpers
// ============================

List<NotifItem> _applyFilter(List<NotifItem> all, NotifFilter f) {
  final copy = List<NotifItem>.from(all);

  // Always keep newest first (within whatever view)
  copy.sort((a, b) => b.time.compareTo(a.time));

  switch (f) {
    case NotifFilter.all:
      return copy;
    case NotifFilter.pinned:
      return copy.where((x) => x.pinned).toList();
    case NotifFilter.booking:
      return copy.where((x) => x.type == NotifType.booking).toList();
    case NotifFilter.message:
      return copy.where((x) => x.type == NotifType.message).toList();
    case NotifFilter.offer:
      return copy.where((x) => x.type == NotifType.offer).toList();
    case NotifFilter.system:
      return copy.where((x) => x.type == NotifType.system).toList();
  }
}

enum _Bucket { today, yesterday, older }

_Bucket _bucketFor(DateTime dt, DateTime now) {
  final d0 = DateTime(now.year, now.month, now.day);
  final d1 = DateTime(dt.year, dt.month, dt.day);
  final diff = d0.difference(d1).inDays;
  if (diff == 0) return _Bucket.today;
  if (diff == 1) return _Bucket.yesterday;
  return _Bucket.older;
}

List<_ListEntry> _buildEntries(List<NotifItem> visible, NotifFilter filter) {
  if (visible.isEmpty) return const [];

  // Pinned tab: single "Pinned" section (premium & clean)
  if (filter == NotifFilter.pinned) {
    return [
      const _HeaderEntry('Pinned'),
      ...visible.map((x) => _ItemEntry(x)),
    ];
  }

  final now = DateTime.now();
  final today = <NotifItem>[];
  final yest = <NotifItem>[];
  final older = <NotifItem>[];

  for (final n in visible) {
    final b = _bucketFor(n.time, now);
    if (b == _Bucket.today) today.add(n);
    if (b == _Bucket.yesterday) yest.add(n);
    if (b == _Bucket.older) older.add(n);
  }

  final out = <_ListEntry>[];
  void addSection(String label, List<NotifItem> items) {
    if (items.isEmpty) return;
    out.add(_HeaderEntry(label));
    out.addAll(items.map((x) => _ItemEntry(x)));
  }

  addSection('Today', today);
  addSection('Yesterday', yest);
  addSection('Older', older);
  return out;
}

sealed class _ListEntry {
  const _ListEntry();
}

class _HeaderEntry extends _ListEntry {
  final String label;
  const _HeaderEntry(this.label);
}

class _ItemEntry extends _ListEntry {
  final NotifItem item;
  const _ItemEntry(this.item);
}

// ============================
// UI Widgets (Modular)
// ============================

class _FilterChipsRow extends StatelessWidget {
  final NotifFilter value;
  final ValueChanged<NotifFilter> onChanged;

  const _FilterChipsRow({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_ChipSpec>[
      const _ChipSpec('All', NotifFilter.all),
      const _ChipSpec('Pinned', NotifFilter.pinned),
      const _ChipSpec('Booking', NotifFilter.booking),
      const _ChipSpec('Messages', NotifFilter.message),
      const _ChipSpec('Offers', NotifFilter.offer),
      const _ChipSpec('System', NotifFilter.system),
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final spec = items[i];
          final active = spec.value == value;

          return InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(spec.value);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: active ? kBrandBlue : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: active ? kBrandBlue : kBorder,
                ),
              ),
              child: Center(
                child: Text(
                  spec.label,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : kText,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChipSpec {
  final String label;
  final NotifFilter value;
  const _ChipSpec(this.label, this.value);
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 10, 2, 8),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: kMuted,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              color: kBorder,
            ),
          ),
        ],
      ),
    );
  }
}

enum _MoreAction { view, pin, delete }

class _NotificationCard extends StatelessWidget {
  final NotifItem item;
  final VoidCallback onTap;
  final ValueChanged<_MoreAction> onMore;

  const _NotificationCard({
    required this.item,
    required this.onTap,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    // Compact, modern, premium card
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: kCard,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap, // ✅ no navigation (only sheet)
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kBorder),
              ),
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left accent bar
                  Container(
                    width: 3,
                    height: 46,
                    decoration: BoxDecoration(
                      color: kBrandBlue,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Leading icon box
                  _TypeIconBox(type: item.type),

                  const SizedBox(width: 10),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.6,
                                  height: 1.15,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTime(item.time),
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: kMuted,
                              ),
                            ),
                            const SizedBox(width: 4),
                            PopupMenuButton<_MoreAction>(
                              tooltip: 'More',
                              splashRadius: 18,
                              icon: const Icon(Icons.more_horiz_rounded,
                                  size: 20, color: kMuted),
                              onSelected: onMore,
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: _MoreAction.view,
                                  child: Text('View details',
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600)),
                                ),
                                PopupMenuItem(
                                  value: _MoreAction.pin,
                                  child: Text(item.pinned ? 'Unpin' : 'Pin',
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600)),
                                ),
                                PopupMenuItem(
                                  value: _MoreAction.delete,
                                  child: Text('Delete',
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12.6,
                            height: 1.25,
                            color: kMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ✅ Pin indicator ONLY when pinned (badge attached to edge, tilted)
        if (item.pinned)
          Positioned(
            top: -7,
            right: 10,
            child: Transform.rotate(
              angle: -0.42,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: kDanger.withOpacity(0.10), // subtle red tint
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kDanger.withOpacity(0.28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.push_pin_rounded,
                    size: 16,
                    color: kDanger, // ✅ red pin
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TypeIconBox extends StatelessWidget {
  final NotifType type;
  const _TypeIconBox({required this.type});

  @override
  Widget build(BuildContext context) {
    final icon = switch (type) {
      NotifType.booking => Icons.event_available_rounded,
      NotifType.message => Icons.chat_bubble_rounded,
      NotifType.offer => Icons.local_offer_rounded,
      NotifType.system => Icons.shield_moon_rounded,
    };

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: kBrandBlue.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBrandBlue.withOpacity(0.16)),
      ),
      child: Icon(icon, size: 20, color: kBrandBlue),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color labelColor;

  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
    required this.iconColor,
    this.labelColor = kText,
  });

  @override
  Widget build(BuildContext context) {
    final isLeft = alignment == Alignment.centerLeft;

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isLeft) ...[
            Text(
              label,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800, color: labelColor),
            ),
            const SizedBox(width: 8),
          ],
          Icon(icon, color: iconColor),
          if (isLeft) ...[
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800, color: labelColor),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onExplore;
  const _EmptyState({required this.onExplore});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 40, 22, 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: kBrandBlue.withOpacity(0.10),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: kBrandBlue.withOpacity(0.16)),
              ),
              child: const Icon(Icons.notifications_none_rounded,
                  color: kBrandBlue, size: 30),
            ),
            const SizedBox(height: 14),
            Text(
              'No notifications yet',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Updates about bookings, messages, and offers will appear here.',
              style: GoogleFonts.poppins(
                  color: kMuted, fontSize: 13, height: 1.35),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: onExplore,
              style: OutlinedButton.styleFrom(
                foregroundColor: kText,
                side: const BorderSide(color: kBorder),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'Explore services',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================
// Formatting
// ============================

String _formatTime(DateTime dt) {
  final h = dt.hour;
  final m = dt.minute.toString().padLeft(2, '0');
  final ap = h >= 12 ? 'PM' : 'AM';
  final hh = ((h + 11) % 12) + 1;
  return '$hh:$m $ap';
}

String _formatDateTime(DateTime dt) {
  final months = const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  final mon = months[dt.month - 1];
  final day = dt.day;
  final year = dt.year;
  return '$mon $day, $year • ${_formatTime(dt)}';
}

// ============================
// Dummy Data
// ============================

List<NotifItem> _dummyNotifications() {
  final now = DateTime.now();

  DateTime minsAgo(int m) => now.subtract(Duration(minutes: m));
  DateTime hoursAgo(int h) => now.subtract(Duration(hours: h));
  DateTime daysAgo(int d) => now.subtract(Duration(days: d));

  return [
    NotifItem(
      id: 'n1',
      title: 'Booking confirmed',
      body:
          'Your venue booking is confirmed. Vendor “Golden Hall” sent the final confirmation and timing details.',
      type: NotifType.booking,
      time: minsAgo(12),
      pinned: true,
    ),
    NotifItem(
      id: 'n2',
      title: 'New message from vendor',
      body:
          '“Luna Photography”: We can offer a second shooter for your date. Want a quick call to finalize the package?',
      type: NotifType.message,
      time: minsAgo(48),
    ),
    NotifItem(
      id: 'n3',
      title: 'Offer unlocked',
      body:
          'You unlocked 15% off on floral design this week. Limited slots available — book early to secure the discount.',
      type: NotifType.offer,
      time: hoursAgo(3),
    ),
    NotifItem(
      id: 'n4',
      title: 'Payment reminder',
      body:
          'A payment is due in 2 days for your catering reservation. Review the invoice and keep everything on track.',
      type: NotifType.system,
      time: hoursAgo(7),
    ),
    // Yesterday
    NotifItem(
      id: 'n5',
      title: 'Booking update',
      body:
          'Your DJ added a new setlist preview. Tap to view details and share your preferred vibe (classic / modern / mix).',
      type: NotifType.booking,
      time: daysAgo(1).add(const Duration(hours: 18, minutes: 10)),
    ),
    NotifItem(
      id: 'n6',
      title: 'System update',
      body:
          'We improved search performance and vendor profiles. Everything should feel faster and cleaner.',
      type: NotifType.system,
      time: daysAgo(1).add(const Duration(hours: 10, minutes: 5)),
      pinned: true,
    ),
    // Older
    NotifItem(
      id: 'n7',
      title: 'New message',
      body:
          '“Royal Cakes”: We can match your theme color and provide a tasting box. Share your date and guest count.',
      type: NotifType.message,
      time: daysAgo(4).add(const Duration(hours: 13)),
    ),
    NotifItem(
      id: 'n8',
      title: 'Offer unlocked',
      body:
          'Limited-time: Free delivery for invitations printing in your city this weekend.',
      type: NotifType.offer,
      time: daysAgo(9).add(const Duration(hours: 9, minutes: 20)),
    ),
  ];
}
