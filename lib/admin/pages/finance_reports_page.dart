import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/colors.dart';
import '../../core/firebase_service.dart';

class FinanceReportsPage extends StatelessWidget {
  const FinanceReportsPage({super.key});

  Future<Map<String, dynamic>> getFinanceData() async {
    final snap = await FirebaseService.firestore
        .collection("payments")
        .get();

    double total = 0;
    double today = 0;
    double month = 0;

    final now = DateTime.now();

    final Map<String, double> dailyMap = {};

    for (var doc in snap.docs) {
      final data = doc.data();
      final amount = (data['amount'] ?? 0).toDouble();
      final date = (data['date'] as Timestamp).toDate();

      total += amount;

      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        today += amount;
      }

      if (date.year == now.year &&
          date.month == now.month) {
        month += amount;
      }

      final key = "${date.day}";
      dailyMap[key] = (dailyMap[key] ?? 0) + amount;
    }

    return {
      "total": total,
      "today": today,
      "month": month,
      "chart": dailyMap,
    };
  }

  Widget buildChart(Map<String, double> data) {
    final keys = data.keys.toList();

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i >= keys.length) return const SizedBox();
                  return Text(
                    keys[i],
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(keys.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: data[keys[i]]!,
                  color: Colors.green,
                  width: 14,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget card(String title, double value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gold),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 10),
            Text(
              value.toStringAsFixed(0),
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("📊 التقارير المالية"),
        backgroundColor: AppColors.black,
      ),

      body: FutureBuilder<Map<String, dynamic>>(
        future: getFinanceData(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [

                Row(
                  children: [
                    card("💰 الإجمالي", data['total']),
                    card("📅 اليوم", data['today']),
                  ],
                ),

                Row(
                  children: [
                    card("📆 الشهر", data['month']),
                  ],
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.gold),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "📈 حركة الفلوس",
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      buildChart(
                          Map<String, double>.from(data['chart'])),
                    ],
                  ),
                ),

              ],
            ),
          );
        },
      ),
    );
  }
}