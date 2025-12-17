// lib/screens/home_customer.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter_application_1/screens/search.dart';
import 'package:flutter_application_1/services/auth_service.dart';

import 'favorites.dart';
import 'ai_assistant.dart';
import 'cart.dart';
import 'profile.dart';
import 'notifications.dart';
import 'offers.dart';
import 'packages.dart';
import 'templates.dart';
import 'services_customer_home.dart';
import 'signin.dart';

// ✅ Chat page
import 'chat_customer_home_page.dart';

/// ✅ RGB(215, 20, 20, 215)
const Color kNavBlue = Color.fromARGB(215, 20, 20, 215);

/// ✅ خلفية
const Color kPageBg = Color(0xFFF6F7FB);

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
          MaterialPageRoute(builder: (_) => const SearchScreen()),
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

      /// ✅ بدل Categories
      const ChatCustomerHomePage(),

      /// AI
      const AiAssistantScreen(),

      /// Cart
      const CartPage(),

      /// Profile
      ProfileScreen(
        currentUser: User(
          fullName: widget.userName,
          email: 'you@example.com',
          phone: '+970000000000',
          location: 'Nablus, Palestine',
        ),
      ),
    ];
  }

  void _setIndex(int i) {
    if (_index == i) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPageBg,
      extendBody: true,
      drawer: const _AppDrawer(),
      body: _tabs[_index],

      /// ✅ Bottom Nav CLEAN (بدون إطار أزرق) + بدون overflow
      bottomNavigationBar: _CleanBottomNav(
        index: _index,
        onChanged: _setIndex,
      ),
    );
  }
}

////////////////////////////////////////////////////////////////////////////////
/// ✅ Bottom Nav CLEAN: White/Glass + Icons Small + No Overflow
////////////////////////////////////////////////////////////////////////////////

class _CleanBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _CleanBottomNav({
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final gap = min(86.0, w * 0.22);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        child: SizedBox(
          height: 84, // ✅ أقل من قبل عشان ما يطلع overflow
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // ✅ Base bar (أبيض)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 62,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.97),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: Colors.black.withOpacity(0.06)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 22,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _NavItemSmall(
                        selected: index == 0,
                        icon: Icons.home_rounded,
                        label: "Home",
                        onTap: () => onChanged(0),
                      ),
                      _NavItemSmall(
                        selected: index == 1,
                        icon: Icons.chat_bubble_rounded,
                        label: "Chat",
                        onTap: () => onChanged(1),
                      ),

                      // gap for center AI
                      SizedBox(width: gap),

                      _NavItemSmall(
                        selected: index == 3,
                        icon: Icons.shopping_bag_rounded,
                        label: "Cart",
                        onTap: () => onChanged(3),
                      ),
                      _NavItemSmall(
                        selected: index == 4,
                        icon: Icons.person_rounded,
                        label: "Profile",
                        onTap: () => onChanged(4),
                      ),
                    ],
                  ),
                ),
              ),

              // ✅ Center AI (أصغر)
              Positioned(
                bottom: 18,
                child: _CenterAIFabSmall(
                  active: index == 2,
                  onTap: () => onChanged(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterAIFabSmall extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const _CenterAIFabSmall({
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: active ? 62 : 58,
        height: active ? 62 : 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: kNavBlue,
          border: Border.all(color: kPageBg, width: 6),
          boxShadow: [
            BoxShadow(
              color: kNavBlue.withOpacity(0.30),
              blurRadius: 22,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: const Icon(
          Icons.auto_awesome_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

class _NavItemSmall extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavItemSmall({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = kNavBlue.withOpacity(selected ? 1 : 0.70);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: SizedBox(
        width: 62,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: selected ? 24 : 22, color: iconColor), // ✅ أصغر
            const SizedBox(height: 3),
            // ✅ نخليه يظهر بس لما selected لتفادي overflow
            SizedBox(
              height: 12,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 160),
                opacity: selected ? 1 : 0,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: kNavBlue,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////////////////////////
/// ✅ Home Tab
////////////////////////////////////////////////////////////////////////////////

class _HomeTab extends StatefulWidget {
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
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final _repo = HomeRepository();
  late Future<HomePayload> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.loadHome();
  }

  Future<void> _refresh() async {
    setState(() => _future = _repo.loadHome(forceRefresh: true));
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.userName.trim().isEmpty ? "there" : widget.userName;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: false,
            floating: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            expandedHeight: 140,
            leading: Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
                tooltip: 'Menu',
              ),
            ),
            actions: [
              // ✅ Favorites (رح يطلع على يسار الجرس)
              IconButton(
                icon: const Icon(Icons.favorite_rounded, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FavoritesPage()),
                  );
                },
                tooltip: 'Favorites',
              ),

              // ✅ Notifications (على اليمين)
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsPage()),
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
                          Colors.black.withOpacity(0.10),
                          Colors.black.withOpacity(0.55),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 18,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, $name!',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Let's plan your perfect day together ♡",
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.92),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
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
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopSearchBar(
                    hint: "Search vendors, packages, services...",
                    onTap: widget.onOpenSearch,
                  ),
                  const SizedBox(height: 18),
                  _SectionTitle(
                    title: "Planning Tools",
                    icon: Icons.dashboard_customize_rounded,
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    padding: EdgeInsets.zero,
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.55,
                    children: [
                      _ToolCard(
                        title: "Services",
                        icon: Icons.storefront_rounded,
                        tint: kNavBlue.withOpacity(0.10),
                        iconColor: kNavBlue,
                        onTap: widget.onOpenVendors,
                      ),
                      _ToolCard(
                        title: "Packages",
                        icon: Icons.inventory_2_rounded,
                        tint: const Color(0xFFFFB74D).withOpacity(0.16),
                        iconColor: const Color(0xFFF57C00),
                        onTap: widget.onOpenPackages,
                      ),
                      _ToolCard(
                        title: "Offers",
                        icon: Icons.local_offer_rounded,
                        tint: const Color(0xFF81C784).withOpacity(0.16),
                        iconColor: const Color(0xFF2E7D32),
                        onTap: widget.onOpenOffers,
                      ),
                      _ToolCard(
                        title: "Templates",
                        icon: Icons.description_rounded,
                        tint: const Color(0xFFB39DDB).withOpacity(0.16),
                        iconColor: const Color(0xFF5E35B1),
                        onTap: widget.onOpenTemplates,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  FutureBuilder<HomePayload>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const _HomeMiniSkeleton();
                      }
                      if (snap.hasError || !snap.hasData) {
                        return _InlineError(onRetry: _refresh);
                      }

                      final data = snap.data!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeaderWithAction(
                            title: "Package Deals!",
                            actionText: "View all",
                            onAction: widget.onOpenPackages,
                          ),
                          const SizedBox(height: 12),
                          HomePackageCarousel(packages: data.packages),

                          const SizedBox(height: 20),

                          _HeaderWithAction(
                            title: "Trending Services",
                            actionText: "View more",
                            onAction: widget.onOpenSearch,
                          ),
                          const SizedBox(height: 12),
                          HomeTrendingRail(
                            services: data.trending,
                            onOpen: (s) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ServiceDetailsPage(service: s),
                                ),
                              );
                            },
                          ),

                          // ✅ مساحة كافية عشان الـ nav ما يغطي
                          const SizedBox(height: 140),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopSearchBar extends StatelessWidget {
  final String hint;
  final VoidCallback onTap;

  const _TopSearchBar({required this.hint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final borderC = Colors.black.withOpacity(0.08);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderC),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: kNavBlue.withOpacity(0.85)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
            Icon(Icons.tune_rounded, color: kNavBlue.withOpacity(0.80)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: kNavBlue.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: kNavBlue),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderWithAction extends StatelessWidget {
  final String title;
  final String actionText;
  final VoidCallback onAction;

  const _HeaderWithAction({
    required this.title,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(
            actionText,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w900,
              color: kNavBlue,
            ),
          ),
        ),
      ],
    );
  }
}

class _ToolCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color tint;
  final Color iconColor;
  final VoidCallback onTap;

  const _ToolCard({
    required this.title,
    required this.icon,
    required this.tint,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderC = Colors.black.withOpacity(0.08);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderC),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: kNavBlue.withOpacity(0.60),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeMiniSkeleton extends StatelessWidget {
  const _HomeMiniSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget box({double h = 16, double w = double.infinity}) => Container(
          height: h,
          width: w,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        box(h: 16, w: 170),
        const SizedBox(height: 10),
        box(h: 260),
        const SizedBox(height: 18),
        box(h: 16, w: 190),
        const SizedBox(height: 10),
        box(h: 170),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  final Future<void> Function() onRetry;
  const _InlineError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD2D2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Color(0xFFD32F2F)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Couldn’t load packages/services. Pull to refresh or retry.",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: () => onRetry(),
            child: Text(
              "Retry",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
            ),
          ),
        ],
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
              leading: const Icon(Icons.favorite_border),
              title: const Text('Favorites'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FavoritesPage()),
                );
              },
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

////////////////////////////////////////////////////////////////////////////////
/// ✅ Data + UI: Packages + Trending
////////////////////////////////////////////////////////////////////////////////

class HomePackageDeal {
  final String id;
  final String imageUrl;
  final String title;
  final String company;
  final List<String> services;
  final double price;
  final double originalPrice;
  final String validity;

  HomePackageDeal({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.company,
    required this.services,
    required this.price,
    required this.originalPrice,
    required this.validity,
  });
}

class HomeTrendingService {
  final String id;
  final String name;
  final String company;
  final String category;
  final double price;
  final String imageUrl;
  final String desc;

  HomeTrendingService({
    required this.id,
    required this.name,
    required this.company,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.desc,
  });
}

class HomePayload {
  final List<HomePackageDeal> packages;
  final List<HomeTrendingService> trending;
  HomePayload({required this.packages, required this.trending});
}

class HomeRepository {
  Future<HomePayload> loadHome({bool forceRefresh = false}) async {
    await Future.delayed(const Duration(milliseconds: 450));

    final packages = [
      HomePackageDeal(
        id: "p1",
        imageUrl:
            "https://images.unsplash.com/photo-1519225468359-2996bc01c5dc?auto=format&fit=crop&q=80&w=1200",
        title: "Elegant Classic Pack",
        company: "Royal Events Co.",
        services: ["Full Decor", "Catering", "Photo", "Live Band"],
        price: 4500,
        originalPrice: 5500,
        validity: "Valid until Dec 31",
      ),
      HomePackageDeal(
        id: "p2",
        imageUrl:
            "https://images.unsplash.com/photo-1511795409834-ef04bbd61622?auto=format&fit=crop&q=80&w=1200",
        title: "Premium Luxe Pack",
        company: "Elite Weddings",
        services: ["Luxury Venue", "Gourmet", "Cinema", "Suite"],
        price: 8200,
        originalPrice: 9500,
        validity: "Valid until Mar 15",
      ),
      HomePackageDeal(
        id: "p3",
        imageUrl:
            "https://images.unsplash.com/photo-1469334031218-e382a71b716b?auto=format&fit=crop&q=80&w=1200",
        title: "Intimate Garden Pack",
        company: "Nature's Vows",
        services: ["Garden Venue", "Floral Arch", "Acoustic", "Organic Menu"],
        price: 3200,
        originalPrice: 3800,
        validity: "Valid until Jun 30",
      ),
    ];

    final trending = [
      HomeTrendingService(
        id: "s1",
        name: "Floral Dreams",
        company: "Bloom & Co.",
        category: "Decor",
        price: 500,
        imageUrl:
            "https://images.unsplash.com/photo-1522673607200-1645062cd495?auto=format&fit=crop&q=80&w=600",
        desc: "Exquisite floral arrangements",
      ),
      HomeTrendingService(
        id: "s2",
        name: "Candid Moments",
        company: "Lens Magic",
        category: "Photo",
        price: 1200,
        imageUrl:
            "https://images.unsplash.com/photo-1520854221256-17451cc330e7?auto=format&fit=crop&q=80&w=600",
        desc: "Award-winning photography",
      ),
      HomeTrendingService(
        id: "s3",
        name: "DJ Pulse",
        company: "SoundWave",
        category: "Music",
        price: 800,
        imageUrl:
            "https://images.unsplash.com/photo-1516280440614-6697288d5d38?auto=format&fit=crop&q=80&w=600",
        desc: "High energy entertainment",
      ),
    ];

    return HomePayload(packages: packages, trending: trending);
  }
}

class HomePackageCarousel extends StatefulWidget {
  final List<HomePackageDeal> packages;
  const HomePackageCarousel({Key? key, required this.packages})
      : super(key: key);

  @override
  State<HomePackageCarousel> createState() => _HomePackageCarouselState();
}

class _HomePackageCarouselState extends State<HomePackageCarousel> {
  late final PageController _controller;
  int _page = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.88);

    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || widget.packages.isEmpty) return;
      final next = (_page + 1) % widget.packages.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.packages.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 280,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.packages.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _PackageHeroCard(pkg: widget.packages[i]),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.packages.length, (i) {
            final active = i == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 7,
              width: active ? 18 : 7,
              decoration: BoxDecoration(
                color: active ? kNavBlue : Colors.black.withOpacity(0.12),
                borderRadius: BorderRadius.circular(99),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _PackageHeroCard extends StatelessWidget {
  final HomePackageDeal pkg;
  const _PackageHeroCard({required this.pkg});

  @override
  Widget build(BuildContext context) {
    final offPct = _discountPercent(pkg.originalPrice, pkg.price);

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Stack(
        children: [
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: pkg.imageUrl,
              fit: BoxFit.cover,

              // ✅ مهم لتخفيف كراش الإيميوليتر
              memCacheWidth: 1000,
              memCacheHeight: 1000,
              maxHeightDiskCache: 1000,
              maxWidthDiskCache: 1000,

              placeholder: (_, __) => Container(color: Colors.white),
              errorWidget: (_, __, ___) => Container(
                color: Colors.white,
                child: const Icon(Icons.image),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.08),
                    Colors.black.withOpacity(0.58),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withOpacity(0.25)),
              ),
              child: Text(
                "$offPct% OFF",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pkg.company.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  pkg.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: pkg.services.take(3).map((s) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      child: Text(
                        s,
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      "\$${pkg.price.toStringAsFixed(0)}",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "\$${pkg.originalPrice.toStringAsFixed(0)}",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_forward_rounded, color: kNavBlue),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  pkg.validity,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HomeTrendingRail extends StatelessWidget {
  final List<HomeTrendingService> services;
  final ValueChanged<HomeTrendingService> onOpen;

  const HomeTrendingRail({
    Key? key,
    required this.services,
    required this.onOpen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 178,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: services.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final s = services[i];
          return _TrendingCard(service: s, onTap: () => onOpen(s));
        },
      ),
    );
  }
}

class _TrendingCard extends StatelessWidget {
  final HomeTrendingService service;
  final VoidCallback onTap;

  const _TrendingCard({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    final double cardW = min(sw * 0.86, 360.0).toDouble();
    const cardH = 150.0;
    const imgW = 96.0;
    const imgH = 126.0;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: SizedBox(
        width: cardW,
        height: cardH,
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: service.imageUrl,
                  width: imgW,
                  height: imgH,
                  fit: BoxFit.cover,

                  // ✅ مهم لتخفيف كراش الإيميوليتر
                  memCacheWidth: 600,
                  memCacheHeight: 600,
                  maxHeightDiskCache: 700,
                  maxWidthDiskCache: 700,

                  placeholder: (_, __) =>
                      Container(color: const Color(0xFFF1F5F9)),
                  errorWidget: (_, __, ___) => Container(
                    color: const Color(0xFFF1F5F9),
                    child: const Icon(Icons.image),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: kNavBlue.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            service.category,
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              color: kNavBlue,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: List.generate(
                            5,
                            (_) => const Icon(Icons.star,
                                size: 11, color: Colors.amber),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      service.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      service.company,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      service.desc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          "\$${service.price.toStringAsFixed(0)}",
                          style: GoogleFonts.poppins(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: kNavBlue,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: kNavBlue,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: kNavBlue.withOpacity(0.22),
                                blurRadius: 14,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
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

class ServiceDetailsPage extends StatelessWidget {
  final HomeTrendingService service;
  const ServiceDetailsPage({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Service",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                service.name,
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                service.company,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                service.desc,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
              Text(
                "\$${service.price.toStringAsFixed(0)}",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: kNavBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

int _discountPercent(double original, double discounted) {
  if (original <= 0) return 0;
  final v = ((original - discounted) / original) * 100;
  return v.isNaN ? 0 : v.clamp(0, 95).round();
}