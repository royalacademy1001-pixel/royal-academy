import 'package:flutter/material.dart';

import '../../admin/pages/admin_page.dart';
import '../../features/center_management/pages/center_management_page.dart';
import '../../core/colors.dart';
import 'home_nav_guard.dart';

class HomeAdminSection extends StatelessWidget {
  const HomeAdminSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title("🛠 لوحات الإدارة"),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            children: [
              _adminCard(
                context,
                title: "🏫 إدارة السنتر",
                subtitle: "كل الصفحات الخاصة بالسنتر والـ VIP",
                icon: Icons.apartment_rounded,
                accent: const Color(0xFFFFD54F),
                onTap: () {
                  if (!context.mounted) return;
                  HomeNavGuard.go(() => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CenterManagementPage(),
                        ),
                      ));
                },
              ),
              const SizedBox(height: 12),
              _adminCard(
                context,
                title: "💻 إدارة التطبيق",
                subtitle: "كل صفحات إدارة البرنامج الأونلاين",
                icon: Icons.dashboard_customize_rounded,
                accent: AppColors.gold,
                onTap: () {
                  if (!context.mounted) return;
                  HomeNavGuard.go(() => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminPage(),
                        ),
                      ));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _adminCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (!context.mounted) return;
          onTap();
        },
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A1A1A),
                const Color(0xFF121212),
                accent.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accent.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.42),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: accent.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent.withValues(alpha: 0.18)),
                ),
                child: Icon(
                  icon,
                  color: accent,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _title(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(15, 20, 15, 10),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.gold,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
}