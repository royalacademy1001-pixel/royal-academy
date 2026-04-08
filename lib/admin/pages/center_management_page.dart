import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/firebase_service.dart';
import 'attendance_report_page.dart';
import 'attendance_sessions.dart';
import 'attendance_take_page.dart';
import 'analytics_dashboard_page.dart';
import 'student_financial_page.dart';
import 'students_crm_page.dart';
import 'students_management_page.dart';
import 'top_students_page.dart';

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

  Widget _adminHeader(Map<String, dynamic> adminData) {
    final name = _safeString(adminData['name'], "Admin");
    final email = _safeString(adminData['email'], "لا يوجد بريد");
    final role = _isAdmin(adminData) ? "Admin" : "User";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppColors.premiumCard,
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.admin_panel_settings, color: AppColors.gold),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        role,
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "متصل بالنظام مباشرة",
                      style: TextStyle(color: Colors.white54, fontSize: 11),
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

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppColors.premiumCard,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.gold, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchText = value.toLowerCase().trim();
        });
      },
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: "ابحث عن صفحة...",
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.black,
        prefixIcon: const Icon(Icons.search, color: AppColors.gold),
        suffixIcon: _searchText.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchText = "";
                  });
                },
                icon: const Icon(Icons.clear, color: Colors.grey),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _moduleCard(BuildContext context, _AdminModule module) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => module.page),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.black,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gold.withOpacity(0.9), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(module.icon, color: AppColors.gold, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              module.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              module.subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modulesGrid(BuildContext context, List<_AdminModule> modules) {
    if (modules.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: AppColors.premiumCard,
        child: const Column(
          children: [
            Icon(Icons.search_off, color: AppColors.gold, size: 42),
            SizedBox(height: 10),
            Text(
              "لا توجد نتائج",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6),
            Text(
              "جرّب كلمة بحث مختلفة",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1100
            ? 4
            : width >= 800
                ? 3
                : 2;

        return GridView.builder(
          itemCount: modules.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            return _moduleCard(context, modules[index]);
          },
        );
      },
    );
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

                final summary = summarySnap.data ??
                    const _CenterSummary(
                      totalCourses: 0,
                      totalUsers: 0,
                      totalPayments: 0,
                      approvedPayments: 0,
                      revenue: 0,
                      totalSessions: 0,
                      totalEvents: 0,
                    );

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    _adminHeader(adminData),
                    const SizedBox(height: 16),
                    _sectionTitle(
                      "ملخص سريع",
                      "أرقام مباشرة من Firestore",
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final crossAxisCount = width >= 1100
                            ? 4
                            : width >= 800
                                ? 3
                                : 2;

                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.9,
                          children: [
                            _statCard(
                              title: "الطلاب",
                              value: summary.totalUsers.toString(),
                              icon: Icons.people_outline,
                            ),
                            _statCard(
                              title: "الكورسات",
                              value: summary.totalCourses.toString(),
                              icon: Icons.menu_book_outlined,
                            ),
                            _statCard(
                              title: "الجلسات",
                              value: summary.totalSessions.toString(),
                              icon: Icons.event_note_outlined,
                            ),
                            _statCard(
                              title: "المدفوعات",
                              value: summary.totalPayments.toString(),
                              icon: Icons.payments_outlined,
                            ),
                            _statCard(
                              title: "المدفوعات المعتمدة",
                              value: summary.approvedPayments.toString(),
                              icon: Icons.verified_outlined,
                            ),
                            _statCard(
                              title: "إجمالي الأرباح",
                              value: summary.revenue.toStringAsFixed(0),
                              icon: Icons.monetization_on_outlined,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _sectionTitle(
                      "الأدوات الرئيسية",
                      "اختر القسم المطلوب للمتابعة",
                    ),
                    const SizedBox(height: 12),
                    _searchField(),
                    const SizedBox(height: 12),
                    _modulesGrid(context, filteredModules),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: AppColors.premiumCard,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "معلومة سريعة",
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "اللوحة مربوطة مباشرة بـ Firestore، وأي تغيير في صلاحيات المستخدم أو البيانات سيظهر تلقائيًا بعد التحديث.",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "عدد الأحداث التحليلية: ${summary.totalEvents}",
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
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