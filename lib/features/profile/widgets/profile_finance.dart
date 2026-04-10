import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase_service.dart';

class ProfileFinance extends StatelessWidget {
  final String uid;

  const ProfileFinance({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.firestore
          .collection("financial")
          .where("userId", isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final docs = snapshot.data!.docs;

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            return ListTile(
              title: Text(
                "مدفوع: ${data['amount'] ?? 0}",
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                data['note'] ?? "",
                style: const TextStyle(color: Colors.grey),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}