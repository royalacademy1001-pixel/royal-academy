import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase_service.dart';
import '../../core/colors.dart';

class StudentResultsFullPage extends StatefulWidget {
  final String userId;

  const StudentResultsFullPage({super.key, required this.userId});

  @override
  State<StudentResultsFullPage> createState() => _StudentResultsFullPageState();
}

class _StudentResultsFullPageState extends State<StudentResultsFullPage> {

  bool isAdmin = false;
  bool loadingUser = true;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future loadUser() async {
    try {
      final data = await FirebaseService.getUserData();
      isAdmin = data['isAdmin'] == true;
    } catch (_) {}
    if (mounted) {
      setState(() => loadingUser = false);
    }
  }

  void show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.gold,
      ),
    );
  }

  Future<void> deleteResult(String id) async {
    await FirebaseService.firestore.collection("results").doc(id).delete();
    show("تم حذف النتيجة ❌");
  }

  Future<void> editResult(String id, int oldScore) async {

    final controller = TextEditingController(text: oldScore.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.black,
        title: const Text("تعديل النتيجة", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () async {

              int newScore = int.tryParse(controller.text) ?? 0;
              if (newScore <= 0) return;

              await FirebaseService.firestore
                  .collection("results")
                  .doc(id)
                  .update({
                "score": newScore,
              });

              if (!mounted) return;
              Navigator.pop(context);
              show("تم التعديل ✅");
            },
            child: const Text("حفظ"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    if (loadingUser) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!isAdmin) {
      return const Scaffold(
        body: Center(
          child: Text(
            "❌ غير مسموح",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("📊 نتائج الطالب", style: TextStyle(color: AppColors.gold)),
        backgroundColor: AppColors.black,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService.firestore
            .collection("results")
            .where("userId", isEqualTo: widget.userId)
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var data = snapshot.data!.docs;

          if (data.isEmpty) {
            return const Center(
              child: Text("لا توجد نتائج", style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, i) {

              var d = data[i];
              var map = d.data() as Map<String, dynamic>;

              return Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(12),
                decoration: AppColors.premiumCard,
                child: Row(
                  children: [

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Text(
                            "الكورس: ${map['courseId'] ?? ""}",
                            style: const TextStyle(color: Colors.white),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            "الدرجة: ${map['score'] ?? 0}",
                            style: const TextStyle(color: AppColors.gold),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => editResult(d.id, map['score'] ?? 0),
                    ),

                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => deleteResult(d.id),
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