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

  int displayValue = 0;

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

    _controller.forward();
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

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            AppColors.black,
            AppColors.black.withOpacity(0.92),
          ],
        ),
        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: AppColors.gold),
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
                Text(
                  _format(displayValue),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}