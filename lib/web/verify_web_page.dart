import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/colors.dart';
import '../core/firebase_service.dart';

class VerifyWebPage extends StatelessWidget {
  final String certId;

  const VerifyWebPage({super.key, required this.certId});

  @override
  Widget build(BuildContext context) {
    final id = certId.trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: id.isEmpty
            ? _invalid("❌ Invalid Certificate")
            : FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                future: FirebaseService.firestore
                    .collection("certificates")
                    .where("certId", isEqualTo: id)
                    .limit(1)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator(color: Colors.amber);
                  }

                  if (snapshot.hasError) {
                    return _invalid("❌ Connection Error");
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _invalid("❌ Certificate Not Found");
                  }

                  final data = snapshot.data!.docs.first.data();

                  return _valid(
                    data['name'],
                    data['course'],
                    data['date'],
                    data['certId'],
                  );
                },
              ),
      ),
    );
  }

  Widget _valid(String name, String course, String date, String id) {
    return Container(
      padding: const EdgeInsets.all(30),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified, color: Colors.green, size: 90),
          const SizedBox(height: 15),
          const Text(
            "Certificate Verified ✅",
            style: TextStyle(
              color: Colors.green,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Text("👤 $name", style: const TextStyle(color: Colors.white)),
          Text("📚 $course", style: const TextStyle(color: Colors.white)),
          Text("📅 $date", style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),
          Text("ID: $id", style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _invalid(String msg) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.cancel, color: Colors.red, size: 90),
        const SizedBox(height: 15),
        Text(msg,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 20,
            )),
      ],
    );
  }
}
