import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/colors.dart';
import '../../../core/firebase_service.dart';

import '../models/center_summary.dart';
import '../models/admin_module.dart';

import '../widgets/center_header.dart';
import '../widgets/center_stats_grid.dart';
import '../widgets/center_modules_grid.dart';
import '../widgets/center_search_bar.dart';

import '../../../admin/pages/attendance_report_page.dart';
import '../../../admin/pages/attendance_sessions.dart';
import '../../../admin/pages/attendance_take_page.dart';
import '../../../admin/pages/analytics_dashboard_page.dart';
import '../../../admin/pages/student_financial_page.dart';
import '../../../admin/pages/students_crm_page.dart';
import '../../../admin/pages/students_management_page.dart';
import '../../../admin/pages/top_students_page.dart';

class CenterManagementPage extends StatefulWidget {
  const CenterManagementPage({super.key});

  @override
  State<CenterManagementPage> createState() => _CenterManagementPageState();
}

class _CenterManagementPageState extends State<CenterManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";
  late Future<_CenterSummary> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = _loadSummary();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshSummary() async {
    setState(() {
      _summaryFuture = _loadSummary();
    });
    await _summaryFuture;
  }

  Future<_CenterSummary> _loadSummary() async {
    final results = await Future.wait<QuerySnapshot<Map<String, dynamic>>>([
      FirebaseService.firestore.collection("courses").get(),
      FirebaseService.firestore.collection("users").get(),
      FirebaseService.firestore.collection("payments").get(),
      FirebaseService.firestore.collection("attendance_sessions").get(),
      FirebaseService.firestore.collection("analytics_events").get(),
    ]);

    final courseSnap = results[0];
    final userSnap = results[1];
    final paymentSnap = results[2];
    final sessionSnap = results[3];
    final analyticsSnap = results[4];

    int approvedPayments = 0;
    double revenue = 0;

    for (final doc in paymentSnap.docs) {
      final data = doc.data();
      final status = (data['status'] ?? '').toString().toLowerCase();

      if (status == 'approved' || status == 'paid' || status == 'success') {
        approvedPayments++;
        revenue += _readMoney(data);
      }
    }

    return _CenterSummary(
      totalCourses: courseSnap.docs.length,
      totalUsers: userSnap.docs.length,
      totalPayments: paymentSnap.docs.length,
      approvedPayments: approvedPayments,
      revenue: revenue,
      totalSessions: sessionSnap.docs.length,
      totalEvents: analyticsSnap.docs.length,
    );
  }

  double _readMoney(Map<String, dynamic> data) {
    final values = [
      data['paid'],
      data['amount'],
      data['price'],
      data['value'],
    ];

    for (final value in values) {
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) return parsed;
      }
    }

    return 0;
  }

  bool _isAdmin(Map<String, dynamic> data) {
    final permissions = data['permissions'];
    final hasCenterPermission =
        permissions is Map && permissions['centerManagement'] == true;

    return data['isAdmin'] == true ||
        data['role'] == 'admin' ||
        hasCenterPermission;
  }

  String _safeString(dynamic value, [String fallback = ""]) {
    final text = value?.toString().trim() ?? "";
    return text.isEmpty ? fallback : text;
  }

  List<_AdminModule> _buildModules(BuildContext context) {
    return [
      _AdminModule(
        title: "👨‍🎓 الطلاب",
        subtitle: "إدارة بيانات الطلاب والملفات",
        icon: Icons.group,
        page: const StudentsManagementPage(),
        section: "الطلاب",
      ),
      _AdminModule(
        title: "📅 تسجيل الحضور",
        subtitle: "تسجيل الحضور بشكل سريع",
        icon: Icons.qr_code_scanner,
        page: const AttendanceTakePage(),
        section: "الحضور",
      ),
      _AdminModule(
        title: "🗓️ جلسات الحضور",
        subtitle: "إنشاء ومتابعة الجلسات",
        icon: Icons.event_note,
        page: const AttendanceSessionsPage(),
        section: "الحضور",
      ),
      _AdminModule(
        title: "📋 تقارير الحضور",
        subtitle: "تقارير ومتابعة الغياب",
        icon: Icons.assignment,
        page: const AttendanceReportPage(),
        section: "الحضور",
      ),
      _AdminModule(
        title: "💰 المصاريف",
        subtitle: "المتابعة المالية للطلاب",
        icon: Icons.payments,
        page: const StudentFinancialPage(),
        section: "المالية",
      ),
      _AdminModule(
        title: "📊 CRM",
        subtitle: "تحليل سلوك الطلاب",
        icon: Icons.analytics,
        page: const StudentsCRMPage(),
        section: "التحليلات",
      ),
      _AdminModule(
        title: "📈 لوحة التحليلات",
        subtitle: "أرقام ورسوم بيانية مباشرة",
        icon: Icons.insights,
        page: const AnalyticsDashboardPage(),
        section: "التحليلات",
      ),
      _AdminModule(
        title: "🏆 أفضل الطلاب",
        subtitle: "ترتيب أعلى الطلاب أداءً",
        icon: Icons.emoji_events,
        page: const TopStudentsPage(),
        section: "التحليلات",
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseService.auth.currentUser?.uid;

    if (currentUserId == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            "غير مسموح بالدخول",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseService.firestore.collection("users").doc(currentUserId).snapshots(),
      builder: (context, adminSnap) {
        if (adminSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!adminSnap.hasData || adminSnap.data?.data() == null) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Text(
                "غير مسموح بالدخول",
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        final adminData = adminSnap.data!.data()!;
        final isAdmin = _isAdmin(adminData);

        if (!isAdmin) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Text(
                "غير مسموح بالدخول",
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        final modules = _buildModules(context);

        final filteredModules = modules.where((module) {
          final title = module.title.toLowerCase();
          final subtitle = module.subtitle.toLowerCase();
          final section = module.section.toLowerCase();
          return _searchText.isEmpty ||
              title.contains(_searchText) ||
              subtitle.contains(_searchText) ||
              section.contains(_searchText);
        }).toList();

        final convertedModules = filteredModules.map((m) => AdminModule(
          id: m.title,
          title: m.title,
          subtitle: m.subtitle,
          icon: m.icon,
          page: m.page,
          section: m.section,
        )).toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text(
              "إدارة السنتر",
              style: TextStyle(color: AppColors.gold),
            ),
            backgroundColor: AppColors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                onPressed: _refreshSummary,
                icon: const Icon(Icons.refresh, color: AppColors.gold),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refreshSummary,
            color: AppColors.gold,
            child: FutureBuilder<_CenterSummary>(
              future: _summaryFuture,
              builder: (context, summarySnap) {
                if (summarySnap.connectionState == ConnectionState.waiting) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: const [
                      SizedBox(height: 60),
                      Center(child: CircularProgressIndicator()),
                    ],
                  );
                }

                final s = summarySnap.data ??
                    const _CenterSummary(
                      totalCourses: 0,
                      totalUsers: 0,
                      totalPayments: 0,
                      approvedPayments: 0,
                      revenue: 0,
                      totalSessions: 0,
                      totalEvents: 0,
                    );

                final summary = CenterSummary(
                  totalCourses: s.totalCourses,
                  totalUsers: s.totalUsers,
                  totalPayments: s.totalPayments,
                  approvedPayments: s.approvedPayments,
                  revenue: s.revenue,
                  totalSessions: s.totalSessions,
                  totalEvents: s.totalEvents,
                  lastUpdated: DateTime.now(),
                );

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [

                    CenterHeader(userData: adminData),

                    const SizedBox(height: 16),

                    CenterSearchBar(
                      onChanged: (v) => setState(() => _searchText = v),
                    ),

                    const SizedBox(height: 16),

                    CenterStatsGrid(
                      summary: summary,
                    ),

                    const SizedBox(height: 20),

                    CenterModulesGrid(
                      modules: convertedModules,
                      isAdmin: isAdmin,
                      isVIP: adminData['isVIP'] == true,
                      isInstructor: adminData['instructorApproved'] == true,
                      search: _searchText,
                    ),

                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _CenterSummary {
  final int totalCourses;
  final int totalUsers;
  final int totalPayments;
  final int approvedPayments;
  final double revenue;
  final int totalSessions;
  final int totalEvents;

  const _CenterSummary({
    required this.totalCourses,
    required this.totalUsers,
    required this.totalPayments,
    required this.approvedPayments,
    required this.revenue,
    required this.totalSessions,
    required this.totalEvents,
  });
}

class _AdminModule {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget page;
  final String section;

  const _AdminModule({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.page,
    required this.section,
  });
}