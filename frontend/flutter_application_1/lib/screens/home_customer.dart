// lib/screens/home_customer.dart

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/screens/search.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/screens/notifications_provider.dart';
import 'package:flutter_application_1/services/user_service/home_user_service.dart';
import 'package:flutter_application_1/services/user_service/chat_user_service.dart';
import 'package:flutter_application_1/services/service_locator.dart'; // ✅ Added for getIt
import 'package:flutter_application_1/widgets/booking_details_modal.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'favorites.dart';
import 'package:flutter_application_1/screens/Ai_Screen/ai_screen_layout.dart';
import 'cart.dart';
import 'profile.dart';
import 'notifications.dart';
import 'offers.dart';
import 'packages.dart';
import 'templates.dart';
import 'provider/services_customer_home.dart';
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
          MaterialPageRoute(builder: (_) => const SearchScreen()),
        ),
      ),

      /// ✅ بدل Categories
      const ChatCustomerHomePage(),

      /// AI
const AiScreenLayout(),
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
        builder: (_) => NotificationsProviderScreen(
          // نمرر الـ ID هنا ليتم استخدامه في الصفحة
          providerId: widget.userName, // أو الـ ID الفعلي إذا كان مخزناً بمتغير آخر
        ),
      ),
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
                            onAction: widget.onOpenVendors,
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
  final String providerId;
  final String category;
  final double price;
  final String imageUrl;
  final String desc;
  final double? latitude;
  final double? longitude;

  HomeTrendingService({
    required this.id,
    required this.name,
    required this.company,
    required this.providerId,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.desc,
    this.latitude,
    this.longitude,
  });
}

class HomePayload {
  final List<HomePackageDeal> packages;
  final List<HomeTrendingService> trending;
  HomePayload({required this.packages, required this.trending});
}

class HomeRepository {
  Future<HomePayload> loadHome({bool forceRefresh = false}) async {
    try {
      // Fetch data from backend API
      final homeData = await HomeUserService.getHomeData();

      // Convert API models to UI models
      final packages = homeData.packages.map((pkg) => HomePackageDeal(
        id: pkg.id,
        imageUrl: pkg.imageUrl.isNotEmpty 
            ? pkg.imageUrl 
            : 'https://images.unsplash.com/photo-1519225468359-2996bc01c5dc?auto=format&fit=crop&q=80&w=1200',
        title: pkg.title,
        company: pkg.company,
        services: pkg.services,
        price: pkg.price,
        originalPrice: pkg.originalPrice,
        validity: pkg.validity,
      )).toList();

      final trending = homeData.trending.map((svc) => HomeTrendingService(
        id: svc.id,
        name: svc.name,
        company: svc.company,
        providerId: svc.providerId,
        category: svc.category,
        price: svc.price,
        imageUrl: svc.imageUrl.isNotEmpty 
            ? svc.imageUrl 
            : 'https://images.unsplash.com/photo-1522673607200-1645062cd495?auto=format&fit=crop&q=80&w=600',
        desc: svc.desc.isNotEmpty ? svc.desc : 'Quality service for your special day',
        latitude: svc.latitude,
        longitude: svc.longitude,
      )).toList();

      return HomePayload(packages: packages, trending: trending);
    } catch (e) {
      print('❌ Error loading home data: $e');
      // Return empty data on error - UI will show error state
      return HomePayload(packages: [], trending: []);
    }
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

class ServiceDetailsPage extends StatefulWidget {
  final HomeTrendingService service;
  const ServiceDetailsPage({super.key, required this.service});

  @override
  State<ServiceDetailsPage> createState() => _ServiceDetailsPageState();
}

class _ServiceDetailsPageState extends State<ServiceDetailsPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _serviceData;
  String? _bookingType;

  @override
  void initState() {
    super.initState();
    _loadServiceDetails();
  }

  Future<void> _loadServiceDetails() async {
    try {
      setState(() => _isLoading = true);
      
      // Import user_service_service for API call
      final response = await _fetchServiceDetails(widget.service.id);
      
      setState(() {
        _serviceData = response;
        _bookingType = response['bookingType']?.toString().toLowerCase();
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading service details: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load service details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _fetchServiceDetails(String serviceId) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${AuthService.baseUrl}/services/$serviceId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load service');
    }
  }

  String _money(double v) => '₪${v.toStringAsFixed(0)}';

  Future<void> _startChat() async {
    if (widget.service.providerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot start chat: Provider not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: kNavBlue),
      ),
    );

    try {
      // ✅ استخدام getIt للحصول على نفس الـ instance
      final chatService = getIt<ChatUserService>();
      await chatService.initializeUserId();
      await chatService.initSocket();
      
      final chatId = await chatService.createChat(widget.service.providerId);
      
      if (mounted) Navigator.pop(context); // Close loading
      
      if (chatId != null && mounted) {
        // Navigate to chat - using the ChatThreadPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatThreadPage(
              thread: ChatThreadModel(
                id: chatId,
                type: ThreadType.vendor,
                title: widget.service.company,
                lastMessage: '',
                lastTime: DateTime.now(),
                unreadCount: 0,
                online: false,
              ),
            ),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to start chat'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openBookingModal() async {
    if (_serviceData == null || _bookingType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service details not loaded yet'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if already in cart
    final inCart = CartStore.instance.contains(widget.service.id);
    if (inCart) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
          content: Text(
            'This service is already in your cart',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
          ),
          action: SnackBarAction(
            label: 'View Cart',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartPage()),
              );
            },
          ),
        ),
      );
      return;
    }

    await showBookingModal(
      context: context,
      serviceId: widget.service.id,
      serviceName: widget.service.name,
      bookingTypeString: _bookingType!,
      serviceData: _serviceData!,
      onSuccess: () {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            content: Text(
              'Added to cart successfully!',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.service;
    
    return Scaffold(
      backgroundColor: kPageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.6,
        iconTheme: const IconThemeData(color: Color(0xFF0B1220)),
        title: Text(
          "Service Details",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0B1220),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.black.withOpacity(0.06))),
          ),
          child: Row(
            children: [
              // ✅ Start Chat button (LEFT)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _startChat,
                  icon: Icon(Icons.chat_bubble_rounded, color: kNavBlue),
                  label: Text(
                    'Start Chat',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: const Color(0xFF0B1220)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.black.withOpacity(0.14)),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // ✅ Add to Cart button (RIGHT)
              Expanded(
                child: ValueListenableBuilder<List<CartItem>>(
                  valueListenable: CartStore.instance.itemsListenable,
                  builder: (_, items, ___) {
                    final inCart = items.any((item) => item.id == s.id);
                    final isDisplayOnly = _bookingType?.toLowerCase() == 'display';

                    return ElevatedButton.icon(
                      onPressed: (inCart || _isLoading || isDisplayOnly) ? null : _openBookingModal,
                      icon: Icon(
                        inCart ? Icons.check_circle_rounded 
                            : isDisplayOnly ? Icons.visibility_rounded 
                            : Icons.add_shopping_cart_rounded,
                        color: (inCart || isDisplayOnly) ? Colors.white70 : kNavBlue,
                      ),
                      label: Text(
                        inCart ? 'In Cart' 
                            : isDisplayOnly ? 'Display Only' 
                            : 'Add to Cart',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (inCart || isDisplayOnly) ? Colors.grey : const Color(0xFF0B1220),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.withOpacity(0.6),
                        disabledForegroundColor: Colors.white70,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kNavBlue))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Hero Image
                if (s.imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: CachedNetworkImage(
                      imageUrl: s.imageUrl,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 220,
                        color: const Color(0xFFF1F5F9),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: 220,
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(Icons.image, size: 48),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Service Info Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.black.withOpacity(0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: kNavBlue.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              s.category,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: kNavBlue,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                _serviceData?['rating']?.toString() ?? '0',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0B1220),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        s.name,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0B1220),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        s.company,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // ✅ Price with booking type indicator
                      _buildPriceSection(),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Description - only show if has content
                if (_hasDescription())
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.black.withOpacity(0.06)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0B1220),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getDescription(),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Company Info - only show if has any data
                if (_hasCompanyInfo())
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.black.withOpacity(0.06)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Company Info',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0B1220),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._buildCompanyInfoRows(),
                      ],
                    ),
                  ),
                
                // ✅ Map Section - only show if service has location
                if (_hasLocation())
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.black.withOpacity(0.06)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0B1220),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              height: 300,
                              child: FlutterMap(
                                options: MapOptions(
                                  initialCenter: LatLng(
                                    widget.service.latitude ?? 32.2211,
                                    widget.service.longitude ?? 35.2544,
                                  ),
                                  initialZoom: 15.0,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.example.flutter_application_1',
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: LatLng(
                                          widget.service.latitude ?? 32.2211,
                                          widget.service.longitude ?? 35.2544,
                                        ),
                                        width: 40,
                                        height: 40,
                                        child: const Icon(
                                          Icons.location_pin,
                                          size: 40,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 100), // Space for bottom bar
              ],
            ),
    );
  }

  // ✅ Helper methods for clean display
  bool _hasDescription() {
    final desc1 = _serviceData?['description']?.toString().trim() ?? '';
    final desc2 = widget.service.desc.trim();
    return desc1.isNotEmpty || desc2.isNotEmpty;
  }

  String _getDescription() {
    final desc1 = _serviceData?['description']?.toString().trim() ?? '';
    if (desc1.isNotEmpty) return desc1;
    return widget.service.desc.isNotEmpty ? widget.service.desc : '';
  }

  bool _hasCompanyInfo() {
    final companyName = _serviceData?['companyInfo']?['name']?.toString().trim() ?? 
                        _serviceData?['companyName']?.toString().trim() ??
                        widget.service.company.trim();
    final city = _serviceData?['city']?.toString().trim() ?? '';
    final email = _serviceData?['companyInfo']?['email']?.toString().trim() ?? '';
    final phone = _serviceData?['companyInfo']?['phone']?.toString().trim() ?? '';
    
    return (companyName.isNotEmpty && companyName != 'Unknown' && companyName != 'N/A') ||
           (city.isNotEmpty && city != 'N/A') ||
           (email.isNotEmpty && email != 'N/A') ||
           (phone.isNotEmpty && phone != 'N/A');
  }

  bool _hasLocation() {
    return widget.service.latitude != null && widget.service.longitude != null;
  }

  List<Widget> _buildCompanyInfoRows() {
    final rows = <Widget>[];
    
    // Company Name - from API or fallback to widget
    final companyName = _serviceData?['companyInfo']?['name']?.toString().trim() ?? 
                        _serviceData?['companyName']?.toString().trim() ??
                        widget.service.company.trim();
    if (companyName.isNotEmpty && companyName != 'Unknown' && companyName != 'N/A') {
      rows.add(_InfoRow(icon: Icons.business_rounded, text: companyName));
    }
    
    // City/Location
    final city = _serviceData?['city']?.toString().trim() ?? '';
    if (city.isNotEmpty && city != 'N/A') {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 8));
      rows.add(_InfoRow(icon: Icons.location_on_rounded, text: city));
    }
    
    // Email
    final email = _serviceData?['companyInfo']?['email']?.toString().trim() ?? '';
    if (email.isNotEmpty && email != 'N/A') {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 8));
      rows.add(_InfoRow(icon: Icons.email_rounded, text: email));
    }
    
    // Phone
    final phone = _serviceData?['companyInfo']?['phone']?.toString().trim() ?? '';
    if (phone.isNotEmpty && phone != 'N/A') {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 8));
      rows.add(_InfoRow(icon: Icons.phone_rounded, text: phone));
    }
    
    return rows;
  }

  Widget _buildPriceSection() {
    final allPrices = _serviceData?['allPrices'] as Map<String, dynamic>?;
    final bookingType = _bookingType?.toLowerCase() ?? 'daily';
    
    String priceLabel;
    double displayPrice = widget.service.price;
    IconData priceIcon;
    
    switch (bookingType) {
      case 'hourly':
        priceLabel = 'per hour';
        priceIcon = Icons.schedule_rounded;
        displayPrice = (allPrices?['perHour'] as num?)?.toDouble() ?? widget.service.price;
        break;
      case 'capacity':
        priceLabel = 'per person';
        priceIcon = Icons.person_rounded;
        displayPrice = (allPrices?['perPerson'] as num?)?.toDouble() ?? widget.service.price;
        break;
      case 'daily':
        priceLabel = 'per day';
        priceIcon = Icons.calendar_today_rounded;
        displayPrice = (allPrices?['perDay'] as num?)?.toDouble() ?? widget.service.price;
        break;
      case 'mixed':
        priceLabel = 'per event';
        priceIcon = Icons.event_rounded;
        displayPrice = (allPrices?['perEvent'] as num?)?.toDouble() ?? widget.service.price;
        break;
      case 'display':
        priceLabel = 'display only';
        priceIcon = Icons.visibility_rounded;
        displayPrice = (allPrices?['displayPrice'] as num?)?.toDouble() ?? widget.service.price;
        break;
      default:
        priceLabel = 'per service';
        priceIcon = Icons.payments_rounded;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kNavBlue.withOpacity(0.08), kNavBlue.withOpacity(0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kNavBlue.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kNavBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(priceIcon, color: kNavBlue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _money(displayPrice),
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: kNavBlue,
                  ),
                ),
                Text(
                  priceLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          if (bookingType == 'display')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'View Only',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.orange.shade800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  
  const _InfoRow({required this.icon, required this.text});
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: kNavBlue),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }
}

// ✅ Helper function - مرة واحدة بس!
int _discountPercent(double original, double discounted) {
  if (original <= 0) return 0;
  final v = ((original - discounted) / original) * 100;
  return v.isNaN ? 0 : v.clamp(0, 95).round();
}

////////////////////////////////////////////////////////////////////////////////
/// ✅ Map Section for Services with Location
////////////////////////////////////////////////////////////////////////////////

class HomeServicesMapSection extends StatefulWidget {
  final List<HomeTrendingService> services;
  final Function(HomeTrendingService) onServiceTap;

  const HomeServicesMapSection({
    Key? key,
    required this.services,
    required this.onServiceTap,
  }) : super(key: key);

  @override
  State<HomeServicesMapSection> createState() => _HomeServicesMapSectionState();
}

class _HomeServicesMapSectionState extends State<HomeServicesMapSection> {
  late MapController _mapController;
  HomeTrendingService? _selectedService;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  LatLng _getCenterPoint() {
    if (widget.services.isEmpty) {
      return const LatLng(32.2211, 35.2544); // Default: Nablus
    }

    double sumLat = 0;
    double sumLng = 0;
    int count = 0;

    for (var service in widget.services) {
      if (service.latitude != null && service.longitude != null) {
        sumLat += service.latitude!;
        sumLng += service.longitude!;
        count++;
      }
    }

    if (count == 0) {
      return const LatLng(32.2211, 35.2544);
    }

    return LatLng(sumLat / count, sumLng / count);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // ✅ Map with OpenStreetMap tiles
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _getCenterPoint(),
                initialZoom: 11.0,
                minZoom: 8.0,
                maxZoom: 18.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.flutter_application_1',
                ),
                // ✅ Red markers for services
                MarkerLayer(
                  markers: widget.services.map((service) {
                    if (service.latitude == null || service.longitude == null) {
                      return null;
                    }

                    final isSelected = _selectedService?.id == service.id;

                    return Marker(
                      width: isSelected ? 50 : 40,
                      height: isSelected ? 50 : 40,
                      point: LatLng(service.latitude!, service.longitude!),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedService = service;
                          });
                          // Move map to service location
                          _mapController.move(
                            LatLng(service.latitude!, service.longitude!),
                            14.0,
                          );
                        },
                        child: Icon(
                          Icons.location_pin,
                          size: isSelected ? 50 : 40,
                          color: Colors.red,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).whereType<Marker>().toList(),
                ),
              ],
            ),

            // ✅ Service info card when selected
            if (_selectedService != null)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => widget.onServiceTap(_selectedService!),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Service image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _selectedService!.imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: _selectedService!.imageUrl,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(
                                    width: 70,
                                    height: 70,
                                    color: kNavBlue.withOpacity(0.1),
                                    child: const Icon(
                                      Icons.business_rounded,
                                      color: kNavBlue,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 70,
                                  height: 70,
                                  color: kNavBlue.withOpacity(0.1),
                                  child: const Icon(
                                    Icons.business_rounded,
                                    color: kNavBlue,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        // Service info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedService!.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1F2937),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _selectedService!.company,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF6B7280),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: kNavBlue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '₪${_selectedService!.price.toStringAsFixed(0)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: kNavBlue,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 18,
                                    color: kNavBlue,
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
              ),

            // ✅ Close button
            if (_selectedService != null)
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedService = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 20,
                      color: Color(0xFF6B7280),
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