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
  List<FlSpot> activitySpots = [];

  late Future<List<QuerySnapshot>> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = Future.wait([
      FirebaseService.firestore.collection("courses").get(),
      FirebaseService.firestore.collection("users").get(),
      FirebaseService.firestore.collection("payments").get(),
    ]);
  }

  Widget card(String title, int value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: AppColors.premiumCard,
      child: Row(
        children: [
          Icon(icon, color: AppColors.gold, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 5),
                Text(value.toString(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget chart() {
    if (activitySpots.isEmpty) {
      return const SizedBox();
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(10),
      decoration: AppColors.premiumCard,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(show: true),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: activitySpots,
              isCurved: true,
              color: AppColors.gold,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.gold.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget barChart(Map<String, int> data) {
    if (data.isEmpty) return const SizedBox();

    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      height: 250,
      padding: const EdgeInsets.all(10),
      decoration: AppColors.premiumCard,
      child: BarChart(
        BarChartData(
          barGroups: List.generate(entries.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: entries[i].value.toDouble(),
                  color: AppColors.gold,
                  width: 18,
                  borderRadius: BorderRadius.circular(6),
                )
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget pieChart(int courses, int lessons, int payments) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(10),
      decoration: AppColors.premiumCard,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: courses.toDouble(),
              color: Colors.orange,
              title: "Courses",
            ),
            PieChartSectionData(
              value: lessons.toDouble(),
              color: Colors.blue,
              title: "Lessons",
            ),
            PieChartSectionData(
              value: payments.toDouble(),
              color: Colors.green,
              title: "Payments",
            ),
          ],
        ),
      ),
    );
  }

  Widget topList(
      String title, List<MapEntry<String, int>> items, IconData icon) {
    if (items.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: AppColors.premiumCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.gold),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      color: AppColors.gold, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.key,
                        style: const TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      e.value.toString(),
                      style: const TextStyle(
                          color: AppColors.gold, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseService.auth.currentUser?.uid;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseService.firestore
          .collection("users")
          .doc(currentUserId)
          .get(),
      builder: (context, adminSnap) {
        if (!adminSnap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final adminData = adminSnap.data!.data() as Map<String, dynamic>? ?? {};
        final isAdmin = adminData['isAdmin'] == true;

        if (!isAdmin) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Text("غير مسموح بالدخول",
                  style: TextStyle(color: Colors.white)),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text("📊 Analytics Dashboard",
                style: TextStyle(color: AppColors.gold)),
            backgroundColor: AppColors.black,
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseService.firestore
                .collection("analytics_events")
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(15),
                  children: [
                    card("المستخدمين النشطين الآن", 0, Icons.online_prediction),
                    const SizedBox(height: 15),
                    card("عدد عمليات الدفع", 0, Icons.attach_money),
                    const SizedBox(height: 15),
                    card("مشاهدات الكورسات", 0, Icons.school),
                    const SizedBox(height: 15),
                    card("فتح الدروس", 0, Icons.play_circle),
                    const SizedBox(height: 25),
                    const Center(
                      child: Text(
                        "لا توجد بيانات Analytics حالياً",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                );
              }

              final docs = snapshot.data!.docs;

              int activeUsers = 0;
              int payments = 0;
              int courseViews = 0;
              int lessons = 0;
              int totalRevenue = 0;

              final now = DateTime.now();

              Map<int, int> hourly = {};
              Map<String, int> courseMap = {};
              Map<String, int> userMap = {};

              for (var doc in docs) {
                final data = doc.data() as Map<String, dynamic>;

                final type = (data['type'] ?? "").toString();
                final time = (data['timestamp'] as Timestamp?)?.toDate();
                final userId = (data['userId'] ?? "").toString();
                final courseId = (data['courseId'] ?? "").toString();

                if (time != null) {
                  int hour = time.hour;
                  hourly[hour] = (hourly[hour] ?? 0) + 1;

                  if (now.difference(time).inMinutes < 5) {
                    activeUsers++;
                  }
                }

                if (userId.isNotEmpty) {
                  userMap[userId] = (userMap[userId] ?? 0) + 1;
                }

                if (type == "course_view") {
                  courseViews++;
                  if (courseId.isNotEmpty) {
                    courseMap[courseId] = (courseMap[courseId] ?? 0) + 1;
                  }
                }

                if (type == "lesson_open") lessons++;
                if (type == "purchase") payments++;
              }

              Map<String, String> courseNames = {};
              Map<String, String> userNames = {};

              return FutureBuilder(
                future: _initFuture,
                builder: (context, snap2) {
                  if (!snap2.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final courseSnap = snap2.data![0];
                  final userSnap = snap2.data![1];
                  final paymentSnap = snap2.data![2];

                  for (var p in paymentSnap.docs) {
                    final d = p.data() as Map<String, dynamic>;
                    if ((d['status'] ?? "") == "approved") {
                      totalRevenue += (d['paid'] ?? 0) as int;
                    }
                  }

                  for (var c in courseSnap.docs) {
                    final d = c.data() as Map<String, dynamic>;
                    courseNames[c.id] = (d['title'] ?? "Course").toString();
                  }

                  for (var u in userSnap.docs) {
                    final d = u.data() as Map<String, dynamic>;
                    userNames[u.id] =
                        (d['name'] ?? d['email'] ?? "User").toString();
                  }

                  List<FlSpot> spots = [];

                  hourly.forEach((hour, activityCount) {
                    spots
                        .add(FlSpot(hour.toDouble(), activityCount.toDouble()));
                  });

                  spots.sort((a, b) => a.x.compareTo(b.x));
                  activitySpots = spots;

                  List<MapEntry<String, int>> topCourses = courseMap.entries
                      .toList()
                    ..sort((a, b) => b.value.compareTo(a.value));

                  List<MapEntry<String, int>> topUsers = userMap.entries
                      .toList()
                    ..sort((a, b) => b.value.compareTo(a.value));

                  topCourses = topCourses.take(5).toList();
                  topUsers = topUsers.take(5).toList();

                  topCourses = topCourses.map((e) {
                    return MapEntry(courseNames[e.key] ?? e.key, e.value);
                  }).toList();

                  topUsers = topUsers.map((e) {
                    return MapEntry(userNames[e.key] ?? e.key, e.value);
                  }).toList();

                  return ListView(
                    padding: const EdgeInsets.all(15),
                    children: [
                      card("المستخدمين النشطين الآن", activeUsers,
                          Icons.online_prediction),
                      const SizedBox(height: 15),
                      card("عدد عمليات الدفع", payments, Icons.attach_money),
                      const SizedBox(height: 15),
                      card("إجمالي الأرباح", totalRevenue,
                          Icons.monetization_on),
                      const SizedBox(height: 15),
                      card("مشاهدات الكورسات", courseViews, Icons.school),
                      const SizedBox(height: 15),
                      card("فتح الدروس", lessons, Icons.play_circle),
                      const SizedBox(height: 25),
                      chart(),
                      const SizedBox(height: 20),
                      barChart(courseMap),
                      const SizedBox(height: 20),
                      pieChart(courseViews, lessons, payments),
                      const SizedBox(height: 20),
                      topList("🔥 Top Courses", topCourses, Icons.menu_book),
                      const SizedBox(height: 15),
                      topList("👑 Top Users", topUsers, Icons.people),
                      const SizedBox(height: 30),
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
