class SalesItem {
  final String id;
  final String name;
  final String? companyName;
  final String imageUrl;
  final double totalSales;
  final String type;
  final int totalBookings;
  final int canceledBookings;

  SalesItem({
    required this.id,
    required this.name,
    this.companyName,
    required this.imageUrl,
    required this.totalSales,
    required this.type,
    this.totalBookings = 0,
    this.canceledBookings = 0,
  });
}
