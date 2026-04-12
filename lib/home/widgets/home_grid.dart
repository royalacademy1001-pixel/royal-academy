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
    return StatefulBuilder(
      builder: (context, setState) {
        bool hovered = false;
        bool pressed = false;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => hovered = true),
          onExit: (_) => setState(() {
            hovered = false;
            pressed = false;
          }),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => setState(() => pressed = true),
            onTapUp: (_) => setState(() => pressed = false),
            onTapCancel: () => setState(() => pressed = false),
            onTap: () {
              try {
                if (!context.mounted) return;
                f();
              } catch (_) {}
            },
            child: RepaintBoundary(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: 82,
                margin: const EdgeInsets.only(right: 12),
                transform: Matrix4.identity()
                  ..scale(pressed
                      ? 0.92
                      : hovered
                          ? 1.1
                          : 1.0)
                  ..translate(0.0, hovered ? -6.0 : 0.0),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      width: hovered ? 64 : 60,
                      height: hovered ? 64 : 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.gold.withValues(
                                alpha: hovered ? 0.6 : 0.25),
                            AppColors.gold.withValues(
                                alpha: hovered ? 0.2 : 0.05),
                            Colors.transparent,
                          ],
                        ),
                        border: Border.all(
                          color: AppColors.gold.withValues(
                              alpha: hovered ? 1 : 0.35),
                          width: hovered ? 1.8 : 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(
                                alpha: hovered ? 0.6 : 0.25),
                            blurRadius: hovered ? 30 : 14,
                            spreadRadius: hovered ? 3 : 1,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: hovered ? 14 : 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: ClipOval(
                        child: SizedBox(
                          width: hovered ? 56 : 52,
                          height: hovered ? 56 : 52,
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
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        color: hovered ? AppColors.gold : Colors.white,
                        fontSize: hovered ? 12 : 11,
                        fontWeight: FontWeight.w700,
                      ),
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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