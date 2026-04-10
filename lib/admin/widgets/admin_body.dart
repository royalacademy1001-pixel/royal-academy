import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../shared/widgets/loading_widget.dart';
import '../widgets/admin_stats.dart';
import '../widgets/admin_buttons.dart';
import '../widgets/admin_app_bar.dart';
import '../widgets/admin_background.dart';
import '../widgets/admin_sections.dart';
import '../widgets/pricing_panel.dart';

import '../pages/courses_admin_page.dart';
import '../pages/notifications_admin_page.dart';
import '../pages/payments_admin_page.dart';
import '../pages/users_page.dart';
import '../pages/students_management_page.dart';
import '../categories_admin_page.dart';
import '../pages/instructor_requests_admin_page.dart';
import '../pages/news_admin_page.dart';
import '../pages/students_crm_page.dart';
import '../pages/admin_navigation_control_page.dart';
import '../pages/analytics_dashboard_page.dart' as analytics;

class AdminBody extends StatelessWidget {
  final bool checkingAdmin;
  final bool isAdmin;
  final bool loadingRefresh;
  final Future<Map<String, dynamic>> statsFuture;

  final Future<void> Function() onRefresh;
  final VoidCallback onAdd;

  const AdminBody({
    super.key,
    required this.checkingAdmin,
    required this.isAdmin,
    required this.loadingRefresh,
    required this.statsFuture,
    required this.onRefresh,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    if (checkingAdmin) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!isAdmin) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            "🚫 غير مصرح بالدخول لمسؤولين فقط",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AdminAppBar(
        loading: loadingRefresh,
        onRefresh: onRefresh,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onAdd,
        backgroundColor: AppColors.gold,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.add, size: 32, color: Colors.black),
      ),
      body: AdminBackground(
        child: FutureBuilder<Map<String, dynamic>>(
          future: statsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingWidget();
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  "❌ خطأ في مزامنة البيانات السحابية",
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            final data = snapshot.data ?? {};

            return RefreshIndicator(
              color: AppColors.gold,
              backgroundColor: AppColors.black,
              onRefresh: onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AdminSection(
                        title: "ملخص الحالة",
                        child: AdminStats(data: data),
                      ),
                      const SizedBox(height: 30),
                      AdminSection(
                        title: "⚙ إعدادات الاشتراك",
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.monetization_on, color: AppColors.gold),
                            title: const Text(
                              "💰 تعديل الأسعار",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              "تعديل الاشتراك الشهري والسنوي",
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PricingPage(),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      AdminSection(
                        title: "⚙ التحكم في البار",
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.tune, color: AppColors.gold),
                            title: const Text(
                              "🎛 تعديل البار",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              "إظهار / إخفاء / ترتيب الأيقونات",
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AdminNavigationControlPage(),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      AdminSection(
                        title: "الأدوات الإدارية",
                        child: AdminButtons(
                          pages: [
                            {"title": "📚 إدارة الكورسات", "page": const CoursesAdminPage()},
                            {"title": "📂 إدارة التصنيفات", "page": const CategoriesAdminPage()},
                            {"title": "🔔 الإشعارات", "page": const NotificationsAdminPage()},
                            {"title": "💰 المدفوعات", "page": const PaymentsAdminPage()},
                            {"title": "👥 المستخدمين", "page": const UsersPage()},
                            {"title": "🎓 إدارة الطلاب", "page": const StudentsManagementPage()},
                            {"title": "👨‍🏫 طلبات المدرسين", "page": const InstructorRequestsAdminPage()},
                            {"title": "📊 Analytics", "page": analytics.AnalyticsDashboardPage()},
                            {"title": "📰 إدارة الأخبار", "page": NewsAdminPage()},
                            {"title": "📊 CRM الطلاب", "page": const StudentsCRMPage()},
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
    );
  }
}