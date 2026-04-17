import 'package:flutter/material.dart';
import '../../../core/colors.dart';
import '../controller/student_profile_controller.dart';

class ProfileOverview extends StatelessWidget {
  final StudentProfileController controller;

  const ProfileOverview({
    super.key,
    required this.controller,
  });

  Widget _metricCard(String title, String value, Color color, IconData icon, double scale) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4 * scale),
        padding: EdgeInsets.all(10 * scale),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14 * scale),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              width: 34 * scale,
              height: 34 * scale,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10 * scale),
              ),
              child: Icon(icon, color: color, size: 18 * scale),
            ),
            SizedBox(width: 8 * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.grey, fontSize: 10 * scale),
                  ),
                  SizedBox(height: 3 * scale),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14 * scale,
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

    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth < 380 ? 0.85 : screenWidth < 420 ? 0.92 : 1.0;

    return Column(
      children: [
        Row(
          children: [
            _metricCard(
              "الكورسات",
              controller.enrolledCourses.length.toString(),
              Colors.blue,
              Icons.menu_book,
              scale,
            ),
            _metricCard(
              "المدفوع",
              "$totalPaid",
              Colors.green,
              Icons.payments_outlined,
              scale,
            ),
          ],
        ),
        SizedBox(height: 6 * scale),
        Row(
          children: [
            _metricCard(
              "المتبقي",
              "$remaining",
              remaining > 0 ? Colors.red : Colors.green,
              Icons.request_quote_outlined,
              scale,
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
              scale,
            ),
          ],
        ),
      ],
    );
  }
}