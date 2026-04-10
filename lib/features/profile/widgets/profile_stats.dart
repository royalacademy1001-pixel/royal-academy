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

  Widget card(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            Text(title,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            card("الكورسات", "$coursesCount", Colors.blue, Icons.menu_book),
            card("المدفوع", "$totalPaid", Colors.green, Icons.payments),
          ],
        ),
        Row(
          children: [
            card("المتبقي", "$remaining",
                remaining > 0 ? Colors.red : Colors.green, Icons.money),
            card("اكتمال", "$completion%", Colors.orange, Icons.check),
          ],
        ),
      ],
    );
  }
}