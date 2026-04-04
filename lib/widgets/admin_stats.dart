import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui'; 

import '../core/colors.dart';
import 'admin_stats_helpers.dart';
import 'admin_stats_widgets.dart';

import '../admin/pages/users_page.dart';
import '../admin/pages/payments_admin_page.dart';
import '../admin/pages/courses_admin_page.dart';

class AdminStats extends StatelessWidget {
  final Map<String, dynamic>? data;
  const AdminStats({super.key, required this.data});

  String format(int value) => NumberFormat('#,###').format(value);

  void go(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    if (data == null) return _loadingSkeleton();

    final safeData = data!;
    
    final int users = AdminStatsHelper.safe(safeData, 'users');
    final int subscribed = AdminStatsHelper.safe(safeData, 'subscribed');
    final int courses = AdminStatsHelper.safe(safeData, 'courses');
    final int revenue = AdminStatsHelper.safe(safeData, 'revenue');
    final int pending = AdminStatsHelper.safe(safeData, 'pending');
    final int payments = AdminStatsHelper.safe(safeData, 'payments');
    
    final int activeUsers = AdminStatsHelper.safe(safeData, 'activeUsers');
    final int conversion = AdminStatsHelper.safe(safeData, 'conversion');

    return Column(
      children: [
        _buildStatGrid(context, users, subscribed, courses, revenue, pending, payments),

        const SizedBox(height: 20),

        _buildLivePulse(activeUsers),

        const SizedBox(height: 10),

        _buildAnalyticalSection(safeData, revenue, conversion),

        const SizedBox(height: 20),

        _buildTopLists(safeData),
        
        const SizedBox(height: 100), 
      ],
    );
  }

  Widget _buildStatGrid(BuildContext context, int u, int s, int c, int r, int p, int pay) {
    return LayoutBuilder(builder: (context, constraints) {
      int crossAxis = constraints.maxWidth > 600 ? 3 : 2;
      return GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxis,
          mainAxisExtent: 130,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        children: [
          _premiumStatCard("المستخدمين", u, Icons.group_outlined, Colors.blue, () => go(context, const UsersPage())),
          _premiumStatCard("المشتركين", s, Icons.stars_rounded, Colors.green, () => go(context, const UsersPage())),
          _premiumStatCard("الكورسات", c, Icons.auto_stories_rounded, Colors.orange, () => go(context, const CoursesAdminPage())),
          _premiumStatCard("الأرباح", r, Icons.account_balance_wallet_rounded, AppColors.gold, () => go(context, const PaymentsAdminPage(initialStatus: "approved")), isGold: true),
          _premiumStatCard("معلق", p, Icons.hourglass_empty_rounded, Colors.redAccent, () => go(context, const PaymentsAdminPage(initialStatus: "pending"))),
          _premiumStatCard("الطلبات", pay, Icons.receipt_long_rounded, Colors.grey, () => go(context, const PaymentsAdminPage(initialStatus: "all"))),
        ],
      );
    });
  }

  Widget _premiumStatCard(String title, int value, IconData icon, Color color, VoidCallback tap, {bool isGold = false}) {
    return GestureDetector(
      onTap: tap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isGold ? AppColors.gold.withOpacity(0.05) : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: isGold ? AppColors.gold.withOpacity(0.3) : Colors.white10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const Spacer(),
            Text(format(value), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildLivePulse(int active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.circle, color: Colors.green, size: 12),
            ],
          ),
          const SizedBox(width: 12),
          const Text("المتواجدون الآن:", style: TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          Text(format(active), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(width: 5),
          const Text("طالب", style: TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildAnalyticalSection(Map<String, dynamic> safeData, int revenue, int conversion) {
    final monthly = AdminStatsHelper.safe(safeData, 'monthly');
    final yearly = AdminStatsHelper.safe(safeData, 'yearly');
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppColors.premiumCard, 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_outlined, color: AppColors.gold, size: 20),
              SizedBox(width: 10),
              Text("التحليل المالي والتحويل", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          _customProgressBar("العائد الشهري", monthly, revenue, Colors.blue),
          const SizedBox(height: 15),
          _customProgressBar("العائد السنوي", yearly, revenue, Colors.orange),
          const SizedBox(height: 15),
          _customProgressBar("نسبة التحويل VIP", conversion, 100, AppColors.gold),
        ],
      ),
    );
  }

  Widget _customProgressBar(String label, int val, int total, Color color) {
    double percent = total == 0 ? 0 : (val / total).clamp(0, 1);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text(label.contains("نسبة") ? "$val%" : format(val), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 6,
            color: color,
            backgroundColor: color.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildTopLists(Map<String, dynamic> safeData) {
    final topCourses = (safeData['topCoursesData'] as List?) ?? [];
    final topUsers = (safeData['topUsersData'] as List?) ?? [];
    
    return Row(
      children: [
        Expanded(child: _topBox("أعلى الكورسات", topCourses, Icons.workspace_premium)),
        const SizedBox(width: 12),
        Expanded(child: _topBox("الطلاب النشطين", topUsers, Icons.trending_up)),
      ],
    );
  }

  Widget _topBox(String title, List items, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: const Color(0xFF0F0F0F), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: AppColors.gold, size: 16), const SizedBox(width: 8), Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold))]),
          const Divider(color: Colors.white10, height: 20),
          ...items.take(3).map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              (e['name'] ?? e['title'] ?? "—").toString(), 
              maxLines: 1, 
              overflow: TextOverflow.ellipsis, 
              style: const TextStyle(color: Colors.white, fontSize: 10)
            ),
          )),
        ],
      ),
    );
  }

  Widget _loadingSkeleton() {
    return const Center(child: CircularProgressIndicator(color: AppColors.gold));
  }
}