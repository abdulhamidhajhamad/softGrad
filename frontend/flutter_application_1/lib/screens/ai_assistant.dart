// lib/screens/ai_assistant.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile.dart'; // for kAccentColor

const String kAiSystemPrompt = '''
You are "My Wedding AI Assistant", a friendly, smart planner that helps users organize their wedding based on their budget and preferences.

Your task:
1. Ask short, clear questions.
2. Always remember the user’s previous answers.
3. Suggest categories and services based on the user’s budget (in NIS).
4. Provide cost breakdowns if possible.
5. Be practical — don’t exceed the user’s total budget.
6. Use simple, empathetic, and professional tone.

Available wedding categories:
- Venues
- Photographers
- Catering
- Cake
- Flower Shops
- Decor & Lighting
- Music & Entertainment
- Wedding Planners & Coordinators
- Card Printing
- Jewelry & Accessories
- Car Rental & Transportation
- Gift & Souvenir

At the beginning, show 3 example questions:
- "I have 20,000 NIS, what can I plan for?"
- "What are the best photographers under 3,000 NIS?"
- "Help me choose a venue and music package for 10,000 NIS."

Message rules:
- Max 400 characters per message from AI.
- Max 300 characters per message from user.
- Keep messages concise and helpful.
- Always continue the chat context — don’t reset memory unless user says "start over".

End your responses with a question or next suggestion to keep conversation going.
''';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({Key? key}) : super(key: key);

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  final List<_ChatMessage> _messages = [];
  bool _isSending = false;

  static const int _maxUserChars = 300;
  static const int _maxAiChars = 400;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    _messages.add(
      const _ChatMessage(
        text:
            "Hi, I'm your AI Wedding Assistant. Tell me your budget in NIS and what services you care about most, and I'll help you plan a package that fits.",
        isUser: false,
      ),
    );
    setState(() {});
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _handleQuickSuggestion(String text) {
    _inputCtrl.text = text;
    _sendMessage();
  }

  void _sendMessage() {
    final raw = _inputCtrl.text.trim();
    if (raw.isEmpty || _isSending) return;

    final userText =
        raw.length > _maxUserChars ? raw.substring(0, _maxUserChars) : raw;

    _inputCtrl.clear();

    setState(() {
      _messages.add(_ChatMessage(text: userText, isUser: true));
      _isSending = true;
    });

    _scrollToBottom();

    // TODO: replace this mock with real API call (OpenAI / backend).
    _mockAiReply(userText);
  }

  Future<void> _mockAiReply(String userText) async {
    await Future.delayed(const Duration(milliseconds: 700));

    final replyBase =
        "Thanks for sharing. I'll use your budget and preferences to suggest a balanced mix of venues, photographers and other services that stay within your total budget.";

    String reply =
        "$replyBase\n\nCan you tell me your total budget in NIS and which 2–3 categories are most important to you?";

    if (reply.length > _maxAiChars) {
      reply = reply.substring(0, _maxAiChars);
    }

    setState(() {
      _messages.add(_ChatMessage(text: reply, isUser: false));
      _isSending = false;
    });

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    const Color scaffoldBg = Color(0xFFF3F4F8);
    const Color textPrimary = Colors.black;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textPrimary),
        title: Text(
          'AI Wedding Assistant',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: Icon(Icons.auto_awesome, color: Colors.black87, size: 22),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: _AssistantHeaderCard(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _QuickSuggestionsRow(
              onTapSuggestion: _handleQuickSuggestion,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 32),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.only(
                            bottom: 12, left: 4, right: 4),
                        itemCount: _messages.length + (_isSending ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (_isSending && index == _messages.length) {
                            return const _TypingIndicator();
                          }
                          final msg = _messages[index];
                          return MessageBubble(
                            text: msg.text,
                            isUser: msg.isUser,
                          );
                        },
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 4, 10, 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color:
                                      const Color.fromARGB(255, 249, 239, 196),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x14000000),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _inputCtrl,
                                  maxLines: 4,
                                  minLines: 1,
                                  maxLength: _maxUserChars,
                                  decoration: InputDecoration(
                                    hintText:
                                        'Type your budget and I’ll suggest the best wedding services for you...',
                                    hintStyle: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                    border: InputBorder.none,
                                    counterText: '',
                                  ),
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _sendMessage,
                              child: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(23),
                                  gradient: LinearGradient(
                                    colors: [
                                      kAccentColor,
                                      kAccentColor.withOpacity(0.8),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x33000000),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.send,
                                    size: 20, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  const _ChatMessage({required this.text, required this.isUser});
}

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const MessageBubble({
    Key? key,
    required this.text,
    required this.isUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isUserMsg = isUser;

    final Gradient userGradient = const LinearGradient(
      colors: [Color(0xFFFFFFFF), Color(0xFFEDEBFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final Gradient aiGradient = LinearGradient(
      colors: [kAccentColor, kAccentColor.withOpacity(0.9)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Align(
      alignment: isUserMsg ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: isUserMsg ? userGradient : aiGradient,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: isUserMsg
                  ? const Radius.circular(18)
                  : const Radius.circular(6),
              bottomRight: isUserMsg
                  ? const Radius.circular(6)
                  : const Radius.circular(18),
            ),
            boxShadow: const [
              BoxShadow(
                blurRadius: 8,
                color: Color(0x22000000),
                offset: Offset(0, 4),
              )
            ],
          ),
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.4,
              color: isUserMsg ? Colors.black : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _AssistantHeaderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F4FF),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child:
                const Icon(Icons.auto_awesome, color: kAccentColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Wedding Assistant!',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Get personalized recommendations based on your wedding budget and preferences',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF555555),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickSuggestionsRow extends StatelessWidget {
  final void Function(String text) onTapSuggestion;

  const _QuickSuggestionsRow({Key? key, required this.onTapSuggestion})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final suggestions = <String>[
      "I have ₪20,000, what can I plan for?",
      "What are the best photographers under ₪3,000?",
      "Help me choose a venue and music package for ₪10,000.",
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Try one of these questions",
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 8),
        Column(
          children: suggestions
              .map(
                (s) => _SuggestionTile(
                  text: s,
                  onTap: () => onTapSuggestion(s),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _SuggestionTile({
    Key? key,
    required this.text,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Material(
        color: Colors.white, // أفتح من الخلفية
        borderRadius: BorderRadius.circular(16),
        elevation: 1.5,
        shadowColor: const Color(0x11000000),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE3E4F2),
                width: 0.7,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EEFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    size: 16,
                    color: kAccentColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF444444),
                      height: 1.4,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Color(0xFFB0B0B0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot(),
            const SizedBox(width: 4),
            _dot(),
            const SizedBox(width: 4),
            _dot(),
          ],
        ),
      ),
    );
  }

  Widget _dot() {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: kAccentColor,
      ),
    );
  }
}
