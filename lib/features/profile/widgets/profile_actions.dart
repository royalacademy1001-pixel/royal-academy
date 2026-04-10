import 'package:flutter/material.dart';

import '../../../shared/widgets/custom_button.dart';
import '../../../core/firebase_service.dart';
import '../controller/student_profile_controller.dart';

class ProfileActions extends StatelessWidget {
  final StudentProfileController controller;

  const ProfileActions({
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
            "إجراءات سريعة",
            subtitle: "كل ما تحتاجه من مكان واحد",
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: "🔄 تحديث اللوحة",
                  onPressed: () async {
                    await controller.loadData();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomButton(
                  text: "🚪 تسجيل الخروج",
                  onPressed: () async {
                    controller.loading = true;
                    controller.notifyListeners();

                    await FirebaseService.auth.signOut();

                    if (!context.mounted) return;

                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
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