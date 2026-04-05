import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../core/firebase_service.dart';
import '../core/utils.dart';
import 'payment_service.dart';

class CheckoutPage extends StatelessWidget {
  final String phone;
  final int price;
  final int paid;
  final int remaining;
  final String plan;
  final String? courseId;
  final String imageUrl;

  const CheckoutPage({
    super.key,
    required this.phone,
    required this.price,
    required this.paid,
    required this.remaining,
    required this.plan,
    this.courseId,
    required this.imageUrl,
  });

  Future confirm(BuildContext context) async {
    final user = FirebaseService.auth.currentUser;

    await PaymentService.submitPayment(
      phone: phone,
      price: price,
      paid: paid,
      remaining: remaining,
      plan: plan,
      courseId: courseId,
      imageUrl: imageUrl,
      userId: user?.uid ?? '',
      email: user?.email ?? '',
    );

    if (!Navigator.of(context).mounted) return;

    showSnack(context, "تم إرسال الطلب بنجاح 🎉");

    Navigator.pop(context);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("تأكيد الدفع"),
        backgroundColor: AppColors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            buildItem("📱 الهاتف", phone),
            buildItem("💼 الباقة", plan),
            buildItem("💰 السعر", "$price جنيه"),
            buildItem("💵 المدفوع", "$paid جنيه"),
            buildItem("📉 المتبقي", "$remaining جنيه"),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                minimumSize: const Size(double.infinity, 55),
              ),
              onPressed: () => confirm(context),
              child: const Text(
                "🚀 تأكيد الدفع",
                style: TextStyle(color: Colors.black),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildItem(String title, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}