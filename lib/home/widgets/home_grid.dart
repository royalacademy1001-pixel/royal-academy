import 'package:flutter/material.dart';

import '../../admin/pages/admin_page.dart';
import '../../features/center_management/pages/center_management_page.dart';
import '../../core/colors.dart';
import '../../instructor/instructor_dashboard_page.dart';
import '../../leaderboard_page.dart';
import '../../payment/payment_page.dart';
import '../widgets/home_nav_guard.dart';
import '../../features/courses/pages/courses_page.dart';

class HomeGrid extends StatelessWidget {
  final bool isAdmin;
  final bool isInstructor;

  const HomeGrid({
    super.key,
    required this.isAdmin,
    required this.isInstructor,
  });

  Widget _title(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(15, 20, 15, 10),
        child: Row(
          children: [
            Text(
              text,
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            const Icon(Icons.flash_on_rounded, color: AppColors.gold, size: 18),
          ],
        ),
      );

  Widget _item(BuildContext context, String title, String asset, VoidCallback f) {
    return GestureDetector(
      onTap: () {
        try {
          if (!context.mounted) return;
          f();
        } catch (_) {}
      },
      child: Container(
        width: 82,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.gold.withValues(alpha: 0.25),
                    AppColors.gold.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.25),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: ClipOval(
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: Image.asset(
                    asset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.black,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.image_not_supported,
                        color: AppColors.gold.withValues(alpha: 0.7),
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool safeIsAdmin = isAdmin == true;
    final bool safeIsInstructor = isInstructor == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title("⚡ الوصول السريع"),
        SizedBox(
          height: 105,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            physics: const BouncingScrollPhysics(),
            children: [
              _item(context, "الكورسات", "assets/images/courses.png", () {
                if (!context.mounted) return;
                HomeNavGuard.go(() => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CoursesPage()),
                    ));
              }),
              _item(context, "الدفع", "assets/images/payment.png", () {
                if (!context.mounted) return;
                HomeNavGuard.go(() => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PaymentPage()),
                    ));
              }),
              _item(context, "المتصدرين", "assets/images/leaderboard.png", () {
                if (!context.mounted) return;
                HomeNavGuard.go(() => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LeaderboardPage(),
                      ),
                    ));
              }),
              if (safeIsInstructor || safeIsAdmin)
                _item(context, "المدرس", "assets/images/instructor.png", () {
                  if (!context.mounted) return;
                  HomeNavGuard.go(() => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InstructorDashboardPage(),
                        ),
                      ));
                }),
              if (safeIsAdmin)
                _item(context, "Admin", "assets/images/admin.png", () {
                  if (!context.mounted) return;
                  HomeNavGuard.go(() => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminPage()),
                      ));
                }),
              if (safeIsAdmin)
                _item(context, "السنتر", "assets/images/admin.png", () {
                  if (!context.mounted) return;
                  HomeNavGuard.go(() => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CenterManagementPage(),
                        ),
                      ));
                }),
            ],
          ),
        ),
      ],
    );
  }
}