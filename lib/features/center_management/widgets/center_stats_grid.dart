import 'package:flutter/material.dart';
import '../../../core/colors.dart';
import '../models/center_summary.dart';

class CenterStatsGrid extends StatelessWidget {
  final CenterSummary summary;

  const CenterStatsGrid({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem("الطلاب", summary.totalUsers, Icons.people),
      _StatItem("الكورسات", summary.totalCourses, Icons.menu_book),
      _StatItem("الجلسات", summary.totalSessions, Icons.event),
      _StatItem("المدفوعات", summary.totalPayments, Icons.payments),
      _StatItem("المدفوعات الناجحة", summary.approvedPayments, Icons.verified),
      _StatItem("الأرباح", summary.revenue.toInt(), Icons.monetization_on),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        int crossAxisCount = 2;

        if (width >= 1200) {
          crossAxisCount = 4;
        } else if (width >= 800) {
          crossAxisCount = 3;
        }

        return GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.7,
          ),
          itemBuilder: (context, index) {
            return _StatCard(item: items[index]);
          },
        );
      },
    );
  }
}

class _StatItem {
  final String title;
  final int value;
  final IconData icon;

  _StatItem(this.title, this.value, this.icon);
}

class _StatCard extends StatefulWidget {
  final _StatItem item;

  const _StatCard({required this.item});

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<double> _glow;

  int displayValue = 0;

  bool hovered = false;
  bool pressed = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _animation = Tween<double>(
      begin: 0,
      end: widget.item.value.toDouble(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ))
      ..addListener(() {
        if (!mounted) return;
        setState(() {
          displayValue = _animation.value.toInt();
        });
      });

    _glow = Tween<double>(begin: 0.05, end: 0.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _StatCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.item.value != widget.item.value) {
      _animation = Tween<double>(
        begin: 0,
        end: widget.item.value.toDouble(),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));

      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _format(int value) {
    if (value >= 1000000) {
      return "${(value / 1000000).toStringAsFixed(1)}M";
    }
    if (value >= 1000) {
      return "${(value / 1000).toStringAsFixed(1)}K";
    }
    return value.toString();
  }

  void _updateState() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        hovered = true;
        _updateState();
      },
      onExit: (_) {
        hovered = false;
        pressed = false;
        _updateState();
      },
      child: GestureDetector(
        onTapDown: (_) {
          pressed = true;
          _updateState();
        },
        onTapUp: (_) {
          pressed = false;
          _updateState();
        },
        onTapCancel: () {
          pressed = false;
          _updateState();
        },
        onTap: () {},
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: pressed
              ? 0.93
              : hovered
                  ? 1.07
                  : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(14),
            transform: Matrix4.identity()
              ..translate(0.0, hovered ? -6.0 : 0.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  AppColors.black,
                  AppColors.black.withOpacity(0.92),
                ],
              ),
              border: Border.all(
                color: hovered
                    ? AppColors.gold.withOpacity(0.9)
                    : AppColors.gold.withOpacity(0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: hovered
                      ? AppColors.gold.withOpacity(0.4)
                      : AppColors.gold.withOpacity(_glow.value),
                  blurRadius: hovered ? 26 : 16,
                  spreadRadius: hovered ? 2 : 0,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: hovered ? 48 : 42,
                  height: hovered ? 48 : 42,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(
                        hovered ? 0.3 : 0.12),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: hovered
                        ? [
                            BoxShadow(
                              color: AppColors.gold.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 1,
                            )
                          ]
                        : [],
                  ),
                  child: Icon(
                    item.icon,
                    color: AppColors.gold,
                    size: hovered ? 28 : 24,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          color: hovered
                              ? AppColors.gold
                              : Colors.white,
                          fontSize: hovered ? 21 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                        child: Text(_format(displayValue)),
                      ),
                    ],
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