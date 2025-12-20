// lib/screens/chat_customer_home_page.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/services/user_service/chat_user_service.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/service_locator.dart'; // ✅ أضف هذا السطر
import 'dart:async';
/// ✅ نفس لونك (ARGB) = RGB(215, 20, 20, 215)
const Color kNavBlue = Color.fromARGB(215, 20, 20, 215);
const Color kPageBg = Color(0xFFF6F7FB);

enum ChatScope { all, vendors, support }

class ChatCustomerHomePage extends StatefulWidget {
  const ChatCustomerHomePage({super.key});

  @override
  State<ChatCustomerHomePage> createState() => _ChatCustomerHomePageState();
}

class _ChatCustomerHomePageState extends State<ChatCustomerHomePage> {
  final _searchCtrl = TextEditingController();
  final _service = getIt<ChatUserService>(); // ✅ أضف هذا السطر

  ChatScope _scope = ChatScope.all;
  List<ChatThreadModel> _all = const [];
  List<ChatThreadModel> _filtered = const [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _searchCtrl.addListener(_applyFilters);
    
  // ✅ استمع للـ Stream بدل callback
  _service.statusUpdateStream.listen((_) {
    if (mounted) {
      _load();
    }
  });
}

  Future<void> _initializeChat() async {
      setState(() => _isLoading = true);
    
    // Initialize user ID in service
    await _service.initializeUserId();
    
    // Initialize socket
    await _service.initSocket();
    
    // Load chats
    await _load();
    
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _service.setActiveChat(null);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final items = await _service.fetchUserChats();
      if (!mounted) return;
      setState(() {
        _all = items;
        _filtered = items;
      });
      _applyFilters();
    } catch (e) {
      print('Error loading chats: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading chats: $e')),
      );
    }
  }

  void _applyFilters() {
    final q = _searchCtrl.text.trim().toLowerCase();
    final filtered = _all.where((t) {
      final inScope = switch (_scope) {
        ChatScope.all => true,
        ChatScope.vendors => t.type == ThreadType.vendor,
        ChatScope.support => t.type == ThreadType.support,
      };

      final inQuery = q.isEmpty
          ? true
          : (t.title.toLowerCase().contains(q) ||
              t.lastMessage.toLowerCase().contains(q));

      return inScope && inQuery;
    }).toList();

    // Sort: unread first + most recent
    filtered.sort((a, b) {
      final ua = a.unreadCount > 0 ? 0 : 1;
      final ub = b.unreadCount > 0 ? 0 : 1;
      if (ua != ub) return ua.compareTo(ub);
      return b.lastTime.compareTo(a.lastTime);
    });

    setState(() => _filtered = filtered);
  }



  int _totalUnread() => _all.fold<int>(0, (sum, t) => sum + t.unreadCount);

  @override
  Widget build(BuildContext context) {
    final unread = _totalUnread();

    return Scaffold(
      backgroundColor: kPageBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            HapticFeedback.lightImpact();
            await _load();
            _applyFilters();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Chat",
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0B1220),
                          ),
                        ),
                      ),
                      _TopIconButton(
                        icon: Icons.mark_chat_unread_rounded,
                        tooltip: "Unread",
                        badge: unread > 0 ? unread : null,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _filtered =
                                _all.where((e) => e.unreadCount > 0).toList();
                          });
                        },
                      ),
                      const SizedBox(width: 10),
                      _TopIconButton(
                        icon: Icons.edit_rounded,
                        tooltip: "New",
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _showNewChatSheet(context);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // ✅ Search
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                  child: _SearchField(
                    controller: _searchCtrl,
                    hint: "Search vendors / support…",
                    onClear: () {
                      _searchCtrl.clear();
                      _applyFilters();
                    },
                  ),
                ),
              ),

              // ✅ Tabs
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
                  child: _ScopeTabs(
                    scope: _scope,
                    onChanged: (s) {
                      HapticFeedback.selectionClick();
                      setState(() => _scope = s);
                      _applyFilters();
                    },
                  ),
                ),
              ),

               SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                sliver: _isLoading
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(color: kNavBlue),
                          ),
                        ),
                      )
                    : _filtered.isEmpty
                        ? SliverToBoxAdapter(
                            child: _EmptyState(
                              title: "No chats yet",
                              subtitle:
                                  "Start a conversation with a vendor or contact support.",
                              onPrimary: () => _showNewChatSheet(context),
                              primaryText: "Start chat",
                            ),
                          )
                        : SliverList.separated(
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final t = _filtered[i];
                              return _ThreadTile(
                                thread: t,
                                onTap: () async {
                                  HapticFeedback.selectionClick();
                                  final updated = await Navigator.push<ChatThreadModel>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatThreadPage(thread: t),
                                    ),
                                  );

                              // ✅ رجّع من صفحة المحادثة: حدّث الليست
                              if (!mounted) return;
                              await _load();
                              if (updated != null) {
                                setState(() {
                                  _all = _all
                                      .map((x) =>
                                          x.id == updated.id ? updated : x)
                                      .toList();
                                });
                                _applyFilters();
                              }
                            },
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

void _showNewChatSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Start a new chat",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0B1220),
              ),
            ),
            const SizedBox(height: 10),
            _SheetAction(
              icon: Icons.storefront_rounded,
              title: "Chat with a vendor",
              subtitle: "Ask about availability, pricing, details…",
              onTap: () async {
                Navigator.pop(context);
                // TODO: Implement vendor selection screen
                // For now, show message to connect to vendors list
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Connect this to Vendors list later ✅")),
                );
              },
            ),
            const SizedBox(height: 10),
            _SheetAction(
              icon: Icons.support_agent_rounded,
              title: "Contact support",
              subtitle: "Payments, booking issues, help…",
              onTap: () async {
                Navigator.pop(context);
                
                // Check if support chat already exists
                final existingSupport = _all.firstWhere(
                  (e) => e.type == ThreadType.support,
                  orElse: () => ChatThreadModel(
                    id: '',
                    type: ThreadType.support,
                    title: '',
                    lastMessage: '',
                    lastTime: DateTime.now(),
                    unreadCount: 0,
                    online: false,
                  ),
                );

                String? chatId;
                
                if (existingSupport.id.isEmpty) {
                  // Create new support chat - need to get admin ID
                  // TODO: Replace with actual admin ID from your system
                  final adminId = 'ADMIN_USER_ID'; // Get this from your backend
                  chatId = await _service.createChat(adminId);
                  
                  if (chatId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to create support chat')),
                    );
                    return;
                  }
                  
                  // Reload chats to get the new one
                  await _load();
                } else {
                  chatId = existingSupport.id;
                }

                // Navigate to chat thread
                if (chatId != null) {
                  final updatedThread = await Navigator.push<ChatThreadModel>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatThreadPage(
                        thread: _all.firstWhere((e) => e.id == chatId),
                      ),
                    ),
                  );

                  if (!mounted) return;
                  if (updatedThread != null) {
                    await _load();
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////////////////////////
// ✅ Chat Thread Screen
////////////////////////////////////////////////////////////////////////////////

class ChatThreadPage extends StatefulWidget {
  final ChatThreadModel thread;
  const ChatThreadPage({super.key, required this.thread});

  @override
  State<ChatThreadPage> createState() => _ChatThreadPageState();
}

class _ChatThreadPageState extends State<ChatThreadPage> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _service = getIt<ChatUserService>(); // ✅ أضف هذا السطر
  StreamSubscription<ChatMessageModel>? _messageSubscription; // ✅ أضف هذا السطر

  late ChatThreadModel _thread;
  List<ChatMessageModel> _messages = [];

  bool _typing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _thread = widget.thread.copyWith(unreadCount: 0);
    _initializeThread();    
  _messageSubscription = _service.messageStream.listen((message) {
    if (mounted && _service.activeChatId == _thread.id) {
      setState(() {
        _messages.add(message);
        _thread = _thread.copyWith(
          lastMessage: message.text,
          lastTime: message.time,
        );
      });
      _animateToBottom();
    }
  });
}

  Future<void> _initializeThread() async {
    setState(() => _isLoading = true);
    
    // Set this as active chat
    _service.setActiveChat(_thread.id);
    
    // Mark as read
    await _service.markAsRead(_thread.id);
    
    // Load messages
    try {
      final messages = await _service.fetchChatMessages(_thread.id);
      if (!mounted) return;
      
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
    } catch (e) {
      print('Error loading messages: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading messages: $e')),
      );
    }
  }

  @override
  void dispose() {
  _messageSubscription?.cancel(); // ✅ إلغاء الاشتراك
  _service.setActiveChat(null);
   _ctrl.dispose();      
    _scroll.dispose();    
    super.dispose();
  }

  void _jumpToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.jumpTo(_scroll.position.maxScrollExtent);
  }

  void _animateToBottom() {
    if (!_scroll.hasClients) return;
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;

    HapticFeedback.selectionClick();

    // Create optimistic message
    final tempMsg = ChatMessageModel(
      id: "temp_${DateTime.now().millisecondsSinceEpoch}",
      text: t,
      time: DateTime.now(),
      fromMe: true,
      isRead: true,
    );

    setState(() {
      _messages.add(tempMsg);
      _thread = _thread.copyWith(
        lastMessage: t,
        lastTime: tempMsg.time,
        unreadCount: 0,
      );
      _ctrl.clear();
    });

    _animateToBottom();

    // Send via service
    try {
      await _service.sendMessage(_thread.id, t);
      // Message will be updated via WebSocket
    } catch (e) {
      print('Error sending message: $e');
      if (!mounted) return;
      
      // Remove optimistic message on error
      setState(() {
        _messages.removeWhere((m) => m.id == tempMsg.id);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  void _openAttachSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Attach",
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _AttachTile(
                    icon: Icons.photo_library_rounded,
                    label: "Gallery",
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Add image picker later ✅")),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AttachTile(
                    icon: Icons.photo_camera_rounded,
                    label: "Camera",
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Add camera later ✅")),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AttachTile(
                    icon: Icons.insert_drive_file_rounded,
                    label: "File",
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Add file picker later ✅")),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _thread.title;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _thread);
        return false;
      },
      child: Scaffold(
        backgroundColor: kPageBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context, _thread),
          ),
          title: Row(
            children: [
              _AvatarCircle(
                seed: title,
                size: 38,
                showOnline: true,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                        color: const Color(0xFF0B1220),
                      ),
                    ),
                    Text(
                      _thread.type == ThreadType.support
                          ? "Support • Online"
                          : "Vendor • Replies fast",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: "Call",
              onPressed: () => HapticFeedback.selectionClick(),
              icon: Icon(Icons.call_rounded, color: kNavBlue.withOpacity(0.95)),
            ),
            IconButton(
              tooltip: "Info",
              onPressed: () => HapticFeedback.selectionClick(),
              icon: Icon(Icons.info_outline_rounded,
                  color: kNavBlue.withOpacity(0.95)),
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: Column(
          children: [
            // Suggestion chips
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _QuickChip(
                        text: "Availability",
                        onTap: () =>
                            _send("Hi! Are you available on my date?")),
                    const SizedBox(width: 8),
                    _QuickChip(
                        text: "Pricing",
                        onTap: () =>
                            _send("Can you share your pricing details?")),
                    const SizedBox(width: 8),
                    _QuickChip(
                        text: "Packages",
                        onTap: () => _send("Do you offer packages / bundles?")),
                    const SizedBox(width: 8),
                    _QuickChip(text: "Send photos", onTap: _openAttachSheet),
                  ],
                ),
              ),
            ),

            // Messages
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: kNavBlue),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      itemCount: _messages.length + (_typing ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (_typing && i == _messages.length) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: _TypingBubble(),
                            ),
                          );
                        }

                        final m = _messages[i];
                        final prev = i > 0 ? _messages[i - 1] : null;

                        final showDay = prev == null || !_sameDay(prev.time, m.time);

                        return Column(
                          children: [
                            if (showDay) ...[
                              const SizedBox(height: 4),
                              _DayDivider(label: _prettyDay(m.time)),
                              const SizedBox(height: 10),
                            ],
                            Align(
                              alignment: m.fromMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: _MessageBubble(message: m),
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                      },
                    ),
            ),

            // Composer
            _ComposerBar(
              controller: _ctrl,
              onAttach: _openAttachSheet,
              onSend: () => _send(_ctrl.text),
            ),
          ],
        ),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _prettyDay(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;

    if (diff == 0) return "Today";
    if (diff == 1) return "Yesterday";
    return "${d.day}/${d.month}/${d.year}";
  }
}

////////////////////////////////////////////////////////////////////////////////
// ✅ Widgets
////////////////////////////////////////////////////////////////////////////////

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: kNavBlue.withOpacity(0.85)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, v, __) {
              final show = v.text.trim().isNotEmpty;
              return AnimatedOpacity(
                duration: const Duration(milliseconds: 160),
                opacity: show ? 1 : 0,
                child: IconButton(
                  onPressed: show ? onClear : null,
                  icon: Icon(Icons.close_rounded,
                      color: kNavBlue.withOpacity(0.9)),
                  splashRadius: 18,
                  tooltip: "Clear",
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ScopeTabs extends StatelessWidget {
  final ChatScope scope;
  final ValueChanged<ChatScope> onChanged;

  const _ScopeTabs({required this.scope, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget tab(String text, ChatScope s, IconData icon) {
      final selected = scope == s;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onChanged(s),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? kNavBlue : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: kNavBlue.withOpacity(0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 10),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: selected ? Colors.white : kNavBlue),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                    color: selected ? Colors.white : const Color(0xFF0B1220),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tab("All", ChatScope.all, Icons.forum_rounded),
        const SizedBox(width: 10),
        tab("Vendors", ChatScope.vendors, Icons.storefront_rounded),
        const SizedBox(width: 10),
        tab("Support", ChatScope.support, Icons.support_agent_rounded),
      ],
    );
  }
}

class _ThreadTile extends StatelessWidget {
 final ChatThreadModel thread;
  final VoidCallback onTap;

  const _ThreadTile({required this.thread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final time = _prettyTime(thread.lastTime);
    final unread = thread.unreadCount;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              _AvatarCircle(
                seed: thread.title,
                size: 46,
                showOnline: thread.type == ThreadType.support || thread.online,
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
                            thread.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0B1220),
                            ),
                          ),
                        ),
                        Text(
                          time,
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            thread.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: unread > 0
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: unread > 0
                                  ? const Color(0xFF0B1220)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        if (unread > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: kNavBlue,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: kNavBlue.withOpacity(0.22),
                                  blurRadius: 14,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Text(
                              unread > 99 ? "99+" : unread.toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _prettyTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return "Now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m";
    if (diff.inHours < 24) return "${diff.inHours}h";
    return "${t.day}/${t.month}";
  }
}

class _AvatarCircle extends StatelessWidget {
  final String seed;
  final double size;
  final bool showOnline;

  const _AvatarCircle({
    required this.seed,
    required this.size,
    required this.showOnline,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _initials(seed);
    final bg = _colorFrom(seed).withOpacity(0.14);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black.withOpacity(0.06)),
          ),
          child: Center(
            child: Text(
              initials,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w900,
                color: kNavBlue,
              ),
            ),
          ),
        ),
        if (showOnline)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  String _initials(String s) {
    final parts = s.trim().split(RegExp(r"\s+"));
    if (parts.isEmpty) return "C";
    final a = parts.first.isNotEmpty ? parts.first[0] : "C";
    final b = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : "";
    return (a + b).toUpperCase();
  }

  Color _colorFrom(String s) {
    final h = s.codeUnits.fold<int>(0, (p, c) => p + c);
    final rnd = Random(h);
    final base = [
      kNavBlue,
      const Color(0xFF7C3AED),
      const Color(0xFF0EA5E9),
      const Color(0xFFF97316)
    ];
    return base[rnd.nextInt(base.length)];
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;  // ✅ صح
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = message.fromMe;

    final bg = isMe ? kNavBlue : Colors.white;
    final fg = isMe ? Colors.white : const Color(0xFF0B1220);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 6),
            bottomRight: Radius.circular(isMe ? 6 : 18),
          ),
          border: Border.all(
              color:
                  isMe ? Colors.transparent : Colors.black.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isMe ? 0.12 : 0.05),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.text,
              style: GoogleFonts.poppins(
                fontSize: 13.2,
                fontWeight: FontWeight.w600,
                color: fg,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _time(message.time),
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: isMe
                    ? Colors.white.withOpacity(0.85)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _time(DateTime t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return "$hh:$mm";
  }
}

class _ComposerBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAttach;
  final VoidCallback onSend;

  const _ComposerBar({
    required this.controller,
    required this.onAttach,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onAttach();
                },
                icon: Icon(Icons.add_circle_rounded,
                    color: kNavBlue.withOpacity(0.95), size: 28),
                splashRadius: 22,
                tooltip: "Attach",
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700, fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: "Type a message…",
                    hintStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF94A3B8),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onSend();
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: kNavBlue,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: kNavBlue.withOpacity(0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayDivider extends StatelessWidget {
  final String label;
  const _DayDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.black.withOpacity(0.08))),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: Colors.black.withOpacity(0.08))),
      ],
    );
  }
}

class _TypingBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dot(),
          const SizedBox(width: 4),
          _Dot(delay: 120),
          const SizedBox(width: 4),
          _Dot(delay: 240),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({this.delay = 0});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final v = (0.5 + _c.value * 0.5);
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, -2 * _c.value),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: kNavBlue.withOpacity(0.85),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _QuickChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0B1220),
          ),
        ),
      ),
    );
  }
}

class _AttachTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AttachTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Ink(
        height: 92,
        decoration: BoxDecoration(
          color: kNavBlue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kNavBlue.withOpacity(0.10)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: kNavBlue, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final int? badge;
  final VoidCallback onTap;

  const _TopIconButton({
    required this.icon,
    required this.tooltip,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Ink(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(icon, color: kNavBlue.withOpacity(0.95), size: 22),
          ),
        ),
        if (badge != null && badge! > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: kNavBlue,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                badge! > 99 ? "99+" : badge.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onPrimary;
  final String primaryText;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.onPrimary,
    required this.primaryText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: kNavBlue.withOpacity(0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.chat_bubble_rounded, color: kNavBlue, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kNavBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                onPrimary();
              },
              child: Text(
                primaryText,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SheetAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kNavBlue.withOpacity(0.06),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: kNavBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: kNavBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: kNavBlue.withOpacity(0.75)),
            ],
          ),
        ),
      ),
    );
  }
}