import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/colors.dart';
import '../../shared/models/vip_student_model.dart';
import '../../shared/services/link_service.dart';
import '../../core/firebase_service.dart';

class LinkVipPage extends StatelessWidget {
  const LinkVipPage({super.key});

  @override
  Widget build(BuildContext context) {
    final VipStudentModel student =
        ModalRoute.of(context)!.settings.arguments as VipStudentModel;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("ربط بحساب"),
        backgroundColor: AppColors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService.firestore.collection("users").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final u = users[index];
              final data = u.data() as Map<String, dynamic>;

              return ListTile(
                title: Text(
                  data['name'] ?? "User",
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  data['email'] ?? "",
                  style: const TextStyle(color: Colors.grey),
                ),
                onTap: () async {
                  await LinkService.linkVipToUser(
                    vipId: student.id,
                    userId: u.id,
                  );

                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
              );
            },
          );
        },
      ),
    );
  }
}