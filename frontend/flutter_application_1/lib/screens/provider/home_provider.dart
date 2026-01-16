import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/notification_provider_service.dart'; 
import 'package:flutter_application_1/services/booked_provider_service.dart';
import 'package:flutter_application_1/services/chat_provider_service.dart';

// Local imports (same folder)
import 'finance_provider.dart';

// Other screens
import 'package:flutter_application_1/screens/edit_profile_provider.dart';
import 'package:flutter_application_1/screens/services_provider.dart';
import 'package:flutter_application_1/screens/signin.dart';
import 'package:flutter_application_1/screens/provider/booking_provider.dart';
import 'package:flutter_application_1/screens/messages_provider.dart';
import 'package:flutter_application_1/screens/notifications_provider.dart';
import 'package:flutter_application_1/screens/reviews_provider.dart';
import 'package:flutter_application_1/screens/provider/packages_provider.dart';
import 'package:flutter_application_1/screens/user/home/home_customer.dart';

const Color kPrimaryColor = Color.fromARGB(215, 20, 20, 215);
const Color kTextColor = Colors.black;
const Color kBackgroundColor = Colors.white;
const Color kContactIconColor = Color(0xFFFF7A00);
const Color kContactCircleColor = Color(0xFFFFE6CC);

class ProviderModel {
  final String brandName;
  final String email;
  final String phone;
  final String description;
  final String city;

  int? bookings;
  int? views;
  int? messages;
  int? reviews;

  ProviderModel({
    required this.brandName,
    required this.email,
    required this.phone,
    required this.description,
    required this.city,
    this.bookings,
    this.views,
    this.messages,
    this.reviews,
  });
}

class HomeProviderScreen extends StatefulWidget {
  final ProviderModel provider;

  const HomeProviderScreen({Key? key, required this.provider})
      : super(key: key);

  @override
  State<HomeProviderScreen> createState() => _HomeProviderScreenState();
}

class _HomeProviderScreenState extends State<HomeProviderScreen> with WidgetsBindingObserver {
  late ProviderModel provider;
  List<Map<String, dynamic>> _services = [];
  
  @override
  void initState() {
    super.initState();
    provider = widget.provider;
    _loadServices();
    
    // ✅ مراقبة حالة التطبيق
    WidgetsBinding.instance.addObserver(this);
    
    // ✅ البدء باتصال الـ Realtime بمجرد إنشاء الشاشة
    _initializeConnections();
  }
  
  /// ✅ دالة موحدة لتهيئة جميع الاتصالات
  Future<void> _initializeConnections() async {
    debugPrint('🚀 Initializing real-time connections...');
    
    // اتصال الإشعارات
    await NotificationProviderService.initRealtimeNotifications();
    
    // تحديث العداد الأولي
    await _updateUnreadCount();
    
    // ✅ جلب عدد الحجوزات غير المشاهدة
    await BookedProviderService.fetchUnseenCount();
    
    // ✅ تهيئة اتصال الشات Real-time + جلب عدد الرسائل غير المقروءة
    await _initializeChatConnection();
    
    // التحقق من حالة الاتصال بعد ثانية
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        final isConnected = NotificationProviderService.isConnected();
        debugPrint('📊 Connection status after init: $isConnected');
        
        if (!isConnected) {
          debugPrint('⚠️ Not connected, retrying...');
          NotificationProviderService.reconnect();
        }
      }
    });
  }
  
  /// ✅ تهيئة اتصال الشات Real-time
  Future<void> _initializeChatConnection() async {
    try {
      // 1. تحديد userId الحالي (مهم جداً قبل initSocket)
      final userData = await AuthService.getUserData();
      final userId = userData?['_id']?.toString() ?? userData?['id']?.toString();
      if (userId != null) {
        ChatProviderService().currentUserId = userId;
        debugPrint('💬 Chat userId set: $userId');
      } else {
        debugPrint('⚠️ Could not get userId for chat');
        return;
      }
      
      // 2. تهيئة Socket للشات (سيسجل الـ listener للـ unreadCount)
      await ChatProviderService().initSocket();
      
      // 3. جلب عدد الرسائل غير المقروءة الأولي
      await ChatProviderService().fetchUnreadCount();
      
      debugPrint('✅ Chat connection initialized, unread count: ${ChatProviderService.unreadGlobalCount.value}');
    } catch (e) {
      debugPrint('❌ Error initializing chat: $e');
    }
  }
  
  /// ✅ معالجة تغييرات حالة التطبيق
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    debugPrint('📱 App lifecycle changed: $state');
    
    switch (state) {
      case AppLifecycleState.resumed:
        // التطبيق عاد للواجهة
        debugPrint('✅ App resumed, reconnecting...');
        _initializeConnections();
        break;
      case AppLifecycleState.paused:
        // التطبيق في الخلفية
        debugPrint('⏸️ App paused');
        break;
      case AppLifecycleState.inactive:
        // التطبيق غير نشط مؤقتاً
        debugPrint('💤 App inactive');
        break;
      case AppLifecycleState.detached:
        // التطبيق سيغلق
        debugPrint('🔴 App detached');
        break;
      default:
        break;
    }
  }
  
  /// ✅ دالة لتحديث عداد الإشعارات
  Future<void> _updateUnreadCount() async {
    if (!mounted) return;
    await NotificationProviderService.updateUnreadCountOnConnect();
  }
  
  @override
  void dispose() {
    // ✅ إزالة المراقب
    WidgetsBinding.instance.removeObserver(this);
    
    // ✅ لا نغلق الاتصال هنا لأننا نريده يبقى نشط
    super.dispose();
  }

  void _loadServices() async {
    _services = [
      {
        "name": "Wedding Photography",
        "price": 1000,
        "discount": "20",
      },
      {
        "name": "Event Lighting",
        "price": 800,
      },
    ];
    setState(() {});
  }

  // ====== BURGER MENU ======
  void _openMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_none_outlined,
                      color: kPrimaryColor),
                  title: Text(
                    'Notifications',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsProviderScreen(),
                      ),
                    );
                    // 💡 عند العودة، نطلب تحديث الحالة يدوياً للتأكد
                    _updateUnreadCount();
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.settings_outlined, color: kPrimaryColor),
                  title: Text(
                    'Settings',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfileProvider(provider: provider),
                      ),
                    );
                    if (updated != null && updated is ProviderModel) {
                      setState(() => provider = updated);
                    }
                  },
                ),
                const Divider(height: 18),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: Text(
                    'Sign out',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.redAccent,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    // ✅ إغلاق الاتصال عند تسجيل الخروج
                    NotificationProviderService.closeRealtimeConnection();
                    await AuthService.deleteToken();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => SignInScreen()),
                      (_) => false,
                    );
                  },
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          backgroundColor: kBackgroundColor,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: _openMenu,
          ),
          title: Text(
            "Provider Dashboard",
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileProvider(provider: provider),
                  ),
                );

                if (updated != null && updated is ProviderModel) {
                  setState(() => provider = updated);
                }
              },
              icon: const Icon(Icons.edit, color: Colors.black),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderCard(provider: provider),
              const SizedBox(height: 16),
              
              // 💰 Finance Card
              _FinanceTeaserCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FinanceProviderScreen(),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 12),
              _PackagesTeaserCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PackagesProviderScreen(
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              Text(
                "Quick Actions",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 15),

              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          title: "Services",
                          icon: Icons.auto_awesome_outlined,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ServicesProviderScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // ✅ Bookings مع Badge
                      Expanded(
                        child: ValueListenableBuilder<int>(
                          valueListenable: BookedProviderService.unseenCountNotifier,
                          builder: (context, unseenCount, child) {
                            return _QuickAction(
                              title: "Bookings",
                              icon: Icons.calendar_month_outlined,
                              showBadge: unseenCount > 0,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const BookingsScreen(),
                                  ),
                                );
                                // ✅ تحديث العداد عند العودة
                                BookedProviderService.fetchUnseenCount();
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ValueListenableBuilder<int>(
                          valueListenable: ChatProviderService.unreadGlobalCount,
                          builder: (context, unreadCount, child) {
                            return _QuickAction(
                              title: "Messages",
                              icon: Icons.chat_bubble_outline,
                              showBadge: unreadCount > 0,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const MessagesProviderScreen(),
                                  ),
                                );
                                ChatProviderService().fetchUnreadCount();
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ValueListenableBuilder<bool>(
                          valueListenable: NotificationProviderService.hasUnreadNotifier,
                          builder: (context, hasUnread, child) {
                            return _QuickAction(
                              title: "Notifications",
                              icon: Icons.notifications_none_outlined,
                              showBadge: hasUnread,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const NotificationsProviderScreen(),
                                  ),
                                );
                                _updateUnreadCount();
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                "About Your Brand",
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  provider.description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Text(
                "Contact Info",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 13),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const _ContactIcon(icon: Icons.email),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Email",
                                style: GoogleFonts.poppins(
                                    fontSize: 14, color: Colors.grey.shade600)),
                            Text(provider.email,
                                style: GoogleFonts.poppins(
                                    fontSize: 15, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    Row(
                      children: [
                        const _ContactIcon(icon: Icons.phone),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Phone",
                                style: GoogleFonts.poppins(
                                    fontSize: 14, color: Colors.grey.shade600)),
                            Text(provider.phone,
                                style: GoogleFonts.poppins(
                                    fontSize: 15, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final ProviderModel provider;

  const _HeaderCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F0FF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: kPrimaryColor.withOpacity(0.18),
            child: Text(
              provider.brandName[0].toUpperCase(),
              style: GoogleFonts.poppins(
                color: kPrimaryColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.brandName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on,
                        size: 18, color: Colors.grey.shade700),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        provider.city,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _StatBox(
      {required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: kPrimaryColor),
          const SizedBox(height: 6),
          Text(
            "$value",
            style:
                GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style:
                GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool showBadge;

  const _QuickAction({
    required this.title,
    required this.icon,
    required this.onTap,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F2FF),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 28, color: kPrimaryColor),
                if (showBadge)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFF3F2FF),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _ContactIcon extends StatelessWidget {
  final IconData icon;

  const _ContactIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 25,
      backgroundColor: kContactCircleColor,
      child: Icon(icon, color: kContactIconColor, size: 26),
    );
  }
}

class _PackagesTeaserCard extends StatelessWidget {
  final VoidCallback onTap;

  const _PackagesTeaserCard({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              kPrimaryColor.withOpacity(0.08),
              kPrimaryColor.withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: kPrimaryColor.withOpacity(0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.inventory_2_rounded,
                color: kPrimaryColor,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Packages Overview",
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: kTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Create and manage your wedding packages in one place.",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: kPrimaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

// 💰 Finance Teaser Card Widget
class _FinanceTeaserCard extends StatelessWidget {
  final VoidCallback onTap;

  const _FinanceTeaserCard({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF10B981).withOpacity(0.12),
              const Color(0xFF10B981).withOpacity(0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: const Color(0xFF10B981).withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Color(0xFF10B981),
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Finance Overview",
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: kTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Track your revenue, bookings, and financial insights.",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: Color(0xFF10B981),
            ),
          ],
        ),
      ),
    );
  }
}