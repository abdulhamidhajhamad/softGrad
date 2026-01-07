class NotificationItem {
  final String id;
  final String title;
  final String description;
  final String time;
  bool read;
  final String type;

  NotificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.read,
    required this.type,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['message'] ?? json['description'] ?? '',
      time: json['createdAt'] ?? json['time'] ?? '',
      read: json['read'] ?? json['isRead'] ?? false,
      type: json['type'] ?? 'system',
    );
  }
}
