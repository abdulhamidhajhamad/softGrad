// lib/models/review_model.dart

class Review {
  final String id;
  final String userId;
  final String userName;
  final String? userPhoto;
  final String serviceId;
  final String serviceName;
  final int rating; // 1-5
  final String? comment;
  final List<String> tags;
  final List<String> images;
  final DateTime reviewDate;

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.serviceId,
    required this.serviceName,
    required this.rating,
    this.comment,
    required this.tags,
    required this.images,
    required this.reviewDate,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    // Handle userId - can be string or object
    String parsedUserId = '';
    String parsedUserName = 'Anonymous';
    String? parsedUserPhoto;
    
    if (json['userId'] is Map) {
      parsedUserId = json['userId']['_id']?.toString() ?? '';
      parsedUserName = json['userId']['userName']?.toString() ?? 'Anonymous';
      parsedUserPhoto = json['userId']['imageUrl']?.toString();
    } else {
      parsedUserId = json['userId']?.toString() ?? '';
      parsedUserName = json['userName']?.toString() ?? 'Anonymous';
    }
    
    // Handle serviceId - can be string or object
    String parsedServiceId = '';
    String parsedServiceName = '';
    
    if (json['serviceId'] is Map) {
      parsedServiceId = json['serviceId']['_id']?.toString() ?? '';
      parsedServiceName = json['serviceId']['serviceName']?.toString() ?? '';
    } else {
      parsedServiceId = json['serviceId']?.toString() ?? '';
      parsedServiceName = json['serviceName']?.toString() ?? '';
    }
    
    return Review(
      id: json['_id']?.toString() ?? '',
      userId: parsedUserId,
      userName: parsedUserName,
      userPhoto: parsedUserPhoto,
      serviceId: parsedServiceId,
      serviceName: parsedServiceName,
      rating: json['rating'] is int ? json['rating'] : int.tryParse(json['rating']?.toString() ?? '0') ?? 0,
      comment: json['comment']?.toString(),
      tags: List<String>.from(json['tags'] ?? []),
      images: List<String>.from(json['images'] ?? []),
      reviewDate: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'comment': comment,
      'tags': tags,
      'images': images,
    };
  }
}

class PendingReview {
  final String bookingId;
  final String serviceId;
  final String serviceName;
  final String? serviceImage;
  final String companyName;
  final DateTime bookingDate;

  PendingReview({
    required this.bookingId,
    required this.serviceId,
    required this.serviceName,
    this.serviceImage,
    required this.companyName,
    required this.bookingDate,
  });

  factory PendingReview.fromJson(Map<String, dynamic> json) {
    print('🔍 PendingReview.fromJson:');
    print('   bookingId: ${json['bookingId']}');
    print('   serviceId: ${json['serviceId']}');
    print('   serviceName: ${json['serviceName']}');
    print('   companyName: ${json['companyName']}');
    
    return PendingReview(
      bookingId: json['bookingId']?.toString() ?? '',
      serviceId: json['serviceId']?.toString() ?? '',
      serviceName: json['serviceName']?.toString() ?? 'Service',
      serviceImage: json['serviceImage']?.toString(),
      companyName: json['companyName']?.toString() ?? '',
      bookingDate: DateTime.parse(json['bookingDate'] ?? DateTime.now().toIso8601String()),
    );
  }

  String get daysAgo {
    final now = DateTime.now();
    final difference = now.difference(bookingDate).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return '1 day ago';
    return '$difference days ago';
  }
}