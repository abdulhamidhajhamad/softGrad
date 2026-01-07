class Message {
  final String id;
  final String senderName;
  final String? avatarUrl;
  final String lastMessage;
  final String time;
  final bool unread;

  Message({
    required this.id,
    required this.senderName,
    this.avatarUrl,
    required this.lastMessage,
    required this.time,
    required this.unread,
  });
}
