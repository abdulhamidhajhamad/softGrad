// lib/screens/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/services/chat_provider_service.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'messages_provider.dart'
    show kPrimaryColor, kBackgroundColor, kTextColor;

class ChatMessage {
  final String id;
  final String text;
  final DateTime createdAt;
  final bool isMe;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.isMe,
    this.isRead = false,
  });
}

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String customerName;

  const ChatScreen({
    Key? key,
    required this.conversationId,
    required this.customerName,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoadingHistory = false;
  bool _isSending = false;
  
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    ChatProviderService().leaveChatRoom(widget.conversationId);
    ChatProviderService().onNewMessage = null;
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    // Get current user ID first
    final userMap = await AuthService.getUserData();
    _currentUserId = _cleanId(userMap?['_id'] ?? userMap?['id']);
    
    print('🔑 Current User ID: $_currentUserId');
    
    // Set currentUserId in ChatProviderService BEFORE initializing socket
    ChatProviderService().currentUserId = _currentUserId;
    
    // Initialize socket
    await ChatProviderService().initSocket();
    
    // Wait a bit for socket to connect
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Join chat room
    ChatProviderService().joinChatRoom(widget.conversationId);

    // Load messages first
    await _loadInitialMessages();

    // Mark messages as read AFTER loading (with retry mechanism)
    await _markMessagesAsReadWithRetry();

    // Listen for new messages
    ChatProviderService().onNewMessage = (message) {
      if (mounted) {
        setState(() {
          _messages.add(message);
        });
        _scrollToBottom();

        // Mark as read if message is not from me
        if (!message.isMe) {
          ChatProviderService().markAsRead(widget.conversationId);
        }
      }
    };
  }

  // Robust mark as read with retry mechanism
  Future<void> _markMessagesAsReadWithRetry() async {
    int attempts = 0;
    const maxAttempts = 3;
    const retryDelay = Duration(milliseconds: 500);

    while (attempts < maxAttempts) {
      try {
        print('📖 Attempting to mark messages as read (attempt ${attempts + 1})');
        await ChatProviderService().markAsRead(widget.conversationId);
        print('✅ Messages marked as read successfully');
        
        // Update local state to reflect read status
        if (mounted) {
          setState(() {
            for (int i = 0; i < _messages.length; i++) {
              if (!_messages[i].isMe) {
                _messages[i] = ChatMessage(
                  id: _messages[i].id,
                  text: _messages[i].text,
                  createdAt: _messages[i].createdAt,
                  isMe: _messages[i].isMe,
                  isRead: true,
                );
              }
            }
          });
        }
        
        break; // Success, exit loop
      } catch (e) {
        attempts++;
        print('⚠️ Failed to mark as read (attempt $attempts): $e');
        if (attempts < maxAttempts) {
          await Future.delayed(retryDelay);
        }
      }
    }
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

  Future<void> _loadInitialMessages() async {
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      print('❌ Cannot load messages: currentUserId is null or empty');
      return;
    }

    setState(() => _isLoadingHistory = true);
    
    try {
      final messages = await ChatProviderService().fetchMessages(widget.conversationId);
      
      print('📨 Loaded ${messages.length} messages');

      if (mounted) {
        setState(() {
          _messages.clear();
          
          for (var msg in messages) {
            // Extract sender ID with robust handling
            final senderData = msg['sender'];
            String senderId = '';
            
            if (senderData is Map) {
              senderId = _cleanId(senderData['_id'] ?? senderData['id']);
            } else if (senderData is String) {
              senderId = _cleanId(senderData);
            } else {
              senderId = _cleanId(senderData);
            }

            // Determine if message is from current user
            final isMe = senderId == _currentUserId;
            
            print('📝 Message: senderId=$senderId, currentUserId=$_currentUserId, isMe=$isMe');

            _messages.add(ChatMessage(
              id: msg['_id']?.toString() ?? '',
              text: msg['content']?.toString() ?? '',
              createdAt: DateTime.tryParse(msg['createdAt']?.toString() ?? '') ?? DateTime.now(),
              isMe: isMe,
              isRead: msg['isRead'] ?? false,
            ));
          }
        });
        
        print('✅ Successfully loaded ${_messages.length} messages');
        _scrollToBottom();
      }
    } catch (e) {
      print('❌ Error loading messages: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load messages: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending) return;

    final tempId = DateTime.now().millisecondsSinceEpoch.toString();

    final message = ChatMessage(
      id: tempId,
      text: text,
      createdAt: DateTime.now(),
      isMe: true, 
    );

    setState(() {
      _isSending = true;
      _messages.add(message);
    });
    _inputController.clear();
    _scrollToBottom();

    try {
      await ChatProviderService().sendMessage(
        widget.conversationId,
        text,
      );
    } catch (e) {
      print('❌ Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          backgroundColor: kBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: kTextColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.customerName,
                style: GoogleFonts.poppins(
                  color: kTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Customer chat',
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: Container(
                color: const Color(0xFFF7F7F7),
                child: _isLoadingHistory && _messages.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: kPrimaryColor,
                        ),
                      )
                    : _messages.isEmpty
                        ? _buildEmptyChatState()
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final msg = _messages[index];
                              final isMe = msg.isMe;
                              
                              return Align(
                                alignment: isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe ? kPrimaryColor : Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft:
                                          Radius.circular(isMe ? 16 : 4),
                                      bottomRight:
                                          Radius.circular(isMe ? 4 : 16),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: isMe
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        msg.text,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: isMe
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatTime(msg.createdAt),
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: isMe
                                              ? Colors.white70
                                              : Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ),

            SafeArea(
              top: false,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFE5E5E5)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F3F3),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _inputController,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText: 'Write a message...',
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: kTextColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _isSending ? null : _sendMessage,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _isSending
                              ? kPrimaryColor.withOpacity(0.6)
                              : kPrimaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChatState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline,
                size: 56, color: kPrimaryColor),
            const SizedBox(height: 12),
            Text(
              'Start the conversation',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Send the first message to your customer\nand keep all planning details here.',
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