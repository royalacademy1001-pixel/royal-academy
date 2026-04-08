// TODO Implement this library.
import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../core/firebase_service.dart';
import '../core/utils.dart';
import 'payment_service.dart';

class CheckoutPage extends StatefulWidget {
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

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool loading = false;
  bool done = false;

  Future confirm() async {
    if (loading || done) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.black,
        title: const Text("تأكيد الدفع",
            style: TextStyle(color: Colors.white)),
        content: const Text(
          "هل أنت متأكد من إرسال الطلب؟",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("إلغاء"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("تأكيد"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => loading = true);

    try {
      final user = FirebaseService.auth.currentUser;

      if (user == null) {
        if (!mounted) return;
        showSnack(context, "يجب تسجيل الدخول ❗", color: Colors.red);
        if (mounted) setState(() => loading = false);
        return;
      }

      if (widget.paid <= 0 || widget.price <= 0) {
        showSnack(context, "بيانات الدفع غير صحيحة ❌", color: Colors.red);
        if (mounted) setState(() => loading = false);
        return;
      }

      if (widget.paid > widget.price) {
        showSnack(context, "المبلغ المدفوع أكبر من المطلوب ❗", color: Colors.red);
        if (mounted) setState(() => loading = false);
        return;
      }

      bool success = await PaymentService.submitPayment(
        phone: widget.phone,
        price: widget.price,
        paid: widget.paid,
        remaining: widget.remaining,
        plan: widget.plan,
        courseId: widget.courseId,
        imageUrl: widget.imageUrl,
        userId: user.uid,
        email: user.email ?? '',
      );

      if (!mounted) return;

      if (!success) {
        showSnack(context, "فشل إرسال الطلب ❌", color: Colors.red);
        setState(() => loading = false);
        return;
      }

      done = true;

      showSnack(context, "تم إرسال الطلب بنجاح 🎉");

      await Future.delayed(const Duration(milliseconds: 400));

      if (!mounted) return;

      Navigator.of(context).pop();
      Navigator.of(context).pop();

    } catch (e) {
      if (mounted) {
        showSnack(context, "حصل خطأ ❌", color: Colors.red);
        setState(() => loading = false);
      }
      return;
    }

    if (mounted) setState(() => loading = false);
  }

  double get progress {
    if (widget.price == 0) return 0;
    double value = widget.paid / widget.price;
    if (value > 1) return 1;
    if (value < 0) return 0;
    return value;
  }

  String get statusText {
    if (widget.remaining <= 0) return "✔ مكتمل";
    if (widget.paid == 0) return "❌ لم يتم الدفع";
    return "⏳ دفع جزئي";
  }

  Color get statusColor {
    if (widget.remaining <= 0) return Colors.green;
    if (widget.paid == 0) return Colors.red;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("تأكيد الدفع"),
        backgroundColor: AppColors.black,
      ),
      body: AbsorbPointer(
        absorbing: loading,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [

              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: statusColor),
                    const SizedBox(width: 10),
                    Text(
                      statusText,
                      style: TextStyle(color: statusColor),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              buildItem("📱 الهاتف", widget.phone),
              buildItem("💼 الباقة", widget.plan),
              buildItem("💰 السعر", "${widget.price} جنيه"),
              buildItem("💵 المدفوع", "${widget.paid} جنيه"),
              buildItem("📉 المتبقي", "${widget.remaining} جنيه"),

              const SizedBox(height: 20),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("حالة الدفع",
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: progress,
                    color: AppColors.gold,
                    backgroundColor: Colors.grey.shade800,
                    minHeight: 8,
                  ),
                ],
              ),

              const Spacer(),

              loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: done
                            ? Colors.green
                            : AppColors.gold,
                        minimumSize:
                            const Size(double.infinity, 55),
                      ),
                      onPressed: done ? null : confirm,
                      child: Text(
                        done ? "✔ تم الإرسال" : "🚀 تأكيد الدفع",
                        style: const TextStyle(color: Colors.black),
                      ),
                    )
            ],
          ),
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