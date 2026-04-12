import 'package:flutter/material.dart';
import '../../core/colors.dart';

class AdminButtons extends StatelessWidget {
  final List<Map<String, dynamic>> pages;

  const AdminButtons({super.key, required this.pages});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final crossAxisCount = width >= 1200
            ? 4
            : width >= 900
                ? 3
                : width >= 600
                    ? 3
                    : 2;

        return GridView.builder(
          itemCount: pages.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: width >= 900 ? 1.4 : 1.25,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final item = pages[index];
            final String title = item['title'] ?? "";
            final IconData icon = _getIcon(title);

            return _buildAdminButton(context, title, icon, item['page']);
          },
        );
      },
    );
  }

  Widget _buildAdminButton(
      BuildContext context, String title, IconData icon, Widget page) {
    return _AnimatedAdminCard(
      title: title,
      icon: icon,
      onTap: () {
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      },
    );
  }

  IconData _getIcon(String title) {
    if (title.contains("كورسات")) return Icons.auto_stories_rounded;
    if (title.contains("تصنيفات")) return Icons.category_rounded;
    if (title.contains("إشعارات")) return Icons.notifications_active_rounded;
    if (title.contains("مدفوعات")) return Icons.account_balance_wallet_rounded;
    if (title.contains("المستخدمين")) return Icons.people_alt_rounded;
    if (title.contains("طلاب")) return Icons.local_library_rounded;
    if (title.contains("مدرس")) return Icons.person_add_alt_1_rounded;
    if (title.contains("Analytics")) return Icons.insights_rounded;
    if (title.contains("أخبار")) return Icons.newspaper_rounded;

    return Icons.grid_view_rounded;
  }
}

class _AnimatedAdminCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _AnimatedAdminCard({
    required this.title,
    required this.icon,
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
      onEnter: (_) {
        if (!mounted) return;
        setState(() => hovered = true);
      },
      onExit: (_) {
        if (!mounted) return;
        setState(() {
          hovered = false;
          pressed = false;
        });
      },
      child: GestureDetector(
        onTapDown: (_) {
          if (!mounted) return;
          setState(() => pressed = true);
        },
        onTapUp: (_) {
          if (!mounted) return;
          setState(() => pressed = false);
        },
        onTapCancel: () {
          if (!mounted) return;
          setState(() => pressed = false);
        },
        onTap: () {
          try {
            widget.onTap();
          } catch (_) {}
        },
        child: AnimatedScale(
          duration: const Duration(milliseconds: 140),
          scale: pressed
              ? 0.92
              : hovered
                  ? 1.08
                  : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            transform: Matrix4.identity()
              ..translate(0.0, hovered ? -6.0 : 0.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: hovered ? 0.12 : 0.05),
                  Colors.white.withValues(alpha: 0.01),
                ],
              ),
              border: Border.all(
                color: hovered
                    ? AppColors.gold.withValues(alpha: 0.8)
                    : AppColors.gold.withValues(alpha: 0.15),
                width: hovered ? 1.6 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: hovered
                      ? AppColors.gold.withValues(alpha: 0.45)
                      : Colors.black.withValues(alpha: 0.25),
                  blurRadius: hovered ? 28 : 10,
                  spreadRadius: hovered ? 2 : 0,
                  offset: Offset(0, hovered ? 14 : 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold.withValues(
                        alpha: hovered ? 0.3 : 0.08,
                      ),
                      boxShadow: hovered
                          ? [
                              BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.5),
                                blurRadius: 24,
                                spreadRadius: 2,
                              )
                            ]
                          : [],
                    ),
                    child: Icon(
                      widget.icon,
                      color: AppColors.gold,
                      size: hovered ? 32 : 26,
                    ),
                  ),
                  const SizedBox(height: 10),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: hovered ? AppColors.gold : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: hovered ? 14 : 12,
                    ),
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}