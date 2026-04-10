import 'package:flutter/material.dart';
import '../../../core/colors.dart';
import '../controller/student_profile_controller.dart';

class ProfileOverview extends StatelessWidget {
  final StudentProfileController controller;

  const ProfileOverview({
    super.key,
    required this.controller,
  });

  Widget _metricCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPaid = controller.studentData?['totalPaid'] ?? 0;
    final remaining = controller.studentData?['remaining'] ?? 0;
    final completion = controller.profileCompletion();

    return Column(
      children: [
        Row(
          children: [
            _metricCard(
              "الكورسات",
              controller.enrolledCourses.length.toString(),
              Colors.blue,
              Icons.menu_book,
            ),
            _metricCard(
              "المدفوع",
              "$totalPaid",
              Colors.green,
              Icons.payments_outlined,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _metricCard(
              "المتبقي",
              "$remaining",
              remaining > 0 ? Colors.red : Colors.green,
              Icons.request_quote_outlined,
            ),
            _metricCard(
              "اكتمال الملف",
              "$completion%",
              completion >= 80
                  ? Colors.green
                  : completion >= 50
                      ? Colors.orange
                      : Colors.red,
              Icons.fact_check_outlined,
            ),
          ],
        ),
      ],
    );
  }
}