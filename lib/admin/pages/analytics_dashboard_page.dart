import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/firebase_service.dart';
import '../../core/colors.dart';

class AnalyticsDashboardPage extends StatefulWidget {
  const AnalyticsDashboardPage({super.key});

  @override
  State<AnalyticsDashboardPage> createState() => _AnalyticsDashboardPageState();
}

class _AnalyticsDashboardPageState extends State<AnalyticsDashboardPage> {
  late Future<List<QuerySnapshot<Map<String, dynamic>>>> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = Future.wait<QuerySnapshot<Map<String, dynamic>>>([
      FirebaseService.firestore.collection("courses").get(),
      FirebaseService.firestore.collection("users").get(),
      FirebaseService.firestore.collection("payments").get(),
    ]);
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String _formatHour(int hour) => '${_twoDigits(hour)}:00';

  String _shortLabel(String text, {int max = 12}) {
    if (text.length <= max) return text;
    return '${text.substring(0, max)}...';
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  String _eventTitle(Map<String, dynamic> data) {
    final type = (data['type'] ?? '').toString();
    final courseId = (data['courseId'] ?? '').toString();
    final lessonId = (data['lessonId'] ?? '').toString();

    switch (type) {
      case 'course_view':
        return courseId.isNotEmpty ? 'فتح كورس: $courseId' : 'مشاهدة كورس';
      case 'lesson_open':
        return lessonId.isNotEmpty ? 'فتح درس: $lessonId' : 'فتح درس';
      case 'purchase':
        return courseId.isNotEmpty ? 'شراء كورس: $courseId' : 'عملية شراء';
      case 'login':
        return 'تسجيل دخول';
      case 'register':
        return 'حساب جديد';
      case 'quiz_start':
        return 'بدء اختبار';
      case 'quiz_finish':
        return 'إنهاء اختبار';
      default:
        return type.isNotEmpty ? type : 'حدث غير معروف';
    }
  }

  IconData _eventIcon(Map<String, dynamic> data) {
    final type = (data['type'] ?? '').toString();
    switch (type) {
      case 'course_view':
        return Icons.school_outlined;
      case 'lesson_open':
        return Icons.play_circle_outline;
      case 'purchase':
        return Icons.attach_money;
      case 'login':
        return Icons.login;
      case 'register':
        return Icons.person_add_alt_1;
      case 'quiz_start':
      case 'quiz_finish':
        return Icons.quiz_outlined;
      default:
        return Icons.bolt_outlined;
    }
  }

  String _eventTimeLabel(Timestamp? ts) {
    if (ts == null) return 'منذ قليل';
    final date = ts.toDate();
    return '${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
  }

  Widget _sectionTitle(String title, {String? subtitle, IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.gold, size: 20),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }

  Widget _metricCard(String title, String value, IconData icon, {String? hint}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: AppColors.premiumCard,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.gold, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (hint != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    hint,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardShell({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(15),
      decoration: AppColors.premiumCard,
      child: child,
    );
  }

  Widget _loadingBox() {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _emptyState(String title, String subtitle, {IconData icon = Icons.insights_outlined}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppColors.premiumCard,
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.gold),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _activityLineChart(List<FlSpot> spots) {
    if (spots.isEmpty) {
      return _emptyState(
        "لا توجد بيانات نشاط كافية",
        "أول ما تبدأ الأحداث تظهر هنا، الرسم الخطي هيعرض النشاط خلال 24 ساعة.",
        icon: Icons.show_chart,
      );
    }

    final maxY = spots.map((e) => e.y).fold<double>(0, (p, e) => e > p ? e : p);
    final effectiveMaxY = (maxY < 5 ? 5.0 : maxY + 2);

    return _cardShell(
      child: SizedBox(
        height: 280,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: 23,
            minY: 0,
            maxY: effectiveMaxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              drawHorizontalLine: true,
              horizontalInterval: effectiveMaxY / 5,
              verticalInterval: 3,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.white.withOpacity(0.08),
                  strokeWidth: 1,
                );
              },
              getDrawingVerticalLine: (value) {
                return FlLine(
                  color: Colors.white.withOpacity(0.06),
                  strokeWidth: 1,
                );
              },
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 34,
                  interval: effectiveMaxY / 5,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) {
                      return const Text(
                        '0',
                        style: TextStyle(color: Colors.white54, fontSize: 10),
                      );
                    }
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: 3,
                  getTitlesWidget: (value, meta) {
                    final hour = value.toInt();
                    if (hour % 3 != 0) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _formatHour(hour),
                        style: const TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppColors.gold,
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 3,
                      color: AppColors.gold,
                      strokeWidth: 2,
                      strokeColor: Colors.black,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.gold.withOpacity(0.18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _barChart(List<MapEntry<String, int>> items, {String? emptyTitle, String? emptySubtitle}) {
    if (items.isEmpty) {
      return _emptyState(
        emptyTitle ?? "لا توجد عناصر لعرضها",
        emptySubtitle ?? "بمجرد وجود مشاهدات أو نشاطات، هتظهر هنا.",
        icon: Icons.bar_chart_outlined,
      );
    }

    final maxY = items.map((e) => e.value).fold<int>(0, (p, e) => e > p ? e : p);
    final effectiveMaxY = (maxY < 5 ? 5.0 : maxY + 2).toDouble();

    return _cardShell(
      child: SizedBox(
        height: 300,
        child: BarChart(
          BarChartData(
            maxY: effectiveMaxY,
            barGroups: List.generate(items.length, (i) {
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: items[i].value.toDouble(),
                    color: AppColors.gold,
                    width: 18,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              );
            }),
            gridData: FlGridData(
              show: true,
              horizontalInterval: effectiveMaxY / 5,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.white.withOpacity(0.08),
                  strokeWidth: 1,
                );
              },
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 34,
                  interval: effectiveMaxY / 5,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 34,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= items.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _shortLabel(items[index].key, max: 9),
                        style: const TextStyle(color: Colors.white54, fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pieChart(int courseViews, int lessons, int payments) {
    final total = courseViews + lessons + payments;
    if (total == 0) {
      return _emptyState(
        "لا توجد بيانات كافية للرسم الدائري",
        "الرسم الدائري بيظهر بعد وجود مشاهدات أو عمليات تفاعل.",
        icon: Icons.pie_chart_outline,
      );
    }

    return _cardShell(
      child: SizedBox(
        height: 300,
        child: PieChart(
          PieChartData(
            centerSpaceRadius: 46,
            sectionsSpace: 2,
            sections: [
              PieChartSectionData(
                value: courseViews.toDouble(),
                color: Colors.orange,
                title: courseViews == 0 ? '' : '$courseViews',
                radius: 85,
                titleStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              PieChartSectionData(
                value: lessons.toDouble(),
                color: Colors.blue,
                title: lessons == 0 ? '' : '$lessons',
                radius: 85,
                titleStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              PieChartSectionData(
                value: payments.toDouble(),
                color: Colors.green,
                title: payments == 0 ? '' : '$payments',
                radius: 85,
                titleStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rankingList(String title, List<MapEntry<String, int>> items, IconData icon) {
    if (items.isEmpty) {
      return _emptyState(
        title,
        "لا توجد بيانات بعد لعرض الترتيب.",
        icon: icon,
      );
    }

    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.gold, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(items.length, (index) {
            final item = items[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.key,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    item.value.toString(),
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _recentEventsList(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (docs.isEmpty) {
      return _emptyState(
        "لا توجد أحداث حديثة",
        "أول ما المستخدمين يبدأوا يتفاعلوا، آخر الأحداث هتظهر هنا.",
        icon: Icons.history,
      );
    }

    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: AppColors.gold, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "آخر الأحداث",
                  style: TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...docs.take(8).map((doc) {
            final data = doc.data();
            final timestamp = data['timestamp'] as Timestamp?;
            final title = _eventTitle(data);
            final icon = _eventIcon(data);
            final userId = (data['userId'] ?? '').toString();
            final courseId = (data['courseId'] ?? '').toString();
            final lessonId = (data['lessonId'] ?? '').toString();

            String subtitle = _eventTimeLabel(timestamp);
            if (userId.isNotEmpty) subtitle += ' • $userId';
            if (courseId.isNotEmpty) subtitle += ' • $courseId';
            if (lessonId.isNotEmpty) subtitle += ' • $lessonId';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: AppColors.gold, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
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

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseService.firestore.collection("users").doc(currentUserId).get(),
      builder: (context, adminSnap) {
        if (adminSnap.connectionState == ConnectionState.waiting) {
          return _loadingBox();
        }

        if (!adminSnap.hasData || !adminSnap.data!.exists) {
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

        final adminData = adminSnap.data!.data() ?? {};
        final isAdmin = adminData['isAdmin'] == true || adminData['role'] == 'admin';

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

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text(
              "📊 Analytics Dashboard",
              style: TextStyle(color: AppColors.gold),
            ),
            backgroundColor: AppColors.black,
            iconTheme: const IconThemeData(color: AppColors.gold),
            elevation: 0,
          ),
          body: FutureBuilder<List<QuerySnapshot<Map<String, dynamic>>>>(
            future: _initFuture,
            builder: (context, initSnap) {
              if (initSnap.connectionState == ConnectionState.waiting) {
                return _loadingBox();
              }

              if (!initSnap.hasData || initSnap.data == null || initSnap.data!.length < 3) {
                return const Center(
                  child: Text(
                    "تعذر تحميل بيانات النظام",
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              final courseSnap = initSnap.data![0];
              final userSnap = initSnap.data![1];
              final paymentSnap = initSnap.data![2];

              final totalCourses = courseSnap.docs.length;
              final totalUsers = userSnap.docs.length;

              int approvedPaymentsCount = 0;
              double totalRevenue = 0;

              for (final p in paymentSnap.docs) {
                final d = p.data();
                final status = (d['status'] ?? '').toString().toLowerCase();
                if (status == 'approved' || status == 'paid' || status == 'success') {
                  approvedPaymentsCount++;
                  totalRevenue += _toDouble(d['paid'] ?? d['amount'] ?? d['price'] ?? 0);
                }
              }

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseService.firestore.collection("analytics_events").snapshots(),
                builder: (context, analyticsSnap) {
                  final docs = analyticsSnap.data?.docs ?? [];

                  final now = DateTime.now();
                  final activeUsersSet = <String>{};
                  int courseViews = 0;
                  int lessons = 0;
                  int purchaseEvents = 0;

                  final Map<int, int> hourly = {for (int i = 0; i < 24; i++) i: 0};
                  final Map<String, int> courseMap = {};
                  final Map<String, int> userMap = {};

                  for (final doc in docs) {
                    final data = doc.data();
                    final type = (data['type'] ?? '').toString();
                    final timestamp = data['timestamp'] as Timestamp?;
                    final userId = (data['userId'] ?? '').toString();
                    final courseId = (data['courseId'] ?? '').toString();

                    if (timestamp != null) {
                      final time = timestamp.toDate();
                      hourly[time.hour] = (hourly[time.hour] ?? 0) + 1;

                      if (now.difference(time).inMinutes <= 5 && userId.isNotEmpty) {
                        activeUsersSet.add(userId);
                      }
                    }

                    if (userId.isNotEmpty) {
                      userMap[userId] = (userMap[userId] ?? 0) + 1;
                    }

                    if (type == 'course_view') {
                      courseViews++;
                      if (courseId.isNotEmpty) {
                        courseMap[courseId] = (courseMap[courseId] ?? 0) + 1;
                      }
                    }

                    if (type == 'lesson_open') {
                      lessons++;
                    }

                    if (type == 'purchase') {
                      purchaseEvents++;
                    }
                  }

                  final courseNames = <String, String>{};
                  final userNames = <String, String>{};

                  for (final c in courseSnap.docs) {
                    final d = c.data();
                    courseNames[c.id] = (d['title'] ?? d['name'] ?? 'Course').toString();
                  }

                  for (final u in userSnap.docs) {
                    final d = u.data();
                    userNames[u.id] = (d['name'] ?? d['email'] ?? 'User').toString();
                  }

                  final List<FlSpot> spots = [];
                  for (int hour = 0; hour < 24; hour++) {
                    spots.add(FlSpot(hour.toDouble(), (hourly[hour] ?? 0).toDouble()));
                  }

                  final topCourses = courseMap.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));

                  final topUsers = userMap.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));

                  final mappedTopCourses = topCourses.take(5).map((e) {
                    return MapEntry(courseNames[e.key] ?? e.key, e.value);
                  }).toList();

                  final mappedTopUsers = topUsers.take(5).map((e) {
                    return MapEntry(userNames[e.key] ?? e.key, e.value);
                  }).toList();

                  final recentEvents = docs.toList()
                    ..sort((a, b) {
                      final ta = (a.data()['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
                      final tb = (b.data()['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
                      return tb.compareTo(ta);
                    });

                  final hasAnalytics = docs.isNotEmpty;

                  return ListView(
                    padding: const EdgeInsets.all(15),
                    children: [
                      _sectionTitle(
                        "ملخص النظام",
                        subtitle: "إجماليات مباشرة من Firestore",
                        icon: Icons.dashboard_outlined,
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.9,
                        children: [
                          _metricCard(
                            "إجمالي الكورسات",
                            totalCourses.toString(),
                            Icons.menu_book_outlined,
                          ),
                          _metricCard(
                            "إجمالي المستخدمين",
                            totalUsers.toString(),
                            Icons.people_outline,
                          ),
                          _metricCard(
                            "المدفوعات المعتمدة",
                            approvedPaymentsCount.toString(),
                            Icons.verified_outlined,
                          ),
                          _metricCard(
                            "إجمالي الأرباح",
                            totalRevenue.toStringAsFixed(0),
                            Icons.monetization_on_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _sectionTitle(
                        "تحليلات مباشرة",
                        subtitle: "مستخرجة من analytics_events",
                        icon: Icons.analytics_outlined,
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.9,
                        children: [
                          _metricCard(
                            "المستخدمون النشطون الآن",
                            activeUsersSet.length.toString(),
                            Icons.bolt_outlined,
                            hint: "آخر 5 دقائق",
                          ),
                          _metricCard(
                            "مشاهدات الكورسات",
                            courseViews.toString(),
                            Icons.visibility_outlined,
                          ),
                          _metricCard(
                            "فتح الدروس",
                            lessons.toString(),
                            Icons.play_circle_outline,
                          ),
                          _metricCard(
                            "عمليات الشراء",
                            purchaseEvents.toString(),
                            Icons.shopping_cart_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _sectionTitle(
                        "النشاط خلال اليوم",
                        subtitle: "كل نقطة تمثل عدد الأحداث في الساعة",
                        icon: Icons.show_chart,
                      ),
                      const SizedBox(height: 12),
                      _activityLineChart(spots),
                      const SizedBox(height: 20),
                      _sectionTitle(
                        "أكثر الكورسات مشاهدة",
                        subtitle: "مرتبة حسب عدد مرات المشاهدة",
                        icon: Icons.bar_chart_outlined,
                      ),
                      const SizedBox(height: 12),
                      _barChart(
                        mappedTopCourses,
                        emptyTitle: "لا توجد مشاهدات كورسات بعد",
                        emptySubtitle: "بمجرد فتح المستخدمين للكورسات ستظهر أكثر العناصر مشاهدة هنا.",
                      ),
                      const SizedBox(height: 20),
                      _sectionTitle(
                        "توزيع الأنشطة",
                        subtitle: "مشاهدات الكورسات / فتح الدروس / الشراء",
                        icon: Icons.pie_chart_outline,
                      ),
                      const SizedBox(height: 12),
                      _pieChart(courseViews, lessons, purchaseEvents),
                      const SizedBox(height: 20),
                      _sectionTitle(
                        "Top Users",
                        subtitle: "أكثر المستخدمين تفاعلاً داخل النظام",
                        icon: Icons.people_alt_outlined,
                      ),
                      const SizedBox(height: 12),
                      _rankingList("Top Users", mappedTopUsers, Icons.people_alt_outlined),
                      const SizedBox(height: 20),
                      _sectionTitle(
                        "Top Courses",
                        subtitle: "أكثر الكورسات استحواذًا على التفاعل",
                        icon: Icons.menu_book_outlined,
                      ),
                      const SizedBox(height: 12),
                      _rankingList("Top Courses", mappedTopCourses, Icons.menu_book_outlined),
                      const SizedBox(height: 20),
                      _sectionTitle(
                        "آخر الأحداث",
                        subtitle: "تحديث مباشر من Firestore",
                        icon: Icons.history_outlined,
                      ),
                      const SizedBox(height: 12),
                      _recentEventsList(recentEvents),
                      const SizedBox(height: 30),
                      if (!hasAnalytics)
                        _emptyState(
                          "لا توجد بيانات Analytics حالياً",
                          "الصفحة شغالة ومتصلة، ولكن لسه ما فيش events متسجلة داخل analytics_events.",
                          icon: Icons.info_outline,
                        ),
                      const SizedBox(height: 10),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}