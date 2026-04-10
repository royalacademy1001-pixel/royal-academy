import 'package:flutter/material.dart';
import '../../../core/colors.dart';
import '../controller/student_profile_controller.dart';

class ProfileHeader extends StatelessWidget {
  final StudentProfileController controller;

  const ProfileHeader({
    super.key,
    required this.controller,
  });

  Widget _statusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = controller.avatarProvider();
    final completion = controller.profileCompletion();

    final endDate = controller.subscriptionEnd;
    final daysLeft = controller.formatDate(endDate).isEmpty
        ? null
        : DateTime.tryParse(controller.formatDate(endDate))
            ?.difference(DateTime.now())
            .inDays;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: controller.pickImage,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 54,
                  backgroundColor: AppColors.gold,
                  backgroundImage: imageProvider,
                  child: imageProvider == null
                      ? const Icon(Icons.camera_alt, color: Colors.black)
                      : null,
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 14,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            controller.name.text.isEmpty
                ? "اسم المستخدم"
                : controller.name.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            controller.email.isEmpty
                ? "لا يوجد إيميل"
                : controller.email,
            style: const TextStyle(color: Colors.grey),
          ),
          if (controller.phone.text.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              controller.phone.text,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
          if (controller.studentId != null &&
              controller.studentId!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _statusChip(
              "Student ID: ${controller.studentId}",
              Colors.blue,
            ),
          ],
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: completion / 100,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(
                completion >= 80
                    ? Colors.green
                    : completion >= 50
                        ? Colors.orange
                        : Colors.red,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "اكتمال الملف: $completion%",
            style: TextStyle(
              color: completion >= 80
                  ? Colors.green
                  : completion >= 50
                      ? Colors.orange
                      : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _statusChip(
                controller.validSubscription
                    ? "اشتراك نشط"
                    : "اشتراك غير نشط",
                controller.validSubscription ? Colors.green : Colors.red,
              ),
              if (controller.isAdmin)
                _statusChip("Admin", Colors.orange),
              if (controller.isVIP)
                _statusChip("VIP", Colors.green),
              if (controller.instructorApproved)
                _statusChip("Instructor", Colors.blue),
              if (controller.instructorRequest)
                _statusChip("طلب مدرس", Colors.amber),
              if (controller.blocked)
                _statusChip("Blocked", Colors.red),
              if (daysLeft != null)
                _statusChip(
                  daysLeft >= 0 ? "باقي $daysLeft يوم" : "منتهي",
                  daysLeft >= 0 ? Colors.teal : Colors.red,
                ),
            ],
          ),
          if (controller.subscriptionEnd != null) ...[
            const SizedBox(height: 12),
            Text(
              "ينتهي الاشتراك: ${controller.formatDate(controller.subscriptionEnd)}",
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}