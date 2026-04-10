// 🔥 FINAL ADMIN WIDGETS (PRO MAX++ UPGRADE SAFE NO DELETE)

import 'package:flutter/material.dart';
import '../../core/colors.dart';

/// ================= STAT CARD =================
Widget buildStatCard(String title, int value, Color color) {
  return Container(
    margin: const EdgeInsets.all(10),
    padding: const EdgeInsets.all(14),
    decoration: AppColors.premiumCard,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [

        Icon(
          _getStatIcon(title),
          color: color,
          size: 26,
        ),

        const SizedBox(height: 10),

        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: value),
          duration: AppColors.normal,
          builder: (context, val, _) {
            return Text(
              val.toString(),
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),

        const SizedBox(height: 5),

        Text(
          title,
          style: const TextStyle(color: AppColors.white),
        ),
      ],
    ),
  );
}

/// 🔥 STAT ICON
IconData _getStatIcon(String title) {
  if (title.contains("مستخدم")) return Icons.people;
  if (title.contains("كورسات")) return Icons.menu_book;
  if (title.contains("أرباح")) return Icons.attach_money;
  if (title.contains("طلبات")) return Icons.receipt;
  if (title.contains("مدرس")) return Icons.school;
  if (title.contains("Analytics")) return Icons.analytics;

  return Icons.bar_chart;
}

/// ================= ADMIN BUTTONS =================

class AdminButtons extends StatelessWidget {
  final List<Map<String, dynamic>> pages;

  const AdminButtons({super.key, required this.pages});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: pages.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (context, index) {

        final item = pages[index];

        return _AdminCard(
          title: item['title'] ?? "",
          page: item['page'],
          icon: getIcon(item['title'] ?? ""),
          badge: item['badge'],
        );
      },
    );
  }

  /// 🔥 ICON LOGIC (UPGRADED)
  IconData getIcon(String title) {
    if (title.contains("كورسات")) return Icons.menu_book;
    if (title.contains("إشعارات")) return Icons.notifications;
    if (title.contains("الدفع")) return Icons.payments;
    if (title.contains("المستخدمين")) return Icons.people;
    if (title.contains("الطلاب")) return Icons.school;
    if (title.contains("مدرس")) return Icons.workspace_premium;
    if (title.contains("Analytics")) return Icons.analytics;

    return Icons.settings;
  }
}

/// ================= CARD =================

class _AdminCard extends StatefulWidget {
  final String title;
  final Widget page;
  final IconData icon;
  final int? badge;

  const _AdminCard({
    required this.title,
    required this.page,
    required this.icon,
    this.badge,
  });

  @override
  State<_AdminCard> createState() => _AdminCardState();
}

class _AdminCardState extends State<_AdminCard> {

  bool pressed = false;

  Color getColor() {
    if (widget.title.contains("كورسات")) return Colors.orange;
    if (widget.title.contains("الدفع")) return Colors.green;
    if (widget.title.contains("إشعارات")) return Colors.blue;
    if (widget.title.contains("المستخدمين")) return Colors.purple;
    if (widget.title.contains("مدرس")) return Colors.teal;
    if (widget.title.contains("Analytics")) return Colors.cyan;

    return AppColors.gold;
  }

  @override
  Widget build(BuildContext context) {

    final color = getColor();

    return GestureDetector(

      onTapDown: (_) => setState(() => pressed = true),
      onTapUp: (_) => setState(() => pressed = false),
      onTapCancel: () => setState(() => pressed = false),

      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => widget.page),
        );
      },

      child: AnimatedContainer(
        duration: AppColors.fast,
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(15),

        transform: Matrix4.identity()
          ..scale(pressed ? 0.93 : 1.0),

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: AppColors.cardGradient,
          border: Border.all(color: color.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: pressed
                  ? Colors.black
                  : color.withValues(alpha: 0.4),
              blurRadius: pressed ? 8 : 28,
              spreadRadius: 1,
            )
          ],
        ),

        child: Stack(
          children: [

            /// 🔴 BADGE
            if ((widget.badge ?? 0) > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.badge! > 9
                        ? "9+"
                        : widget.badge.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                /// 🔥 ICON
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.icon,
                    size: 30,
                    color: color,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}