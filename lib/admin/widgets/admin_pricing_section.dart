import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../core/firebase_service.dart';

class AdminPricingSection extends StatelessWidget {
  const AdminPricingSection({super.key});

  @override
  Widget build(BuildContext context) {
    final monthlyController = TextEditingController();
    final yearlyController = TextEditingController();

    return FutureBuilder(
      future: FirebaseService.firestore.collection("settings").doc("pricing").get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator(color: AppColors.gold);
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

        monthlyController.text = data['monthly']?.toString() ?? "";
        yearlyController.text = data['yearly']?.toString() ?? "";

        return Column(
          children: [
            TextField(controller: monthlyController),
            TextField(controller: yearlyController),
          ],
        );
      },
    );
  }
}