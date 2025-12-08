import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'search.dart';
import 'favorites.dart';
import 'ai_assistant.dart';
import 'cart.dart';
import 'profile.dart';
import 'notifications.dart';
import 'offers.dart';
import 'packages.dart';
import 'templates.dart';
import 'vendors.dart';
import 'vendor_profile.dart';
import 'signin.dart';

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
        onOpenAiAssistant: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
        ),
      ),
      ProfileScreen(
        currentUser: User(
          fullName: widget.userName,
          email: 'you@example.com',
          phone: '+970000000000',
          location: 'Nablus, Palestine',
        ),
      ),
      const CartPage(),
      const FavoritesPage(),
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
  final VoidCallback onOpenAiAssistant;

  const _HomeTab({
    Key? key,
    required this.userName,
    required this.onOpenSearch,
    required this.onOpenPackages,
    required this.onOpenOffers,
    required this.onOpenTemplates,
    required this.onOpenVendors,
    required this.onOpenAiAssistant,
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
          expandedHeight: 250,
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
                        "Let's plan your perfect day together ♡",
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
            padding: const EdgeInsets.fromLTRB(18, 20, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: brand),
                    const SizedBox(width: 9),
                    Text(
                      'Quick Actions',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Here is your Shortcuts to plan faster',
                  strutStyle: const StrutStyle(
                    height: 1.3,
                    leading: 0.0,
                    forceStrutHeight: true,
                  ),
                  textHeightBehavior: const TextHeightBehavior(
                    applyHeightToFirstAscent: false,
                    applyHeightToLastDescent: false,
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 13.2,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF8E8EA0),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 19),
                GridView.count(
                  padding: EdgeInsets.zero,
                  crossAxisCount: 2,
                  childAspectRatio: 3.1,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 10,
                  children: [
                    _QuickActionCard(
                      label: 'Search',
                      icon: Icons.search,
                      tint: brand.withOpacity(0.12),
                      iconColor: brand,
                      onTap: onOpenVendors,
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
                _AiAssistantCard(onTap: onOpenAiAssistant),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '⋆˙⟡ TRENDING VENDORS ⋆˙⟡',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    TextButton(
                      onPressed: onOpenVendors,
                      child: Text(
                        'See All',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                const _VendorCard(
                  tag: 'Venue',
                  title: 'Sunset Garden Venue',
                  location: 'Nablus',
                  rating: 4.8,
                  reviews: 124,
                  priceLevel: 3,
                  image: 'assets/images/table.png',
                ),
                const SizedBox(height: 10),
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
          padding: const EdgeInsets.all(19),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiAssistantCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AiAssistantCard({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFF2B7DE9);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3ECFF)),
      ),
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
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Get personalized recommendations based on your wedding timeline and preferences',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF4A4A68),
            ),
          ),
          const SizedBox(height: 19),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(185, 255, 106, 0),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size.fromHeight(44),
              ),
              child: Text(
                'Get Smart Suggestions',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
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
              onTap: () async {
                await AuthService.deleteToken();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => SignInScreen()),
                  (_) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
