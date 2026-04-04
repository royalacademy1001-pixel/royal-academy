// 🔥 IMPORTS FIRST (IMPORTANT)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🔥 Pages
import 'home_page.dart';
import 'courses_page.dart';
import 'student_profile_page.dart';
import 'payment/payment_page.dart';
import 'admin/pages/payments_admin_page.dart';
import 'admin/pages/verify_certificate_page.dart';
import 'admin/pages/analytics_dashboard_page.dart';
import 'admin/pages/instructor_requests_admin_page.dart';
import 'admin/pages/users_page.dart';
import 'admin/pages/admin_navigation_control_page.dart';
import 'admin/pages/courses_admin_page.dart';
import 'admin/categories_admin_page.dart';
import 'admin/pages/notifications_admin_page.dart';
import 'admin/pages/students_management_page.dart';
import 'admin/pages/news_admin_page.dart';

// 🔥 Instructor
import 'instructor/instructor_dashboard_page.dart';

// 🔥 Core
import 'core/colors.dart';
import 'core/firebase_service.dart';
import 'core/constants.dart';


// 🔥 NAV GUARD (مهم بس آمن)
class NavGuard {
  static bool locked = false;

  static void run(VoidCallback action) {
    if (locked) return;
    locked = true;

    try {
      action();
    } catch (e) {
      debugPrint("🔥 Nav Error: $e");
    }

    Future.delayed(const Duration(milliseconds: 250), () {
      locked = false;
    });
  }
}


// ================= MAIN NAV =================

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() =>
      _MainNavigationPageState();
}

class _MainNavigationPageState
    extends State<MainNavigationPage>
    with TickerProviderStateMixin {

  int currentIndex = 0;

  bool isAdmin = false;
  bool isInstructor = false;
  bool isVIP = false;

  bool _isLoadingUser = true;
  bool _deepLinkHandled = false;

  Stream<QuerySnapshot>? _notificationStream;

  List<Map<String, dynamic>> dynamicNav = [];

  late AnimationController _navAnim;
  late Animation<double> _fadeAnim;

  final List<Map<String, dynamic>> fallbackNav = [
    {
      "id": "home",
      "title": "الرئيسية",
      "icon": "home",
      "roles": ["all"],
      "order": 1,
      "enabled": true,
    },
    {
      "id": "courses",
      "title": "الكورسات",
      "icon": "courses",
      "roles": ["all"],
      "order": 2,
      "enabled": true,
    },
    {
      "id": "payment",
      "title": "الدفع",
      "icon": "payment",
      "roles": ["all"],
      "order": 3,
      "enabled": true,
    },
    {
      "id": "profile",
      "title": "حسابي",
      "icon": "profile",
      "roles": ["all"],
      "order": 4,
      "enabled": true,
    },
  ];

  @override
  void initState() {
    super.initState();

    _navAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _navAnim, curve: Curves.easeIn),
    );

    _navAnim.forward();

    _initAll();
  }

  Future<void> _initAll() async {

    try {
      final data = await FirebaseService.getUserData(refresh: true);

      isAdmin = data['isAdmin'] == true;
      isInstructor = data['instructorApproved'] == true;
      isVIP = data['subscribed'] == true;

    } catch (e) {
      debugPrint("User Load Error: $e");
    }

    final user = FirebaseService.auth.currentUser;

    if (user != null) {
      _notificationStream = FirebaseService.firestore
          .collection(AppConstants.notifications)
          .where('userId', isEqualTo: user.uid)
          .where('seen', isEqualTo: false)
          .limit(20)
          .snapshots();
    }

    FirebaseService.firestore
        .collection("app_settings")
        .doc("navigation")
        .snapshots()
        .listen((doc) {
      final data = doc.data();

      if (data == null || data['items'] == null) {
        dynamicNav = fallbackNav;
        if (mounted) setState(() {});
        return;
      }

      List items = data['items'];

      if (items.isEmpty) {
        dynamicNav = fallbackNav;
        if (mounted) setState(() {});
        return;
      }

      items = items.where((e) => (e['enabled'] ?? true) == true).toList();

      if (items.isEmpty) {
        dynamicNav = fallbackNav;
        if (mounted) setState(() {});
        return;
      }

      items.sort((a, b) =>
          (a['order'] ?? 0).compareTo(b['order'] ?? 0));

      dynamicNav = items.cast<Map<String, dynamic>>();

      if (mounted) setState(() {});
    });

    if (mounted) {
      setState(() => _isLoadingUser = false);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDeepLink();
    });
  }

  void _checkDeepLink() {

    if (_deepLinkHandled) return;
    _deepLinkHandled = true;

    try {
      final uri = Uri.base;

      if (uri.pathSegments.contains("verify")) {

        final index = uri.pathSegments.indexOf("verify");

        if (uri.pathSegments.length > index + 1) {

          final certId = uri.pathSegments[index + 1];

          if (!mounted) return;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  VerifyCertificatePage(certId: certId),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("DeepLink Error: $e");
    }
  }

  void _onTap(int index) {

    if (currentIndex == index) return;

    NavGuard.run(() {

      HapticFeedback.selectionClick();

      setState(() {
        currentIndex = index;
      });

    });
  }

  Widget _getPage(String id) {
    switch (id) {
      case "home":
        return _notificationWrapper(const HomePage());
      case "courses":
        return const CoursesPage();
      case "payment":
        return const PaymentPage();
      case "profile":
        return const StudentProfilePage();
      case "instructor":
        return const InstructorDashboardPage();
      case "admin_payments":
        return const PaymentsAdminPage();
      case "admin_requests":
        return const InstructorRequestsAdminPage();
      case "admin_analytics":
        return AnalyticsDashboardPage();
      case "admin_users":
        return const UsersPage();
      case "admin_nav_control":
        return const AdminNavigationControlPage();
      case "admin_courses":
        return const CoursesAdminPage();
      case "admin_categories":
        return const CategoriesAdminPage();
      case "admin_notifications":
        return const NotificationsAdminPage();
      case "admin_students":
        return const StudentsManagementPage();
      case "admin_news":
        return const NewsAdminPage();
      default:
        return const HomePage();
    }
  }

  IconData _getIcon(String name) {
    switch (name) {
      case "home":
        return Icons.home;
      case "courses":
        return Icons.school;
      case "payment":
        return Icons.payment;
      case "profile":
        return Icons.person;
      case "admin":
        return Icons.admin_panel_settings;
      case "analytics":
        return Icons.analytics;
      case "users":
        return Icons.group;
      case "instructor":
        return Icons.workspace_premium;
      case "settings":
        return Icons.settings;
      case "categories":
        return Icons.category;
      case "notifications":
        return Icons.notifications;
      case "news":
        return Icons.campaign;
      default:
        return Icons.circle;
    }
  }

  bool _allowItem(List roles) {
    if (roles.contains("all")) return true;
    if (roles.contains("admin") && isAdmin) return true;
    if (roles.contains("instructor") && isInstructor) return true;
    if (roles.contains("vip") && isVIP) return true;
    if (roles.contains("user") && !isAdmin) return true;
    return false;
  }

  List<Map<String, dynamic>> _activeNav() {
    final homeItem = fallbackNav.firstWhere(
      (e) => e['id'] == 'home',
      orElse: () => fallbackNav.first,
    );

    final List<Map<String, dynamic>> result = [homeItem];

    final source = dynamicNav.isEmpty ? fallbackNav : dynamicNav;

    for (final item in source) {
      final id = (item['id'] ?? "").toString();

      if (id == "home") continue;

      if (_allowItem(item['roles'] ?? [])) {
        result.add(item);
      }
    }

    if (result.length == 1) {
      for (final item in fallbackNav) {
        if ((item['id'] ?? "").toString() == "home") continue;
        result.add(item);
      }
    }

    return result;
  }

  List<Widget> _pages() {
    final items = _activeNav();
    return items.map((e) => _getPage(e['id'])).toList();
  }

  Widget _notificationWrapper(Widget child) {

    if (_notificationStream == null) return child;

    return Stack(
      children: [

        child,

        Positioned(
          top: 10,
          right: 10,
          child: StreamBuilder<QuerySnapshot>(
            stream: _notificationStream,
            builder: (context, snapshot) {

              final count = snapshot.data?.docs.length ?? 0;

              if (count == 0) return const SizedBox();

              return Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count > 9 ? "9+" : count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCustomNav(List<Map<String, dynamic>> items) {
    final width = MediaQuery.of(context).size.width;
    final compact = items.length <= 4;
    final itemWidth = compact ? (width / items.length) : 92.0;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        height: 86,
        decoration: BoxDecoration(
          color: AppColors.black,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final selected = index == currentIndex;

                return GestureDetector(
                  onTap: () => _onTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: itemWidth,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.gold.withOpacity(0.14) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? AppColors.gold : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedScale(
                          duration: const Duration(milliseconds: 200),
                          scale: selected ? 1.2 : 1,
                          child: Icon(
                            _getIcon((item['icon'] ?? '').toString()),
                            color: selected ? AppColors.gold : Colors.grey,
                            size: selected ? 26 : 24,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          (item['title'] ?? '').toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selected ? AppColors.gold : Colors.grey,
                            fontSize: 11,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _navAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final user = FirebaseService.auth.currentUser;
    if (user == null) {
      Future.microtask(() {
        Navigator.pushNamedAndRemoveUntil(
            context, '/login', (_) => false);
      });
      return const SizedBox();
    }

    if (_isLoadingUser) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pages = _pages();

    if (pages.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text("⚠️ لا توجد صفحات متاحة"),
        ),
      );
    }

    if (currentIndex >= pages.length) {
      currentIndex = 0;
    }

    final navItems = _activeNav();

    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: IndexedStack(
            key: ValueKey(currentIndex),
            index: currentIndex,
            children: pages,
          ),
        ),
      ),
      bottomNavigationBar: _buildCustomNav(navItems),
    );
  }
}