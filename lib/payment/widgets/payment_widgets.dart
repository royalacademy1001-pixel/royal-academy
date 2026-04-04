// 🔥 FINAL PAYMENT WIDGETS (PRO MAX++ UPGRADE NO DELETE)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/colors.dart';
import '../../core/firebase_service.dart';
import '../../core/constants.dart';

class _TapGuard {
  static final Map<String, DateTime> _locks = {};

  static bool canTap(String key) {
    final now = DateTime.now();

    if (_locks.containsKey(key)) {
      if (now.difference(_locks[key]!).inMilliseconds < 500) {
        return false;
      }
    }

    _locks[key] = now;
    return true;
  }
}

/// ================= PLAN CARD =================
Widget buildPlan({
  required String text,
  required bool selected,
  required VoidCallback onTap,
}) {
  IconData icon;

  if (text.contains("شهري") || text.contains("Monthly")) {
    icon = Icons.calendar_month;
  } else if (text.contains("سنوي") || text.contains("Yearly")) {
    icon = Icons.workspace_premium;
  } else {
    icon = Icons.menu_book;
  }

  return Expanded(
    child: GestureDetector(
      onTap: () {
        if (!_TapGuard.canTap(text)) return;
        onTap();
      },
      child: AnimatedContainer(
        duration: AppColors.fast,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.goldGradient : null,
          color: selected ? null : AppColors.black,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.gold
                : Colors.white.withOpacity(0.1),
          ),
          boxShadow: selected ? AppColors.goldShadow : [],
        ),
        child: Column(
          children: [

            Icon(
              icon,
              size: 26,
              color: selected ? Colors.black : AppColors.gold,
            ),

            const SizedBox(height: 8),

            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selected ? Colors.black : AppColors.white,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// ================= PAYMENT TYPE =================
Widget buildPaymentType({
  required String text,
  required bool selected,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: () {
      if (!_TapGuard.canTap(text)) return;
      onTap();
    },
    child: AnimatedContainer(
      duration: AppColors.fast,
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: selected ? AppColors.goldGradient : null,
        color: selected ? null : AppColors.black,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: selected
              ? AppColors.gold
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          Icon(
            text.contains("كامل")
                ? Icons.check_circle
                : Icons.pie_chart,
            color: selected ? Colors.black : AppColors.gold,
          ),

          const SizedBox(width: 8),

          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: selected ? Colors.black : AppColors.white,
            ),
          ),
        ],
      ),
    ),
  );
}

/// ================= COURSE SELECTOR 🔥 =================
Widget courseSelector({
  required Function(String id) onSelect,
  String? selectedId,
}) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseService.firestore
        .collection(AppConstants.courses)
        .orderBy("title")
        .snapshots(),
    builder: (context, snapshot) {

      if (!snapshot.hasData) {
        return const Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          ),
        );
      }

      var courses = snapshot.data!.docs;

      if (courses.isEmpty) {
        return const Text(
          "لا يوجد كورسات حالياً",
          style: TextStyle(color: Colors.grey),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "اختر الكورس",
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: courses.length,
              itemBuilder: (context, index) {

                var c = courses[index];
                var data = c.data() as Map<String, dynamic>;

                bool selected = selectedId == c.id;

                return GestureDetector(
                  onTap: () {
                    if (!_TapGuard.canTap(c.id)) return;
                    onSelect(c.id);
                  },
                  child: AnimatedContainer(
                    duration: AppColors.fast,
                    width: 150,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: selected ? AppColors.goldGradient : null,
                      color: selected
                          ? null
                          : AppColors.black,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected
                            ? Colors.green
                            : AppColors.gold.withOpacity(0.4),
                        width: selected ? 2 : 1,
                      ),
                      boxShadow:
                          selected ? AppColors.goldShadow : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        Text(
                          data['title'] ?? "",
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selected
                                ? Colors.black
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          "${data['price'] ?? 0} جنيه",
                          style: TextStyle(
                            color: selected
                                ? Colors.black87
                                : Colors.grey,
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(height: 6),

                        if (selected)
                          const Icon(Icons.check,
                              color: Colors.black),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    },
  );
}

/// ================= SUMMARY =================
Widget paymentSummary({
  required int price,
  required int paid,
  required int remaining,
}) {
  return FutureBuilder<DocumentSnapshot>(
    future: FirebaseService.firestore
        .collection("settings")
        .doc("pricing")
        .get(),
    builder: (context, snapshot) {

      int finalPrice = price;

      if (snapshot.hasData) {
        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

        if (price == AppConstants.monthlyPrice) {
          finalPrice = int.tryParse(data['monthly']?.toString() ?? "") ?? price;
        }

        if (price == AppConstants.yearlyPrice) {
          finalPrice = int.tryParse(data['yearly']?.toString() ?? "") ?? price;
        }
      }

      int finalPaid = paid;
      if (finalPaid > finalPrice) finalPaid = finalPrice;

      int finalRemaining = finalPrice - finalPaid;
      if (finalRemaining < 0) finalRemaining = 0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "💰 ملخص الدفع",
            style: TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          _row("السعر", finalPrice, AppColors.white),
          _row("المدفوع", finalPaid, Colors.green),
          _row("المتبقي", finalRemaining, Colors.red),
        ],
      );
    },
  );
}

Widget _row(String title, int value, Color color) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: AppColors.grey)),
        Text(
          "$value جنيه",
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

/// ================= STATUS =================
Widget paymentStatus({
  String? image,
  bool hasCourse = false,
}) {
  return Column(
    children: [

      if (image != null)
        const Text(
          "✅ تم رفع صورة الدفع",
          style: TextStyle(color: Colors.green),
        ),

      if (hasCourse)
        const Text(
          "🎓 تم اختيار الكورس",
          style: TextStyle(color: AppColors.gold),
        ),
    ],
  );
}