// 🔥 STUDENT RESULTS SYSTEM

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🔥 CORE
import '../../core/firebase_service.dart';
import '../../core/colors.dart';

// 🔥 WIDGET
import '../../widgets/loading_widget.dart';

class StudentResultsPage extends StatefulWidget {
  const StudentResultsPage({super.key});

  @override
  State<StudentResultsPage> createState() =>
      _StudentResultsPageState();
}

class _StudentResultsPageState
    extends State<StudentResultsPage> {

  String search = "";
  String selectedUserId = "";
  List<QueryDocumentSnapshot> users = [];

  void show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future loadUsers() async {
    try {
      final snap = await FirebaseService.firestore
          .collection("users")
          .get();
      users = snap.docs;
      if (mounted) {
        setState(() {});
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future addResult(String userId) async {

    final degreeController = TextEditingController();
    final titleController = TextEditingController();
    String localSelectedUserId = userId;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.black,
            title: const Text("إضافة نتيجة",
                style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: localSelectedUserId.isEmpty ? null : localSelectedUserId,
                  dropdownColor: AppColors.black,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: "اختر الطالب"),
                  items: users.map((u) {
                    final data = u.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: u.id,
                      child: Text(
                        data['name'] ?? "Student",
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setDialogState(() {
                      localSelectedUserId = val ?? "";
                    });
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration:
                      const InputDecoration(hintText: "اسم الاختبار"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: degreeController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration:
                      const InputDecoration(hintText: "الدرجة"),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("إلغاء")),
              ElevatedButton(
                onPressed: () async {

                  int degree =
                      int.tryParse(degreeController.text) ?? 0;

                  String title = titleController.text.trim();

                  if (degree <= 0 || title.isEmpty) return;
                  if (localSelectedUserId.isEmpty) return;

                  await FirebaseService.firestore
                      .collection("results")
                      .add({
                    "userId": localSelectedUserId,
                    "title": title,
                    "degree": degree,
                    "timestamp": FieldValue.serverTimestamp(),
                  });

                  Navigator.pop(context);
                  show("تم إضافة النتيجة ✅");
                },
                child: const Text("حفظ"),
              )
            ],
          );
        },
      ),
    );
  }

  Future<String> getUserName(String userId) async {
    try {
      var doc = await FirebaseService.firestore
          .collection("users")
          .doc(userId)
          .get();

      return doc.data()?['name'] ?? "Student";
    } catch (_) {
      return "Student";
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("📊 نتائج الطلاب",
            style: TextStyle(color: AppColors.gold)),
        backgroundColor: AppColors.black,
      ),

      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "ابحث بالاسم...",
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.gold),
                filled: true,
                fillColor:
                    Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(15),
                    borderSide: BorderSide.none),
              ),
              onChanged: (val) =>
                  setState(() => search = val.toLowerCase()),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseService.firestore
                  .collection("results")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingWidget();
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      "❌ خطأ في تحميل البيانات",
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "📭 لا توجد نتائج حالياً",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                var docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {

                    var d = docs[index];
                    var data =
                        d.data() as Map<String, dynamic>;

                    String userId = data['userId'];
                    int degree = data['degree'] ?? 0;
                    String title = data['title'] ?? "";

                    return FutureBuilder<String>(
                      future: getUserName(userId),
                      builder: (context, snap) {

                        if (snap.connectionState == ConnectionState.waiting) {
                          return const SizedBox();
                        }

                        String name =
                            snap.data ?? "Student";

                        if (search.isNotEmpty &&
                            !name.toLowerCase().contains(search)) {
                          return const SizedBox();
                        }

                        return Container(
                          margin:
                              const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius:
                                BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [

                              const Icon(Icons.school,
                                  color: AppColors.gold),

                              const SizedBox(width: 10),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [

                                    Text(name,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight:
                                                FontWeight.bold)),

                                    Text(title,
                                        style: const TextStyle(
                                            color: Colors.grey)),

                                    Text("📊 $degree درجة",
                                        style: const TextStyle(
                                            color: Colors.green)),
                                  ],
                                ),
                              ),

                              IconButton(
                                icon: const Icon(Icons.add,
                                    color: Colors.green),
                                onPressed: () =>
                                    addResult(userId),
                              )
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}