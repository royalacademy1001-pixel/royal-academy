import 'package:flutter/material.dart';
import '../../../core/colors.dart';
import '../controller/student_profile_controller.dart';

class ProfileHeader extends StatelessWidget {
  final StudentProfileController controller;

  const ProfileHeader({
    super.key,
    required this.controller,
  });

  Widget _statusChip(String text, Color color, double scale) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 4 * scale),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9 * scale,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = controller.avatarProvider();
    final completion = controller.profileCompletion();

    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth < 380 ? 0.8 : screenWidth < 420 ? 0.9 : 1.0;

    final endDate = controller.subscriptionEnd;
    final daysLeft = controller.formatDate(endDate).isEmpty
        ? null
        : DateTime.tryParse(controller.formatDate(endDate))
            ?.difference(DateTime.now())
            .inDays;

    return Container(
      padding: EdgeInsets.all(14 * scale),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18 * scale),
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
                  radius: 44 * scale,
                  backgroundColor: AppColors.gold,
                  backgroundImage: imageProvider,
                  child: imageProvider == null
                      ? Icon(Icons.camera_alt, color: Colors.black, size: 18 * scale)
                      : null,
                ),
                Container(
                  padding: EdgeInsets.all(5 * scale),
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Icon(
                    Icons.edit,
                    size: 12 * scale,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10 * scale),
          Text(
            controller.name.text.isEmpty
                ? "اسم المستخدم"
                : controller.name.text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16 * scale,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            controller.email.isEmpty
                ? "لا يوجد إيميل"
                : controller.email,
            style: TextStyle(color: Colors.grey, fontSize: 12 * scale),
          ),
          if (controller.phone.text.isNotEmpty) ...[
            SizedBox(height: 3 * scale),
            Text(
              controller.phone.text,
              style: TextStyle(color: Colors.grey, fontSize: 12 * scale),
            ),
          ],
          if (controller.studentId != null &&
              controller.studentId!.isNotEmpty) ...[
            SizedBox(height: 8 * scale),
            _statusChip(
              "Student ID: ${controller.studentId}",
              Colors.blue,
              scale,
            ),
          ],
          SizedBox(height: 10 * scale),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: completion / 100,
              minHeight: 8 * scale,
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
          SizedBox(height: 6 * scale),
          Text(
            "اكتمال الملف: $completion%",
            style: TextStyle(
              color: completion >= 80
                  ? Colors.green
                  : completion >= 50
                      ? Colors.orange
                      : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 12 * scale,
            ),
          ),
          SizedBox(height: 10 * scale),
          Wrap(
            spacing: 5 * scale,
            runSpacing: 5 * scale,
            alignment: WrapAlignment.center,
            children: [
              _statusChip(
                controller.validSubscription
                    ? "اشتراك نشط"
                    : "اشتراك غير نشط",
                controller.validSubscription ? Colors.green : Colors.red,
                scale,
              ),
              if (controller.isAdmin)
                _statusChip("Admin", Colors.orange, scale),
              if (controller.isVIP)
                _statusChip("VIP", Colors.green, scale),
              if (controller.instructorApproved)
                _statusChip("Instructor", Colors.blue, scale),
              if (controller.instructorRequest)
                _statusChip("طلب مدرس", Colors.amber, scale),
              if (controller.blocked)
                _statusChip("Blocked", Colors.red, scale),
              if (daysLeft != null)
                _statusChip(
                  daysLeft >= 0 ? "باقي $daysLeft يوم" : "منتهي",
                  daysLeft >= 0 ? Colors.teal : Colors.red,
                  scale,
                ),
            ],
          ),
          if (controller.subscriptionEnd != null) ...[
            SizedBox(height: 10 * scale),
            Text(
              "ينتهي الاشتراك: ${controller.formatDate(controller.subscriptionEnd)}",
              style: TextStyle(color: Colors.grey, fontSize: 11 * scale),
            ),
          ],
        ],
      ),
    );
  }
}