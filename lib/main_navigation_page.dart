import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home/home_page.dart';
import 'features/courses/pages/courses_page.dart';
import 'student_profile_page.dart';
import 'payment/payment_page.dart';
import 'admin/pages/payments_admin_page.dart';
import 'admin/pages/verify_certificate_page.dart';
import 'admin/pages/analytics_dashboard_page.dart' as analytics;
import 'admin/pages/instructor_requests_admin_page.dart';
import 'admin/pages/users_page.dart';
import 'admin/pages/admin_navigation_control_page.dart';
import 'admin/pages/courses_admin_page.dart';
import 'admin/categories_admin_page.dart';
import 'admin/pages/notifications_admin_page.dart';
import 'admin/pages/students_management_page.dart';
import 'admin/pages/news_admin_page.dart';
import 'admin/pages/students_crm_page.dart';
import 'admin/pages/attendance_report_page.dart';
import 'admin/pages/permissions_admin_page.dart';
import 'features/center_management/pages/center_management_page.dart';

import 'instructor/instructor_dashboard_page.dart';

import 'pages/student_dashboard_page.dart';
import 'pages/qr_attendance_page.dart';

import 'core/colors.dart';
import 'core/firebase_service.dart';
import 'core/constants.dart';
import 'core/permission_service.dart';

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

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage>
    with TickerProviderStateMixin {
  int currentIndex = 0;

  bool isAdmin = false;
  bool isInstructor = false;
  bool isVIP = false;

  String currentRole = "guest";

  bool _isLoadingUser = true;
  bool _deepLinkHandled = false;
  bool _redirectedToLogin = false;

  Stream<QuerySnapshot<Map<String, dynamic>>>? _notificationStream;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _navSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;

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
      "id": "student_dashboard",
      "title": "لوحتي",
      "icon": "dashboard",
      "roles": ["all"],
      "order": 2,
      "enabled": true,
    },
    {
      "id": "courses",
      "title": "الكورسات",
      "icon": "courses",
      "roles": ["all"],
      "order": 3,
      "enabled": true,
    },
    {
      "id": "qr_attendance",
      "title": "الحضور",
      "icon": "qr",
      "roles": ["all"],
      "order": 4,
      "enabled": true,
    },
    {
      "id": "payment",
      "title": "الدفع",
      "icon": "payment",
      "roles": ["all"],
      "order": 5,
      "enabled": true,
    },
    {
      "id": "profile",
      "title": "حسابي",
      "icon": "profile",
      "roles": ["all"],
      "order": 6,
      "enabled": true,
    },
    {
      "id": "admin_center",
      "title": "إدارة السنتر",
      "icon": "admin",
      "roles": ["admin"],
      "order": 7,
      "enabled": true,
    },
    {
      "id": "admin_students",
      "title": "إدارة الطلاب",
      "icon": "users",
      "roles": ["admin"],
      "order": 8,
      "enabled": true,
    },
    {
      "id": "admin_attendance",
      "title": "تقارير الحضور",
      "icon": "attendance",
      "roles": ["admin"],
      "order": 9,
      "enabled": true,
    },
    {
      "id": "admin_crm",
      "title": "CRM",
      "icon": "analytics",
      "roles": ["admin"],
      "order": 10,
      "enabled": true,
    },
    {
      "id": "admin_permissions",
      "title": "الصلاحيات",
      "icon": "settings",
      "roles": ["admin"],
      "order": 11,
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

  List<Map<String, dynamic>> _cloneItems(List<Map<String, dynamic>> source) {
    return source.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> _initAll() async {
    try {
      await PermissionService.load();

      final user = FirebaseService.auth.currentUser;

      if (user != null) {
        final doc = await FirebaseService.firestore
            .collection("users")
            .doc(user.uid)
            .get();

        final data = doc.data() ?? {};

        isAdmin = data['isAdmin'] == true;
        isInstructor = data['instructorApproved'] == true;
        isVIP = data['isVIP'] == true;
        currentRole = PermissionService.getRole(data);

        _userSub = FirebaseService.firestore
            .collection("users")
            .doc(user.uid)
            .snapshots()
            .listen((doc) {
          final data = doc.data() ?? {};

          isAdmin = data['isAdmin'] == true;
          isInstructor = data['instructorApproved'] == true;
          isVIP = data['isVIP'] == true;
          currentRole = PermissionService.getRole(data);

          if (mounted) setState(() {});
        });
      }
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

    try {
      final navRef =
          FirebaseService.firestore.collection("app_settings").doc("navigation");

      _navSub = navRef.snapshots().listen((doc) {
        try {
          final data = doc.data();

          if (data == null || data['items'] == null) {
            dynamicNav = _cloneItems(fallbackNav);
            if (mounted) {
              setState(() {
                if (currentIndex >= dynamicNav.length) {
                  currentIndex = 0;
                }
              });
            }
            return;
          }

          List items = data['items'];

          if (items.isEmpty) {
            dynamicNav = _cloneItems(fallbackNav);
            if (mounted) {
              setState(() {
                if (currentIndex >= dynamicNav.length) {
                  currentIndex = 0;
                }
              });
            }
            return;
          }

          items = items.where((e) => (e['enabled'] ?? true) == true).toList();

          if (items.isEmpty) {
            dynamicNav = _cloneItems(fallbackNav);
            if (mounted) {
              setState(() {
                if (currentIndex >= dynamicNav.length) {
                  currentIndex = 0;
                }
              });
            }
            return;
          }

          items.sort((a, b) => (a['order'] ?? 0).compareTo(b['order'] ?? 0));

          dynamicNav = items.cast<Map<String, dynamic>>();

          if (mounted) {
            setState(() {
              if (currentIndex >= _activeNav().length) {
                currentIndex = 0;
              }
            });
          }
        } catch (e) {
          dynamicNav = _cloneItems(fallbackNav);
          if (mounted) {
            setState(() {
              if (currentIndex >= dynamicNav.length) {
                currentIndex = 0;
              }
            });
          }
        }
      });
    } catch (e) {
      dynamicNav = _cloneItems(fallbackNav);
    }

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
              builder: (_) => VerifyCertificatePage(certId: certId),
            ),
          );
        }
      }
    } catch (_) {}
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

  String _permissionKeyForNavId(String id) {
    if (id == "admin_permissions") return "permissions";
    if (id == "admin_students") return "students";
    if (id == "admin_crm") return "students_crm";
    if (id == "admin_center") return "admin";
    if (id == "admin_attendance") return "attendance";
    if (id == "payment") return "payments";
    return id.trim().toLowerCase();
  }

  Widget _guard(String page, Widget child) {
    if (!PermissionService.isLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return child;
  }

  Widget _getPage(String id) {
    switch (id) {
      case "home":
        return _guard("home", const HomePage());
      case "student_dashboard":
        return _guard("home", const StudentDashboardPage());
      case "courses":
        return _guard("courses", const CoursesPage());
      case "qr_attendance":
        return _guard("qr", const QRAttendancePage());
      case "payment":
        return _guard("payments", const PaymentPage());
      case "profile":
        return _guard("profile", const StudentProfilePage());
      case "admin_center":
        return _guard("admin", CenterManagementPage());
      case "admin_students":
        return _guard("students", const StudentsManagementPage());
      case "admin_attendance":
        return _guard("attendance", const AttendanceReportPage());
      case "admin_crm":
        return _guard("students_crm", const StudentsCRMPage());
      case "admin_permissions":
        return _guard("permissions", const PermissionsAdminPage());
      default:
        return _guard("home", const HomePage());
    }
  }

  IconData _getIcon(String name) {
    switch (name) {
      case "home":
        return Icons.home;
      case "profile":
        return Icons.person;
      case "courses":
        return Icons.school;
      case "payment":
        return Icons.payments;
      case "qr":
        return Icons.qr_code;
      case "dashboard":
        return Icons.dashboard;
      case "users":
        return Icons.group;
      case "analytics":
        return Icons.analytics;
      case "attendance":
        return Icons.fact_check;
      case "settings":
        return Icons.settings;
      case "admin":
        return Icons.admin_panel_settings;
      default:
        return Icons.circle;
    }
  }

  bool _allowItem(Map<String, dynamic> item, String pageId) {
    if (!PermissionService.isLoaded) return false;
    if (item['enabled'] == false) return false;

    if (pageId == "courses" || pageId == "payment") return true;

    final rolesRaw = item['roles'];
    List roles = [];

    if (rolesRaw is List) {
      roles = rolesRaw.map((e) => e.toString().toLowerCase()).toList();
    }

    final allowByRole =
        roles.contains("all") ||
        (roles.contains("admin") && isAdmin);

    final hasPermission = PermissionService.canAccess(
      role: currentRole,
      page: _permissionKeyForNavId(pageId),
    );

    return allowByRole && hasPermission;
  }

  List<Map<String, dynamic>> _activeNav() {
    final source = dynamicNav.isEmpty ? fallbackNav : dynamicNav;

    final List<Map<String, dynamic>> result = [];

    final homeItem = source.firstWhere(
      (e) => (e['id'] ?? "") == "home",
      orElse: () => fallbackNav.first,
    );

    final profileItem = source.firstWhere(
      (e) => (e['id'] ?? "") == "profile",
      orElse: () => fallbackNav.firstWhere((e) => (e['id'] ?? "") == "profile"),
    );

    result.add(homeItem);
    result.add(profileItem);

    for (final item in source) {
      final id = (item['id'] ?? "").toString();

      if (id == "home" || id == "profile") continue;

      if (_allowItem(item, id)) {
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

    return child;
  }

  Widget _buildCustomNav(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 60,
      color: AppColors.navBar,
      child: Row(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          return Expanded(
            child: GestureDetector(
              onTap: () => _onTap(index),
              child: SizedBox(
                height: 60,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 22,
                      child: Icon(
                        _getIcon((item['icon'] ?? "").toString()),
                        size: 20,
                        color: currentIndex == index
                            ? AppColors.gold
                            : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      height: 14,
                      child: Text(
                        (item['title'] ?? "").toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          height: 1,
                          color: currentIndex == index
                              ? AppColors.gold
                              : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  void dispose() {
    _navSub?.cancel();
    _userSub?.cancel();
    _navAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseService.auth.currentUser;

    if (user == null) {
      return const SizedBox();
    }

    if (_isLoadingUser) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pages = _pages();

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: _buildCustomNav(_activeNav()),
    );
  }
}