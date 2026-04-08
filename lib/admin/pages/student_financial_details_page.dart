// 🔥 STUDENT FINANCIAL DETAILS PAGE (PRO CRM)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase_service.dart';
import '../../core/colors.dart';

import '../../widgets/loading_widget.dart';

class StudentFinancialDetailsPage extends StatefulWidget {
  final String userId;

  const StudentFinancialDetailsPage({super.key, required this.userId});

  @override
  State<StudentFinancialDetailsPage> createState() =>
      _StudentFinancialDetailsPageState();
}

class _StudentFinancialDetailsPageState
    extends State<StudentFinancialDetailsPage> {
  Map<String, dynamic> userData = {};
  bool loadingUser = true;

  Map<String, dynamic> safeMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return {};
  }

  int safeInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  String safeString(dynamic v) {
    if (v == null) return "";
    return v.toString();
  }

  Future loadUser() async {
    try {
      final doc = await FirebaseService.firestore
          .collection("users")
          .doc(widget.userId)
          .get();

      userData = safeMap(doc.data());

      if (mounted) setState(() => loadingUser = false);
    } catch (_) {
      if (mounted) setState(() => loadingUser = false);
    }
  }

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future deletePayment(String id) async {
    await FirebaseService.firestore.collection("financial").doc(id).delete();
  }

  Future editPayment(String id, int oldAmount) async {
    final controller = TextEditingController(text: oldAmount.toString());

    final result = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.black,
        title: const Text("تعديل المبلغ",
            style: TextStyle(color: Colors.white)),
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
            onPressed: () {
              int value = int.tryParse(controller.text) ?? 0;
              Navigator.pop(context, value);
            },
            child: const Text("حفظ"),
          )
        ],
      ),
    );

    if (result == null || result <= 0) return;

    await FirebaseService.firestore
        .collection("financial")
        .doc(id)
        .update({"amount": result});
  }

  @override
  Widget build(BuildContext context) {
    String name = safeString(userData['name']).isEmpty
        ? "Student"
        : safeString(userData['name']);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("💰 $name",
            style: const TextStyle(color: AppColors.gold)),
        backgroundColor: AppColors.black,
      ),
      body: loadingUser
          ? const LoadingWidget()
          : Column(
              children: [
                /// 🔥 HEADER
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Text(name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(
                        safeString(userData['email']),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                /// 🔥 LIST
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseService.firestore
                        .collection("financial")
                        .where("userId", isEqualTo: widget.userId)
                        .orderBy("timestamp", descending: true)
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const LoadingWidget();
                      }

                      if (!snap.hasData || snap.data!.docs.isEmpty) {
                        return const Center(
                          child: Text("لا توجد مدفوعات",
                              style: TextStyle(color: Colors.grey)),
                        );
                      }

                      var docs = snap.data!.docs;

                      int total = 0;

                      for (var d in docs) {
                        final data = safeMap(d.data());
                        total += safeInt(data['amount']);
                      }

                      return Column(
                        children: [
                          /// 🔥 TOTAL
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text(
                              "💵 الإجمالي: $total جنيه",
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),

                          Expanded(
                            child: ListView.builder(
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                var d = docs[index];
                                var data = safeMap(d.data());

                                int amount = safeInt(data['amount']);
                                Timestamp? ts = data['timestamp'];
                                String date = ts != null
                                    ? ts.toDate().toString()
                                    : "";

                                return Container(
                                  margin: const EdgeInsets.all(10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.money,
                                          color: Colors.green),
                                      const SizedBox(width: 10),

                                      /// DATA
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text("$amount جنيه",
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            Text(date,
                                                style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12)),
                                          ],
                                        ),
                                      ),

                                      /// ACTIONS
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.orange),
                                        onPressed: () =>
                                            editPayment(d.id, amount),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () =>
                                            deletePayment(d.id),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          )
                        ],
                      );
                    },
                  ),
                )
              ],
            ),
    );
  }
}