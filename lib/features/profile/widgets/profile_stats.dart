import 'package:flutter/material.dart';

class ProfileStats extends StatelessWidget {
  final int coursesCount;
  final int totalPaid;
  final int remaining;
  final int completion;

  const ProfileStats({
    super.key,
    required this.coursesCount,
    required this.totalPaid,
    required this.remaining,
    required this.completion,
  });

  Widget card(String title, String value, Color color, IconData icon, double scale) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.all(3 * scale),
        padding: EdgeInsets.all(10 * scale),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12 * scale),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18 * scale),
            SizedBox(height: 4 * scale),
            Text(value,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13 * scale)),
            Text(title,
                style: TextStyle(color: Colors.grey, fontSize: 10 * scale)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth < 380 ? 0.8 : screenWidth < 420 ? 0.9 : 1.0;

    return Column(
      children: [
        Row(
          children: [
            card("الكورسات", "$coursesCount", Colors.blue, Icons.menu_book, scale),
            card("المدفوع", "$totalPaid", Colors.green, Icons.payments, scale),
          ],
        ),
        Row(
          children: [
            card("المتبقي", "$remaining",
                remaining > 0 ? Colors.red : Colors.green, Icons.money, scale),
            card("اكتمال", "$completion%", Colors.orange, Icons.check, scale),
          ],
        ),
      ],
    );
  }
}