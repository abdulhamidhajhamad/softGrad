// lib/screens/home.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'search.dart';
import 'favorites.dart'; // أبقِ هذه
// import 'ai_assistant.dart'; // احذفه هنا لتفادي تعارض FavoritesPage
import 'cart.dart';
import 'profile.dart';
import 'notifications.dart';
import 'offers.dart';
import 'packages.dart';
import 'templates.dart';
import 'vendors.dart';
import 'vendor_profile.dart';

class HomePage extends StatefulWidget {
  final String userName;
  const HomePage({Key? key, this.userName = "Guest"}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      _HomeTab(
        userName: widget.userName,
        // افتح صفحة البحث بدفع route بدل تغيير التبويب
        onOpenSearch: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SearchPage()),
        ),
        onOpenOffers: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OffersPage()),
        ),
        onOpenPackages: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PackagesPage()),
        ),
        onOpenTemplates: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TemplatesPage()),
        ),
        onOpenVendors: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VendorsListPage()),
        ),
      ),
      const ProfilePage(),
      const CartPage(),
      const FavoritesPage(),
      // لا تضع SearchPage هنا
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const _AppDrawer(),
      body: _tabs[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          // لا يوجد Search هنا
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final String userName;
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenPackages;
  final VoidCallback onOpenOffers;
  final VoidCallback onOpenTemplates;
  final VoidCallback onOpenVendors;

  const _HomeTab({
    Key? key,
    required this.userName,
    required this.onOpenSearch,
    required this.onOpenPackages,
    required this.onOpenOffers,
    required this.onOpenTemplates,
    required this.onOpenVendors,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFF2B7DE9);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: false,
          floating: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          expandedHeight: 220,
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
              tooltip: 'Menu',
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsPage()),
                );
              },
              tooltip: 'Notifications',
            ),
            const SizedBox(width: 8),
          ],
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset('assets/images/table.png', fit: BoxFit.cover),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.45),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, ${userName.trim().isEmpty ? "there" : userName}!',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Let's continue planning your perfect day",
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: brand),
                    const SizedBox(width: 8),
                    Text(
                      'Quick Actions',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 2.6,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _QuickActionCard(
                      label: 'Search Vendors',
                      icon: Icons.search,
                      tint: brand.withOpacity(0.12),
                      iconColor: brand,
                      onTap: onOpenSearch,
                    ),
                    _QuickActionCard(
                      label: 'Packages',
                      icon: Icons.inventory_2_rounded,
                      tint: const Color(0xFFFFB74D).withOpacity(0.18),
                      iconColor: const Color(0xFFF57C00),
                      onTap: onOpenPackages,
                    ),
                    _QuickActionCard(
                      label: 'Offers',
                      icon: Icons.local_offer_outlined,
                      tint: const Color(0xFF81C784).withOpacity(0.18),
                      iconColor: const Color(0xFF2E7D32),
                      onTap: onOpenOffers,
                    ),
                    _QuickActionCard(
                      label: 'Templates',
                      icon: Icons.event_available_outlined,
                      tint: const Color(0xFFB39DDB).withOpacity(0.18),
                      iconColor: const Color(0xFF5E35B1),
                      onTap: onOpenTemplates,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Trending Vendors',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    TextButton(
                      onPressed: onOpenVendors,
                      child: Text(
                        'See all',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const _VendorCard(
                  tag: 'Venue',
                  title: 'Sunset Garden Venue',
                  location: 'Nablus',
                  rating: 4.8,
                  reviews: 124,
                  priceLevel: 3,
                  image: 'assets/images/table.png',
                ),
                const SizedBox(height: 12),
                const _VendorCard(
                  tag: 'Photography',
                  title: 'Moments Photography',
                  location: 'Nablus',
                  rating: 4.9,
                  reviews: 89,
                  priceLevel: 2,
                  image: 'assets/images/table.png',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color tint;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    Key? key,
    required this.label,
    required this.icon,
    required this.tint,
    required this.iconColor,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tint,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VendorCard extends StatelessWidget {
  final String tag;
  final String title;
  final String location;
  final double rating;
  final int reviews;
  final int priceLevel;
  final String image;

  const _VendorCard({
    Key? key,
    required this.tag,
    required this.title,
    required this.location,
    required this.rating,
    required this.reviews,
    required this.priceLevel,
    required this.image,
  }) : super(key: key);

  String get _priceText => '\$' * priceLevel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => VendorProfilePage(title: title)),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.asset(image, fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Text(_priceText),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/signin');
              },
            ),
          ],
        ),
      ),
    );
  }
}
