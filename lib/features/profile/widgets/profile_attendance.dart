import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase_service.dart';

class ProfileAttendance extends StatelessWidget {
  final String uid;

  const ProfileAttendance({super.key, required this.uid});

  int _safeBoolCount(List<QueryDocumentSnapshot> docs) {
    int count = 0;
    for (var e in docs) {
      final data = e.data() as Map<String, dynamic>? ?? {};
      if (data['present'] == true) {
        count++;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.firestore
          .collectionGroup("records")
          .where("userId", isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text(
              "خطأ في تحميل الحضور",
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              "لا يوجد حضور",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final total = docs.length;
        final present = _safeBoolCount(docs);
        final percent = total == 0 ? 0 : (present / total * 100);

        return Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: Text(
                "📊 نسبة الحضور: ${percent.toStringAsFixed(1)}%",
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: percent / 100,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(
                  percent >= 75
                      ? Colors.green
                      : percent >= 50
                          ? Colors.orange
                          : Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}