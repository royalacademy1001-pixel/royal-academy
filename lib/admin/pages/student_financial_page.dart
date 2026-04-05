// 🔥 STUDENT FINANCIAL SYSTEM (CRM)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';

// 🔥 CORE
import '../../core/firebase_service.dart';
import '../../core/colors.dart';

// 🔥 WIDGET
import '../../widgets/loading_widget.dart';

class StudentFinancialPage extends StatefulWidget {
  const StudentFinancialPage({super.key});

  @override
  State<StudentFinancialPage> createState() =>
      _StudentFinancialPageState();
}

class _StudentFinancialPageState
    extends State<StudentFinancialPage> {

  String search = "";

  void show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future addPayment(String userId) async {

    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.black,
        title: const Text("إضافة دفعة",
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration:
              const InputDecoration(hintText: "المبلغ"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () async {

              int amount =
                  int.tryParse(amountController.text) ?? 0;

              if (amount <= 0) return;

              await FirebaseService.firestore
                  .collection("financial")
                  .add({
                "userId": userId,
                "amount": amount,
                "timestamp": FieldValue.serverTimestamp(),
              });

              Navigator.pop(context);
              show("تم إضافة الدفع ✅");
            },
            child: const Text("حفظ"),
          )
        ],
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
        title: const Text("💰 إدارة المصاريف",
            style: TextStyle(color: AppColors.gold)),
        backgroundColor: AppColors.black,
      ),

      body: Column(
        children: [

          /// 🔍 SEARCH
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "ابحث...",
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
                  .collection("financial")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const LoadingWidget();
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
                    int amount = data['amount'] ?? 0;

                    Timestamp? ts = data['timestamp'];
                    String date = ts != null
                        ? ts.toDate().toString()
                        : "";

                    return FutureBuilder<String>(
                      future: getUserName(userId),
                      builder: (context, snap) {

                        String name =
                            snap.data ?? "Loading...";

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

                              const Icon(Icons.person,
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

                                    Text("💵 $amount جنيه",
                                        style: const TextStyle(
                                            color: Colors.green)),

                                    Text(date,
                                        style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),

                              IconButton(
                                icon: const Icon(Icons.add,
                                    color: Colors.green),
                                onPressed: () =>
                                    addPayment(userId),
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