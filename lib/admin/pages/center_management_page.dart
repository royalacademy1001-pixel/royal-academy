import 'package:flutter/material.dart';

import '../../core/colors.dart';
import 'students_management_page.dart';
import 'attendance_report_page.dart';
import 'students_crm_page.dart';
import 'payments_admin_page.dart';
import 'top_students_page.dart';
import 'package:royal_academy/admin/pages/attendance_take_page.dart';

class CenterManagementPage extends StatelessWidget {
  const CenterManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("إدارة السنتر"),
        backgroundColor: AppColors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [

            _card(
              context,
              "👨‍🎓 الطلاب",
              Icons.group,
              const StudentsManagementPage(),
            ),

            _card(
              context,
              "📅 الحضور",
              Icons.fact_check,
              const AttendanceTakePage(),
            ),

            _card(
              context,
              "💰 المصاريف",
              Icons.payments,
              const PaymentsAdminPage(),
            ),

            _card(
              context,
              "📊 CRM",
              Icons.analytics,
              const StudentsCRMPage(),
            ),

            _card(
              context,
              "🏆 أفضل الطلاب",
              Icons.emoji_events,
              const TopStudentsPage(),
            ),

          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, String title, IconData icon, Widget page) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.black,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gold, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Icon(icon, color: AppColors.gold, size: 40),

            const SizedBox(height: 10),

            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}