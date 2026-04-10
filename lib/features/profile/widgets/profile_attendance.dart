import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase_service.dart';

class ProfileAttendance extends StatelessWidget {
  final String uid;

  const ProfileAttendance({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.firestore
          .collectionGroup("records")
          .where("userId", isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final docs = snapshot.data!.docs;

        final total = docs.length;
        final present = docs.where((e) {
          final data = e.data() as Map<String, dynamic>;
          return data['present'] == true;
        }).length;

        final percent = total == 0 ? 0 : (present / total * 100).round();

        return Column(
          children: [
            Text(
              "الحضور: $percent%",
              style: const TextStyle(color: Colors.white),
            ),
            LinearProgressIndicator(value: percent / 100),
          ],
        );
      },
    );
  }
}