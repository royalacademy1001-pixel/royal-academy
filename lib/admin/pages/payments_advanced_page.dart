import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/colors.dart';
import '../../core/firebase_service.dart';
import '../../core/constants.dart';
import '../services/notification_sender.dart';

class PaymentsAdvancedPage extends StatefulWidget {
  const PaymentsAdvancedPage({super.key});

  @override
  State<PaymentsAdvancedPage> createState() => _PaymentsAdvancedPageState();
}

class _PaymentsAdvancedPageState extends State<PaymentsAdvancedPage> {
  String search = "";

  final double coursePrice = 500;

  Future<void> addPayment(String userId, String name) async {
    final amountController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: AppColors.black,
          title: const Text("إضافة دفع", style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(hintText: "المبلغ"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إلغاء"),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text) ?? 0;

                await FirebaseService.firestore.collection("payments").add({
                  "userId": userId,
                  "name": name,
                  "amount": amount,
                  "date": Timestamp.now(),
                });

                if (mounted) Navigator.pop(context);
              },
              child: const Text("حفظ"),
            ),
          ],
        );
      },
    );
  }

  Future<double> getTotalPaid(String userId) async {
    final snap = await FirebaseService.firestore
        .collection("payments")
        .where("userId", isEqualTo: userId)
        .get();

    double total = 0;

    for (var doc in snap.docs) {
      total += (doc['amount'] ?? 0);
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("💰 إدارة المصاريف"),
        backgroundColor: AppColors.black,
        actions: [
          IconButton(
            onPressed: () async {
              await NotificationSender.sendPaymentReminders();

              if (!mounted) return;

              ScaffoldMessenger.of(this.context).showSnackBar(
                const SnackBar(
                  content: Text("تم إرسال التذكيرات 🔔"),
                ),
              );
            },
            icon: const Icon(Icons.notifications_active, color: AppColors.gold),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "بحث باسم الطالب...",
                hintStyle: TextStyle(color: Colors.grey.shade600),
                prefixIcon: const Icon(Icons.search, color: AppColors.gold),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => search = val),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseService.firestore
                  .collection(AppConstants.users)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final students = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final name = (data['name'] ?? "").toString().toLowerCase();

                  return data['isAdmin'] != true &&
                      data['instructorApproved'] != true &&
                      name.contains(search.toLowerCase());
                }).toList();

                return ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final doc = students[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final name = data['name'] ?? "Student";

                    return FutureBuilder<double>(
                      future: getTotalPaid(doc.id),
                      builder: (context, snapshot2) {
                        final paid = snapshot2.data ?? 0;
                        final remaining = coursePrice - paid;
                        final isPaid = remaining <= 0;

                        return Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isPaid ? Colors.green : Colors.red,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "مدفوع: $paid جنيه",
                                      style:
                                          const TextStyle(color: Colors.green),
                                    ),
                                    Text(
                                      isPaid
                                          ? "✅ مدفوع كامل"
                                          : "❌ متبقي: $remaining جنيه",
                                      style: TextStyle(
                                        color:
                                            isPaid ? Colors.green : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => addPayment(doc.id, name),
                                icon: const Icon(Icons.add,
                                    color: AppColors.gold),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
