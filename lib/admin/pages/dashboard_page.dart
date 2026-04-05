import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/colors.dart';
import '../../core/firebase_service.dart';
import '../../core/constants.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  Future<Map<String, int>> getStats() async {
    final usersSnap = await FirebaseService.firestore
        .collection(AppConstants.users)
        .get();

    final sessionsSnap = await FirebaseService.firestore
        .collection("attendance_sessions")
        .get();

    int students = 0;
    int sessions = sessionsSnap.docs.length;
    int present = 0;
    int absent = 0;

    for (var doc in usersSnap.docs) {
      final data = doc.data();
      if (data['isAdmin'] != true &&
          data['instructorApproved'] != true) {
        students++;
      }
    }

    for (var doc in sessionsSnap.docs) {
      final data = doc.data();
      present += (data['presentCount'] ?? 0) as int;
      absent += (data['absentCount'] ?? 0) as int;
    }

    return {
      "students": students,
      "sessions": sessions,
      "present": present,
      "absent": absent,
    };
  }

  Future<List<Map<String, dynamic>>> getChartData() async {
    final snap = await FirebaseService.firestore
        .collection("attendance_sessions")
        .orderBy("sessionDateTime")
        .limit(7)
        .get();

    return snap.docs.map((doc) {
      final data = doc.data();
      return {
        "date": (data['sessionDate'] ?? "").toString(),
        "present": (data['presentCount'] ?? 0),
      };
    }).toList();
  }

  double percent(int present, int absent) {
    final total = present + absent;
    if (total == 0) return 0;
    return (present / total) * 100;
  }

  Widget _buildChart(List<Map<String, dynamic>> data) {
    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= data.length) return const SizedBox();
                  final date = data[index]['date'];
                  return Text(
                    date.split("-").last,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(data.length, (index) {
            final item = data[index];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: (item['present'] as int).toDouble(),
                  color: Colors.green,
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: AppColors.black,
      ),

      body: FutureBuilder<Map<String, int>>(
        future: getStats(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          final p = percent(
            data['present']!,
            data['absent']!,
          );

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [

                Row(
                  children: [
                    _card("👨‍🎓 الطلاب", data['students']!),
                    _card("📅 الحصص", data['sessions']!),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    _card("✅ حضور", data['present']!),
                    _card("❌ غياب", data['absent']!),
                  ],
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.gold),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "نسبة الحضور",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "${p.toStringAsFixed(1)}%",
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                FutureBuilder<List<Map<String, dynamic>>>(
                  future: getChartData(),
                  builder: (context, snapshot) {

                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final chartData = snapshot.data!;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.gold),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "📊 الحضور خلال الأسبوع",
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          _buildChart(chartData),
                        ],
                      ),
                    );
                  },
                ),

              ],
            ),
          );
        },
      ),
    );
  }

  Widget _card(String title, int value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gold),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              value.toString(),
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}