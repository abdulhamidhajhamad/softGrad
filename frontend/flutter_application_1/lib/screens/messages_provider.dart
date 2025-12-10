// lib/screens/messages_provider.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/chat_provider_service.dart';
import 'chat_screen.dart';

const Color kPrimaryColor = Color.fromARGB(255, 20, 20, 215);
const Color kTextColor = Colors.black;
const Color kBackgroundColor = Colors.white;

class ConversationThread {
  final String id;
  final String customerName;
  final String? avatarUrl;
  final String lastMessage;
  final DateTime lastMessageTime;

  int unreadCount;
  bool isArchived;
  bool isPinned;

  ConversationThread({
    required this.id,
    required this.customerName,
    required this.lastMessage,
    required this.lastMessageTime,
    this.avatarUrl,
    this.unreadCount = 0,
    this.isArchived = false,
    this.isPinned = false,
  });
}

class MessagesRepository {
  static Future<List<ConversationThread>> fetchConversationsForProvider(
    String providerId,
  ) async {
    try {
      final chats = await ChatProviderService().fetchUserChats();
      final currentUserId = ChatProviderService().currentUserId;
      
      List<ConversationThread> conversations = [];
      
      for (var chat in chats) {
        final participants = chat['participants'] as List<dynamic>;
        
        // Find the other participant (customer)
        Map<String, dynamic>? otherParticipant;
        for (var p in participants) {
          final participantId = p['_id'] ?? p['id'];
          if (participantId != currentUserId) {
            otherParticipant = p as Map<String, dynamic>;
            break;
          }
        }
        
        if (otherParticipant == null) continue;
        
        // Get unread count for this chat
        final messages = await ChatProviderService().fetchMessages(chat['_id']);
        int unreadCount = 0;
        for (var msg in messages) {
          final senderId = msg['sender'] is Map 
              ? msg['sender']['_id'] ?? msg['sender']['id']
              : msg['sender'];
          if (senderId != currentUserId && msg['isRead'] == false) {
            unreadCount++;
          }
        }
        
        conversations.add(ConversationThread(
          id: chat['_id'],
          customerName: otherParticipant['userName'] ?? 'Unknown',
          avatarUrl: otherParticipant['imageUrl'],
          lastMessage: chat['lastMessage'] ?? 'No messages yet',
          lastMessageTime: DateTime.parse(chat['updatedAt'] ?? chat['createdAt']),
          unreadCount: unreadCount,
        ));
      }
      
      return conversations;
    } catch (e) {
      print('Error in fetchConversationsForProvider: $e');
      return [];
    }
  }

  static Future<void> markConversationsAsRead(
    List<String> conversationIds,
  ) async {
    for (var id in conversationIds) {
      await ChatProviderService().markAsRead(id);
    }
  }

  static Future<void> markConversationsAsUnread(
    List<String> conversationIds,
  ) async {
    // Backend doesn't have mark as unread, so we skip this
  }

  static Future<void> deleteConversations(
    List<String> conversationIds,
  ) async {
    for (var id in conversationIds) {
      await ChatProviderService().deleteChat(id);
    }
  }

  static Future<void> pinConversation(String id, bool pinned) async {
    // Pin functionality not implemented in backend yet
  }
}

enum MessageFilter { all, unreadOnly }

enum _ConversationMenuAction { togglePin, toggleRead, delete }

class MessagesProviderScreen extends StatefulWidget {
  final String? providerId;

  const MessagesProviderScreen({Key? key, this.providerId}) : super(key: key);

  @override
  State<MessagesProviderScreen> createState() => _MessagesProviderScreenState();
}

class _MessagesProviderScreenState extends State<MessagesProviderScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  List<ConversationThread> _allConversations = [];
  MessageFilter _filter = MessageFilter.all;

  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _loadConversations();
    
    // Listen for real-time updates
    ChatProviderService().onMessageStatusUpdate = () {
      if (mounted) {
        _loadConversations();
      }
    };
  }
  
  @override
  void dispose() {
    ChatProviderService().onMessageStatusUpdate = null;
    super.dispose();
  }

  Future<void> _initializeChat() async {
    await ChatProviderService().initSocket();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await MessagesRepository.fetchConversationsForProvider(
        widget.providerId ?? 'provider-id',
      );
      if (mounted) {
        setState(() {
          _allConversations = data;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load messages.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openSearch() async {
    if (_allConversations.isEmpty) return;

    final selected = await showSearch<ConversationThread?>(
      context: context,
      delegate: ConversationSearchDelegate(
        conversations: _allConversations,
      ),
    );

    if (selected != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: selected.id,
            customerName: selected.customerName,
          ),
        ),
      ).then((_) => _loadConversations());
    }
  }

  List<ConversationThread> get _visibleConversations {
    Iterable<ConversationThread> source = _allConversations;

    switch (_filter) {
      case MessageFilter.unreadOnly:
        source = source.where((c) => c.unreadCount > 0);
        break;
      case MessageFilter.all:
      default:
        break;
    }

    final list = source.toList();

    list.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      return b.lastMessageTime.compareTo(a.lastMessageTime);
    });

    return list;
  }

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
    final ids = _selectedIds.toList();
    setState(() {
      for (final conv in _allConversations) {
        if (ids.contains(conv.id)) {
          conv.unreadCount = 0;
        }
      }
    });
    await MessagesRepository.markConversationsAsRead(ids);
    _exitSelectionMode();
  }

  Future<void> _markSelectedAsUnread() async {
    final ids = _selectedIds.toList();
    setState(() {
      for (final conv in _allConversations) {
        if (ids.contains(conv.id)) {
          conv.unreadCount = 1;
        }
      }
    });
    await MessagesRepository.markConversationsAsUnread(ids);
    _exitSelectionMode();
  }

  Future<void> _deleteSelectedConversations() async {
    final ids = _selectedIds.toList();
    setState(() {
      _allConversations.removeWhere((c) => ids.contains(c.id));
    });
    await MessagesRepository.deleteConversations(ids);
    _exitSelectionMode();
  }

  Future<void> _deleteSingleConversation(ConversationThread conv) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete conversation'),
          content: Text('Delete conversation with ${conv.customerName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _allConversations.removeWhere((c) => c.id == conv.id);
      _selectedIds.remove(conv.id);
    });

    await MessagesRepository.deleteConversations([conv.id]);

    if (_selectionMode && _selectedIds.isEmpty) {
      _selectionMode = false;
    }
  }

  Future<void> _togglePinConversation(ConversationThread conv) async {
    final newValue = !conv.isPinned;
    setState(() {
      conv.isPinned = newValue;
    });
    await MessagesRepository.pinConversation(conv.id, newValue);
  }

  Future<void> _toggleReadConversation(ConversationThread conv) async {
    final isCurrentlyUnread = conv.unreadCount > 0;

    setState(() {
      conv.unreadCount = isCurrentlyUnread ? 0 : 1;
    });

    if (isCurrentlyUnread) {
      await MessagesRepository.markConversationsAsRead([conv.id]);
    } else {
      await MessagesRepository.markConversationsAsUnread([conv.id]);
    }
  }

  void _openFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Filter messages',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Icon(
                  Icons.inbox_outlined,
                  color: _filter == MessageFilter.all
                      ? kPrimaryColor
                      : Colors.grey.shade700,
                ),
                title: Text(
                  'All conversations',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                trailing: _filter == MessageFilter.all
                    ? const Icon(Icons.check, color: kPrimaryColor)
                    : null,
                onTap: () {
                  setState(() => _filter = MessageFilter.all);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.mark_email_unread_outlined,
                  color: _filter == MessageFilter.unreadOnly
                      ? kPrimaryColor
                      : Colors.grey.shade700,
                ),
                title: Text(
                  'Unread only',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                trailing: _filter == MessageFilter.unreadOnly
                    ? const Icon(Icons.check, color: kPrimaryColor)
                    : null,
                onTap: () {
                  setState(() => _filter = MessageFilter.unreadOnly);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _openMoreMenu() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final hasAny = _allConversations.isNotEmpty;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'More options',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading:
                    const Icon(Icons.checklist_outlined, color: kTextColor),
                title: Text(
                  'Select conversations',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  if (hasAny) {
                    setState(() {
                      _selectionMode = true;
                      _selectedIds.clear();
                    });
                  }
                },
              ),
              ListTile(
                enabled: hasAny,
                leading: Icon(
                  Icons.mark_email_read_outlined,
                  color: hasAny ? kPrimaryColor : Colors.grey.shade400,
                ),
                title: Text(
                  'Mark all as read',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                onTap: hasAny
                    ? () async {
                        Navigator.pop(ctx);
                        await _markAllAsRead();
                      }
                    : null,
              ),
              ListTile(
                enabled: hasAny,
                leading: Icon(
                  Icons.mark_email_unread_outlined,
                  color: hasAny ? kPrimaryColor : Colors.grey.shade400,
                ),
                title: Text(
                  'Mark all as unread',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                onTap: hasAny
                    ? () async {
                        Navigator.pop(ctx);
                        await _markAllAsUnread();
                      }
                    : null,
              ),
              const Divider(height: 24),
              ListTile(
                enabled: hasAny,
                leading: Icon(
                  Icons.delete_outline,
                  color: hasAny ? Colors.redAccent : Colors.grey.shade400,
                ),
                title: Text(
                  'Delete all conversations',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: hasAny ? Colors.redAccent : Colors.grey.shade500,
                  ),
                ),
                onTap: hasAny
                    ? () async {
                        Navigator.pop(ctx);
                        await _deleteAllConversations();
                      }
                    : null,
              ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }

  Future<void> _markAllAsRead() async {
    final ids = _allConversations.map((c) => c.id).toList();
    setState(() {
      for (final c in _allConversations) {
        c.unreadCount = 0;
      }
    });
    await MessagesRepository.markConversationsAsRead(ids);
  }

  Future<void> _markAllAsUnread() async {
    final ids = _allConversations.map((c) => c.id).toList();
    setState(() {
      for (final c in _allConversations) {
        if (c.unreadCount == 0) {
          c.unreadCount = 1;
        }
      }
    });
    await MessagesRepository.markConversationsAsUnread(ids);
  }

  Future<void> _deleteAllConversations() async {
    if (_allConversations.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete all conversations'),
          content: const Text(
            'Are you sure you want to delete all conversations? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final ids = _allConversations.map((c) => c.id).toList();
    setState(() {
      _allConversations.clear();
      _selectedIds.clear();
      _selectionMode = false;
    });
    await MessagesRepository.deleteConversations(ids);
  }

  PreferredSizeWidget _buildAppBar() {
    if (_selectionMode) {
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
            tooltip: 'Mark as unread',
            onPressed: _markSelectedAsUnread,
            icon:
                const Icon(Icons.mark_email_unread_outlined, color: kTextColor),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: _deleteSelectedConversations,
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          ),
        ],
      );
    }

    return AppBar(
      backgroundColor: kBackgroundColor,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: kTextColor),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Messages',
        style: GoogleFonts.poppins(
          color: kTextColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Search',
          onPressed: _openSearch,
          icon: const Icon(Icons.search, color: kTextColor),
        ),
        IconButton(
          tooltip: 'Filter',
          onPressed: _openFilterSheet,
          icon: const Icon(Icons.tune_rounded, color: kTextColor),
        ),
        IconButton(
          tooltip: 'More',
          onPressed: _openMoreMenu,
          icon: const Icon(Icons.more_vert, color: kTextColor),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleConversations;

    return SafeArea(
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: _buildAppBar(),
        body: _isLoading
            ? const _LoadingState()
            : _errorMessage != null
                ? _ErrorState(
                    onRetry: _loadConversations,
                  )
                : visible.isEmpty
                    ? const _EmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadConversations,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          itemCount: visible.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final convo = visible[index];
                            final isSelected = _selectedIds.contains(convo.id);
                            return _ConversationTile(
                              conversation: convo,
                              isSelected: isSelected,
                              selectionMode: _selectionMode,
                              onTap: () async {
                                if (_selectionMode) {
                                  _toggleSelection(convo.id);
                                } else {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(
                                        conversationId: convo.id,
                                        customerName: convo.customerName,
                                      ),
                                    ),
                                  );
                                  _loadConversations();
                                }
                              },
                              onLongPress: () {
                                if (!_selectionMode) {
                                  _enterSelectionMode(convo.id);
                                } else {
                                  _toggleSelection(convo.id);
                                }
                              },
                              onDelete: () => _deleteSingleConversation(convo),
                              onTogglePin: () => _togglePinConversation(convo),
                              onToggleRead: () =>
                                  _toggleReadConversation(convo),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}

class ConversationSearchDelegate extends SearchDelegate<ConversationThread?> {
  final List<ConversationThread> conversations;

  ConversationSearchDelegate({required this.conversations})
      : super(searchFieldLabel: 'Search by name or message');

  @override
  ThemeData appBarTheme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: kTextColor),
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: GoogleFonts.poppins(
          color: kTextColor,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: kTextColor),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new, color: kTextColor),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = _filtered();

    if (results.isEmpty) {
      return Center(
        child: Text(
          'No conversations found',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final convo = results[index];
        return ListTile(
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: kPrimaryColor.withOpacity(0.08),
            child: Text(
              convo.customerName.isNotEmpty
                  ? convo.customerName[0].toUpperCase()
                  : '?',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kPrimaryColor,
              ),
            ),
          ),
          title: Text(
            convo.customerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            convo.lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          onTap: () => close(context, convo),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }

  List<ConversationThread> _filtered() {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return conversations;

    return conversations.where((c) {
      final name = c.customerName.toLowerCase();
      final msg = c.lastMessage.toLowerCase();
      return name.contains(q) || msg.contains(q);
    }).toList();
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationThread conversation;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  final VoidCallback onDelete;
  final VoidCallback onTogglePin;
  final VoidCallback onToggleRead;

  const _ConversationTile({
    Key? key,
    required this.conversation,
    required this.isSelected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
    required this.onTogglePin,
    required this.onToggleRead,
  }) : super(key: key);

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
    final hasUnread = conversation.unreadCount > 0;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected
              ? kPrimaryColor.withOpacity(0.08)
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
          children: [
            if (selectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
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
            _Avatar(
              customerName: conversation.customerName,
              url: conversation.avatarUrl,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                conversation.customerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: hasUnread
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: kTextColor,
                                ),
                              ),
                            ),
                            if (conversation.isPinned) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.push_pin_rounded,
                                size: 16,
                                color: kPrimaryColor,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(conversation.lastMessageTime),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conversation.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                      color: hasUnread ? Colors.black87 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (hasUnread)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: kPrimaryColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${conversation.unreadCount} new',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            if (hasUnread && !selectionMode)
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: kPrimaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            if (!selectionMode)
              PopupMenuButton<_ConversationMenuAction>(
                onSelected: (value) {
                  switch (value) {
                    case _ConversationMenuAction.togglePin:
                      onTogglePin();
                      break;
                    case _ConversationMenuAction.toggleRead:
                      onToggleRead();
                      break;
                    case _ConversationMenuAction.delete:
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: _ConversationMenuAction.togglePin,
                    child: Row(
                      children: [
                        Icon(
                          conversation.isPinned
                              ? Icons.push_pin_outlined
                              : Icons.push_pin_rounded,
                          size: 18,
                          color: kTextColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          conversation.isPinned
                              ? 'Unpin conversation'
                              : 'Pin to top',
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: _ConversationMenuAction.toggleRead,
                    child: Row(
                      children: [
                        Icon(
                          conversation.unreadCount > 0
                              ? Icons.mark_email_read_outlined
                              : Icons.mark_email_unread_outlined,
                          size: 18,
                          color: kTextColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          conversation.unreadCount > 0
                              ? 'Mark as read'
                              : 'Mark as unread',
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: _ConversationMenuAction.delete,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Delete conversation',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String customerName;
  final String? url;

  const _Avatar({Key? key, required this.customerName, this.url})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(url!),
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: kPrimaryColor.withOpacity(0.08),
      child: Text(
        customerName.isNotEmpty ? customerName[0].toUpperCase() : '?',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: kPrimaryColor,
        ),
      ),
    );
  }
}

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
            'Loading your messages...',
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
              Icons.chat_bubble_outline,
              size: 64,
              color: kPrimaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Once customers start chatting with you,\nall conversations will appear here.',
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
              '''We couldn't load your messages.\nPlease try again.''', // Use triple quotes              textAlign: TextAlign.center,
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