import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🔥 Core
import '../core/firebase_service.dart';
import '../core/constants.dart';
import '../core/colors.dart';

class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  State<PaymentHistoryPage> createState() =>
      _PaymentHistoryPageState();
}

class _PaymentHistoryPageState
    extends State<PaymentHistoryPage> {

  String filter = "all";

  bool loadingLock = false;

  @override
  Widget build(BuildContext context) {

    var user = FirebaseService.auth.currentUser;

    Query query = FirebaseService.firestore
        .collection(AppConstants.payments)
        .where("userId", isEqualTo: user?.uid);

    if (filter != "all") {
      query = query.where("status", isEqualTo: filter);
    }

    query = query.orderBy("createdAt", descending: true);

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("📊 سجل المدفوعات"),
        backgroundColor: AppColors.black,
      ),

      body: Column(
        children: [

          /// 🔥 FILTER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              buildFilter("الكل", "all"),
              buildFilter("⏳ Pending", "pending"),
              buildFilter("✅ Approved", "approved"),
              buildFilter("❌ Rejected", "rejected"),
            ],
          ),

          const SizedBox(height: 10),

          /// 🔥 LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.gold),
                  );
                }

                var payments = snapshot.data!.docs;

                if (payments.isEmpty) {
                  return const Center(
                    child: Text(
                      "لا يوجد طلبات",
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: payments.length,
                  itemBuilder: (context, index) {

                    var data = payments[index].data()
                        as Map<String, dynamic>;

                    return buildCard(data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================== CARD ==================

  Widget buildCard(Map<String, dynamic> data) {

    int price = data['price'] ?? 0;
    int paid = data['paid'] ?? data['paidAmount'] ?? 0;
    int remaining = data['remaining'] ?? 0;

    String status = data['status'] ?? "pending";

    Color statusColor = Colors.orange;

    if (status == "approved") statusColor = Colors.green;
    if (status == "rejected") statusColor = Colors.red;

    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.gold),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text("💼 ${data['plan']}",
              style: const TextStyle(color: Colors.white)),

          const SizedBox(height: 5),

          Text("💰 $price جنيه",
              style: const TextStyle(color: AppColors.gold)),

          Text("💵 $paid جنيه",
              style: const TextStyle(color: Colors.green)),

          Text("📉 $remaining جنيه",
              style: const TextStyle(color: Colors.red)),

          const SizedBox(height: 8),

          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ================== FILTER ==================

  Widget buildFilter(String text, String value) {
    return GestureDetector(
      onTap: () {
        if (loadingLock) return;
        loadingLock = true;

        setState(() => filter = value);

        Future.delayed(const Duration(milliseconds: 300), () {
          loadingLock = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: filter == value
              ? AppColors.gold
              : AppColors.black,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: filter == value
                ? Colors.black
                : Colors.white,
          ),
        ),
      ),
    );
  }
}