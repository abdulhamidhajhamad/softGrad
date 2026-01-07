import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import '../models/message.dart';
import '../../../services/admin_service/admin_service.dart';
import '../../../services/socket_service.dart';
import '../../../services/auth_service.dart';
import 'admin_chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> with WidgetsBindingObserver {
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  StreamSubscription? _messageSubscription;
  String? _currentAdminId;

  @override
  void initState() {
    super.initState();
    print('🟢 MessagesScreen initState() called');
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🟢 PostFrameCallback - calling _fetchMessages');
      _initializeAndFetch();
    });
    _setupRealtimeUpdates();
  }

  Future<void> _initializeAndFetch() async {
    // Get current admin user ID
    final userData = await AuthService.getUserData();
    _currentAdminId = userData?['_id']?.toString() ?? userData?['id']?.toString();
    print('🔑 Current Admin ID: $_currentAdminId');
    await _fetchMessages();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchMessages();
    }
  }

  Future<void> _fetchMessages() async {
    print('📨 _fetchMessages() called');
    try {
      if (_isLoading) {
        // Already loading, don't set state again
      } else {
        if (mounted) setState(() => _isLoading = true);
      }
      
      print('📨 Calling AdminService.getChats()...');
      final chatsData = await AdminService.getChats();
      print('📨 Got ${chatsData.length} chats from API');
      print('📨 Current Admin ID for filtering: $_currentAdminId');
      
      if (mounted) {
        setState(() {
          _messages = chatsData.map((m) {
            print('📨 Parsing message: ${m['_id']}');
            return Message.fromJson(m, currentUserId: _currentAdminId);
          }).toList();
          print('📨 Parsed ${_messages.length} messages');
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching messages: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _setupRealtimeUpdates() {
    _messageSubscription = SocketService.messageStream.listen((data) {
      print('📨 Real-time update received - refreshing chats');
      _fetchMessages();
    });
  }

  @override
  Widget build(BuildContext context) {
    print('🔵 MessagesScreen build() - isLoading: $_isLoading, hasError: $_hasError, messages: ${_messages.length}');
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.alertCircle, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Failed to load messages',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchMessages,
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: Text('Retry', style: GoogleFonts.poppins()),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    final unreadCount = _messages.where((m) => m.unread).length;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Messages',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$unreadCount unread messages',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.messageSquare, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your conversations will appear here',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _messages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final message = _messages[index];

                return Dismissible(
                  key: ValueKey(message.hashCode),
                  direction: DismissDirection.endToStart,
                  background: _DeleteBackground(),
                  confirmDismiss: (_) => _confirmDelete(context, message),
                  onDismissed: (_) => _deleteMessage(context, message),
                  child: GestureDetector(
                    onTap: () => _openChat(context, message),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: message.unread
                            ? kPrimaryColor.withOpacity(0.05)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: message.unread
                              ? kPrimaryColor.withOpacity(0.2)
                              : Colors.grey[200]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                backgroundColor: kPrimaryColor.withOpacity(0.1),
                              radius: 24,
                              child: Text(
                                message.senderName[0].toUpperCase(),
                                style: GoogleFonts.poppins(
                                  color: kPrimaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (message.unread)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: kPrimaryColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    message.senderName,
                                    style: GoogleFonts.poppins(
                                      fontWeight: message.unread
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      fontSize: 14,
                                      color: kTextColor,
                                    ),
                                  ),
                                  Text(
                                    message.time,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                message.lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: message.unread
                                      ? kTextColor
                                      : Colors.grey[600],
                                  fontWeight: message.unread
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _openChat(BuildContext context, Message message) async {
    // Navigate to chat screen
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminChatScreen(
          chatId: message.id,
          participantName: message.senderName,
          participantAvatar: message.avatarUrl,
        ),
      ),
    );
    // Refresh messages when returning
    _fetchMessages();
  }

  Future<bool?> _confirmDelete(BuildContext context, dynamic message) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete message?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This will remove this message from the list.\n\n"${message.lastMessage}"',
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

  void _deleteMessage(BuildContext context, dynamic message) {
    final removedIndex = _messages.indexOf(message);
    if (removedIndex == -1) return;

    setState(() => _messages.removeAt(removedIndex));

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Message deleted', style: GoogleFonts.poppins()),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() => _messages.insert(removedIndex, message));
          },
        ),
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade600,
        borderRadius: BorderRadius.circular(12),
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
