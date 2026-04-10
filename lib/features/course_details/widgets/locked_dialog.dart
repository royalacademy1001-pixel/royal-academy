import 'package:flutter/material.dart';
import '/../payment/payment_page.dart';
import '../../../core/colors.dart';

void showLockedDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppColors.black,
        title: const Text(
          "🔒 الدرس مقفول",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "اشترك لفتح باقي الدروس",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            style: AppColors.goldButton,
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PaymentPage(),
                ),
              );
            },
            child: const Text("اشترك الآن"),
          ),
        ],
      );
    },
  );
}