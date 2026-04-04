import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/firebase_service.dart';
import '../core/constants.dart';
import '../core/colors.dart';

import '../payment/payment_page.dart';

class UserPaymentsPage extends StatelessWidget {
  const UserPaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {

    final user = FirebaseService.auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("💰 مدفوعاتي",
            style: TextStyle(color: AppColors.gold)),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService.firestore
            .collection(AppConstants.payments)
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),

        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.gold),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _emptyView();
          }

          var payments = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: payments.length,
            itemBuilder: (context, index) {

              var doc = payments[index];
              var data = doc.data() as Map<String, dynamic>;

              int price = data['price'] ?? 0;
              int paid = data['paidAmount'] ?? 0;
              int remaining = data['remaining'] ?? (price - paid);

              String status = data['status'] ?? "pending";

              double progress =
                  price == 0 ? 0 : (paid / price).clamp(0, 1);

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(15),
                decoration: AppColors.premiumCard,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// 🔥 HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          data['plan'] ?? "Plan",
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        buildStatus(status),
                      ],
                    ),

                    const SizedBox(height: 15),

                    /// 💰 DETAILS
                    row("💰 السعر", "$price جنيه", AppColors.white),
                    row("💵 المدفوع", "$paid جنيه", Colors.green),
                    row("📉 المتبقي", "$remaining جنيه", Colors.red),

                    const SizedBox(height: 15),

                    /// 📊 PROGRESS
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        color: AppColors.gold,
                        backgroundColor: Colors.grey.shade800,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "📊 ${(progress * 100).toInt()}%",
                      style: const TextStyle(color: AppColors.grey),
                    ),

                    const SizedBox(height: 15),

                    /// 🔄 ACTION
                    if (remaining > 0 && status != "rejected")
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          minimumSize:
                              const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PaymentPage(),
                            ),
                          );
                        },
                        child: const Text(
                          "💳 استكمال الدفع",
                          style: TextStyle(color: Colors.black),
                        ),
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

  /// ================= EMPTY =================
  Widget _emptyView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payments_outlined,
              size: 80, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            "لا يوجد مدفوعات حتى الآن",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// ================= STATUS =================
  Widget buildStatus(String status) {
    Color color;
    String text;

    switch (status) {
      case "approved":
        color = Colors.green;
        text = "تم القبول";
        break;

      case "rejected":
        color = Colors.red;
        text = "مرفوض";
        break;

      default:
        color = Colors.orange;
        text = "قيد المراجعة";
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  /// ================= ROW =================
  Widget row(String title, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: AppColors.grey)),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}