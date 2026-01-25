class Review {
  final String id;
  final String userName;
  final String? userId;
  final String? providerId;
  final String? providerName;
  final double rating;
  final String serviceName;
  final String? serviceId;
  final String? packageId;
  final String text;
  final String date;
  final bool isPositive;

  Review({
    required this.id,
    required this.userName,
    this.userId,
    this.providerId,
    this.providerName,
    required this.rating,
    required this.serviceName,
    this.serviceId,
    this.packageId,
    required this.text,
    required this.date,
    required this.isPositive,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    // Extract user ID from various possible locations
    String? userId;
    if (json['user'] is Map) {
      userId = json['user']['_id']?.toString() ?? json['user']['id']?.toString();
    } else if (json['userId'] != null) {
      userId = json['userId'].toString();
    } else if (json['user'] is String) {
      userId = json['user'];
    }
    
    // Extract provider ID and name from various possible locations
    String? providerId;
    String? providerName;
    
    // ✅ First check direct fields from API response
    providerId = json['providerId']?.toString();
    providerName = json['providerName']?.toString();
    
    // Try from service if not found
    if (json['service'] is Map) {
      final service = json['service'];
      if (service['provider'] is Map) {
        providerId ??= service['provider']['_id']?.toString() ?? service['provider']['id']?.toString();
        providerName ??= service['provider']['companyName'] ?? service['provider']['userName'];
      } else if (service['providerId'] != null) {
        providerId ??= service['providerId'].toString();
      }
      providerName ??= service['providerName'];
    }
    
    // Try from package if not found
    if (json['package'] is Map) {
      final package = json['package'];
      if (package['provider'] is Map) {
        providerId ??= package['provider']['_id']?.toString() ?? package['provider']['id']?.toString();
        providerName ??= package['provider']['companyName'] ?? package['provider']['userName'];
      } else if (package['providerId'] != null) {
        providerId ??= package['providerId'].toString();
      }
      providerName ??= package['providerName'];
    }
    
    // Debug logging
    print('📝 Review parsed: userId=$userId, providerId=$providerId, providerName=$providerName');
    
    return Review(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userName: json['userName'] ?? json['user']?['userName'] ?? 'Unknown',
      userId: userId,
      providerId: providerId,
      providerName: providerName,
      rating: (json['rating'] ?? 0).toDouble(),
      serviceName: json['serviceName'] ?? json['service']?['name'] ?? json['package']?['name'] ?? 'Unknown',
      serviceId: json['serviceId']?.toString() ?? json['service']?['_id']?.toString(),
      packageId: json['packageId']?.toString() ?? json['package']?['_id']?.toString(),
      text: json['comment'] ?? json['text'] ?? '',
      date: json['createdAt'] ?? json['date'] ?? '',
      isPositive: (json['rating'] ?? 0) >= 4,
    );
  }
}
