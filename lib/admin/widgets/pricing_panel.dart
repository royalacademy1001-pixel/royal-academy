import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../core/firebase_service.dart';

class PricingPage extends StatefulWidget {
  const PricingPage({super.key});

  @override
  State<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends State<PricingPage> {

  final monthlyController = TextEditingController();
  final yearlyController = TextEditingController();

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    monthlyController.dispose();
    yearlyController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    try {
      final doc = await FirebaseService.firestore
          .collection("settings")
          .doc("pricing")
          .get();

      final data = doc.data() ?? {};

      monthlyController.text = data['monthly']?.toString() ?? "";
      yearlyController.text = data['yearly']?.toString() ?? "";
    } catch (_) {}

    if (!mounted) return;
    setState(() => loading = false);
  }

  Future<void> save() async {
    try {
      await FirebaseService.firestore
          .collection("settings")
          .doc("pricing")
          .set({
        "monthly": int.tryParse(monthlyController.text) ?? 0,
        "yearly": int.tryParse(yearlyController.text) ?? 0,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم الحفظ ✅")),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ حدث خطأ أثناء الحفظ")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("⚙ إعدادات الاشتراك"),
        backgroundColor: Colors.black,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextField(
                    controller: monthlyController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "السعر الشهري",
                      labelStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: yearlyController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "السعر السنوي",
                      labelStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: save,
                    child: const Text("حفظ"),
                  )
                ],
              ),
            ),
    );
  }
}