import 'package:flutter/material.dart';

import '../../../core/colors.dart';
import '../../../course_details_page.dart';
import '../../../payment/payment_page.dart';
import '../../../shared/widgets/custom_button.dart';
import '../controller/student_profile_controller.dart';

class ProfileCourses extends StatelessWidget {
  final StudentProfileController controller;

  const ProfileCourses({
    super.key,
    required this.controller,
  });

  Widget _panel({required Widget child, required double scale}) {
    return Container(
      padding: EdgeInsets.all(14 * scale),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18 * scale),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title, {String? subtitle, required double scale}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14 * scale,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null) ...[
          SizedBox(height: 3 * scale),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 11 * scale,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth < 380 ? 0.8 : screenWidth < 420 ? 0.9 : 1.0;

    if (controller.enrolledCourses.isEmpty) {
      return _panel(
        scale: scale,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(
              "كورساتي",
              subtitle: "لا توجد كورسات مسجلة على الحساب",
              scale: scale,
            ),
            SizedBox(height: 12 * scale),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16 * scale),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14 * scale),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    color: AppColors.gold,
                    size: 26 * scale,
                  ),
                  SizedBox(height: 8 * scale),
                  Text(
                    "لم يتم تسجيل أي كورس بعد",
                    style: TextStyle(color: Colors.white, fontSize: 12 * scale),
                  ),
                  SizedBox(height: 8 * scale),
                  CustomButton(
                    text: "💳 فتح الدفع والاشتراك",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final items = controller.enrolledCourses.toList();

    return _panel(
      scale: scale,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            "كورساتي",
            subtitle: "اضغط على أي كورس لعرض التفاصيل",
            scale: scale,
          ),
          SizedBox(height: 12 * scale),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: screenWidth < 350 ? 1 : 2,
              childAspectRatio: screenWidth < 350 ? 1.3 : 1,
              crossAxisSpacing: 8 * scale,
              mainAxisSpacing: 8 * scale,
            ),
            itemBuilder: (context, index) {
              final id = items[index];
              final title = controller.courseNames[id] ?? id;

              final palette = [
                Colors.blue,
                Colors.purple,
                Colors.green,
                Colors.orange,
                Colors.teal,
                Colors.red,
              ];

              final color = palette[index % palette.length];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CourseDetailsPage(
                        title: title,
                        courseId: id,
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16 * scale),
                    border: Border.all(color: color.withValues(alpha: 0.25)),
                  ),
                  padding: EdgeInsets.all(10 * scale),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40 * scale,
                        height: 40 * scale,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12 * scale),
                        ),
                        child: Icon(
                          Icons.menu_book,
                          color: color,
                          size: 22 * scale,
                        ),
                      ),
                      SizedBox(height: 8 * scale),
                      Text(
                        title,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 11 * scale,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}