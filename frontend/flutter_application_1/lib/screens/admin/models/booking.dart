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
}
