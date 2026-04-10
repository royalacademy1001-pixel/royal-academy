import 'package:flutter/material.dart';
import '../../core/colors.dart';
import 'admin_stats_helpers.dart';

class AdminLiveSection extends StatelessWidget {
  final int activeUsers;
  final Map<String, dynamic> safeData;
  final int revenue;
  final int conversion;
  final String Function(int) format;

  const AdminLiveSection({
    super.key,
    required this.activeUsers,
    required this.safeData,
    required this.revenue,
    required this.conversion,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    final monthly = AdminStatsHelper.safe(safeData, 'monthly');
    final yearly = AdminStatsHelper.safe(safeData, 'yearly');

    return Column(
      children: [
        _buildLivePulse(activeUsers),
        const SizedBox(height: 12),
        _buildAnalyticalSection(monthly, yearly),
      ],
    );
  }

  Widget _buildLivePulse(int active) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.9, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.withValues(alpha: 0.10),
                  Colors.green.withValues(alpha: 0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.12),
                  blurRadius: 25,
                  spreadRadius: 1,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOut,
                  builder: (context, pulse, _) {
                    return Transform.scale(
                      scale: pulse,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green.withValues(alpha: 0.18),
                            ),
                          ),
                          const Icon(Icons.circle, color: Colors.green, size: 12),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "المتواجدون الآن",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: active.toDouble()),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Text(
                      format(value.toInt()),
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
                const Text(
                  "طالب",
                  style: TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalyticalSection(int monthly, int yearly) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: AppColors.premiumCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_outlined, color: AppColors.gold, size: 20),
              SizedBox(width: 10),
              Text(
                "التحليل المالي والتحويل",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _customProgressBar("العائد الشهري", monthly, revenue, Colors.blue),
          const SizedBox(height: 14),
          _customProgressBar("العائد السنوي", yearly, revenue, Colors.orange),
          const SizedBox(height: 14),
          _customProgressBar("نسبة التحويل VIP", conversion, 100, AppColors.gold),
        ],
      ),
    );
  }

  Widget _customProgressBar(
    String label,
    int val,
    int total,
    Color color,
  ) {
    final double percent = total == 0 ? 0 : (val / total).clamp(0, 1);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: percent),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, animatedPercent, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  label.contains("نسبة") ? "$val%" : format(val),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: animatedPercent,
                minHeight: 7,
                color: color,
                backgroundColor: color.withValues(alpha: 0.10),
              ),
            ),
          ],
        );
      },
    );
  }
}