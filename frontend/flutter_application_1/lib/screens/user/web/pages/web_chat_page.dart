// lib/screens/user/web/pages/web_chat_page.dart
//
// ✅ Web Chat Page
// ✅ Split view: Threads list + Active conversation
// ✅ Real-time messaging with socket

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../web_theme.dart';
import 'package:flutter_application_1/services/user_service/chat_user_service.dart';

class WebChatPage extends StatefulWidget {
  const WebChatPage({super.key});

  @override
  State<WebChatPage> createState() => _WebChatPageState();
}

class _WebChatPageState extends State<WebChatPage> {
  final ChatUserService _chatService = ChatUserService();
  List<ChatThreadModel> _threads = [];
  List<ChatMessageModel> _messages = [];
  bool _isLoading = true;
  bool _isLoadingMessages = false;
  ChatThreadModel? _selectedThread;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    await _chatService.initializeUserId();
    await _chatService.initSocket();
    await _loadThreads();
    
    // Listen for new messages
    _chatService.messageStream.listen((message) {
      if (_selectedThread != null) {
        setState(() {
          _messages.add(message);
        });
        _scrollToBottom();
      }
      _loadThreads(); // Refresh threads for updated last message
    });
  }

  Future<void> _loadThreads() async {
    try {
      final threads = await _chatService.fetchUserChats();
      setState(() {
        _threads = threads;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMessages(String chatId) async {
    setState(() => _isLoadingMessages = true);
    
    try {
      final messages = await _chatService.fetchChatMessages(chatId);
      await _chatService.markAsRead(chatId);
      
      setState(() {
        _messages = messages;
        _isLoadingMessages = false;
      });
      
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoadingMessages = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _selectedThread == null) return;
    
    _messageController.clear();
    
    await _chatService.sendMessage(_selectedThread!.id, text);
    _loadMessages(_selectedThread!.id);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        children: [
          // Threads sidebar
          SizedBox(
            width: 360,
            child: _buildThreadsList(),
          ),
          
          const SizedBox(width: 24),
          
          // Chat area
          Expanded(
            child: _buildChatArea(),
          ),
        ],
      ),
    );
  }

  Widget _buildThreadsList() {
    return Container(
      decoration: WebDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Text('Messages', style: WebTypography.h4),
                const Spacer(),
                ValueListenableBuilder<int>(
                  valueListenable: ChatUserService.unreadGlobalCount,
                  builder: (context, count, _) {
                    if (count == 0) return const SizedBox();
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: kWebPrimary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                hintStyle: GoogleFonts.poppins(fontSize: 14, color: kWebTextMuted),
                prefixIcon: const Icon(Icons.search_rounded, color: kWebTextMuted),
                filled: true,
                fillColor: kWebBgSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          
          // Threads list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: kWebPrimary))
                : _threads.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 48, color: kWebTextMuted),
                            const SizedBox(height: 16),
                            Text('No conversations yet', style: WebTypography.body.copyWith(color: kWebTextMuted)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _threads.length,
                        itemBuilder: (context, index) {
                          final thread = _threads[index];
                          final isSelected = _selectedThread?.id == thread.id;
                          
                          return InkWell(
                            onTap: () {
                              setState(() => _selectedThread = thread);
                              _chatService.setActiveChat(thread.id);
                              _loadMessages(thread.id);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected ? kWebPrimary.withOpacity(0.1) : Colors.transparent,
                                border: Border(
                                  left: BorderSide(
                                    color: isSelected ? kWebPrimary : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Avatar
                                  Stack(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: kWebPrimary.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            thread.title.isNotEmpty ? thread.title[0].toUpperCase() : '?',
                                            style: GoogleFonts.poppins(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: kWebPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (thread.online)
                                        Positioned(
                                          bottom: 2,
                                          right: 2,
                                          child: Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: kWebSuccess,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 2),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  
                                  const SizedBox(width: 12),
                                  
                                  // Content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                thread.title,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  fontWeight: thread.unreadCount > 0 
                                                      ? FontWeight.w600 
                                                      : FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Text(
                                              _formatTime(thread.lastTime),
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color: kWebTextMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                thread.lastMessage,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  color: kWebTextMuted,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (thread.unreadCount > 0)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: kWebPrimary,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  '${thread.unreadCount}',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
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
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    if (_selectedThread == null) {
      return Container(
        decoration: WebDecorations.card,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: kWebPrimary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat_rounded, color: kWebPrimary, size: 40),
              ),
              const SizedBox(height: 24),
              Text('Select a conversation', style: WebTypography.h5),
              const SizedBox(height: 8),
              Text(
                'Choose from your existing conversations\nor start a new one',
                style: WebTypography.body.copyWith(color: kWebTextMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: WebDecorations.card,
      child: Column(
        children: [
          // Chat header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kWebBgCard,
              border: Border(bottom: BorderSide(color: kWebBorder)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: kWebPrimary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _selectedThread!.title.isNotEmpty 
                          ? _selectedThread!.title[0].toUpperCase() 
                          : '?',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: kWebPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_selectedThread!.title, style: WebTypography.h6),
                      Text(
                        _selectedThread!.online ? 'Online' : 'Offline',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: _selectedThread!.online ? kWebSuccess : kWebTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_vert_rounded),
                  color: kWebTextMuted,
                ),
              ],
            ),
          ),
          
          // Messages
          Expanded(
            child: _isLoadingMessages
                ? const Center(child: CircularProgressIndicator(color: kWebPrimary))
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet. Start the conversation!',
                          style: WebTypography.body.copyWith(color: kWebTextMuted),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(20),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return _buildMessageBubble(message);
                        },
                      ),
          ),
          
          // Input
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kWebBgCard,
              border: Border(top: BorderSide(color: kWebBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: GoogleFonts.poppins(fontSize: 14, color: kWebTextMuted),
                      filled: true,
                      fillColor: kWebBgSecondary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: kWebPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message) {
    final isMe = message.fromMe;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? kWebPrimary : kWebBgSecondary,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.text,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isMe ? Colors.white : kWebTextBody,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatMessageTime(message.time),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: isMe ? Colors.white70 : kWebTextMuted,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                        size: 14,
                        color: message.isRead ? Colors.white : Colors.white70,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Now';
    }
  }

  String _formatMessageTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
