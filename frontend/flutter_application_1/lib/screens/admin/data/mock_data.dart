import '../models/review.dart';
import '../models/message.dart';
import '../models/notification_item.dart';
import '../models/sales_item.dart';
import '../models/user.dart';
import '../models/booking.dart';

final List<Map<String, dynamic>> mockFinancialData = [
  {'name': 'Jan', 'value': 12000},
  {'name': 'Feb', 'value': 19000},
  {'name': 'Mar', 'value': 15000},
  {'name': 'Apr', 'value': 22000},
  {'name': 'May', 'value': 28000},
  {'name': 'Jun', 'value': 26000},
  {'name': 'Jul', 'value': 34000},
];

final List<Review> mockReviews = [
  Review(
    id: '1',
    userName: 'Sarah Jenkins',
    rating: 5,
    serviceName: 'Wedding Photography',
    serviceId: '1',
    text: 'Absolutely stunning work! The team was professional, on time, and captured every moment perfectly. We couldn\'t be happier with the results.',
    date: '2h ago',
    isPositive: true,
  ),
  Review(
    id: '2',
    userName: 'Michael Chen',
    rating: 2,
    serviceName: 'Gourmet Catering',
    serviceId: '2',
    text: 'The food was good but the service was slower than expected. Several guests had to wait too long for their main course.',
    date: '5h ago',
    isPositive: false,
  ),
  Review(
    id: '3',
    userName: 'Emily Davis',
    rating: 5,
    serviceName: 'Full Wedding Package',
    packageId: '1',
    text: 'A lifesaver! I didn\'t have to worry about a single thing. The decoration was exactly as I imagined.',
    date: '1d ago',
    isPositive: true,
  ),
  Review(
    id: '4',
    userName: 'Robert Wilson',
    rating: 1,
    serviceName: 'DJ & Sound System',
    serviceId: '3',
    text: 'The DJ arrived late and had equipment issues. Very disappointing for such an important evening.',
    date: '2d ago',
    isPositive: false,
  ),
  Review(
    id: '5',
    userName: 'Jessica Brown',
    rating: 4,
    serviceName: 'Floral Decoration',
    serviceId: '4',
    text: 'Beautiful setup. Just a minor misunderstanding about the color scheme initially, but they fixed it quickly.',
    date: '3d ago',
    isPositive: true,
  ),
  Review(
    id: '6',
    userName: 'Amanda White',
    rating: 5,
    serviceName: 'Wedding Photography',
    serviceId: '1',
    text: 'Professional and creative! They captured our special day beautifully.',
    date: '4d ago',
    isPositive: true,
  ),
  Review(
    id: '7',
    userName: 'Chris Martin',
    rating: 3,
    serviceName: 'Corporate Event Bundle',
    packageId: '2',
    text: 'Good overall service but there were some coordination issues with the catering.',
    date: '5d ago',
    isPositive: false,
  ),
  Review(
    id: '8',
    userName: 'David Miller',
    rating: 5,
    serviceName: 'Full Wedding Package',
    packageId: '1',
    text: 'Everything was perfect! Worth every penny.',
    date: '1w ago',
    isPositive: true,
  ),
  Review(
    id: '9',
    userName: 'Sophie Turner',
    rating: 4,
    serviceName: 'Birthday Party Basic',
    packageId: '3',
    text: 'Great party setup, kids loved it!',
    date: '1w ago',
    isPositive: true,
  ),
  Review(
    id: '10',
    userName: 'Alice Freeman',
    rating: 5,
    serviceName: 'Venue Lighting',
    serviceId: '5',
    text: 'The lighting transformed the venue completely. Amazing work!',
    date: '2w ago',
    isPositive: true,
  ),
];

final List<Message> mockMessages = [
  Message(
    id: '1',
    senderName: 'Alice Freeman',
    lastMessage: 'Hi! Is the venue available for next Saturday?',
    time: '10:30 AM',
    unread: true,
  ),
  Message(
    id: '2',
    senderName: 'John Smith',
    lastMessage: 'Thanks for the quick response. We will proceed with the gold package.',
    time: 'Yesterday',
    unread: false,
  ),
  Message(
    id: '3',
    senderName: 'Event Staff: Mark',
    lastMessage: 'Setup is complete for the Johnson wedding.',
    time: 'Yesterday',
    unread: false,
  ),
  Message(
    id: '4',
    senderName: 'Sophie Turner',
    lastMessage: 'Can we schedule a call to discuss the menu?',
    time: 'Mon',
    unread: true,
  ),
  Message(
    id: '5',
    senderName: 'David Miller',
    lastMessage: 'I sent the deposit receipt via email.',
    time: 'Mon',
    unread: false,
  ),
];

final List<NotificationItem> mockNotifications = [
  NotificationItem(
    id: '1',
    title: 'New Booking Request',
    description: 'Sarah J. requested "Full Wedding Package" for Oct 12.',
    time: '10 min ago',
    read: false,
    type: 'booking',
  ),
  NotificationItem(
    id: '2',
    title: 'Payment Received',
    description: '\$1,500.00 received from Michael Chen.',
    time: '1 hour ago',
    read: false,
    type: 'payment',
  ),
  NotificationItem(
    id: '3',
    title: 'New Review',
    description: 'You received a 5-star review from Emily Davis.',
    time: '3 hours ago',
    read: true,
    type: 'review',
  ),
  NotificationItem(
    id: '4',
    title: 'System Update',
    description: 'The platform will undergo maintenance at 2 AM.',
    time: '1 day ago',
    read: true,
    type: 'system',
  ),
];

final List<SalesItem> mockServices = [
  SalesItem(
    id: '1',
    name: 'Wedding Photography',
    companyName: 'Flash Moments Inc.',
    imageUrl: 'https://images.unsplash.com/photo-1537633552985-df8429e8048b?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
    totalSales: 12500,
    type: 'service',
    totalBookings: 48,
    canceledBookings: 3,
  ),
  SalesItem(
    id: '2',
    name: 'Gourmet Catering',
    companyName: 'TasteBuds Catering',
    imageUrl: 'https://images.unsplash.com/photo-1555244162-803834f70033?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
    totalSales: 8400,
    type: 'service',
    totalBookings: 32,
    canceledBookings: 2,
  ),
  SalesItem(
    id: '3',
    name: 'DJ & Sound System',
    companyName: 'Beats Audio',
    imageUrl: 'https://images.unsplash.com/photo-1571266028243-37160d7fced0?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
    totalSales: 5600,
    type: 'service',
    totalBookings: 24,
    canceledBookings: 4,
  ),
  SalesItem(
    id: '4',
    name: 'Floral Decoration',
    companyName: 'Blooming Arts',
    imageUrl: 'https://images.unsplash.com/photo-1522673607200-1645062cd958?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
    totalSales: 3200,
    type: 'service',
    totalBookings: 18,
    canceledBookings: 1,
  ),
  SalesItem(
    id: '5',
    name: 'Venue Lighting',
    companyName: 'Bright Lights Co.',
    imageUrl: 'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
    totalSales: 4800,
    type: 'service',
    totalBookings: 22,
    canceledBookings: 2,
  ),
];

final List<SalesItem> mockPackages = [
  SalesItem(
    id: '1',
    name: 'Full Wedding Package',
    imageUrl: 'https://images.unsplash.com/photo-1519225421980-715cb0202128?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
    totalSales: 45000,
    type: 'package',
    totalBookings: 85,
    canceledBookings: 6,
  ),
  SalesItem(
    id: '2',
    name: 'Corporate Event Bundle',
    imageUrl: 'https://images.unsplash.com/photo-1511578314322-379afb476865?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
    totalSales: 28500,
    type: 'package',
    totalBookings: 42,
    canceledBookings: 3,
  ),
  SalesItem(
    id: '3',
    name: 'Birthday Party Basic',
    imageUrl: 'https://images.unsplash.com/photo-1530103862676-de3c9a59af57?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
    totalSales: 6200,
    type: 'package',
    totalBookings: 28,
    canceledBookings: 2,
  ),
  SalesItem(
    id: '4',
    name: 'Anniversary Special',
    imageUrl: 'https://images.unsplash.com/photo-1522413452208-996ff3f3e740?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
    totalSales: 9800,
    type: 'package',
    totalBookings: 15,
    canceledBookings: 1,
  ),
];

final List<User> mockUsers = [
  User(id: '1', name: 'Alice Freeman', role: 'Client'),
  User(id: '2', name: 'John Smith', role: 'Client'),
  User(id: '3', name: 'Mark Evans', role: 'Staff'),
  User(id: '4', name: 'Sophie Turner', role: 'Provider'),
  User(id: '5', name: 'David Miller', role: 'Client'),
  User(id: '6', name: 'Sarah Jenkins', role: 'Client'),
  User(id: '7', name: 'Emily Davis', role: 'Client'),
  User(id: '8', name: 'Robert Wilson', role: 'Provider'),
  User(id: '9', name: 'Jessica Brown', role: 'Provider'),
  User(id: '10', name: 'Michael Chen', role: 'Client'),
  User(id: '11', name: 'Amanda White', role: 'Provider'),
  User(id: '12', name: 'Chris Martin', role: 'Provider'),
];

final List<Booking> mockBookings = [
  Booking(id: '1', customerName: 'Alice Freeman', packageName: 'Full Wedding Package', date: 'Oct 12, 2024', amount: 4500, status: 'confirmed'),
  Booking(id: '2', customerName: 'John Smith', packageName: 'Corporate Event Bundle', date: 'Sep 25, 2024', amount: 2800, status: 'confirmed'),
  Booking(id: '3', customerName: 'Emily Davis', packageName: 'Birthday Party Basic', date: 'Nov 05, 2024', amount: 800, status: 'confirmed'),
  Booking(id: '4', customerName: 'Michael Chen', packageName: 'Anniversary Special', date: 'Dec 10, 2024', amount: 1200, status: 'confirmed'),
  Booking(id: '5', customerName: 'Sarah Jenkins', packageName: 'Full Wedding Package', date: 'Jan 15, 2025', amount: 4500, status: 'confirmed'),
  Booking(id: '6', customerName: 'David Miller', packageName: 'Birthday Party Basic', date: 'Feb 20, 2025', amount: 800, status: 'canceled'),
  Booking(id: '7', customerName: 'Jessica Brown', packageName: 'Anniversary Special', date: 'Mar 01, 2025', amount: 1200, status: 'canceled'),
  Booking(id: '8', customerName: 'Robert Wilson', packageName: 'Corporate Event Bundle', date: 'Apr 10, 2025', amount: 2800, status: 'canceled'),
];

List<Review> getReviewsForService(String serviceId) {
  return mockReviews.where((r) => r.serviceId == serviceId).toList();
}

List<Review> getReviewsForPackage(String packageId) {
  return mockReviews.where((r) => r.packageId == packageId).toList();
}
