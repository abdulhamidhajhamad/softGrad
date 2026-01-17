// lib/screens/admin/screens/admin_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import '../../../services/admin_service/admin_service.dart';
import '../../../services/auth_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class AdminChatMessage {
  final String id;
  final String text;
  final DateTime createdAt;
  final bool isMe;
  final bool isRead;

  AdminChatMessage({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.isMe,
    this.isRead = false,
  });
}

class AdminChatScreen extends StatefulWidget {
  final String chatId;
  final String participantName;
  final String? participantAvatar;

  const AdminChatScreen({
    super.key,
    required this.chatId,
    required this.participantName,
    this.participantAvatar,
  });

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> with WidgetsBindingObserver {
  final List<AdminChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isSending = false;
  String? _currentUserId;
  IO.Socket? _socket;

  static String get _baseUrl => AuthService.baseUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeChat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _socket?.disconnect();
    _socket?.dispose();
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  String _cleanId(dynamic id) {
    if (id == null) return '';
    return id.toString()
        .replaceAll('ObjectId', '')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .trim();
  }

  Future<void> _initializeChat() async {
    setState(() => _isLoading = true);

    // Get current user ID
    final userData = await AuthService.getUserData();
    _currentUserId = _cleanId(userData?['_id'] ?? userData?['id']);
    print('🔑 Admin User ID: $_currentUserId');

    // Initialize socket
    await _initSocket();

    // Load messages
    await _loadMessages();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initSocket() async {
    final token = await AuthService.getToken();
    if (token == null) {
      print('❌ No token for socket');
      return;
    }

    print('🔌 Initializing admin chat socket...');

    _socket = IO.io(
      _baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setQuery({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .enableForceNewConnection()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      print('✅ Admin Chat Socket Connected');
      _socket?.emit('joinRoom', {'chatId': widget.chatId, 'userId': _currentUserId});
      // ✅ Mark messages as read when entering the chat
      _markMessagesAsRead();
    });

    _socket!.onDisconnect((_) {
      print('❌ Admin Chat Socket Disconnected');
    });

    // Listen for new messages
    _socket?.on('newMessage', (data) {
      print('📨 New message received: $data');
      
      final messageData = data['message'] ?? data;
      if (messageData != null) {
        final senderData = messageData['sender'];
        String senderId = senderData is Map
            ? _cleanId(senderData['_id'] ?? senderData['id'])
            : _cleanId(senderData);

        final chatID = _cleanId(messageData['chat'] ?? data['chatId']);
        final isMe = senderId == _currentUserId;

        // Only add if for this chat
        if (chatID == widget.chatId) {
          final newMessage = AdminChatMessage(
            id: messageData['_id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
            text: messageData['content']?.toString() ?? '',
            createdAt: DateTime.tryParse(messageData['createdAt']?.toString() ?? '') ?? DateTime.now(),
            isMe: isMe,
            isRead: messageData['isRead'] ?? false,
          );

          // Check for duplicates
          final exists = _messages.any((m) =>
              (m.id == newMessage.id) ||
              (m.text == newMessage.text && m.createdAt.difference(newMessage.createdAt).abs().inSeconds < 2));

          if (!exists && mounted) {
            setState(() {
              _messages.insert(0, newMessage);
            });
            _scrollToBottom();
          }
        }
      }
    });

    _socket?.on('messagesRead', (data) {
      print('✅ Messages marked as read');
      if (mounted) {
        _loadMessages(silent: true);
      }
    });
  }

  /// ✅ Mark all messages in this chat as read
  void _markMessagesAsRead() {
    if (_socket?.connected == true && widget.chatId.isNotEmpty) {
      print('📖 Marking messages as read for chat: ${widget.chatId}');
      _socket?.emit('markAsRead', {
        'chatId': widget.chatId,
        'userId': _currentUserId,
      });
    }
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final messagesData = await AdminService.getMessages(widget.chatId);
      
      if (mounted) {
        final messages = messagesData.map((m) {
          final senderData = m['sender'];
          String senderId = senderData is Map
              ? _cleanId(senderData['_id'] ?? senderData['id'])
              : _cleanId(senderData);

          return AdminChatMessage(
            id: _cleanId(m['_id']),
            text: m['content'] ?? '',
            createdAt: DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
            isMe: senderId == _currentUserId,
            isRead: m['isRead'] ?? false,
          );
        }).toList();

        setState(() {
          _messages.clear();
          _messages.addAll(messages.reversed);
        });

        if (!silent) {
          _scrollToBottom(jump: true);
        }
      }
    } catch (e) {
      print('❌ Error loading messages: $e');
    } finally {
      if (!silent && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (jump) {
          _scrollController.jumpTo(0.0);
        } else {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  Future<void> _handleSendMessage() async {
    if (_inputController.text.trim().isEmpty || _isSending) return;

    final content = _inputController.text.trim();
    _inputController.clear();

    setState(() {
      _isSending = true;
      // Add temp message
      final tempMessage = AdminChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: content,
        createdAt: DateTime.now(),
        isMe: true,
        isRead: false,
      );
      _messages.insert(0, tempMessage);
      _scrollToBottom();
    });

    try {
      await AdminService.sendMessage(widget.chatId, content);
      print('✅ Message sent successfully');
    } catch (e) {
      print('❌ Failed to send message: $e');
      // Remove temp message on error
      if (mounted) {
        setState(() {
          _messages.removeAt(0);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: kTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: kPrimaryColor.withOpacity(0.1),
              radius: 18,
              backgroundImage: widget.participantAvatar != null
                  ? NetworkImage(widget.participantAvatar!)
                  : null,
              child: widget.participantAvatar == null
                  ? Text(
                      widget.participantName.isNotEmpty
                          ? widget.participantName[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.poppins(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.participantName,
                style: GoogleFonts.poppins(
                  color: kTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                  : _messages.isEmpty
                      ? _buildEmptyState()
                      : _buildMessagesList(),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.messageSquare,
              size: 56,
              color: kPrimaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Start the conversation',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send your first message to ${widget.participantName}',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      reverse: true,
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(AdminChatMessage message) {
    final isMe = message.isMe;
    final borderRadius = BorderRadius.circular(16);
    // My messages: Purple (kPrimaryColor), Their messages: White
    final bubbleColor = isMe ? kPrimaryColor : Colors.white;
    final textColor = isMe ? Colors.white : kTextColor;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: isMe
                    ? borderRadius.copyWith(bottomRight: const Radius.circular(4))
                    : borderRadius.copyWith(bottomLeft: const Radius.circular(4)),
                border: isMe ? null : Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.isRead ? Colors.blue.shade600 : Colors.grey,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: kBackgroundColor,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        style: GoogleFonts.poppins(fontSize: 14, color: kTextColor),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onSubmitted: (_) => _handleSendMessage(),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _handleSendMessage,
              child: Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: kPrimaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.send,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
