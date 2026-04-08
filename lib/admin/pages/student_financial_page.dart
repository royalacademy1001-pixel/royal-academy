// 🔥 STUDENT FINANCIAL SYSTEM (CRM)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase_service.dart';
import '../../core/colors.dart';

import '../../widgets/loading_widget.dart';

class StudentFinancialPage extends StatefulWidget {
  const StudentFinancialPage({super.key});

  @override
  State<StudentFinancialPage> createState() => _StudentFinancialPageState();
}

class _StudentFinancialPageState extends State<StudentFinancialPage> {
  String search = "";
  String selectedUserId = "";
  List<QueryDocumentSnapshot> users = [];
  Map<String, String> userNames = {};

  void show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

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

  Future loadUsers() async {
    try {
      final snap = await FirebaseService.firestore.collection("users").get();
      users = snap.docs;

      for (var u in users) {
        final raw = u.data();
        final data = safeMap(raw);

        userNames[u.id] = safeString(data['name']).isEmpty
            ? "Student"
            : safeString(data['name']);
      }

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

  Future addPayment(String userId) async {
    final amountController = TextEditingController();
    String localSelectedUserId = userId;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (innerCtx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.black,
            title:
                const Text("إضافة دفعة", style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue:
                      localSelectedUserId.isEmpty ? null : localSelectedUserId,
                  dropdownColor: AppColors.black,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: "اختر الطالب"),
                  items: users.map((u) {
                    return DropdownMenuItem<String>(
                      value: u.id,
                      child: Text(
                        userNames[u.id] ?? "Student",
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
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: "المبلغ"),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text("إلغاء"),
              ),
              ElevatedButton(
                onPressed: () {
                  int amount = int.tryParse(amountController.text) ?? 0;

                  if (amount <= 0) return;
                  if (localSelectedUserId.isEmpty) return;

                  Navigator.pop(dialogCtx, {
                    "userId": localSelectedUserId,
                    "amount": amount,
                  });
                },
                child: const Text("حفظ"),
              )
            ],
          );
        },
      ),
    );

    amountController.dispose();

    if (result == null) return;

    _savePayment(result);
  }

  Future _savePayment(Map<String, dynamic> data) async {
    await FirebaseService.firestore.collection("financial").add({
      "userId": safeString(data["userId"]),
      "amount": safeInt(data["amount"]),
      "timestamp": FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("تم إضافة الدفع ✅")),
    );
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
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "ابحث...",
                prefixIcon: const Icon(Icons.search, color: AppColors.gold),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => search = val.toLowerCase()),
            ),
          ),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseService.firestore.collection("financial").snapshots(),
            builder: (context, snap) {
              int total = 0;
              int count = 0;

              if (snap.hasData) {
                for (var d in snap.data!.docs) {
                  final data = safeMap(d.data());
                  total += safeInt(data['amount']);
                }
                count = snap.data!.docs.length;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _card("💵 الإجمالي", "$total جنيه"),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _card("📊 العمليات", "$count"),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseService.firestore
                  .collection("financial")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingWidget();
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "📭 لا توجد معاملات مالية حالياً",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                var docs = snapshot.data!.docs;

                Map<String, int> totals = {};

                for (var d in docs) {
                  final data = safeMap(d.data());

                  String uid = safeString(data['userId']);
                  int amount = safeInt(data['amount']);

                  if (uid.isEmpty) continue;

                  totals[uid] = (totals[uid] ?? 0) + amount;
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: totals.length,
                  itemBuilder: (context, index) {
                    String userId = totals.keys.elementAt(index);
                    int totalAmount = totals[userId] ?? 0;

                    String name = userNames[userId] ?? "Student";

                    if (search.isNotEmpty &&
                        !name.toLowerCase().contains(search)) {
                      return const SizedBox();
                    }

                    return GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          "/studentFinancialDetails",
                          arguments: userId,
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person, color: AppColors.gold),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                  Text("💰 الإجمالي: $totalAmount جنيه",
                                      style: const TextStyle(
                                          color: Colors.green)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.add, color: Colors.green),
                              onPressed: () => addPayment(userId),
                            )
                          ],
                        ),
                      ),
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

  Widget _card(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 5),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}