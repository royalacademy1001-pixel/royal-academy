// 🔥 IMPORTS
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase_service.dart';
import '../../core/colors.dart';

// 🔥 PAGE
class StudentsListPage extends StatefulWidget {
  const StudentsListPage({super.key});

  @override
  State<StudentsListPage> createState() => _StudentsListPageState();
}

class _StudentsListPageState extends State<StudentsListPage> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  bool loading = false;

  Future<void> addStudent() async {
    if (nameController.text.trim().isEmpty) return;

    final navigator = Navigator.of(context);

    setState(() => loading = true);

    try {
      await FirebaseService.firestore.collection("students").add({
        "name": nameController.text.trim(),
        "phone": phoneController.text.trim(),
        "notes": "",
        "linkedUserId": "",
        "createdAt": Timestamp.now(),
      });

      nameController.clear();
      phoneController.clear();

      navigator.pop();
    } catch (e) {
      debugPrint("Add Student Error: $e");
    }

    if (!mounted) return;

    setState(() => loading = false);
  }

  void showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.black,
        title:
            const Text("➕ إضافة طالب", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: "الاسم"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: "رقم الهاتف"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: loading ? null : addStudent,
            child: const Text("حفظ"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("📋 طلاب السنتر",
            style: TextStyle(color: AppColors.gold)),
        backgroundColor: AppColors.black,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        onPressed: showAddDialog,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService.firestore
            .collection("students")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child:
                  Text("لا يوجد طلاب", style: TextStyle(color: Colors.white)),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              return ListTile(
                title: Text(
                  data['name'] ?? "",
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  data['phone'] ?? "",
                  style: const TextStyle(color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
