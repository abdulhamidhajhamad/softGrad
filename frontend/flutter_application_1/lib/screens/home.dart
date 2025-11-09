// lib/screens/home.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatefulWidget {
  final String userName; // مرّر الاسم بعد التسجيل/الدخول إن توفر
  const HomePage({Key? key, this.userName = "Guest"}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ترتيب النافبار: Home, Profile, Cart, Favorites, Search
  int _index = 0;

  // صفحات النافبار
  late final List<Widget> _tabs = [
    _HomeTab(
      userName: widget.userName,
      onOpenSearch: () => setState(() => _index = 4),
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
    ),
    const ProfilePage(),
    const CartPage(),
    const FavoritesPage(),
    const SearchPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const _AppDrawer(),
      body: _tabs[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        height: 64,
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
          NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
        ],
      ),
    );
  }
}

/// تبويب الهوم
class _HomeTab extends StatelessWidget {
  final String userName;
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenPackages;
  final VoidCallback onOpenOffers;
  final VoidCallback onOpenTemplates;

  const _HomeTab({
    Key? key,
    required this.userName,
    required this.onOpenSearch,
    required this.onOpenPackages,
    required this.onOpenOffers,
    required this.onOpenTemplates,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final brand = const Color(0xFF2B7DE9);
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: false,
          floating: true,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
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
                // صورة الغلاف
                Image.asset('assets/images/table.png', fit: BoxFit.cover),
                // تدرّج للقراءة
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
                // التحية
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

        // محتوى الصفحة
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Actions
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
                const SizedBox(height: 1),
                GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 2.6,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _QuickActionCard(
                      label: 'Search',
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

                const SizedBox(height: 23),

                // AI Wedding Assistant
                Container(
                  decoration: BoxDecoration(
                    color: brand.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12),
                  ),
                  padding: const EdgeInsets.all(23),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, color: brand),
                          const SizedBox(width: 8),
                          Text(
                            'AI Wedding Assistant!',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color.fromARGB(255, 39, 32, 139),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'Get personalized recommendations based on your wedding timeline and preferences.',
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AiAssistantPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brand,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Get Smart Suggestions',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Trending Vendors
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
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const VendorsListPage(),
                        ),
                      ),
                      child: Text(
                        'See all',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // بطاقات مزودين مثال
                _VendorCard(
                  tag: 'Venue',
                  title: 'Sunset Garden Venue',
                  location: 'Nablus',
                  rating: 4.8,
                  reviews: 124,
                  priceLevel: 3,
                  image: 'assets/images/table.png',
                ),
                const SizedBox(height: 12),
                _VendorCard(
                  tag: 'Photography',
                  title: 'Moments Photography',
                  location: 'Nablus',
                  rating: 4.9,
                  reviews: 89,
                  priceLevel: 2,
                  image: 'assets/images/table.png',
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// بطاقة إجراء سريع
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
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black12),
          ),
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

/// بطاقة مزوّد
class _VendorCard extends StatelessWidget {
  final String tag;
  final String title;
  final String location;
  final double rating;
  final int reviews;
  final int priceLevel; // 1..4
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
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // صورة
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.asset(image, fit: BoxFit.cover),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // الوسم + زر عرض
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF4FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tag,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2B7DE9),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VendorProfilePage(title: title),
                              ),
                            );
                          },
                          child: Text(
                            'View Profile',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          location,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.star,
                          size: 16,
                          color: Color(0xFFFFC107),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '$rating',
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '  ($reviews)',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            color: Colors.grey[700],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _priceText,
                          style: GoogleFonts.poppins(fontSize: 13.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Drawer بسيط لزر القائمة
class _AppDrawer extends StatelessWidget {
  const _AppDrawer({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & Support'),
              onTap: () {},
            ),
            const Divider(),
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

/* ===================== صفحات ثانوية بسيطة ===================== */

class SearchPage extends StatelessWidget {
  const SearchPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return _ScaffoldTab(title: 'Search', icon: Icons.search);
  }
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return _ScaffoldTab(title: 'Favorites', icon: Icons.favorite);
  }
}

class CartPage extends StatelessWidget {
  const CartPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return _ScaffoldTab(title: 'Cart', icon: Icons.shopping_cart);
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return _ScaffoldTab(title: 'Profile', icon: Icons.person);
  }
}

class OffersPage extends StatelessWidget {
  const OffersPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return _ListStub(title: 'Offers');
  }
}

class PackagesPage extends StatelessWidget {
  const PackagesPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return _ListStub(title: 'Packages');
  }
}

class TemplatesPage extends StatelessWidget {
  const TemplatesPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return _ListStub(title: 'Templates');
  }
}

class VendorsListPage extends StatelessWidget {
  const VendorsListPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return _ListStub(title: 'All Vendors');
  }
}

class VendorProfilePage extends StatelessWidget {
  final String title;
  const VendorProfilePage({Key? key, required this.title}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Vendor profile for $title')),
    );
  }
}

class AiAssistantPage extends StatelessWidget {
  const AiAssistantPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return _ScaffoldTab(
      title: 'AI Wedding Assistant',
      icon: Icons.auto_awesome,
    );
  }
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return _ListStub(title: 'Notifications');
  }
}

/* ===================== Widgets مساعدة ===================== */

class _ScaffoldTab extends StatelessWidget {
  final String title;
  final IconData icon;
  const _ScaffoldTab({Key? key, required this.title, required this.icon})
    : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64),
            const SizedBox(height: 12),
            Text('This is $title page'),
          ],
        ),
      ),
    );
  }
}

class _ListStub extends StatelessWidget {
  final String title;
  const _ListStub({Key? key, required this.title}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (_, i) => ListTile(
          leading: const Icon(Icons.local_offer_outlined),
          title: Text('$title Item ${i + 1}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemCount: 12,
      ),
    );
  }
}
