class Review {
  final String id;
  final String userName;
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
    required this.rating,
    required this.serviceName,
    this.serviceId,
    this.packageId,
    required this.text,
    required this.date,
    required this.isPositive,
  });
}
