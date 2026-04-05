import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/colors.dart';
import '../../core/firebase_service.dart';

class TopStudentsPage extends StatelessWidget {
  const TopStudentsPage({super.key});

  Future<List<Map<String, dynamic>>> getTopStudents() async {
    final sessionsSnap = await FirebaseService.firestore
        .collection("attendance_sessions")
        .get();

    final Map<String, Map<String, dynamic>> students = {};

    for (var session in sessionsSnap.docs) {
      final records = await session.reference
          .collection("records")
          .get();

      for (var rec in records.docs) {
        final data = rec.data();

        final id = rec.id;
        final name = (data['name'] ?? "").toString();

        if (!students.containsKey(id)) {
          students[id] = {
            "name": name,
            "present": 0,
            "total": 0,
          };
        }

        students[id]!['total']++;

        if (data['present'] == true) {
          students[id]!['present']++;
        }
      }
    }

    final list = students.values.toList();

    for (var s in list) {
      final total = s['total'] as int;
      final present = s['present'] as int;

      s['percent'] = total == 0 ? 0 : (present / total) * 100;
    }

    list.sort((a, b) =>
        (b['percent'] as double).compareTo(a['percent'] as double));

    return list.take(20).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("أفضل الطلاب"),
        backgroundColor: AppColors.black,
      ),

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getTopStudents(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator());
          }

          final students = snapshot.data!;

          if (students.isEmpty) {
            return const Center(
              child: Text(
                "لا يوجد بيانات",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            itemBuilder: (context, index) {

              final s = students[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.gold),
                ),
                child: Row(
                  children: [

                    Text(
                      "#${index + 1}",
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Text(
                            s['name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            "حضور: ${s['present']} / ${s['total']}",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Column(
                      children: [
                        Text(
                          "${(s['percent'] as double).toStringAsFixed(1)}%",
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Icon(Icons.emoji_events,
                            color: Colors.amber),
                      ],
                    ),

                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}