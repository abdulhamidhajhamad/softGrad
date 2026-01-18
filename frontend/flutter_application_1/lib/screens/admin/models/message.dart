class Message {
  final String id;
  final String senderName;
  final String? avatarUrl;
  final String lastMessage;
  final String time;
  final bool unread;
  final String? otherParticipantId;

  Message({
    required this.id,
    required this.senderName,
    this.avatarUrl,
    required this.lastMessage,
    required this.time,
    required this.unread,
    this.otherParticipantId,
  });

  /// Factory to parse chat JSON and get the OTHER participant (not the admin)
  /// [currentUserId] is the admin's ID - we exclude this person from display
  factory Message.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    // Get the other participant (not the current user/admin)
    String senderName = 'Unknown';
    String? avatarUrl;
    String? otherParticipantId;
    
    print('🔍 Parsing chat: ${json['_id']}');
    print('🔍 currentUserId (admin): $currentUserId');
    
    if (json['participants'] != null && json['participants'] is List) {
      final participants = json['participants'] as List;
      print('🔍 Participants count: ${participants.length}');
      
      for (var p in participants) {
        if (p is Map) {
          final participantId = p['_id']?.toString() ?? p['id']?.toString();
          final role = p['role']?.toString();
          final userName = p['userName']?.toString();
          
          print('🔍 Checking participant: id=$participantId, role=$role, userName=$userName');
          
          // Skip if this is the current admin user
          if (currentUserId != null && participantId == currentUserId) {
            print('🔍 Skipping - this is the admin');
            continue;
          }
          
          // Skip if this participant has role 'admin'
          if (role == 'admin') {
            print('🔍 Skipping - role is admin');
            continue;
          }
          
          // Found the other participant (user or vendor)
          // For vendors, use companyName first, then fallback to userName
          if (role == 'vendor') {
            senderName = p['companyName']?.toString() ?? userName ?? 'Unknown';
            print('🏢 Vendor participant - using companyName: ${p['companyName']}');
          } else {
            senderName = userName ?? 'Unknown';
          }
          avatarUrl = p['imageUrl']?.toString() ?? p['avatar']?.toString();
          otherParticipantId = participantId;
          print('✅ Found other participant: $senderName (id: $otherParticipantId, role: $role)');
          break;
        }
      }
    }
    
    // Fallback to otherParticipant if backend provides it
    if (senderName == 'Unknown' && json['otherParticipant'] != null) {
      final other = json['otherParticipant'];
      if (other is Map) {
        senderName = other['userName']?.toString() ?? other['companyName']?.toString() ?? 'Unknown';
        avatarUrl = other['imageUrl']?.toString() ?? other['avatar']?.toString();
        otherParticipantId = other['_id']?.toString() ?? other['id']?.toString();
      }
    }
    
    // Parse lastMessage - can be String or Map
    String lastMessageText = '';
    final lastMsg = json['lastMessage'];
    if (lastMsg != null) {
      if (lastMsg is Map) {
        lastMessageText = lastMsg['content']?.toString() ?? '';
      } else {
        lastMessageText = lastMsg.toString();
      }
    } else if (json['content'] != null) {
      lastMessageText = json['content'].toString();
    }
    
    return Message(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      senderName: senderName,
      avatarUrl: avatarUrl,
      lastMessage: lastMessageText,
      time: json['time']?.toString() ?? json['updatedAt']?.toString() ?? json['createdAt']?.toString() ?? '',
      unread: json['unread'] == true || json['hasUnread'] == true,
      otherParticipantId: otherParticipantId,
    );
  }
}
