import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kPrimary = Color.fromARGB(215, 20, 20, 215);
const Color kBg = Color(0xFFF6F7FB);
const Color kText = Color(0xFF0B1220);
const Color kMuted = Color(0xFF6B7280);

class ChatInsideSearchScreen extends StatefulWidget {
  final String providerName;
  final String providerEmail;
  final String providerPhone;

  const ChatInsideSearchScreen({
    super.key,
    required this.providerName,
    required this.providerEmail,
    required this.providerPhone,
  });

  @override
  State<ChatInsideSearchScreen> createState() => _ChatInsideSearchScreenState();
}

class _ChatInsideSearchScreenState extends State<ChatInsideSearchScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  final List<_Msg> _msgs = [
    _Msg(text: 'Hi! How can I help you?', me: false),
    _Msg(text: 'I want details about the service.', me: true),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _msgs.add(_Msg(text: t, me: true));
      _msgs.add(_Msg(text: 'Sure! I will reply shortly ✅', me: false));
    });
    _ctrl.clear();
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: kText),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.providerName,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w900,
                color: kText,
              ),
            ),
            Text(
              '${widget.providerEmail} • ${widget.providerPhone}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: kMuted,
                fontSize: 11.2,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: _msgs.length,
              itemBuilder: (_, i) => _Bubble(m: _msgs[i]),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.black.withOpacity(0.06)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 24,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Write a message...',
                        hintStyle: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: kMuted,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF3F4F6),
                        border: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.black.withOpacity(0.08)),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.black.withOpacity(0.08)),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: kPrimary.withOpacity(.6)),
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        color: kText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: _send,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: kText,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: kPrimary.withOpacity(.28)),
                      ),
                      child: Icon(Icons.send_rounded, color: kPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Msg {
  final String text;
  final bool me;
  _Msg({required this.text, required this.me});
}

class _Bubble extends StatelessWidget {
  final _Msg m;
  const _Bubble({required this.m});

  @override
  Widget build(BuildContext context) {
    final align = m.me ? Alignment.centerRight : Alignment.centerLeft;
    final bg = m.me ? kText : Colors.white;
    final fg = m.me ? Colors.white : kText;
    final bd = m.me ? Colors.transparent : Colors.black.withOpacity(0.06);

    return Align(
      alignment: align,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: bd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Text(
          m.text,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: fg,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}