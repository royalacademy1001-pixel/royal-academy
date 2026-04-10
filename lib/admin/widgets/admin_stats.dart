import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'admin_stats_grid.dart';
import 'admin_live_section.dart';
import '../../core/colors.dart';
import 'admin_stats_helpers.dart';

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
        /// 🔥 GRID الجديد
        AdminStatsGrid(
          users: users,
          subscribed: subscribed,
          courses: courses,
          revenue: revenue,
          pending: pending,
          payments: payments,
          onNavigate: go,
          format: format,
        ),

        const SizedBox(height: 18),

        /// 🔥 LIVE + ANALYTICS الجديد
        AdminLiveSection(
          activeUsers: activeUsers,
          safeData: safeData,
          revenue: revenue,
          conversion: conversion,
          format: format,
        ),

        const SizedBox(height: 18),

        /// 🔥 TOP LISTS (مخليها هنا لأنها خاصة بالصفحة)
        _buildTopLists(safeData),

        const SizedBox(height: 96),
      ],
    );
  }

  // ================= TOP LIST =================

  Widget _buildTopLists(Map<String, dynamic> safeData) {
    final topCourses = _safeList(safeData['topCoursesData']);
    final topUsers = _safeList(safeData['topUsersData']);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;

        if (isNarrow) {
          return Column(
            children: [
              _topBox("أعلى الكورسات", topCourses, Icons.workspace_premium),
              const SizedBox(height: 12),
              _topBox("الطلاب النشطين", topUsers, Icons.trending_up),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _topBox("أعلى الكورسات", topCourses, Icons.workspace_premium),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _topBox("الطلاب النشطين", topUsers, Icons.trending_up),
            ),
          ],
        );
      },
    );
  }

  Widget _topBox(String title, List<dynamic> items, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.gold, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 20),
          if (items.isEmpty)
            const Text(
              "لا توجد بيانات",
              style: TextStyle(color: Colors.grey, fontSize: 11),
            )
          else
            ...items.take(3).map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _topItemTile(e),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _topItemTile(dynamic item) {
    final map = item is Map<String, dynamic> ? item : {};
    final name = (map['name'] ?? map['title'] ?? "—").toString();

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.gold,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ),
      ],
    );
  }

  List<dynamic> _safeList(dynamic value) {
    if (value is List) return value;
    return const [];
  }

  Widget _loadingSkeleton() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.gold),
    );
  }
}