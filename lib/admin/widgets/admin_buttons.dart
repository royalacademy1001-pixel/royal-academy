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
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() {
        hovered = false;
        pressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => pressed = true),
        onTapUp: (_) => setState(() => pressed = false),
        onTapCancel: () => setState(() => pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: pressed ? 0.96 : (hovered ? 1.02 : 1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: hovered ? 0.08 : 0.05),
                  Colors.white.withValues(alpha: 0.01),
                ],
              ),
              border: Border.all(
                color: hovered
                    ? AppColors.gold.withValues(alpha: 0.35)
                    : AppColors.gold.withValues(alpha: 0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: hovered
                      ? AppColors.gold.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.2),
                  blurRadius: hovered ? 18 : 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold.withValues(
                        alpha: hovered ? 0.18 : 0.08,
                      ),
                    ),
                    child: Icon(
                      widget.icon,
                      color: AppColors.gold,
                      size: hovered ? 28 : 26,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: hovered ? 13 : 12,
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