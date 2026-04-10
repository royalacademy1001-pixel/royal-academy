import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../pages/users_page.dart';
import '../pages/payments_admin_page.dart';
import '../pages/courses_admin_page.dart';

class AdminStatsGrid extends StatelessWidget {
  final int users;
  final int subscribed;
  final int courses;
  final int revenue;
  final int pending;
  final int payments;
  final void Function(BuildContext context, Widget page) onNavigate;
  final String Function(int) format;

  const AdminStatsGrid({
    super.key,
    required this.users,
    required this.subscribed,
    required this.courses,
    required this.revenue,
    required this.pending,
    required this.payments,
    required this.onNavigate,
    required this.format,
  });

  void _go(BuildContext context, Widget page) {
    onNavigate(context, page);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxis = width >= 1400
            ? 4
            : width >= 1000
                ? 3
                : width >= 600
                    ? 2
                    : 2;

        final mainExtent = width >= 1000 ? 135.0 : 120.0;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxis,
            mainAxisExtent: mainExtent,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            switch (index) {
              case 0:
                return _premiumStatCard(
                  title: "المستخدمين",
                  value: users,
                  icon: Icons.group_outlined,
                  color: Colors.blue,
                  onTap: () => _go(context, const UsersPage()),
                );
              case 1:
                return _premiumStatCard(
                  title: "المشتركين",
                  value: subscribed,
                  icon: Icons.stars_rounded,
                  color: Colors.green,
                  onTap: () => _go(context, const UsersPage()),
                );
              case 2:
                return _premiumStatCard(
                  title: "الكورسات",
                  value: courses,
                  icon: Icons.auto_stories_rounded,
                  color: Colors.orange,
                  onTap: () => _go(context, const CoursesAdminPage()),
                );
              case 3:
                return _premiumStatCard(
                  title: "الأرباح",
                  value: revenue,
                  icon: Icons.account_balance_wallet_rounded,
                  color: AppColors.gold,
                  isGold: true,
                  onTap: () => _go(
                    context,
                    const PaymentsAdminPage(initialStatus: "approved"),
                  ),
                );
              case 4:
                return _premiumStatCard(
                  title: "معلق",
                  value: pending,
                  icon: Icons.hourglass_empty_rounded,
                  color: Colors.redAccent,
                  onTap: () => _go(
                    context,
                    const PaymentsAdminPage(initialStatus: "pending"),
                  ),
                );
              default:
                return _premiumStatCard(
                  title: "الطلبات",
                  value: payments,
                  icon: Icons.receipt_long_rounded,
                  color: Colors.grey,
                  onTap: () => _go(
                    context,
                    const PaymentsAdminPage(initialStatus: "all"),
                  ),
                );
            }
          },
        );
      },
    );
  }

  Widget _premiumStatCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isGold = false,
  }) {
    return _InteractiveStatCard(
      title: title,
      value: value,
      icon: icon,
      color: color,
      isGold: isGold,
      onTap: onTap,
      formatter: format,
    );
  }
}

class _InteractiveStatCard extends StatefulWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final bool isGold;
  final VoidCallback onTap;
  final String Function(int) formatter;

  const _InteractiveStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isGold,
    required this.onTap,
    required this.formatter,
  });

  @override
  State<_InteractiveStatCard> createState() => _InteractiveStatCardState();
}

class _InteractiveStatCardState extends State<_InteractiveStatCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isGold
        ? AppColors.gold.withValues(alpha: 0.07)
        : Colors.white.withValues(alpha: 0.025);

    final borderColor = widget.isGold
        ? AppColors.gold.withValues(alpha: _hovered ? 0.6 : 0.25)
        : Colors.white.withValues(alpha: _hovered ? 0.25 : 0.08);

    final shadowColor = widget.isGold
        ? AppColors.gold.withValues(alpha: _hovered ? 0.25 : 0.08)
        : Colors.black.withValues(alpha: _hovered ? 0.4 : 0.2);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (!mounted) return;
        setState(() => _hovered = true);
      },
      onExit: (_) {
        if (!mounted) return;
        setState(() {
          _hovered = false;
          _pressed = false;
        });
      },
      child: GestureDetector(
        onTapDown: (_) {
          if (!mounted) return;
          setState(() => _pressed = true);
        },
        onTapCancel: () {
          if (!mounted) return;
          setState(() => _pressed = false);
        },
        onTapUp: (_) {
          if (!mounted) return;
          setState(() => _pressed = false);
        },
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 140),
          scale: _pressed ? 0.96 : (_hovered ? 1.02 : 1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: baseColor,
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: _hovered ? 26 : 12,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: _hovered ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.color,
                    size: _hovered ? 22 : 20,
                  ),
                ),
                const Spacer(),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: widget.value.toDouble()),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, val, _) {
                    return Text(
                      widget.formatter(val.toInt()),
                      style: TextStyle(
                        color: widget.isGold ? AppColors.gold : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 3),
                Text(
                  widget.title,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 10.5,
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