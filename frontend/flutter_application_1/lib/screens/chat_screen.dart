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

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final List<ChatMessage> _messages = [];

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoadingHistory = false;
  bool _isSending = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeChat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ChatProviderService().onNewMessage = null; 
    ChatProviderService().onMessageStatusUpdate = null;
    ChatProviderService().setActiveChat(null);

    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // ✅ عند العودة للتطبيق، وضع علامة مقروءة فقط إذا كان هناك رسائل من الطرف الآخر
      _markAsReadIfNeeded();
    }
  }

  /// ✅ دالة جديدة: تضع علامة مقروءة فقط إذا كانت آخر رسالة ليست مني
  Future<void> _markAsReadIfNeeded() async {
    if (_messages.isEmpty) return;
    
    // ✅ نحصل على آخر رسالة (الأحدث)
    final latestMessage = _messages.first;
    
    // ✅ إذا آخر رسالة ليست مني، نضع علامة مقروءة
    if (!latestMessage.isMe) {
      print('📖 Marking as read (last message is from other person)');
      await ChatProviderService().markAsRead(widget.conversationId);
    } else {
      print('🚫 NOT marking as read (last message is mine)');
    }
  }

  Future<void> _initializeChat() async {
    if (!mounted) return;

    setState(() {
      _isLoadingHistory = true;
      _messages.clear();
    });

    // 1. جلب ID المستخدم الحالي
    final userMap = await AuthService.getUserData();
    _currentUserId = _cleanId(userMap?['_id'] ?? userMap?['id']);
    
    print('🔑 Current User ID: $_currentUserId');
    
    // 2. تعيين الدردشة النشطة و ID المستخدم في الـ Service
    ChatProviderService().currentUserId = _currentUserId;
    ChatProviderService().setActiveChat(widget.conversationId);
    
    // 3. تهيئة الـ Socket
    await ChatProviderService().initSocket();
    
    // 4. تحميل الرسائل
    await _loadChatHistory(); 

    // 5. ✅ وضع علامة مقروءة فقط إذا كانت آخر رسالة من الطرف الآخر
    await _markAsReadIfNeeded();

    // 6. ✅ إعداد مستمع الرسائل الجديدة (real-time)
    ChatProviderService().onNewMessage = (message) {
      if (mounted) {
        print('📨 New message received in ChatScreen: ${message.text}');
        print('📨 Message isMe: ${message.isMe}');
        
        // التحقق من عدم وجود تكرار
        final exists = _messages.any((m) => 
          (m.id == message.id) || 
          (m.text == message.text && m.createdAt.difference(message.createdAt).abs().inSeconds < 2)
        );
        
        if (!exists) {
          setState(() {
            _messages.insert(0, message);
          });
          _scrollToBottom();
          print('✅ Message added to UI');
          
          // ✅ FIX: وضع علامة مقروءة فقط إذا كانت الرسالة من الطرف الآخر
          if (!message.isMe) {
            print('📖 Marking message as read (from other person)');
            ChatProviderService().markAsRead(widget.conversationId);
          } else {
            print('🚫 NOT marking as read (my own message)');
          }
        } 
      }
    };
    
    // ✅ مستمع تحديث حالة الرسائل
    ChatProviderService().onMessageStatusUpdate = () {
      if (mounted) {
        _loadChatHistory(silent: true); 
      }
    };

    if (mounted) {
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _loadChatHistory({bool silent = false}) async { 
    if (!mounted || _currentUserId == null || _currentUserId!.isEmpty) return;

    if (!silent) {
      setState(() {
        _isLoadingHistory = true;
      });
    }

    try {
      final messages = await ChatProviderService().fetchChatMessages(widget.conversationId);
      if (mounted) {
        setState(() {
          _messages.clear();
          // ✅ عكس الترتيب لعرض الأحدث في الأسفل
          _messages.addAll(messages.reversed); 
        });
        if (!silent) {
          _scrollToBottom(jump: true);
        }
      }
    } catch (e) {
      print('❌ Error loading chat history: $e');
    } finally {
      if (mounted && !silent) {
        setState(() {
          _isLoadingHistory = false;
        });
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

  Future<void> _handleSendMessage() async {
    if (_inputController.text.trim().isEmpty || _isSending) return;

    final content = _inputController.text.trim();
    _inputController.clear();

    setState(() {
      _isSending = true;
      // ✅ رسالتي تظهر مع isRead: false (لأنها ما زالت لم تُقرأ من الطرف الآخر)
      final tempMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(), 
        text: content,
        createdAt: DateTime.now(),
        isMe: true,
        isRead: false, // ✅ دائماً false عند الإرسال
      );
      _messages.insert(0, tempMessage); 
      _scrollToBottom();
    });

    try {
      await ChatProviderService().sendMessage(widget.conversationId, content);
      print('✅ Message sent successfully');
    } catch (e) {
      print('❌ Failed to send message: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: Text(
          widget.customerName,
          style: GoogleFonts.poppins(
            color: kTextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: kTextColor),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoadingHistory
                  ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                  : _messages.isEmpty
                      ? _buildEmptyChatState()
                      : _buildChatList(),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      reverse: true,
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isMe = message.isMe;
    final borderRadius = BorderRadius.circular(15);
    final bubbleColor = isMe ? kPrimaryColor : Colors.grey.shade200;
    final textColor = isMe ? Colors.white : kTextColor;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
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
                    ? borderRadius.copyWith(topRight: Radius.zero)
                    : borderRadius.copyWith(topLeft: Radius.zero),
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
                    color: Colors.grey,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  // ✅ علامة صح واحدة (رمادي) = تم الإرسال
                  // ✅ علامتين صح (أزرق) = تم القراءة من الطرف الآخر
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.isRead ? Colors.blue.shade600 : Colors.grey,
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: kBackgroundColor,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        style: GoogleFonts.poppins(fontSize: 14, color: kTextColor),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: GoogleFonts.poppins(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onSubmitted: (_) => _handleSendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _handleSendMessage,
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: kPrimaryColor,
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