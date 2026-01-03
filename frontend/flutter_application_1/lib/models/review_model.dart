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
    return Review(
      id: json['_id'] ?? '',
      userId: json['userId']?['_id'] ?? json['userId'] ?? '',
      userName: json['userId']?['userName'] ?? json['userName'] ?? 'Anonymous',
      userPhoto: json['userId']?['imageUrl'],
      serviceId: json['serviceId']?['_id'] ?? json['serviceId'] ?? '',
      serviceName: json['serviceId']?['serviceName'] ?? json['serviceName'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      tags: List<String>.from(json['tags'] ?? []),
      images: List<String>.from(json['images'] ?? []),
      reviewDate: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
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
    return PendingReview(
      bookingId: json['bookingId'] ?? '',
      serviceId: json['serviceId'] ?? '',
      serviceName: json['serviceName'] ?? 'Service',
      serviceImage: json['serviceImage'],
      companyName: json['companyName'] ?? '',
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