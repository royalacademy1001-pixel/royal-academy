import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../admin/pages/admin_page.dart';
import '../../features/center_management/pages/center_management_page.dart';
import '../../core/colors.dart';
import '../../core/firebase_service.dart';
import 'home_nav_guard.dart';

class HomeAdminSection extends StatelessWidget {
  const HomeAdminSection({super.key});

  static bool? _cachedVisible;
  static DateTime? _lastCheckTime;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final useCache = _cachedVisible != null &&
        _lastCheckTime != null &&
        now.difference(_lastCheckTime!).inSeconds < 60;

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: useCache
          ? null
          : FirebaseService.firestore
              .collection("app_settings")
              .doc("home_sections")
              .get(),
      builder: (context, snapshot) {
        bool visible = true;

        if (useCache) {
          visible = _cachedVisible ?? true;
        } else {
          if (snapshot.hasData &&
              snapshot.data != null &&
              snapshot.data!.data() != null) {
            final config = snapshot.data!.data()!;
            final sections = config['sections'];

            if (sections is List) {
              final found = sections.where((e) {
                if (e is Map<String, dynamic>) {
                  return e['id'] == "admin";
                }
                return false;
              }).toList();

              if (found.isNotEmpty) {
                final item = found.first as Map<String, dynamic>;
                visible = (item['enabled'] ?? true) == true;
              }
            }
          }

          _cachedVisible = visible;
          _lastCheckTime = DateTime.now();
        }

        if (!visible) {
          return const SizedBox();
        }

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
      },
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
    final Color safeAccent = accent;
    return _AnimatedAdminCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      accent: safeAccent,
      onTap: onTap,
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

class _AnimatedAdminCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _AnimatedAdminCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_AnimatedAdminCard> createState() => _AnimatedAdminCardState();
}

class _AnimatedAdminCardState extends State<_AnimatedAdminCard> {
  bool hovered = false;
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() {
        hovered = false;
        pressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => pressed = true),
        onTapUp: (_) => setState(() => pressed = false),
        onTapCancel: () => setState(() => pressed = false),
        onTap: () {
          try {
            if (!context.mounted) return;
            widget.onTap();
          } catch (_) {}
        },
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: pressed
              ? 0.95
              : hovered
                  ? 1.03
                  : 1,
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
                  widget.accent.withValues(alpha: hovered ? 0.18 : 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: hovered
                    ? widget.accent.withValues(alpha: 0.5)
                    : widget.accent.withValues(alpha: 0.18),
              ),
              boxShadow: [
                BoxShadow(
                  color: hovered
                      ? widget.accent.withValues(alpha: 0.35)
                      : Colors.black.withValues(alpha: 0.42),
                  blurRadius: hovered ? 26 : 18,
                  spreadRadius: hovered ? 1 : 0,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: widget.accent.withValues(alpha: hovered ? 0.25 : 0.14),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.accent.withValues(alpha: hovered ? 0.5 : 0.18),
                    ),
                    boxShadow: hovered
                        ? [
                            BoxShadow(
                              color: widget.accent.withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 1,
                            )
                          ]
                        : [],
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.accent,
                    size: hovered ? 32 : 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          color: hovered ? widget.accent : Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: hovered ? 16 : 15,
                        ),
                        child: Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.subtitle,
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
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: hovered ? 0.1 : 0.04),
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
      ),
    );
  }
}