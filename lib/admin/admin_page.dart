import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🔥 Core
import '../core/colors.dart';

// 🔥 Widgets
import '../widgets/loading_widget.dart';
import '../widgets/admin_stats.dart';
import '../widgets/admin_buttons.dart';

// 🔥 Pages
import 'pages/courses_admin_page.dart';
import 'pages/notifications_admin_page.dart';
import 'pages/payments_admin_page.dart';
import 'pages/users_page.dart';
import 'pages/students_management_page.dart';
import 'categories_admin_page.dart';
import 'pages/instructor_requests_admin_page.dart';
import 'add_course_page.dart';
import 'add_lesson_page.dart';
import 'pages/analytics_dashboard_page.dart' as analytics;
import 'add_news_page.dart';
import 'pages/news_admin_page.dart';
import 'pick_lesson_page.dart';
import 'pages/students_crm_page.dart';
import 'pages/admin_navigation_control_page.dart';

// 🔥 QUIZ
import '../features/quiz/admin_add_quiz_page.dart';

// 🔥 SERVICE
import 'services/admin_dashboard_service.dart' as admin_service;

// 🔥 Firebase
import '../core/firebase_service.dart';
import '../core/constants.dart';

class AdminCache {
  static Map<String, dynamic>? stats;
  static bool loading = false;
}

Widget adminSafe(Widget child) {
  return RepaintBoundary(child: child);
}

class AdminTapGuard {
  static bool _locked = false;

  static bool canTap() {
    if (_locked) return false;
    _locked = true;
    Future.delayed(const Duration(milliseconds: 400), () {
      _locked = false;
    });
    return true;
  }
}

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late Future<Map<String, dynamic>> statsFuture;

  bool loadingRefresh = false;
  bool openingMenu = false;

  bool isAdmin = false;
  bool checkingAdmin = true;

  bool tapping = false;

  final List<Map<String, dynamic>> allAdminPages = [
    {"id": "admin_courses", "title": "إدارة الكورسات", "icon": "courses"},
    {
      "id": "admin_categories",
      "title": "إدارة التصنيفات",
      "icon": "categories"
    },
    {
      "id": "admin_notifications",
      "title": "الإشعارات",
      "icon": "notifications"
    },
    {"id": "admin_payments", "title": "المدفوعات", "icon": "payment"},
    {"id": "admin_users", "title": "المستخدمين", "icon": "users"},
    {"id": "admin_students", "title": "إدارة الطلاب", "icon": "users"},
    {"id": "admin_requests", "title": "طلبات المدرسين", "icon": "instructor"},
    {"id": "admin_analytics", "title": "Analytics", "icon": "analytics"},
    {"id": "admin_news", "title": "إدارة الأخبار", "icon": "news"},
    {"id": "admin_crm", "title": "CRM", "icon": "analytics"},
  ];

  @override
  void initState() {
    super.initState();
    _init();
    _syncNavWithAdminPages();
  }

  Future<void> _syncNavWithAdminPages() async {
    try {
      final ref = FirebaseService.firestore
          .collection("app_settings")
          .doc("navigation");

      final doc = await ref.get();
      final data = doc.data();

      List items = [];

      if (data != null && data['items'] != null) {
        items = List.from(data['items']);
      }

      for (var page in allAdminPages) {
        bool exists = items.any((e) => e['id'] == page['id']);

        if (!exists) {
          items.add({
            "id": page['id'],
            "title": page['title'],
            "icon": page['icon'],
            "order": items.length + 1,
            "roles": ["admin"],
            "enabled": false,
          });
        }
      }

      await ref.set({"items": items});
    } catch (e) {
      debugPrint("🔥 Sync Nav Error: $e");
    }
  }

  Future<void> _init() async {
    try {
      final user = FirebaseService.auth.currentUser;
      if (user == null) return;

      final doc = await FirebaseService.firestore
          .collection(AppConstants.users)
          .doc(user.uid)
          .get();

      final data = doc.data() ?? {};

      isAdmin = data['isAdmin'] == true;

      final r = (data['role'] ?? "").toString().toLowerCase();

      if (r.isNotEmpty) {
        isAdmin = r == "admin";
      } else {
        if (data['isAdmin'] == true) {
          isAdmin = true;
        } else if (data['instructorApproved'] == true) {
          isAdmin = false;
        } else if (data['isVIP'] == true) {
          isAdmin = false;
        } else if (data['subscribed'] == true) {
          isAdmin = false;
        } else {
          isAdmin = false;
        }
      }
    } catch (e) {
      debugPrint("Admin Check Error: $e");
    }

    admin_service.AdminStatsService.clearCache();
    AdminCache.stats = null;
    statsFuture = admin_service.AdminStatsService.getStats();

    if (mounted) {
      setState(() => checkingAdmin = false);
    }
  }

  Future<void> refresh() async {
    if (loadingRefresh) return;

    setState(() => loadingRefresh = true);

    try {
      admin_service.AdminStatsService.clearCache();
      AdminCache.stats = null;

      final data = await admin_service.AdminStatsService.getStats();

      if (mounted) {
        setState(() {
          statsFuture = Future.value(data);
        });
      }
    } catch (e) {
      debugPrint("Refresh Error: $e");
    }

    if (mounted) {
      setState(() => loadingRefresh = false);
    }
  }

  Widget _pricingPanel() {
    final monthlyController = TextEditingController();
    final yearlyController = TextEditingController();

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseService.firestore.collection("settings").doc("pricing").get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator(color: AppColors.gold);
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

        monthlyController.text = data['monthly']?.toString() ?? "";
        yearlyController.text = data['yearly']?.toString() ?? "";

        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              TextField(
                controller: monthlyController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "السعر الشهري",
                  labelStyle: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: yearlyController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "السعر السنوي",
                  labelStyle: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                ),
                onPressed: () async {
                  final monthly = int.tryParse(monthlyController.text) ?? 0;
                  final yearly = int.tryParse(yearlyController.text) ?? 0;

                  await FirebaseService.firestore
                      .collection("settings")
                      .doc("pricing")
                      .set({
                    "monthly": monthly,
                    "yearly": yearly,
                  });

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("تم تحديث الأسعار ✅")),
                    );
                  }
                },
                child: const Text("حفظ"),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> pickLesson() async {
    try {
      if (tapping || !AdminTapGuard.canTap()) return null;

      tapping = true;

      final lessonId = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => const PickLessonPage(),
        ),
      );

      tapping = false;

      return lessonId;
    } catch (_) {
      tapping = false;
      return null;
    }
  }

  void openAddMenu() {
    if (openingMenu || !AdminTapGuard.canTap()) return;

    openingMenu = true;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.black.withValues(alpha: 0.4),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(30)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "🚀 إضافة جديدة",
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 25),

                // 🔥 ADD COURSE
                _menuItem(
                  icon: Icons.menu_book,
                  color: AppColors.gold,
                  title: "إضافة كورس",
                  subtitle: "إنشاء كورس تدريبي جديد",
                  onTap: () async {
                    if (Navigator.canPop(sheetContext)) {
                      Navigator.pop(sheetContext);
                    }

                    await Future.delayed(const Duration(milliseconds: 200));

                    if (!mounted) return;

                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddCoursePage(),
                      ),
                    );

                    if (!mounted) return;

                    refresh();
                  },
                ),

                // 🔥 ADD LESSON
                _menuItem(
                  icon: Icons.play_circle,
                  color: Colors.green,
                  title: "إضافة محتوى",
                  subtitle: "رفع فيديو أو درس جديد",
                  onTap: () async {
                    if (Navigator.canPop(sheetContext)) {
                      Navigator.pop(sheetContext);
                    }

                    await Future.delayed(const Duration(milliseconds: 200));

                    if (!mounted) return;

                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddLessonPage(),
                      ),
                    );

                    if (!mounted) return;

                    refresh();
                  },
                ),

                // 🔥 ADD QUIZ (FIXED 100%)
                _menuItem(
                  icon: Icons.quiz,
                  color: Colors.orange,
                  title: "إضافة Quiz",
                  subtitle: "إضافة اختبار لتقييم الطلاب",
                  onTap: () async {
                    if (Navigator.canPop(sheetContext)) {
                      Navigator.pop(sheetContext);
                    }

                    await Future.delayed(const Duration(milliseconds: 200));

                    String? lessonId = await pickLesson();

                    if (!mounted) return;

                    if (lessonId == null || lessonId.isEmpty) {
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("❌ لم يتم اختيار درس")),
                      );
                      return;
                    }

                    if (!mounted) return;

                    // ignore: use_build_context_synchronously
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AddQuizPage(
                          lessonId: lessonId,
                        ),
                      ),
                    );

                    if (!mounted) return;

                    refresh();
                  },
                ),

                // 🔥 ADD NEWS
                _menuItem(
                  icon: Icons.campaign,
                  color: Colors.blue,
                  title: "إضافة خبر",
                  subtitle: "نشر إعلان هام للأكاديمية",
                  onTap: () async {
                    if (Navigator.canPop(sheetContext)) {
                      Navigator.pop(sheetContext);
                    }

                    await Future.delayed(const Duration(milliseconds: 200));

                    if (!mounted) return;

                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddNewsPage(),
                      ),
                    );

                    if (!mounted) return;

                    refresh();
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      openingMenu = false;
    });
  }

  Widget _menuItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color),
        ),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing:
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (checkingAdmin) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: LoadingWidget()),
      );
    }

    if (!isAdmin) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text("🚫 غير مصرح بالدخول لمسؤولين فقط",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("⚙ Royal Dashboard",
            style: TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1)),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          loadingRefresh
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: AppColors.gold, strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.gold),
                  onPressed: refresh,
                )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: openAddMenu,
        backgroundColor: AppColors.gold,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.add, size: 32, color: Colors.black),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.03),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                  child: const SizedBox()),
            ),
          ),
          adminSafe(
            FutureBuilder<Map<String, dynamic>>(
              future: statsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingWidget();
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text("❌ خطأ في مزامنة البيانات السحابية",
                        style: TextStyle(color: Colors.white)),
                  );
                }

                final data = snapshot.data ?? {};

                return RefreshIndicator(
                  color: AppColors.gold,
                  backgroundColor: AppColors.black,
                  onRefresh: refresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "ملخص الحالة",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 15),
                          AdminStats(data: data),
                          const SizedBox(height: 30),
                          const Text(
                            "⚙ إعدادات الاشتراك",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 15),
                          _pricingPanel(),
                          const SizedBox(height: 30),
                          const Text(
                            "⚙ التحكم في البار",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 15),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.black.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.05)),
                            ),
                            child: ListTile(
                              leading:
                                  const Icon(Icons.tune, color: AppColors.gold),
                              title: const Text("🎛 تعديل البار",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              subtitle: const Text(
                                  "إظهار / إخفاء / ترتيب الأيقونات",
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                              trailing: const Icon(Icons.arrow_forward_ios,
                                  color: Colors.grey, size: 14),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const AdminNavigationControlPage(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 30),
                          const Text(
                            "الأدوات الإدارية",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 15),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.black.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.05)),
                            ),
                            child: AdminButtons(
                              pages: [
                                {
                                  "title": "📚 إدارة الكورسات",
                                  "page": const CoursesAdminPage()
                                },
                                {
                                  "title": "📂 إدارة التصنيفات",
                                  "page": const CategoriesAdminPage()
                                },
                                {
                                  "title": "🔔 الإشعارات",
                                  "page": const NotificationsAdminPage()
                                },
                                {
                                  "title": "💰 المدفوعات",
                                  "page": const PaymentsAdminPage()
                                },
                                {
                                  "title": "👥 المستخدمين",
                                  "page": const UsersPage()
                                },
                                {
                                  "title": "🎓 إدارة الطلاب",
                                  "page": const StudentsManagementPage()
                                },
                                {
                                  "title": "👨‍🏫 طلبات المدرسين",
                                  "page": const InstructorRequestsAdminPage()
                                },
                                {
                                  "title": "📊 Analytics",
                                  "page": analytics.AnalyticsDashboardPage()
                                },
                                {
                                  "title": "📰 إدارة الأخبار",
                                  "page": NewsAdminPage()
                                },
                                {
                                  "title": "📊 CRM الطلاب",
                                  "page": const StudentsCRMPage()
                                },
                              ],
                            ),
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
