class Booking {
  final String id;
  final String customerName;
  final String? packageName;
  final String date;
  final double amount;
  final String status;

  Booking({
    required this.id,
    required this.customerName,
    this.packageName,
    required this.date,
    required this.amount,
    required this.status,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['_id'] ?? json['id'] ?? '',
      customerName: json['customerName'] ?? json['user']?['userName'] ?? 'Unknown',
      packageName: json['packageName'] ?? json['package']?['name'] ?? json['service']?['name'],
      date: json['date'] ?? json['createdAt'] ?? '',
      amount: (json['amount'] ?? json['totalPrice'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
    );
  }
}
