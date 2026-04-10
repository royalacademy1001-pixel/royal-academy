import 'package:flutter/material.dart';

// 🔥 NEW
import '../controller/admin_controller.dart';
import '../widgets/admin_body.dart';
import '../widgets/admin_add_menu.dart';

// 🔥 Pages
import '../pick_lesson_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {

  final AdminController controller = AdminController();

  bool tapping = false;

  final List<Map<String, dynamic>> allAdminPages = [
    {"id": "admin_courses", "title": "إدارة الكورسات", "icon": "courses"},
    {"id": "admin_categories", "title": "إدارة التصنيفات", "icon": "categories"},
    {"id": "admin_notifications", "title": "الإشعارات", "icon": "notifications"},
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

    controller.init(allAdminPages, () {
      if (mounted) setState(() {});
    });
  }

  Future<void> refresh() async {
    await controller.refresh(() {
      if (mounted) setState(() {});
    });
  }

  Future<String?> pickLesson() async {
    try {
      if (tapping) return null;

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
    AdminAddMenu.open(
      context: context,
      refresh: refresh,
      pickLesson: pickLesson,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminBody(
      checkingAdmin: controller.checkingAdmin,
      isAdmin: controller.isAdmin,
      loadingRefresh: controller.loadingRefresh,
      statsFuture: controller.statsFuture,
      onRefresh: refresh,
      onAdd: openAddMenu,
    );
  }
}