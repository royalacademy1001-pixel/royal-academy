import 'package:flutter/material.dart';

import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_textfield.dart';
import '../../../user_payments_page.dart';
import '../../../payment/payment_page.dart';
import '../controller/student_profile_controller.dart';

class ProfileEdit extends StatelessWidget {
  final StudentProfileController controller;

  const ProfileEdit({
    super.key,
    required this.controller,
  });

  Widget _panel({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            "بيانات الحساب",
            subtitle: "عدّل اسمك ورقمك والصورة الشخصية",
          ),
          const SizedBox(height: 14),
          CustomTextField(
            hint: "الاسم",
            controller: controller.name,
          ),
          const SizedBox(height: 10),
          CustomTextField(
            hint: "رقم الهاتف",
            controller: controller.phone,
          ),
          const SizedBox(height: 14),
          CustomButton(
            text: "💾 حفظ التغييرات",
            onPressed: controller.saveData,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: "💰 مدفوعاتي",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserPaymentsPage(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomButton(
                  text: "💳 تجديد الاشتراك",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}